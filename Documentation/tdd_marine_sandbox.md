# Technical Design Document (TDD): Interactive Marine Sandbox (iOS)

**Document Version:** v1.3  
**Status:** Directory Architecture & Backlog Defined (Updated for 2-Week MVP Scope)  

---

## 1. Team & Backlog Ownership

### 1.1 Team Members
*   **Team:** Bishal, Reno, Zarina, Samantha, Bobo
*   **Role Allocation:** Roles are not finalized. Tasks from the MVP Chores backlog are grabbed dynamically by developers during sprint planning.

### 1.2 MVP Chores Backlog (Sprint Task Board)
Below is the master list of tasks required to build the MVP, annotated with their scoping for the 2-week deadline. Developers claim these tasks by prefixing branches with their names (e.g., `feat/samantha/TASK-102-eco-engine`).

| Task ID | Component | Task Title / Description | Dependencies | MVP Scope Status |
| --- | --- | --- | --- | --- |
| **TASK-101** | Models | Implement SwiftData schemas (`UserProfile`, `ReefCanvas`, `PlacedStructure`, `CoralFrag`). | None | **In Scope** (Basic local models, no complex security wrappers) |
| **TASK-102** | Services | Implement `EcoEngine.swift` state math functions, Shannon index, and growth calculations. | TASK-101 | **In Scope** |
| **TASK-103** | UI | Build `LottieCoralView.swift` SwiftUI wrapper and logic to scrub playheads based on state. | None | **In Scope** (Supports fallback default rendering if vector resources are mock) |
| **TASK-104** | UI | Build `ParallaxScrollView.swift` horizontal container with 3-layer parallax translation. | None | **In Scope** |
| **TASK-105** | ViewModel| Implement `SandboxViewModel.swift` state coordination, Fast Forward, and Reset operations. | TASK-102 | **In Scope** |
| **TASK-106** | UI | Create main `SandboxView.swift` foreground seabed canvas with drag-and-drop structures. | TASK-104, TASK-105 | **In Scope** |
| **TASK-107** | UI | Design and implement the `DiagnosticCardView.swift` reflection modals and text parsing. | TASK-105 | **In Scope** |
| **TASK-108** | Services | Set up static JSON configurations for local presets (`NGOConfig`). | None | **In Scope** (Only Bali/Living Seas configuration is loaded) |
| **TASK-109** | Security | Enforce COPPA guidelines: encrypt saved data and isolate user profiles inside local container storage. | TASK-101 | **Deferred** (Basic unencrypted offline sandbox storage for MVP) |
| **TASK-110** | Integration| Build Apple native iCloud / CloudKit syncing layer for profiles and settings. | TASK-101 | **Deferred** (No cloud sync, local only for 2-week launch) |
| **TASK-111** | UI | Construct the `ShareCardView.swift` custom 9:16 layout and export wrapper. | TASK-106 | **In Scope** |

---

## 2. Architecture Overview

### 2.1 Layer Diagram (MVVM + S)
The application adheres to a strict 4-layer MVVM pattern.

```
+-------------------------------------------------------------+
|                          VIEW LAYER                         |
|   - ParallaxScrollView: Renders 3 layers (BG, Mid, FG).     |
|   - LottieCoralView: Binds to animation frame progress.     |
+------------------------------+------------------------------+
                               | Observes ViewModels
+------------------------------v------------------------------+
|                       VIEWMODEL LAYER                       |
|   - SandboxViewModel: Coordinates active/timelapse states,   |
|     receives touch inputs, runs fastForward() triggers.      |
+------------------------------+------------------------------+
                               | Calls Services
+------------------------------v------------------------------+
|                       SERVICES LAYER                        |
|   - EcoEngine: Pure Swift, stateless, execution of math.    |
|   - CloudKitSync: Handles background iCloud account sync.   |
+------------------------------+------------------------------+
                               | Persists to
+------------------------------v------------------------------+
|                     STORAGE/DATABASE LAYER                  |
|   - SwiftData: Local persistent store (saves grid layouts). |
+-------------------------------------------------------------+
```

### 2.2 Project Directory Architecture (MVVM+S Structure)
Below is the layout of the project's source root, standardizing where all MVP implementation files live.

