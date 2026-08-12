# Transcript: Team Discussion on Sandbox Mechanics & Onboarding Flow

- **Date:** August 12, 2026
- **Location:** In-Person Meeting Room
- **Participants:**
  - **Gilbert (Reno)**: PM & Lead Developer
  - **Bishal**: Backend Developer
  - **Zarina**: Frontend / Coder
  - **Sam**: UI/UX Designer
  - **Bobo**: Frontend / Coder

---

### Part 1: Main Progression & Onboarding Context

**Gilbert**: Let's skip onboarding setup for the prototype. Let's focus on the main progression screen first—the seabed. We want to start the user in a "dead ocean" scene where everything is covered in white coral rubble.

**Bobo**: So it starts dead? How do they get the first fragment?

**Gilbert**: Yes. There's a pile of dead coral rubble. The user has to literally "rummage around" in the rubble to find a single colored, living fragment of Staghorn coral. Once they find it, we show a pop-up card: *"You found a Staghorn fragment!"* and then they drag it to replant it.

**Sam**: Does the background change as they progress?

**Gilbert**: The background starts simple—mostly just blue water and sand. But as the user levels up and plants more species, we introduce more biodiversity. The water becomes clearer, more fish appear (like turtles, damselfish, and baby sharks), and the colony grows.

---

### Part 2: Active Care Tools & Interactions

**Zarina**: How do they handle predators and threats, like the snails?

**Gilbert**: The snails (predators) will appear and eat the corals. If it's the first time, we show a tooltip explaining what they are. To remove them, the user can tap to smush them or swipe/fling them off the screen.

**Zarina**: And what about the algae?

**Gilbert**: Algae will grow as a green/brown moss layer over the coral. We'll provide a "brush tool" on the screen. The user grabs the brush and swipes over the dirty coral to clean it, triggering a sparkle effect on success.

**Bishal**: Are we simulating heatwaves and bleaching for the exhibition?

**Gilbert**: Bleaching is tied to ocean temperature. But for the immediate exhibition, let's keep it simple. If we do bleaching, it can be a "prestige restart" where they get an achievement and start over. Let's focus on the active care of one coral type first before introducing complex bleaching loops.

---

### Part 3: Sign-In with Apple vs. Passkeys (Technical Debt)

**Bishal**: We need a way to track user progress. If we don't have login, all progress is saved locally. If they delete the app or change devices, they lose everything.

**Gilbert**: For the exhibition, local tracking is fine. But for the production app, we need something robust.

**Bishal**: I checked Passkeys vs. Sign-in with Apple. Passkeys give us unique cryptographic credentials, but they don't easily return user emails. This makes mapping user accounts in the database very complicated. Apple Sign-In is faster—they verify with Face ID, and we immediately get a stable user ID and email.

**Gilbert**: Okay, let's go with **Apple Sign-In** instead of Passkeys. But for now, we'll hardcode the info cards and keep the sync local. 

**Bishal**: That's going to be technical debt (`DEBT-002`). I'll eventually have to rewrite the local storage mappings to sync properly with the remote database once Apple Sign-In is fully integrated.

**Sam**: I'm really hungry. Can we please take a break and get food?

**Gilbert**: Yes, let's clock out and grab lunch. Thank you, everyone.

---

### Key Decisions & Action Items

1. **Onboarding Flow:** Start in a dead rubble scene. User rummages through rubble to find the first Staghorn fragment, then drag-plants it.
2. **Active Care Tools:**
   * **Snail Smash/Fling:** Tap or swipe snails to remove them.
   * **Algae Brush:** Swipe a brush tool over corals to clean moss layers.
3. **Authentication:** Implement **Sign-in with Apple** (Face ID verification) for the MVP instead of Passkeys to ensure straightforward email mapping in the database.
4. **Technical Debt (`DEBT-002`):** Hardcoded info cards and local SwiftData caches will require database refactoring once user accounts are integrated.
