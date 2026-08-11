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
│   ├── TechDemoView.swift              # Unified control center (Canvas + Action Controls + Log console)
│   ├── ParallaxScrollView.swift        # Three-layer counter-scrolling implementation
│   └── MockCoralView.swift             # Basic vector/shape shapes representing coral health and size
```

### 2.1. In-Memory State Model
Instead of loading SwiftData contexts, `TechDemoViewModel` will instantiate a standard, mutable in-memory model configuration:

```swift
struct PlacedStructureState: Identifiable {
    let id: UUID = UUID()
    var xPos: Double
    var species: String? // "Acropora" (Staghorn), "BrainCoral" (Massive), or nil (Empty Star)
    var growthProgress: Double // 0.0 (Baby) to 1.0 (Adult)
    var algaePercentage: Double // 0.0 to 1.0
    var predatorDamage: Double // 0.0 to 1.0 ( COT / snail / flatworm damage)
    var activePredators: [String] // ["CrownOfThorns", "DrupellaSnail", "Flatworm"]
    var isBleached: Bool
    var isDead: Bool
    
    var isBaby: Bool { growthProgress < 0.3 && !isDead && species != nil }
    var isTeenager: Bool { growthProgress >= 0.3 && growthProgress < 0.7 && !isDead && species != nil }
    var isAdult: Bool { growthProgress >= 0.7 && !isDead && species != nil }
}
```

---

## 3. Tech Demonstrator Task Board (Backlog)

These tasks must be completed in order to deliver the Tech Demonstrator by the Day 3 milestone.

### TASK-TD-101: Core Stateless EcoEngine Math
* **PIC:** Samantha
* **Description:** Implement `marinesandbox/Services/EcoEngine.swift` with growth stage thresholds and fauna recruitment counts:
  * Baby stage ($g < 0.3$): recruits small reef fish and invertebrates; highly vulnerable to algae.
  * Teenager stage ($0.3 \le g < 0.7$): recruits tiny gobies and damselfish.
  * Adult stage ($g \ge 0.7$): recruits large schools, herbivores, and predators.
  * Algae rate boosted for Baby/Teenager corals; grazing rate modulated by recruited herbivorous fish.
  * Predator infestation damage rate modulated by recruited predatory fish (e.g. wrasses).
  * Mortality triggers: bleached & algae overgrowth > 80%, or predator damage >= 100%.
* **Validation:** Write unit tests verifying that adult corals attract grazers and wrasses that automate algae and predator control, whereas baby monocultures quickly succumb to weeds/pests.

### TASK-TD-102: 3-Layer Parallax Container View
* **PIC:** Talin
* **Description:** Build `marinesandbox/Views/Canvas/ParallaxScrollView.swift` with:
  * **Background Layer:** Light blue gradient (ratio 0.2).
  * **Midground Layer:** Renders floating particles and silhouettes of recruited fish groups (small reef fish, gobies, or large schools) depending on the active recruitment counts (ratio 0.5).
  * **Foreground Layer:** The active seabed where users place stars and plant frags (ratio 1.0).
* **Validation:** Verify horizontal swiping translates layers smoothly and updates active fish counts in the midground layer.

### TASK-TD-103: Interactive Seabed Canvas & Onboarding Flow
* **PIC:** Reno
* **Description:** Build the interactive canvas containing:
  * **Onboarding Selector:** A simple location selection screen (defaulting to Padangbai, Bali).
  * **Guided Tutorial:** Force a new user to deploy a Reef Star structure and plant exactly **one Staghorn frag** (Acropora) to begin.
  * **MockCoralView:** Render shapes dynamically based on growth stage (scale), algae overgrowth (brown overlay), bleaching (white), and predator damage (cracked overlays).
* **Validation:** Verify the new user workflow successfully launches the guided tutorial and enforces a single initial Staghorn placement.

### TASK-TD-104: Time Tick & Simulation Run Controls
* **PIC:** Bishal
* **Description:** Implement time progression and sandbox buttons:
  * **Time Step Button:** Simulates 1 step (1 month) of coral growth and threat increments.
  * **Fast Forward Button:** Loops simulation steps to fast-forward growth (Baby $\rightarrow$ Teenager $\rightarrow$ Adult).
  * **Active Alerts:** Display notification prompts when algae overruns baby/teen corals or when predator damage exceeds 75%.
* **Validation:** Ensure that warning notifications fire in real-time when coral health is in jeopardy.

### TASK-TD-105: Active Care Menu Tools (Brush, Kill & Trimming)
* **PIC:** Bobo
* **Description:** Implement the active care and shock events:
  * **Brush Tool:** Selecting the brush from the menu and swiping a coral reduces its algae percentage to 0.0.
  * **Kill Tool (Remove Pests):** Selecting the kill tool and tapping a coral clears its active predators and resets predator damage to 0.0.
  * **Trimming Interaction:** Tapping and holding a coral lets the user manually trim back overgrowing Acropora to prevent competitive smothering.
  * **Environmental Shock Buttons:** Add debug buttons to trigger a Marine Heatwave (increases water temp to 31°C), Agricultural Runoff (nutrient spike), or spawn active predators to test gardening stress.
* **Validation:** Confirm that using the Brush and Kill tools works, and trimming overgrowing Acropora stops it from shading massive corals.

### TASK-TD-106: Tech Demonstrator Integration & Registration Prompt
* **PIC:** Zarina
* **Description:** Integrate modules into the app target:
  * Redirect `marinesandbox/marinesandboxApp.swift` to launch `TechDemoView` as the root screen.
  * Implement the account registration dialog prompt: triggers after the first successful adult coral maturation to "save progress" locally.
  * Add a debug console at the bottom showing active Shannon Index ($H$), growth progress, fish recruitment status, and alert logs.
* **Validation:** The application compiles, launches, and operates end-to-end on the iOS simulator.

