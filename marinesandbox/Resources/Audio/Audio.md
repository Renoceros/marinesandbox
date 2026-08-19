# Audio & SFX Assets Specification

This document details all sound effects (SFX) and background audio loops required for the exhibition build of the Interactive Marine Sandbox. 

Place all compiled audio files in this directory:
`marinesandbox/Resources/Audio/`

All short interaction sounds should be in an uncompressed format (such as `.wav` or `.caf`) to minimize playback latency. Background loops should be compressed (such as `.mp3` or `.m4a`).

---

## 1. Active Care Tools (Interaction SFX)

| Filename | Format | Description / Audio Cue | Trigger Event |
| :--- | :--- | :--- | :--- |
| `brush_swipe.wav` | Short loop / dynamic | A soft, watery brushing or "swishing" sound with subtle grit. Plays while dragging the **Brush Tool** over algae cells. | Dragging brush on algae |
| `sparkle_clean.wav` | `.wav` | A bright, high-pitched chime, crystalline bubble pop, or magical sparkle ring. | Algae cell cleared by brush |
| `pest_smush.wav` | `.wav` | A wet, organic, satisfying squish or "splat" sound (no crunch, as snails are soft). | Tapping a pest with the **Hand Tool** |
| `pest_flick.wav` | `.wav` | An elastic, ascending whistle or "whoosh" sound. | Flicking a pest with a velocity > 100 pt/s |
| `pest_splash.wav` | `.wav` | A distant, muffled underwater splash or bubble drop. | Flipped pest despawns past the viewport bounds |

---

## 2. Coral Gardening & Seabed Placement

| Filename | Format | Description / Audio Cue | Trigger Event |
| :--- | :--- | :--- | :--- |
| `frag_lift.wav` | `.wav` | A light, upward-pitching bubble pop or soft suction release. | Selecting/lifting a fragment from the palette |
| `frag_plant.wav` | `.wav` | A soft, sand-displacement "thump" or muffled gravelly settle. | Fragment snapping/planting onto the seabed |
| `plant_reject.wav` | `.wav` | A low-frequency, dull wobble bubble or gentle rejection "donk". | Dropping a fragment outside playable boundaries |

---

## 3. Menu, UI & Progression

| Filename | Format | Description / Audio Cue | Trigger Event |
| :--- | :--- | :--- | :--- |
| `tool_switch.wav` | `.wav` | A clean, mechanical underwater click or soft switch click. | Tapping Hand, Brush, or Plant tools on HUD |
| `palette_slide.wav` | `.wav` | A rattling coral/gravel sliding sound. | Palette sliding up when unlocked at Teenager |
| `fast_forward_swell.wav` | `.wav` | An atmospheric, rising bubble rush, ticking stopwatch, or wind swell. | Initiating the 5-Year Fast Forward sweep |
| `card_pop.wav` | `.wav` | A clean, soft transition sweep or ambient chime. | Diagnostic Card modal sliding into focus |
| `click_dismiss.wav` | `.wav` | A gentle bubble pop or downward swoop. | Closing modals / returning to the reef screen |

---

## 4. Background Ambient & Threat Loops

| Filename | Format | Description / Audio Cue | Trigger Event |
| :--- | :--- | :--- | :--- |
| `ambient_ocean_loop.mp3` | Loopable `.mp3` | A continuous, low-frequency underwater loop (muffled currents, bubbles, distant marine life clicks). | Continuous loop on the main sandbox screen |
| `threat_warning.wav` | `.wav` | A subtle, organic underwater echo or deep warning tone (e.g., distant warning click/rumble). | Warning when algae exceeds 75% or pests spawn |
