# Technical Design Document (TDD): Interactive Marine Sandbox (iOS)

**Document Version:** v1.3  
**Status:** Directory Architecture & Backlog Defined (Updated for 2-Week MVP Scope)  

---

## 1. Team & Backlog Ownership

### 1.1 Team Members & Roles
*   **Reno (PM-Coder Hybrid):** Coordinates development, interactive view flows, and onboarding view integrations.
*   **Bishal (Backend Connoisseur):** Owns SwiftData schemas, mathematical `EcoEngine`, view models, and state coordination.
*   **Zarina (Coder / UX Tester):** Handles app integration, Bali regional presets, and share card generation.
*   **Bobo (Frontend / SwiftUI):** Develops custom layouts, parallax scrolling, Lottie integrations, and recruited fish layers.
*   **Sam (Designer / UX):** Leads visual layouts, asset specifications, and share postcard design mocks.

### 1.2 MVP Chores Backlog (Sprint Task Board)
Below is the master list of tasks required to build the MVP and subsequent features, matching the task breakdown.

| Task ID | Component | Task Title / Description | PIC | MVP Scope Status |
| --- | --- | --- | --- | --- |
| **TASK-TD-101** | `marinesandbox/Services` | Implement `marinesandbox/Services/EcoEngine.swift` core stateless math: Shannon Index, time-step growth progress, algae, and bleaching. | Bishal | **In Scope** (Tech Demo) |
| **TASK-TD-102** | `marinesandbox/Views` | Implement the skeleton of `marinesandbox/Views/Canvas/ParallaxScrollView.swift` with three horizontal scroll layers. | Bobo | **In Scope** (Tech Demo) |
| **TASK-TD-103** | `marinesandbox/Views` | Create `marinesandbox/Views/Canvas/MockCoralView.swift` to render growth stages, algae shifts, and bleaching states. | Reno | **In Scope** (Tech Demo) |
| **TASK-TD-104** | `marinesandbox/Views` | Build mid-fidelity canvas UI overlays for care tool selection (Brush/Hand) and status messages. | Bobo | **In Scope** (Tech Demo) |
| **TASK-TD-105** | `marinesandbox/Views` | Integrate notifications/alerts for active threats (algae overgrowth in baby/teen, or predator damage > 75%). | Reno / Bobo | **In Scope** (Tech Demo) |
| **TASK-TD-106** | `marinesandbox/Views` | Redirect entry point to launch `TechDemoView` root view and implement bottom debug log console. | Zarina | **In Scope** (Tech Demo) |
| **TASK-MVP-201** | `marinesandbox/Models` | Implement SwiftData schemas (`UserProfile`, `ReefCanvas`, `PlacedStructure`, `CoralFrag`) in `marinesandbox/Models/`. | Bishal | **In Scope** |
| **TASK-MVP-202** | `marinesandbox/ViewModels`| Implement `marinesandbox/ViewModels/SandboxViewModel.swift` state coordination and Fast Forward operations. (Hard Reset moved to settings). | Bishal | **In Scope** |
| **TASK-MVP-203** | `marinesandbox/Services` | Set up static JSON configurations for local presets (`NGOConfig`) to seed mock Bali data on launch. | Zarina | **In Scope** |
| **TASK-MVP-204** | `marinesandbox/Views` | Build Location Selection Screen and user routing system (new vs. returning users). | Reno / Bobo | **In Scope** |
| **TASK-MVP-301** | `marinesandbox/Views` | Build `LottieCoralView.swift` SwiftUI wrapper and logic to scrub playheads based on state. | Bobo | **In Scope** |
| **TASK-MVP-302** | `marinesandbox/Views` | Add custom animations and touch feedback for Brush Tool and Snail Kill Tool. | Reno | **In Scope** |
| **TASK-MVP-303** | `marinesandbox/Views` | Connect the midground layer to render custom recruited fauna silhouettes. | Bobo | **In Scope** |
| **TASK-MVP-304** | `marinesandbox/Views` | Construct the `ShareCardView.swift` custom 9:16 layout and export wrapper. | Zarina / Sam | **In Scope** |
| **TASK-MVP-305** | `marinesandbox/Views` | Implement local registration prompt dialog to save progress after adult coral matures. | Bishal | **In Scope** |
| **TASK-MVP-401** | `marinesandbox/Services` | Verify EcoEngine calculations under long simulations (math stress tests). | Bishal / Zarina | **In Scope** |
| **TASK-MVP-402** | `marinesandbox/Views` | Optimize `ParallaxScrollView` render frames to ensure fluid 60fps scrolling. | Bobo / Zarina | **In Scope** |
| **TASK-MVP-403** | `All` | Code review cleanup and memory safety check (`[weak self]`). | All | **In Scope** |
| **TASK-ROAD-501** | `marinesandbox/Services` | Enforce COPPA guidelines: encrypt saved data and isolate user profiles inside local container storage. | Bishal / Zarina | **Deferred** |
| **TASK-ROAD-502** | `marinesandbox/Services` | Build Apple native iCloud / CloudKit syncing layer for profiles and settings. | Bishal | **Deferred** |
| **TASK-ROAD-503** | `marinesandbox/Views` | Implement advanced parallax micro-animations (swaying seaweed/seagrass blades, custom spline swimming fish paths). | Bobo | **Deferred** |

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
marinesandbox/
├── App/
│   └── MarineSandboxApp.swift          # App entry point, SwiftData container initialization
├── Models/
│   ├── UserProfile.swift               # SwiftData profile schema (unlocked cosmetics, saves)
│   ├── ReefCanvas.swift                # SwiftData canvas schema (NGO region, width)
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
    │   ├── FG/                         # Foreground image assets (FG0, FG1, FG2)
    │   ├── MG/                         # Midground image assets (MG0, MG1, MG2)
    │   └── BG/                         # Background image assets (BG0, BG1, BG2)
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
    var canvasWidth: Double // Total horizontal scroll width
    @Relationship(deleteRule: .cascade) var placedStructures: [PlacedStructure]
    
    init(id: UUID = UUID(), ngoRegion: String, canvasWidth: Double = 2000.0, placedStructures: [PlacedStructure] = []) {
        self.id = id
        self.ngoRegion = ngoRegion
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
    var species: String // "Acropora" (Staghorn), "BrainCoral" (Massive), etc.
    var growthProgress: Double // 0.0 (Baby) to 1.0 (Mature Adult)
    var algaePercentage: Double // 0.0 (Clean) to 1.0 (Fully Smothered)
    var predatorDamage: Double // 0.0 (None) to 1.0 (Fully Consumed)
    var activePredators: [String] // ["CrownOfThorns", "DrupellaSnail", "Flatworm"]
    var isBleached: Bool
    var isDead: Bool
    
    // Computed helper variables for growth stages
    var isBaby: Bool { growthProgress < 0.3 && !isDead }
    var isTeenager: Bool { growthProgress >= 0.3 && growthProgress < 0.7 && !isDead }
    var isAdult: Bool { growthProgress >= 0.7 && !isDead }
    
    init(species: String, growthProgress: Double = 0.0, algaePercentage: Double = 0.0, predatorDamage: Double = 0.0, activePredators: [String] = [], isBleached: Bool = false, isDead: Bool = false) {
        self.species = species
        self.growthProgress = growthProgress
        self.algaePercentage = algaePercentage
        self.predatorDamage = predatorDamage
        self.activePredators = activePredators
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

## 4. Visual Parallax Architecture (Permutation-Based 3-Segment Tiling)

To provide spatial depth and variety without infinite scrolling, the sandbox implements a **Fixed 3-Segment Parallax** container optimized for modern device dimensions.

### 4.1. Conceptual Specifications
1. **Device Target:** Target device is the **iPhone 17 base model** (with a standard 19.5:9 display aspect ratio).
2. **Landscape Dimensions (3-Segment Limit):** The landscape view is not infinite. It is stitched together from exactly **3 segments** (columns `0, 1, 2`). Each segment has a width of exactly **1.5x the viewport width** ($W = 1.5 \times \text{viewportWidth}$), resulting in a total content width of $4.5\times$ the viewport width (representing 4.5x whole screen swipes).
3. **Clamped Scrolling Boundaries:** To prevent the user from scrolling past the boundaries of the 3-segment landscape, the active scroll offset `scrollX` is strictly clamped:
   $$\text{scrollX} \in [-(3 \times W - \text{viewportWidth}), 0.0] \implies \text{scrollX} \in [-3.5 \times \text{viewportWidth}, 0.0]$$
4. **ZStack Draw Order:** The layers are drawn back-to-front inside a single viewport container:
   * **1st (Backmost):** Solid backdrop color `#3BAFED` ignoring all safe areas.
   * **2nd:** Midground Layer (MG, Ratio: 0.50, Top-Pinned)
   * **3rd:** Background Layer (BG, Ratio: 0.20, Top-Pinned)
   * **4th (Frontmost):** Foreground Layer (FG, Ratio: 1.00, Bottom-Pinned)
5. **Prevision Permutation Rule (No Duplicate Stacks):** To prevent duplicate assets from stacking vertically (e.g. avoiding matching `0-0-0` or `1-1-1` layers), each segment column `col` calculates a deterministic permutation of the three variant indices `[0, 1, 2]`. Each layer (BG, MG, FG) gets a unique index from the permutation, ensuring diverse visual combinations per column.
6. **Unseamed Rendering (No Transitions):** Because the 3 columns are rendered statically inside a constant `0..<3` list, no views are added or removed during panning. This guarantees absolute zero transitions, zero fades, and a perfectly "unseamed" sliding camera pan.

### 4.2. Mathematical Formulations
* For a given layer with speed ratio $R$, its scroll translation is:
  $$\text{layerOffset} = \text{scrollX} \times R$$
* The left-most visible column index is:
  $$\text{startCol} = \lfloor -\text{layerOffset} / W \rfloor$$
* The number of columns rendering in the viewport is:
  $$\text{visibleCount} = \lceil \text{viewportWidth} / W \rceil + 1$$
* The deterministic block mapping function for background/midground layers:
  $$f(\text{col}, \text{seed}) = |((\text{col} \oplus \text{seed}) \times 324159265) \oplus ((\text{col} \oplus \text{seed}) \gg 16)| \pmod 3$$

### 4.3. Swift Implementation Spec

```swift
import SwiftUI

public enum BlockVariant {
    case blockA, blockB, blockC
}

struct ParallaxScrollView: View {
    @State private var scrollX: CGFloat = 0.0
    @State private var dragOffset: CGFloat = 0.0 // State variable supporting momentum glide
    
    var body: some View {
        GeometryReader { geometry in
            let viewportWidth = geometry.size.width
            let height = geometry.size.height
            let blockWidth = viewportWidth * 1.5
            
            // Total content width is 3 * blockWidth (4.5 * viewportWidth)
            let minScroll = viewportWidth - (blockWidth * 3) // Clamps view to exactly 3 segments
            let currentOffset = scrollX + dragOffset
            
            ZStack(alignment: .leading) {
                // 1st Layer: Solid backdrop color (#3BAFED)
                Color(hex: "3BAFED")
                    .edgesIgnoringSafeArea(.all)
                
                // 2nd Layer: Midground Layer (Parallax Ratio: 0.50, Top-Aligned)
                layerContainer(viewportWidth: viewportWidth, height: height, blockWidth: blockWidth, offset: currentOffset * 0.50, layerName: "Midground", alignment: .top)
                
                // 3rd Layer: Background Layer (Parallax Ratio: 0.20, Top-Aligned)
                layerContainer(viewportWidth: viewportWidth, height: height, blockWidth: blockWidth, offset: currentOffset * 0.20, layerName: "Background", alignment: .top)
                
                // 4th Layer: Foreground Layer (Parallax Ratio: 1.00, Bottom-Aligned)
                layerContainer(viewportWidth: viewportWidth, height: height, blockWidth: blockWidth, offset: currentOffset * 1.00, layerName: "Foreground", alignment: .bottom)
            }
            .edgesIgnoringSafeArea(.all)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Strict clamping during active drag to lock horizontal scrolling to exactly 3 segments
                        let activeOffset = scrollX + value.translation.width
                        let clampedOffset = max(minScroll, min(0, activeOffset))
                        dragOffset = clampedOffset - scrollX
                    }
                    .onEnded { value in
                        let predicted = value.predictedEndTranslation.width
                        let targetX = scrollX + predicted
                        let clampedTarget = max(minScroll, min(0, targetX))
                        
                        withAnimation(.easeOut(duration: 1.2)) {
                            scrollX = clampedTarget
                            dragOffset = 0.0
                        }
                    }
            )
        }
    }
    
    @ViewBuilder
    private func layerContainer(
        viewportWidth: CGFloat,
        height: CGFloat,
        blockWidth: CGFloat,
        offset: CGFloat,
        layerName: String,
        alignment: Alignment
    ) -> some View {
        ZStack(alignment: .leading) {
            ForEach(0..<3, id: \.self) { col in
                let xPosition = CGFloat(col) * blockWidth + offset
                let perm = getPermutation(col: col)
                
                // Mutually exclusive variant index ensures no duplicate 0-0-0 or 1-1-1 stacks occur
                let variantIndex = layerName == "Background" ? perm[0] : (layerName == "Midground" ? perm[1] : perm[2])
                
                VStack(spacing: 0) {
                    if alignment == .bottom {
                        Spacer()
                    }
                    renderBlockView(layer: layerName, variantIndex: variantIndex)
                        .frame(width: blockWidth)
                    if alignment == .top {
                        Spacer()
                    }
                }
                .frame(width: blockWidth, height: height)
                .offset(x: xPosition)
                .transition(.identity)
            }
        }
    }
    
    // Returns a unique permutation of variant indices [0, 1, 2] per column
    private func getPermutation(col: Int) -> [Int] {
        let permutations = [
            [0, 1, 2], [0, 2, 1], [1, 0, 2],
            [1, 2, 0], [2, 0, 1], [2, 1, 0]
        ]
        let hash = abs((col ^ 1001) &* 324159265) % 6
        return permutations[hash]
    }
    
    @ViewBuilder
    private func renderBlockView(layer: String, variantIndex: Int) -> some View {
        let prefix = layer == "Background" ? "BG" : (layer == "Midground" ? "MG" : "FG")
        Image("\(prefix)\(variantIndex)")
            .resizable()
    }
}
```

### 4.4. Technical Debt & Architectural Trade-offs
*   **Asymmetrical State Management (Tech Debt DEBT-001):** Decoupling background column rendering from foreground active structure arrays means the app maintains two separate coordination systems. Backgrounds are purely stateless (derived from coordinates), whereas foregrounds require full SwiftData CRUD updates.
*   **Visual Drift Risk:** Since the layers scroll at different speeds, the visual alignment between a background landmark (e.g., a shipwreck) and a foreground coordinate will change. Playable reef boundaries must be constrained to foreground coordinates to prevent user interaction drift.
*   **Non-Infinite Foreground Restriction:** Unlocking foreground columns slowly requires managing a hard limit bounds constraint in `SandboxViewModel.swift`, preventing the user from scrolling past the currently unlocked foreground column, while background elements scroll infinitely underneath.


---

## 5. Engineering Standards & Operations

### 5.1 Swift-Native Ecological Engine Implementation
The simulation engine functions as a stateless math processor. It implements time-step updates calculating growth, algae competition, predator damage, and recruited fauna based on the growth stages defined in the user journey.

```swift
struct EcoEngine {
    static func updateState(
        canvas: ReefCanvas,
        threats: ThreatVector,
        steps: Int
    ) -> ReefCanvas {
        var updatedCanvas = canvas
        
        for _ in 0..<steps {
            // 1. Calculate Shannon Diversity Index (H)
            let H = calculateShannonIndex(for: updatedCanvas)
            
            // 2. Calculate Fauna Recruitment counts based on growth stages
            var smallReefFishCount = 0
            var gobiesAndDamselfishCount = 0
            var largeSchoolsCount = 0
            var herbivoreCount = 0
            var predatorCount = 0
            
            for structure in updatedCanvas.placedStructures {
                guard let coral = structure.coral, !coral.isDead else { continue }
                if coral.isBaby {
                    smallReefFishCount += 1
                } else if coral.isTeenager {
                    gobiesAndDamselfishCount += 1
                } else if coral.isAdult {
                    largeSchoolsCount += 1
                    herbivoreCount += 1
                    predatorCount += 1 // Wrasses / triggerfish attracted by adult corals
                }
            }
            
            // Modulate grazing rate and predator control based on fish counts and Shannon Index H
            let herbivoreRecruitment = Double(herbivoreCount) * (1.0 + beta * H)
            let predatorRecruitment = Double(predatorCount) * (1.0 + beta * H)
            
            // 3. Process placed structures
            for structure in updatedCanvas.placedStructures {
                guard let coral = structure.coral else { continue }
                if coral.isDead { continue }
                
                // Growth calculation adjusted by algae overgrowth and predator damage
                let algaeSmotherModifier = max(0.0, 1.0 - coral.algaePercentage)
                let predatorModifier = max(0.0, 1.0 - coral.predatorDamage)
                
                let growthIncrement = baseGrowthRate * algaeSmotherModifier * predatorModifier
                coral.growthProgress = min(1.0, coral.growthProgress + growthIncrement)
                
                // Process Algae growth vs Grazer control (Baby/Teenager phases are most vulnerable)
                let nutrientInflow = threats.agriculturalRunoff ? 2.5 : 1.0
                let baseAlgaeRate = (coral.isBaby || coral.isTeenager) ? baseAlgaeGrowthRate * 1.5 : baseAlgaeGrowthRate
                let algaeGrowth = baseAlgaeRate * nutrientInflow
                let grazingRate = herbivoreRecruitment * baseGrazingRate
                coral.algaePercentage = max(0.0, min(1.0, coral.algaePercentage + algaeGrowth - grazingRate))
                
                // Process Predator infestations (Crown-of-Thorns, Drupella snails, flatworms)
                if !coral.activePredators.isEmpty {
                    // Predation rate increases damage, offset by recruited predatory fish (e.g. wrasses)
                    let basePredation = basePredatorDamageRate * Double(coral.activePredators.count)
                    let predatorControl = predatorRecruitment * basePredatorControlRate
                    let netPredatorDamage = max(0.0, basePredation - predatorControl)
                    coral.predatorDamage = min(1.0, coral.predatorDamage + netPredatorDamage)
                }
                
                // Process Heat stress (Bleaching)
                if threats.waterTemperature > 30.0 {
                    coral.isBleached = true
                } else if coral.isBleached && !threats.isHeatwaveActive && coral.algaePercentage < 0.3 {
                    coral.isBleached = false
                }
                
                // Mortality checks
                // 1. Smothered: If bleached coral is smothered by algae, it dies
                if coral.isBleached && coral.algaePercentage > 0.8 {
                    coral.isDead = true
                }
                // 2. Predator Overconsumption: If predators consume more than 100% of tissue
                if coral.predatorDamage >= 1.0 {
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
