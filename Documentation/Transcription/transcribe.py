import sys
import os
import json
import torch
import whisper
import ssl
import urllib.request

# Force unbuffered stdout
sys.stdout.reconfigure(line_buffering=True)

# Bypass SSL certificate verification for downloads
ssl._create_default_https_context = ssl._create_unverified_context

MODEL_URLS = {
    "turbo": "https://openaipublic.azureedge.net/main/whisper/models/aff26ae408abcba5fbf8813c21e62b0941638c5f6eebfb145be0c9839262a19a/large-v3-turbo.pt",
    "medium": "https://openaipublic.azureedge.net/main/whisper/models/345ae4da62f9b3d59415adc60127b97c714f32e89e936602e85993674d08dcb1/medium.pt",
    "small": "https://openaipublic.azureedge.net/main/whisper/models/9ecf779972d90ba49c06d968637d720dd632c55bbf19d441fb42bf17a411e794/small.pt",
    "base": "https://openaipublic.azureedge.net/main/whisper/models/ed3a0b6b1c0edf879ad9b11b1af5a0e6ab5db9205f891f668f8b0e6c6326e34e/base.pt"
}


def check_and_download_model(model_name, cache_dir):
    os.makedirs(cache_dir, exist_ok=True)
    
    filename = "large-v3-turbo.pt" if model_name == "turbo" else f"{model_name}.pt"
    dest_path = os.path.join(cache_dir, filename)
    url = MODEL_URLS.get(model_name, MODEL_URLS["turbo"])
    
    print(f"[STATUS] Checking model file: {dest_path}")
    
    # Get total size of model from URL
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            total_size = int(response.info().get('Content-Length', 0))
    except Exception as e:
        print(f"[WARNING] Could not check remote model size: {e}. Will attempt using local file or download.")
        total_size = 0

    local_size = 0
    if os.path.exists(dest_path):
        local_size = os.path.getsize(dest_path)
        if total_size > 0 and local_size == total_size:
            print(f"[STATUS] Model '{model_name}' is already downloaded and verified ({local_size / (1024*1024):.2f} MB).")
            return dest_path
        elif local_size > total_size and total_size > 0:
            print(f"[WARNING] Local size {local_size} is larger than remote size {total_size}. Deleting and starting fresh.")
            os.remove(dest_path)
            local_size = 0

    # Start download
    headers = {'User-Agent': 'Mozilla/5.0'}
    mode = 'wb'
    downloaded = 0
    
    if local_size > 0:
        print(f"[STATUS] Local file exists but is incomplete ({local_size / (1024*1024):.2f} MB / {total_size / (1024*1024):.2f} MB). Attempting to resume...")
        headers['Range'] = f'bytes={local_size}-'
        mode = 'ab'
        downloaded = local_size
    else:
        print(f"[STATUS] Starting fresh download of model '{model_name}' ({total_size / (1024*1024):.2f} MB)...")
        
    sys.stdout.flush()

    try:
        req = urllib.request.Request(url, headers=headers)
        try:
            response = urllib.request.urlopen(req)
            # Check if server supports range requests (should return status 206 for range)
            status = response.status if hasattr(response, 'status') else 200
            if local_size > 0 and status != 206:
                # Range request not supported or ignored by server, restart from scratch
                print("[WARNING] Server did not accept Range request. Restarting download from scratch...")
                response.close()
                headers.pop('Range', None)
                mode = 'wb'
                downloaded = 0
                req = urllib.request.Request(url, headers=headers)
                response = urllib.request.urlopen(req)
        except Exception as e:
            if local_size > 0:
                print(f"[WARNING] Range request failed: {e}. Restarting download from scratch...")
                mode = 'wb'
                downloaded = 0
                req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
                response = urllib.request.urlopen(req)
            else:
                raise e

        with response:
            block_size = 1024 * 1024  # 1MB
            last_percent = -1
            
            # Print initial state if resuming
            if downloaded > 0:
                percent = int(downloaded * 100 / total_size)
                print(f"[DOWNLOAD PROGRESS] Resuming from {percent}% ({downloaded / (1024*1024):.2f} MB)")
                sys.stdout.flush()
                last_percent = percent

            with open(dest_path, mode) as f:
                while True:
                    buffer = response.read(block_size)
                    if not buffer:
                        break
                    f.write(buffer)
                    downloaded += len(buffer)
                    
                    if total_size > 0:
                        percent = int(downloaded * 100 / total_size)
                        if percent % 5 == 0 and percent != last_percent:
                            print(f"[DOWNLOAD PROGRESS] {percent}% completed ({downloaded / (1024*1024):.2f} MB / {total_size / (1024*1024):.2f} MB)")
                            sys.stdout.flush()
                            last_percent = percent
                    else:
                        print(f"[DOWNLOAD PROGRESS] Downloaded {downloaded / (1024*1024):.2f} MB")
                        sys.stdout.flush()
                        
        print("[STATUS] Download completed successfully.")
        sys.stdout.flush()
    except Exception as e:
        print(f"[ERROR] Failed to download model: {e}")
        sys.exit(1)
        
    return dest_path


def transcribe(audio_path, output_json, model_name="turbo"):
    if not os.path.exists(audio_path):
        print(f"[ERROR] Audio file {audio_path} does not exist.")
        sys.exit(1)
        
    # Check GPU/MPS availability
    mps_available = torch.backends.mps.is_available()
    device = "mps" if mps_available else "cpu"
    
    print(f"[STATUS] Device Info: MPS (Apple Silicon GPU) available = {mps_available}")
    print(f"[STATUS] Using device: {device.upper()}")
    sys.stdout.flush()
    
    # Download model if needed
    cache_dir = os.path.expanduser("~/.cache/whisper")
    model_file_path = check_and_download_model(model_name, cache_dir)
    
    print(f"[STATUS] Loading Whisper model '{model_name}' into device '{device.upper()}'...")
    sys.stdout.flush()
    
    # Load model
    model = whisper.load_model(model_name, device=device)
    print(f"[STATUS] Whisper model '{model_name}' loaded successfully. Starting transcription...")
    sys.stdout.flush()
    
    # Run transcription
    # Note: verbose=True will automatically print segments to stdout as they are processed
    result = model.transcribe(audio_path, verbose=True)
    
    print(f"[STATUS] Transcription completed. Saving output to {output_json}...")
    sys.stdout.flush()
    
    # Save the output to JSON
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    print(f"[STATUS] Successfully saved output to {output_json}")
    sys.stdout.flush()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python transcribe.py <audio_path> <output_json> [model_name]")
        sys.exit(1)
        
    audio = sys.argv[1]
    out_json = sys.argv[2]
    model = sys.argv[3] if len(sys.argv) > 3 else "turbo"
    
    transcribe(audio, out_json, model)
