# Product Requirements Document (PRD): Interactive Marine Sandbox

**Document Version:** v1.2  
**Status:** Approved  

---

## 1. Executive Summary & Vision

### 1.1. Context
This document defines the product requirements for the **Interactive Marine Sandbox**, a mobile educational application designed for high school students (specifically International Baccalaureate students participating in Environmental Systems and Societies or CAS service programs) who have completed a field-based marine conservation workshop.

### 1.2. Problem Statement
Field-based marine conservation programs (e.g., Living Seas in Bali) generate strong emotional and physical connections to marine ecosystems while students are on-site. However, once students return home, this engagement drops off due to a lack of active, ongoing tools. Traditional educational follow-ups are passive (social media updates, email newsletters) and fail to capture the interactive, decision-based nature of real-world conservation.

### 1.3. Product Vision
To sustain student engagement, the application provides a digital sandbox where users can actively experiment with ecosystem variables. 

**Core Product Shift (No Real-World Predictor/CCTV):**
The app is strictly a **pedagogical sandbox**, not a predictive scientific model or virtual monitoring tool ("virtual CCTV") for their physical restoration plots. Trying to predict real-world outcomes sets false expectations. Instead, the app uses generalized ecological rules to illustrate cause-and-effect relationships and long-term systemic dynamics.

### 1.4. Strategic Objective
The core of this development is a generalizable **pedagogical-ecological sandbox equation**. This mathematical engine must be domain-agnostic, allowing the system to be adapted to other environmental subjects (e.g., forestry, kelp restoration, regenerative agriculture) by swapping out biological parameters.

---

## 2. User Persona: Maximia

```
+-----------------------------------------------------------------------------------+
| USER PROFILE                                                                      |
| Name: Maximia          Age: 17                Nationality: Dutch-American         |
| Occupation: High School Student               Lifestyle: High Academic Pressure   |
+-----------------------------------------------------------------------------------+
| MOTIVATIONS & VALUES                                                              |
| - Express curiosity & creativity suppressed in rigid classroom environments.     |
| - Unwind from high school exams, assignments, and academic stress.                |
| - Loves new experiences and discovering unique aesthetic spaces.                  |
| - Social sharing: likes posting "cool", unique things with friends.               |
| - Attracted to cute, stylized, and high-fidelity visual design.                   |
+-----------------------------------------------------------------------------------+
| GOALS                                                                             |
| - Escaping school pressure to unwind during holidays/between semesters.           |
| - Creating something unique that is shareable via social media (Snap/Insta).      |
| - Interacting in a low-pressure, toy-like sandbox space (e.g., Roblox).          |
+-----------------------------------------------------------------------------------+
| FRUSTRATIONS & PAIN POINTS                                                        |
| - "Classroom environments": Hates long text guides, briefings, or briefings.      |
| - Lack of visual, tactile, and immediate feedback.                                |
| - High-pressure learning: dislikes rigid task instructions or strict grading.     |
+-----------------------------------------------------------------------------------+
```

---

## 3. Neuroscience & Pedagogical Validation Framework

To create an environment that fosters **natural learning** (learning driven by curiosity, play, and intrinsic motivation rather than rote memorization), the product design must be validated by established cognitive science, neuroscience, and educational psychology.

```
                  +-------------------------------------------------------+
                  |         NATURAL LEARNING ENVIRONMENT (GEPF)           |
                  +-------------------------------------------------------+
                   /                          |                          \
                  /                           |                           \
  [NEUROSCIENCE FOUNDATION]       [PEDAGOGICAL FRAMEWORK]       [THEORETICAL VALIDATION]
  - Dopaminergic Automation       - Kolb's Experiential Cycle   - Validated: Visual Timelapse
  - Predictive Coding (Contrast)  - Self-Determination (SDT)    - Validated: Active -> Auto care
  - Reduced Prefrontal Fatigue    - Vygotsky's ZPD Scaffolding  - Invalidated: Real-world CCTV
```