```
MarineSandbox/
├── App/
│   └── MarineSandboxApp.swift          # App entry point, SwiftData container initialization
├── Models/
│   ├── UserProfile.swift               # SwiftData profile schema (unlocked cosmetics, saves)
│   ├── ReefCanvas.swift                # SwiftData canvas schema (NGO region, location type, width)
│   ├── PlacedStructure.swift           # SwiftData structural entity (xPos coordinate, structure type)
│   ├── CoralFrag.swift                 # SwiftData biological fragment state (species, growth, bleaching)
│   └── NGOConfig.swift                 # Environmental static data configurations (Bali, Jeju, Caribbean)
├── ViewModels/
│   └── SandboxViewModel.swift          # Coordinates simulation state, input handlers, active workflows
├── Views/
│   ├── Canvas/
│   │   ├── SandboxView.swift           # Primary interactive scroll view canvas
│   │   ├── ParallaxScrollView.swift    # Background, Midground, and Foreground rendering container
│   │   └── LottieCoralView.swift       # Lottie view wrapping animation frame-scrubbing controllers
│   ├── Modals/
│   │   ├── DiagnosticCardView.swift    # Post-timelapse feedback overlay popup cards
│   │   └── ShareCardView.swift         # Visual share postcard generator (9:16 layout)
│   └── GlobalMap/
│       └── GlobalMapView.swift         # Virtual globe showing pins of peer sandboxes (roadmap item)
├── Services/
│   ├── EcoEngine.swift                 # Pure math stateless ecosystem update calculations
│   ├── CloudKitSync.swift              # Handles background CloudKit container synchronization
│   └── QRScannerService.swift          # Handles NGO code scanning (roadmap item)
└── Resources/
    ├── Assets.xcassets/                # Image catalogs, custom UI colors, app icons
    ├── Lottie/                         # Vector JSON animations (e.g. acropora_grow.json)
    └── Configs/                        # Static regional environmental JSON presets (e.g. BaliConfig.json)
```

### 2.3 Core Architectural Mandates
*   **Continuous Coordinates:** Positions along the seabed are represented as continuous floating-point horizontal offsets (`xPos`), rather than discrete grid cells.
*   **Frame-Bound Lottie Playbacks:** Coral growth and decay animations must be driven dynamically by binding the `CoralFrag.growthProgress` and `CoralFrag.algaePercentage` to the progress bounds of a Lottie vector animation file.
*   **Local-First Sync:** SwiftData handles local state and profile storage offline. Syncing occurs in the background via native CloudKit container integration.

---

## 3. Data Models & Lottie Integration

### 3.1 SwiftData Domain Models

```swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var currentSaveDate: Date
    var unlockedCosmetics: [String] // List of unlocked skin IDs from QR codes
    var activeCanvas: ReefCanvas?
    
    init(id: UUID = UUID(), currentSaveDate: Date = Date(), unlockedCosmetics: [String] = []) {
        self.id = id
        self.currentSaveDate = currentSaveDate
        self.unlockedCosmetics = unlockedCosmetics
    }
}

@Model
final class ReefCanvas {
    @Attribute(.unique) var id: UUID
    var ngoRegion: String // "Bali", "Jeju", "Caribbean"
    var locationType: String // "ShallowFlat", "DeepWall", "CurrentChannel"
    var canvasWidth: Double // Total horizontal scroll width
    @Relationship(deleteRule: .cascade) var placedStructures: [PlacedStructure]
    
    init(id: UUID = UUID(), ngoRegion: String, locationType: String, canvasWidth: Double = 2000.0, placedStructures: [PlacedStructure] = []) {
        self.id = id
        self.ngoRegion = ngoRegion
        self.locationType = locationType
        self.canvasWidth = canvasWidth
        self.placedStructures = placedStructures
    }
}

@Model
final class PlacedStructure {
    @Attribute(.unique) var id: UUID
    var xPos: Double // Continuous horizontal offset on the seabed
    var structureType: String // "ReefStar", "Bottle"
    @Relationship(deleteRule: .cascade) var coral: CoralFrag?
    
    init(id: UUID = UUID(), xPos: Double, structureType: String, coral: CoralFrag? = nil) {
        self.id = id
        self.xPos = xPos
        self.structureType = structureType
        self.coral = coral
    }
}

@Model
final class CoralFrag {
    var species: String // "Acropora", "BrainCoral", "Fimbria"
    var growthProgress: Double // 0.0 (Baby) to 1.0 (Mature)
    var algaePercentage: Double // 0.0 (Clean) to 1.0 (Fully Smothered)
    var isBleached: Bool
    var isDead: Bool
    
    init(species: String, growthProgress: Double = 0.0, algaePercentage: Double = 0.0, isBleached: Bool = false, isDead: Bool = false) {
        self.species = species
        self.growthProgress = growthProgress
        self.algaePercentage = algaePercentage
        self.isBleached = isBleached
        self.isDead = isDead
    }
}
```

### 3.2 Lottie Animation Frame Integration Mechanics
To visualize the gradual growth, bleaching, or algae overgrowth, each coral species is mapped to a unified Lottie animation containing specific frame segments:

```
Lottie Animation Playhead (0.0 to 1.0 Progress)
+-------------------------------------------------------------------------------+
|   Growth Sequence (0.0 -> 0.6)   |  Bleaching (0.6 -> 0.8) |  Algae (0.8 -> 1.0) |
|  Baby -> Juvenile -> Adult Coral  |  Healthy -> Stark White |  Smothered / Decay  |
+-------------------------------------------------------------------------------+
```

