# Technical Design Document (TDD): Marine Sandbox Tech Demonstrator

**Document Version:** v1.0  
**Status:** Defined & Ready for Sprint Execution  
**Milestone Target:** Day 3 of 2-Week Sprint  

---

## 1. Executive Summary & Objective

### 1.1. Context
Before assembling the full production iOS app with SwiftData persistent stores, CloudKit syncing, and Lottie animations, we will build a **Tech Demonstrator**. 

### 1.2. Purpose
The Tech Demonstrator is a rapid-prototype milestone designed to:
1. **Validate the EcoEngine Math:** Prove that the Shannon Diversity Index ($H$), nutrient levels, and bio-control feedback loops behave as expected under various configurations.
2. **Validate Parallax Scroll Feel:** Experience the physical depth of the 3-layer parallax container (`ParallaxScrollView`) with interactive foreground elements.
3. **Simulate Degradation & Bleaching:** Manually stress the ecosystem (heatwaves, runoff) and observe recovery or collapse dynamics in real-time.
4. **Minimize Architectural Overhead:** Run the entire system with **in-memory models** to bypass database setup errors.

---

## 2. Tech Demonstrator Architecture

To build this quickly, we will consolidate the application into a lightweight, sandbox-focused structure.

```
marinesandbox/
├── Services/
│   └── EcoEngine.swift                 # Pure math stateless calculations (From TDD Section 5.1)
├── ViewModels/
│   └── TechDemoViewModel.swift         # Manages in-memory ReefCanvas state, active timers, and controls
├── Views/
│   ├── TechDemoView.swift              # Unified control center (Canvas + Sliders + Log console)
│   ├── ParallaxScrollView.swift        # Three-layer counter-scrolling implementation
│   └── MockCoralView.swift             # Basic vector/shape shapes representing coral health and size
```

### 2.1. In-Memory State Model
Instead of loading SwiftData contexts, `TechDemoViewModel` will instantiate a standard, mutable in-memory model configuration:

```swift
struct PlacedStructureState: Identifiable {
    let id: UUID = UUID()
    var xPos: Double
    var species: String? // "Acropora" (Branching), "BrainCoral" (Massive), or nil (Empty Star)
    var growthProgress: Double // 0.0 to 1.0
    var algaePercentage: Double // 0.0 to 1.0
    var isBleached: Bool
    var isDead: Bool
}
```

---

## 3. Tech Demonstrator Task Board (Backlog)

These tasks must be completed in order to deliver the Tech Demonstrator by the Day 3 milestone.

### TASK-TD-101: Core Stateless EcoEngine Math
* **PIC:** Samantha
* **Description:** Implement `EcoEngine.swift` according to the specification in the TDD. Make sure it calculates:
  * Shannon Index: $H = -\sum (p_i \ln p_i)$ where $p_i$ is the ratio of species $i$ to total live corals.
  * Growth increments modified by regional configs (Bali light/current) and algae smothering.
  * Algae growth rates boosted by Agricultural Runoff, offset by Grazer Control (recruited herbivores).
  * Bleaching triggers (temp > 30°C) and the 6-month recovery window.
* **Validation:** Write unit tests verifying that high-diversity reefs recover from heat stress, while monocultures collapse to grey rubble.

### TASK-TD-102: 3-Layer Parallax Container View
* **PIC:** Talin
* **Description:** Build `ParallaxScrollView.swift` with:
  * **Background Layer:** Light blue gradient with slow counter-scrolling (ratio 0.2).
  * **Midground Layer:** Renders floating particle bubbles and silhouette fish moving at moderate speed (ratio 0.5).
  * **Foreground Layer:** The active seabed where users interact with placed stars (ratio 1.0).
* **Validation:** Verify horizontal swiping translates layers smoothly without stuttering.

### TASK-TD-103: Interactive Seabed Canvas & Fragment Placement
* **PIC:** Reno
* **Description:** Build the layout where users can:
  * Tap on the seabed to deploy a Reef Star structure at that `xPos`.
  * Tap a structure to open a radial fragging menu: choose either **Acropora** (Branching) or **Brain Coral** (Massive).
  * Render the corals using `MockCoralView.swift` which displays:
    * Growth: scale factor of the shape.
    * Algae: a brown/green outline overlay.
    * Bleaching: shifts the shape's color to pure white.
    * Dead: shifts the shape to a grey cracked stone pattern.
* **Validation:** Manually verify that placing a branching fragment directly next to a massive brain coral results in competitive space shading (slowing the massive coral's growth).

### TASK-TD-104: Simulation Run Controls & Time Tick
* **PIC:** Bishal
* **Description:** Implement the sidebar dashboard controls:
  * **Time Step Button:** Triggers `EcoEngine.updateState` for 1 step (1 month).
  * **Fast Forward Button:** Simulates 60 steps (5 years) in a quick visual loop.
  * **Agricultural Runoff Toggle:** Increases baseline nutrient levels, causing rapid algae overgrowth.
  * **Manual Cleaning Buttons:** "Brush Algae" and "Pick Snails" to manually reduce local threat levels.
* **Validation:** Ensure that manually cleaning algae keeps corals alive even when herbivorous fish are absent.

### TASK-TD-105: Bleaching & Heatwave Runner
* **PIC:** Bobo
* **Description:** Implement a temperature slider (25°C to 33°C) and a "Trigger Heatwave" button:
  * Adjusting temp above 30°C should immediately turn the canvas border red/orange and trigger bleaching across all coral structures.
  * Returning the temp to 27°C starts the recovery window.
* **Validation:** Verify that bleached corals recover their color if algae levels are low, but die (rubble) if algae overgrowth exceeds 80%.

### TASK-TD-106: Tech Demonstrator Integration
* **PIC:** Zarina
* **Description:** Integrate the completed modules into the main app target:
  * Redirect `marinesandboxApp.swift` to launch `TechDemoView` as its root interface.
  * Include a debug log console at the bottom of the screen showing live outputs of $H$, fish counts, and mortality states.
* **Validation:** The application builds and runs successfully on the simulator without errors.