### 3.1. Experiential Learning via Kolb's Cycle (Sandbox Loop)
Kolb's Experiential Learning Theory posits that knowledge is created through the transformation of experience in a four-stage cyclical process.
*   **Application:**
    1.  *Concrete Experience:* User places structures (Reef Stars) and fragments, and performs active manual care (brushing algae, picking snails).
    2.  *Reflective Observation:* User triggers the **Fast Forward** and observes the multi-year visual timelapse of their reef's growth or collapse.
    3.  *Abstract Conceptualization:* User reads the diagnostic reflection card, linking their visual outcome to ecological principles (e.g., "Monocultures reduce grazer recruitment, leading to algae overgrowth").
    4.  *Active Experimentation:* User triggers a **Hard Reset**, alters species spacing or diversity, and tests a new hypothesis.
*   **Validation:** The sandbox gameplay loop directly mirrors this natural cognitive sequence, converting visual feedback into theoretical understanding.

### 3.2. Dopaminergic Reinforcement & Procedural Satisfaction
The brain's reward system, mediated by dopamine release in the mesolimbic pathway, reacts strongly to **Reward Prediction Errors** (the difference between expected and actual outcomes) and the **relief of cognitive effort** (the transition from active task execution to automated success).
*   **Validation of the Manual-to-Automated Progression:**
    *   Starting with manual, active tasks (brushing algae, picking snails) creates a baseline of cognitive effort and tension.
    *   When the system reaches ecological balance and recruits helper fish, the **automation** of these manual tasks acts as a powerful secondary reinforcer. The brain perceives the shift from active labor to passive automated health as a high-reward state.
    *   *If we started with automation:* The user would feel detached, leading to boredom and rapid disengagement.
    *   *If we never automated:* The user would experience cognitive fatigue (ego depletion) and abandon the app as a chore.