*   **Lottie Animation Mapping Rule:**
    *   **Growth Phase:** Map `CoralFrag.growthProgress` directly to Lottie progress `0.0` to `0.6`.
    *   **Bleached State:** If `isBleached == true`, interpolate playhead from `0.6` (healthy adult) to `0.8` (pure white skeleton).
    *   **Algae Smothered State:** If `algaePercentage > 0.0`, interpolate playhead from `0.6` to `1.0` proportionally, representing a hairy brown moss layer covering the structure.
    *   **Mortality State:** If `isDead == true`, run playhead to `1.0` representing a grey rubble structure.

---

## 4. Visual Parallax Architecture

To render the visual depth Maximia expects, the canvas uses a custom horizontal scroll container with three overlay layers translating at different ratios based on the scroll coordinate:

```swift
import SwiftUI

struct ParallaxScrollView<Content: View>: View {
    let canvasWidth: CGFloat
    let foregroundContent: Content
    
    @State private var scrollOffset: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                ZReader {
                    // Layer 1: Background Layer (Parallax Ratio: 0.2)
                    BackgroundLayer()
                        .offset(x: scrollOffset * 0.8) // Counter-scroll offset to slow down
                        .frame(width: canvasWidth)
                    
                    // Layer 2: Midground Layer (Parallax Ratio: 0.5)
                    MidgroundLayer()
                        .offset(x: scrollOffset * 0.5)
                        .frame(width: canvasWidth)
                    
                    // Layer 3: Foreground Layer (Active Interactive Bed) (Parallax Ratio: 1.0)
                    foregroundContent
                        .frame(width: canvasWidth)
                }
                .background(GeometryReader { proxy in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: proxy.frame(in: .named("scroll")).minX
                    )
                })
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                self.scrollOffset = value
            }
        }
    }
}
```

---

## 5. Engineering Standards & Operations

### 5.1 Swift-Native Ecological Engine Implementation
The simulation engine functions as a stateless math processor. 

```swift
struct EcoEngine {
    static func updateState(
        canvas: ReefCanvas,
        location: LocationConfig,
        threats: ThreatVector,
        steps: Int
    ) -> ReefCanvas {
        var updatedCanvas = canvas
        
        for _ in 0..<steps {
            // 1. Calculate Shannon Diversity Index (H)
            let H = calculateShannonIndex(for: updatedCanvas)
            
            // 2. Calculate Herbivore Recruitment modulated by H
            let herbivoreRecruitment = baseHerbivoreRate * (1.0 + beta * H) * calculateTotalCoralCover(for: updatedCanvas)
            
            // 3. Process placed structures
            for structure in updatedCanvas.placedStructures {
                guard let coral = structure.coral else { continue }
                
                // Growth calculation adjusted by location and algae overgrowth
                let lightFactor = location.lightFactor
                let currentFactor = location.currentFactor
                let algaeSmotherModifier = 1.0 - coral.algaePercentage
                
                let growthIncrement = baseGrowthRate * lightFactor * currentFactor * algaeSmotherModifier
                coral.growthProgress = min(1.0, coral.growthProgress + growthIncrement)
                
                // Process Algae growth vs Grazer control
                let nutrientInflow = threats.agriculturalRunoff ? 2.5 : 1.0
                let algaeGrowth = baseAlgaeGrowthRate * nutrientInflow
                let grazingRate = herbivoreRecruitment * baseGrazingRate
                coral.algaePercentage = max(0.0, min(1.0, coral.algaePercentage + algaeGrowth - grazingRate))
                
                // Process Heat stress (Bleaching)
                if threats.waterTemperature > 30.0 {
                    coral.isBleached = true
                } else if coral.isBleached && !threats.isHeatwaveActive && coral.algaePercentage < 0.3 {
                    coral.isBleached = false
                }
                
                // Mortality check (If bleached coral is smothered by algae, it dies)
                if coral.isBleached && coral.algaePercentage > 0.8 {
                    coral.isDead = true
                }
            }
        }
        
        return updatedCanvas
    }
}
```

### 5.2 Security & Compliance
*   **GDPR / COPPA Safety:** No textual database entry for user profiles. All shared configurations are represented by a randomly generated structural code and an anonymous pseudonym.
*   **App Store Submissions:** Provide a clear "Reset Profile" button in settings that deletes the `UserProfile` data to fulfill iOS guidelines.

---

## 6. Development Workflow
*   **Branching Convention:** `feat/{developer-name}/{TASK-ID-description}` (e.g., `feat/sam/TASK-102-eco-engine`).
*   **Mock Seeding Configuration:** Reads static JSON files (such as `BaliConfig.json`) to seed standard NGO parameters during mock runs.
