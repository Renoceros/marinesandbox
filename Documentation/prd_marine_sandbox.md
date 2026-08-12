# Product Requirements Document (PRD): Interactive Marine Sandbox

**Document Version:** v1.3  
**Status:** Approved (Updated for 2-Week MVP Scope)  

---

## 1. Executive Summary & Vision

### 1.1. Context
This document defines the product requirements for the **Interactive Marine Sandbox**, a mobile educational application designed for high school students (specifically International Baccalaureate students participating in Environmental Systems and Societies or CAS service programs) who have completed a field-based marine conservation workshop.

### 1.2. Problem Statement
Field-based marine conservation programs (e.g., Living Seas in Bali) generate strong emotional and physical connections to marine ecosystems while students are on-site. However, once students return home, this engagement drops off due to a lack of active, ongoing tools. Traditional educational follow-ups are passive (social media updates, email newsletters) and fail to capture the interactive, decision-based nature of real-world conservation.

### 1.3. Product Vision & Positioning
To sustain student engagement, the application provides a digital sandbox where users can actively experiment with ecosystem variables. 

*   **NOT a Traditional Educational App:** The primary mission is education, but the product must focus first and foremost on being a **highly entertaining, attractive, and visually premium game**. The interface, animations, and transitions should look so stunning and feel so satisfying to touch that students *want* to use it recreationally. If it feels like an encyclopedia, a flashcard tool, or a test/quiz app, it has failed.
*   **Implicit (Subliminal) Education:** Learning occurs entirely through action-reaction gameplay mechanics and visual feedback, rather than text-heavy popups or multiple-choice questions. For instance, a user learns that biodiversity attracts grazers because they experience the physical frustration of brushing algae, observe that a monoculture fails to solve it, and naturally discover that planting multiple species automates the cleaning.
*   **Pedagogical Sandbox (No Real-World Predictor/CCTV):** The app is strictly an interactive learning sandbox, not a predictive scientific model or virtual monitoring tool ("virtual CCTV") for their physical restoration plots. Trying to predict real-world outcomes sets false expectations. Instead, it uses generalized ecological rules to illustrate cause-and-effect relationships and long-term systemic dynamics.

### 1.4. Strategic Objective
The core of this development is a generalizable **pedagogical-ecological sandbox equation**. This mathematical engine must be domain-agnostic, allowing the system to be adapted to other environmental subjects (e.g., forestry, kelp restoration, regenerative agriculture) by swapping out biological parameters.

### 1.5. 2-Week MVP Scope Boundaries
To meet the 2-week launch deadline, features have been strictly prioritized:
* **IN SCOPE:**
  * Core gameplay loop (Reef Star structure placement, fragging with *Acropora* and *Brain Coral*).
  * Pure Swift `EcoEngine` (stateless calculations of growth, algae overgrowth, manual vs helper fish grazing, and heat stress).
  * Manual care loop (brushing algae, picking snails) transitioning to automated care (attracting parrotfish and wrasses).
  * 3-layer horizontal Parallax Scroll View for seabed visual depth.
  * Thermal bleaching & ecological recovery window mechanics (Marine Heatwaves).
  * Mock regional config (Bali/Living Seas presets).
  * Visual Share Card generator (9:16 vertical postcard layout).
  * Local sandbox saves using in-memory / basic local persistence.
* **DEFERRED (Post-MVP / Future Roadmap):**
  * Multi-region Configurations (Jeju Island and Caribbean modules).
  * QR Code Amiibo-style scan rewards.
  * iCloud / CloudKit syncing and complex profile settings.
  * Global Social Map (peer visitation pins).

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

### 3.6. Subliminal Education & Entertainment-First Design Philosophy
Traditional education applications fail because they prioritize educational formatting (textbooks, encyclopedias, quizzes) over player retention, resulting in a product that feels like homework. This application flips that dynamic:
*   **The Entertainment-First Mandate:** The primary metric of success is player retention and enjoyment. The app is styled as a highly polished visual toy and creative sandbox. Visual beauty, smooth momentum-based animations, and pleasing tactical sfx are prioritized so that users choose to open the app voluntarily.
*   **Action-Reaction Biology (No Rote Memorization):** Ecological knowledge is gained implicitly by playing the game. For example, rather than memorizing a text slide stating *"biodiversity increases ecological resilience"*, the player discovers this through direct cause-and-effect mechanics: planting a monoculture fails to recruit grazers and requires constant manual brushing effort, while planting a diverse reef automates the care via helper fish. The mechanics *are* the teacher.

---

## 4. Functional Requirements & Features

### 4.1. Visual & Tactile Design: The "Cute & Escape" Aesthetic
To support Maximia's goals of escaping stress and expressing creativity, the UI avoids clinical dashboard design in favor of stylized, relaxing aesthetics:
*   **Stylized Ecosystem Elements:** Coral species (branching, massive) are drawn with cute, organic growth animations. Herbivorous fish and predatory wrasses feature bouncy, expressive swimming animations. Snails appear as distinct, tap-friendly pests.
*   **Audio Landscape:** A low-pressure, immersive auditory background featuring gentle ocean currents, soft water bubble sounds, and calming ambient melodies.
*   **Bioluminescent night-Mode:** A toggle allowing users to view their reef in a glowing, bioluminescent aesthetic, highlighting healthy coral polyps.