### 3.3. Predictive Coding & Visual Dominance
The human brain is a predictive organ (Friston's Free Energy Principle). It constantly projects internal models of the world to minimize prediction errors. The visual cortex is the brain's largest processing system and is optimized for spatial-visual comparison over symbolic data (numbers, charts).
*   **Validation of Visual Timelapses vs. Numerical Dashboards:**
    *   Displaying raw numbers (e.g., "Coral cover: 42%") requires effortful, slow symbolic processing in the prefrontal cortex, which fatigues quickly.
    *   Using a visual timelapse transition ($C = \|\mathbf{S}_{\text{future}} - \mathbf{S}_t\|_2$) forces bottom-up visual processing. When a user sees their clean reef turn into a brown, algae-choked graveyard, the predictive mismatch instantly triggers attention, curiosity, and synaptic plasticity.

### 3.4. Self-Determination Theory (SDT)
SDT (Deci & Ryan) states that intrinsic motivation occurs when three basic psychological needs are met:
1.  **Autonomy:** The feeling of control over one's choices.
2.  **Competence:** The feeling of mastery and growth.
3.  **Relatedness:** The feeling of connection to a community.
*   **Validation of Sandbox Design:**
    *   *Autonomy:* The sandbox provides complete freedom of placement and species composition, unlike structured linear quizzes.
    *   *Competence:* Success is earned through balancing species diversity and spatial distribution to achieve automation.
    *   *Relatedness:* The **Global Map** allows students to visit peer reefs, fulfilling the social comparison drive without the anxiety of open-ended communication.

### 3.5. Cognitive Load & Scaffolding in the Zone of Proximal Development (ZPD)
Vygotsky's ZPD defines the space between what a learner can do unassisted and what they cannot do. Learning is most effective when scaffolding is used.
*   **Validation of Scaffolding vs. Onboardings:**
    *   Maximia's frustration with formal briefings/briefings means we must avoid structured tutorials. Instead, the interface utilizes **implicit scaffolding**: intuitive drag-and-drop actions, visually distinct glowing connection nodes, and immediate visual reactions.
    *   By bounding the simulation's success rate ($0.4 \le Ag \le 0.7$) and providing a diagnostic card (scaffolding) only upon failure, we keep the student within their ZPD without forcing structured classroom-like instruction.

---

## 4. Functional Requirements & Features

### 4.1. Visual & Tactile Design: The "Cute & Escape" Aesthetic
To support Maximia's goals of escaping stress and expressing creativity, the UI avoids clinical dashboard design in favor of stylized, relaxing aesthetics:
*   **Stylized Ecosystem Elements:** Coral species (branching, massive) are drawn with cute, organic growth animations. Herbivorous fish and predatory wrasses feature bouncy, expressive swimming animations. Snails appear as distinct, tap-friendly pests.
*   **Audio Landscape:** A low-pressure, immersive auditory background featuring gentle ocean currents, soft water bubble sounds, and calming ambient melodies.
*   **Bioluminescent night-Mode:** A toggle allowing users to view their reef in a glowing, bioluminescent aesthetic, highlighting healthy coral polyps.

### 4.2. Onboarding Flow: Zero-Briefing Sandbox Entry
To prevent Maximia's pain point of "classroom spaces," the app enforces a **zero-briefing entry**:
*   *No Slides/Video Briefings:* On first launch, the user is dropped directly into the grid environment with a single empty Reef Star.
*   *Implicit Prompts:* A soft pulsing visual ring surrounds the empty star structure, indicating that it accepts frags. Dragging a frag onto the star instantly initiates the simulation, teaching the user through direct, low-pressure exploration.

### 4.3. Parallax 2D Side-On Canvas (No Grid)
The simulation canvas moves away from a grid-based coordinate system to a continuous, side-on scrollable seabed environment:
*   **Foreground Layer:** The active interactive layer representing the seabed. Users can place Reef Star structures and plant coral fragments at any arbitrary horizontal coordinate ($x$-position) along the terrain.
*   **Midground Layer:** Renders swimming fish, particles, and secondary reef flora. Uses parallax mapping to scroll at a slower speed than the foreground, providing spatial depth.
*   **Background Layer:** Renders distant water gradients, deep ocean contours, and soft bioluminescent backdrops. Scrolls at a minimal speed to generate a three-dimensional parallax effect.

### 4.4. Core Gameplay Loop: Coral Restoration Mechanics
The simulation models reef restoration progression through three primary phases: baseline setup, active care, and ecological automation.

```
                  +----------------------------------+
                  |       1. BASELINE SETUP          |
                  |  - Place Reef Star on seabed     |
                  |  - Attach coral frags to star    |
                  +----------------+-----------------+
                                   |
                                   v
                  +----------------------------------+
                  |       2. ACTIVE CARE             |
                  |  - Manually brush algae          |
                  |  - Manually pick predatory snails|
                  +----------------+-----------------+
                                   |
                Corals Grow &      | Attract Symbiotic
                Reef Matures       | Helper Fish
                                   v
                  +----------------------------------+
                  |     3. ECOLOGICAL AUTOMATION     |
                  |  - Herbivores graze algae        |
                  |  - Predators eat snails          |
                  |  * MANUAL CHECKS ARE AUTOMATED   |
                  +----------------------------------+
```

1.  **Baseline Setup:**
    *   **Structure Deployment:** The user places a **Reef Star** structure onto the continuous foreground seabed line.
    *   **Frag Attachment:** The user attaches coral fragments (frags) onto the Reef Star nodes, choosing which species to plant.
2.  **Active Care (Manual Maintenance - The "Annoying Bit"):**
    *   Before helper species arrive, the user must perform active gardening:
        *   *Algae Overgrowth:* Every other time cycle, algae starts covering the coral frags. The user must manually brush the corals to keep them clear.
        *   *Predatory Snails:* Coral-eating snails infest the grid and eat coral tissue. The user must manually inspect the frags and pick the snails off.
3.  **Ecological Automation (Bio-Control Loop):**
    *   As the corals grow and the reef matures, they begin attracting specific symbiotic fish:
        *   *Herbivorous Fish* (e.g., parrotfish, surgeonfish) arrive to consume the algae, automating the manual brushing mechanic.
        *   *Predatory Fish* (e.g., wrasses, triggerfish) arrive to eat the snails, automating the manual snail-picking mechanic.
    *   *System Reward:* Achieving this ecological balance frees the user from tedious manual cleaning tasks, shifting gameplay to high-level system observation and shock testing.

### 4.5. Coral Growth Competition & Space Management
Different coral species exhibit distinct growth rates, attract different fish, and compete for space:
*   **Acropora (Branching Coral):** Fast-growing coral. Attracts type-X fish (which graze algae).
*   **Brain Coral (Massive/Round Coral):** Slower-growing coral. Attracts type-Y fish (which consume snails).
*   **Space Aggression & Gardening:** If *Acropora* is planted directly next to Brain Coral, its rapid growth will overshadow and smother the slow-growing Brain Coral. To grow Brain Coral successfully, the user must either:
    1.  *Spatial Planning:* Physically space out fast-growing and slow-growing corals along the continuous foreground surface to prevent competitive exclusion.
    2.  *Trimming/Gardening:* Manually trim back the fast-growing *Acropora* over time to ensure the Brain Coral receives sufficient light and resources.

### 4.6. Thermal Bleaching vs. Algae Overgrowth Mechanics
To prevent the pedagogical misconception that coral bleaching is caused by time or general neglect, the simulation makes a strict separation between maintenance issues and climate anomalies.

#### 4.6.1. Baseline Stability (Time Isolation)
If the user configures a balanced reef (with appropriate herbivores) and leaves it run, the corals will **never bleach** as a function of time. Time alone does not cause bleaching.

#### 4.6.2. Mechanical & Visual Contrast
The app divides reef degradation into two separate visual and causal states:
1.  **Algae Overgrowth (Neglect / Competitor Threat):**
    *   *Causal Trigger:* Low herbivore fish count (due to planting a monoculture) or triggering an Agricultural Runoff event.
    *   *Visual Representation:* Corals become covered in a fuzzy, brown/green organic slime.
    *   *Pedagogical Concept:* Overgrowth is a localized competition problem. Corals can be saved by manually brushing or restoring ecological herbivore balance.
2.  **Coral Bleaching (Climatic Threat):**
    *   *Causal Trigger:* Water temperature spike above $30^\circ\text{C}$ (triggered exclusively via an active **Marine Heatwave** threat event).
    *   *Visual Representation:* Corals turn a stark, bone-white. The underlying screen overlay shifts to a warm amber/red glow with temperature gauges showing the heat stress.
    *   *Pedagogical Concept:* Bleaching is an acute reaction to climate stress where corals eject their symbiotic zooxanthellae. It cannot be manually brushed away.

#### 4.6.3. The Ecological Recovery Window (Hope & Resilience)
When a Marine Heatwave terminates, water temperatures return to a baseline $27^\circ\text{C}$, opening a **6-month recovery window**:
*   *Resilient Reef Recovery:* If the reef has high biodiversity ($H > 1$) and low algae levels, the bleached corals have a high probability of absorbing zooxanthellae back from the water column, recovering their healthy colors.
*   *Monoculture Reef Collapse:* If the reef is a monoculture or choked with algae, algae will quickly colonize the weakened bleached skeletons, permanently killing the coral and turning it into grey rubble.
*   *Pedagogical Message:* We cannot stop global heating spikes locally, but by cultivating biodiverse reefs, we build the resilience needed for ecosystems to survive and recover from climate shocks.

### 4.7. Sandbox Controls & Timelapse Visuals
*   **Hard Reset Action:** Instantly clears all structures and biological components, returning the grid to barren rubble.
*   **Fast Forward Action:** Runs the simulation model forward for $N$ steps (simulating 5–10 years of growth) to calculate the steady-state result of the user's configuration.
    *   *Timelapse morphing:* Plays a short visual transition showing the reef's evolution (growth, competition, algae outbreaks, or bleaching).
    *   *Diagnostic reflection Card:* Explains the steady-state outcome based on ecological laws (e.g., "Your slow-growing brain coral was overgrown by Acropora because they were planted too close together").

### 4.8. Visual Share Card Generator
To satisfy Maximia's motivation to share "cool", unique things with friends on Instagram Stories and Snapchat:
*   **Visual Snapshot Capture:** A camera button in the UI lets the user capture their reef design.
*   **Share Card Styling:** Generates a stylized vertical layout (9:16 aspect ratio) featuring:
    *   A high-definition, aesthetic snapshot of their customized, bioluminescent reef.
    *   A unique "Reef Identity Card" detailing their reef's custom name, diversity score, and local NGO region (e.g., "Padangbai, Living Seas").
    *   An export option directly to the iOS share sheet (Instagram Stories, Snapchat, messaging apps).

---

## 5. Multi-NGO Configuration Module
Loads local environmental parameters and species sets for different regions:
*   **Bali (Living Seas):** Tropical reef stars, *Acropora*, brain corals, temperature-induced bleaching.
*   **Jeju Island:** Rocky kelp forests, abalone, urchin overpopulation threats.
*   **Caribbean:** Deep-sea coral species, disease vectors, physical hurricane damage threats.

---

## 6. Social Map & Profile Layer
*   **User Profiles:** Tracks student progress, saved grid configurations, and profile customization.
*   **Global Map:** Interactive virtual globe showing pins of other students' sandboxes. Users can tap pins to visit and view peer reefs in their steady state. No active text-based communication is allowed.

---

## 7. Compliance, Security, & App Store Readiness

### 7.1. Minor Data Protection (COPPA & GDPR)
*   **Strict PII Protection:** No collection of minors' personal data.
*   **Anonymized Sharing:** Peer visitations on the Global Map are strictly anonymous or use school-approved pseudonyms. No free-text interaction is permitted.

### 7.2. App Store Policy Adherence
*   **Account Deletion:** Users can self-delete their profiles and all associated data from the settings menu.
*   **Privacy Transparency:** Clear documentation of storage limitations (sandbox saves and authentication tokens only).

---

## 8. Product Roadmap Extensions

### 8.1. Physical Scan Unlock (Amiibo-Style Mechanic)
To encourage engagement with local conservation efforts, the application roadmaps a physical scan unlock feature:
*   **Mechanism:** Partner NGOs place unique physical QR codes at their offices, visitor centers, or workshop sites.
*   **Unlock Rewards:** Scanning these physical QR codes unlocks special digital rewards:
    *   *Rare Coral Breeds:* Aesthetic, non-gameplay-affecting coral variants (e.g., bioluminescent or unique color morphs).
    *   *Cosmetic Themes:* Custom environmental skins for the sandbox (e.g., deep twilight mode, unique background sea floor layouts).
    *   *Profile Badges:* Verifiable credentials showing they visited the physical partner office.
*   **Impact:** Bridges physical visits to digital cosmetics without violating the "no predictive CCTV tracker" policy.

### 8.2. Plantation Location Selection
To increase ecological depth, the app roadmaps a pre-simulation step where users choose the exact environmental zone for their plantation:
*   **Mechanism:** Before configuring their reef grid, users select an environmental location within the loaded NGO region.
*   **Location Impact on the Ecological Equation:** Choosing a location dynamically modifies the baseline constants of the **Ecosystem State Vector** ($\mathbf{S}_0$) and the **Growth & Stress variables** ($\mathbf{G}, \mathbf{T}$):
    *   *Shallow Reef Flat (e.g., Padangbai Bay):* High ambient light (accelerating *Acropora* growth) but high susceptibility to thermal bleaching spikes and boat physical collisions.
    *   *Deep Wall Slope (e.g., Wall Bay Nusa Penida):* Decreased ambient light (slowing branching growth, favoring slow-growing massive corals like brain corals) but protected from thermal waves and physical turbulence.
    *   *Strong-Current Channel (e.g., Toyapakeh Strait):* Influx of high nutrients (boosting overall growth rates) but high current shear stress, requiring structural reinforcement (e.g., concrete anchor structures) to prevent fragments from dislodging.
*   **Pedagogical Value:** Teaches students that marine restoration strategies must adapt to localized environmental stressors, demonstrating that a "one-size-fits-all" solution does not exist.