### 4.2. Onboarding & Account Lifecycle Flow
The application implements a streamlined entry path tailored to both new and returning students:
*   **User Routing:**
    *   *New Users:* Are routed through a **Location Selection Screen** (defaulting to Padangbai, Bali) $\rightarrow$ land on the active **Sea Bed Canvas** $\rightarrow$ guided to plant exactly **one Staghorn (Acropora) fragment** onto a pulsing Reef Star.
    *   *Returning Users:* Bypass selection and are loaded directly into their last active **Sea Bed Canvas** from local cache.
*   **Account Registration Prompt:** After successfully completing the initial planting and observing growth, the user is prompted with a modal to "Create a Login Account" to save progress (represented as a local profile registration for the MVP).

### 4.3. Parallax 2D Side-On Canvas (No Grid)
The simulation canvas moves away from a grid-based coordinate system to a continuous, side-on scrollable seabed environment:
*   **Foreground Layer:** The active interactive layer representing the seabed. Users can place Reef Star structures and plant coral fragments at any arbitrary horizontal coordinate ($x$-position) along the terrain.
*   **Midground Layer:** Renders swimming fish, particles, and secondary reef flora. Uses parallax mapping to scroll at a slower speed than the foreground, providing spatial depth.
*   **Background Layer:** Renders distant water gradients, deep ocean contours, and soft bioluminescent backdrops. Scrolls at a minimal speed to generate a three-dimensional parallax effect.

### 4.4. Core Gameplay Loop: Coral Restoration Mechanics
The simulation models reef restoration progression through three primary phases: baseline setup, active care, and ecological automation, structured around concrete growth stages.

```
                  +----------------------------------------------+
                  |               1. ONBOARDING & SETUP          |
                  |  - Select location (Bali)                    |
                  |  - Deploy Reef Star & Frag (First Staghorn)   |
                  +----------------------+-----------------------+
                                         |
                                         v
                  +----------------------------------------------+
                  |               2. ACTIVE CARE                 |
                  |  - Baby/Teenager stage vulnerable to Algae    |
                  |  - Snail/Starfish (>75% damage) threat       |
                  |  - Manually Brush Algae & Kill/Remove Pests  |
                  +----------------------+-----------------------+
                                         |
                       Corals Grow &     | Attract Symbiotic
                       Reef Matures      | Helper Fish
                                         v
                  +----------------------------------------------+
                  |           3. ECOLOGICAL AUTOMATION           |
                  |  - Herbivores graze algae automatically      |
                  |  - Predatory wrasses eat snails/starfish     |
                  +----------------------------------------------+
```

1.  **Coral Growth & Fauna Recruitment Stages:**
    *   **Baby Stage:** Small coral fragment. Attracts **small reef fish and invertebrates** immediately. Highly vulnerable to algae overgrowth.
    *   **Teenager Stage:** Medium coral colony. Attracts **tiny gobies and damselfish** which hide inside branches for protection. Still susceptible to algae.
    *   **Adult Stage:** Fully matured colony. Attracts **large schools of fish, grazing fish, and predators**. Free from juvenile algae vulnerability and unlocks bio-control automation.
2.  **Active Care & Interaction Menu (Manual Maintenance):**
    *   Before helper species arrive, the user must respond to automated notification alerts:
        *   *Algae Overgrowth:* Moss covers baby/teenager corals. The user receives an alert, opens the active menu, selects the **Brush Tool**, and manually swipes the coral to clean it.
        *   *Predator Infestations:* Crown-of-Thorns starfish, Drupella snails, or flatworms attack the frags. If damage exceeds **75%**, a warning notification triggers. The user must open the menu, select the **Kill Tool** (or tap-to-remove), and clear the pests.
3.  **Ecological Automation (Bio-Control Loop):**
    *   Once a coral reaches the **Adult Stage**, the attracted fish automate the care:
        *   *Herbivorous Fish* (e.g., parrotfish) consume algae, automating the Brush Tool.
        *   *Predatory Fish* (e.g., wrasses) consume snails/starfish, automating the Kill Tool.
    *   *System Reward:* Achieving this balance relieves the user from manual chores, completing the procedural satisfaction cycle.

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

### 8.3. Advanced Parallax Micro-Animations
To further elevate visual engagement and polish, the application roadmaps advanced parallax micro-animations for the deep horizontal layers:
*   **Swaying Seaweed & Seagrass:** Add vector-based sea-grass and seaweed blades that sway dynamically using continuous sine-wave time-offsets or spring physics in response to user scroll momentum.
*   **Fauna Path Swimming:** Implement school fish silhouettes following complex, procedural spline paths (e.g., sine/cosine loops and vertical curves) instead of simple linear horizontal swim lanes.

