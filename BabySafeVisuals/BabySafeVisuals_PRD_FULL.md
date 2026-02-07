# BabySafe Visuals — Product Requirements Document (PRD)
**Version:** 1.0 (Implementation-ready)  
**Submission strategy:** **NOT** iOS “Kids” category on initial release  
**Recommended App Store category:** Parenting (backup: Utilities)  
**Platforms:** iPhone + iPad (Universal)  
**Orientation:** Portrait + Landscape (auto-rotation supported)  
**Minimum iOS:** **iOS 17.0**  
**Monetization:** Free download + **$2.99** one-time non-consumable IAP (“Unlock All Scenes”)  
**Adult controls:** Hidden Parent Gate (6s hold) **+ Face ID/Touch ID** confirmation  
**Audio:** OFF by default; parent-toggle only  
**Networking:** None (no remote calls)  
**Data collection:** None (no analytics, no tracking, no ads)

---

## 1) Executive Summary

BabySafe Visuals is a **parent-controlled handoff utility** that provides calm, fullscreen, interactive visual scenes (e.g., a shakeable snowglobe, gentle ripples). The parent installs and configures the app and can optionally enable iOS Guided Access to pin the device to the app. The child may interact with the visuals under supervision, but **navigation, settings, and purchases remain behind a Parent Gate and biometric confirmation**.

The app is designed to reduce parent anxiety during short device handoffs by keeping the experience calm, predictable, and hard for a child to alter.

---

## 2) Product Principles (Non-negotiable)

1. **Parent-first utility**: Designed to serve parents; child interaction is supervised output.
2. **Calm > flashy**: No overstimulation, no rapid flashing, no loud audio by default.
3. **No manipulation**: No streaks, rewards, achievements, timers, or “keep playing” loops.
4. **No clutter**: No visible buttons in baby mode. No baby-accessible navigation.
5. **Privacy by design**: No network calls, no SDKs, no analytics, no tracking identifiers.
6. **Guided Access-friendly**: Encourage and support iOS Guided Access; don’t try to replace it.

---

## 3) Positioning & Category Strategy (Avoid “Kids” Category)

### 3.1 What Apple will infer
Apple’s review outcome is influenced by:
- App category selection
- Metadata wording (title/subtitle/description/keywords)
- Screenshots and their captions
- Presence of parent controls (Parent Gate, biometric prompts)
- Presence/absence of kid-targeted marketing language

### 3.2 Required marketing language rules
**Avoid** (anywhere in metadata):
- “for kids,” “for toddlers,” “for babies to play,” “games,” “ages 1–3,” “educational baby app”

**Prefer**:
- “for parents of young children,” “supervised handoff,” “parent-controlled,” “calm visuals,” “Guided Access”

### 3.3 Screenshot style rules
- Minimalist UI (ideally no UI elements visible)
- Calm, modern typography in captions (adult tone)
- Captions emphasize **parent utility** and **Parent Gate** and **Guided Access**

---

## 4) Problem Statement

Parents sometimes need a short “handoff” solution:
- a quick, safe way to occupy a young child for a moment
- without accidental navigation into settings/messages/purchases
- without ads and tracking
- without overstimulating content

Existing child-facing apps are often noisy, cluttered, ad-driven, and include baby-accessible navigation.

---

## 5) Goals & Success Metrics

### 5.1 Primary goals
- Parent can hand off device with low anxiety
- Child cannot navigate within the app (no accidental scene switching or purchasing)
- App works well with Guided Access

### 5.2 MVP success metrics (measured informally, no analytics)
Because we collect no data, success is assessed via:
- Internal QA checklist pass rate
- App Review acceptance without forcing Kids category
- App Store reviews mentioning “safe,” “calm,” “no ads,” “easy to lock”

---

## 6) Target Users & Use Context

### 6.1 Persona: Parent (primary)
- Wants quick, reliable “hand phone over” solution
- Values calm and safety over content variety
- Hates ads/subscriptions in child-adjacent apps

### 6.2 Persona: Child (secondary user)
- Non-reader
- Exploratory tapping and shaking
- Short attention span, easily overstimulated

### 6.3 Typical use context
- Waiting rooms, car passenger, quick transitions at home
- One hand free; parent needs something reliable fast
- Child may be fussy; calm visuals preferred

---

## 7) Scope

### 7.1 In scope (MVP)
- 7 fullscreen visual scenes (1 free, 6 paid)
- Parent Gate + biometric confirmation
- Parent Menu (scene selection + IAP + sound toggle + Guided Access status + help)
- StoreKit 2 one-time unlock + restore
- Guided Access status indicator + “how to enable” help screen
- iPhone + iPad layouts + rotation support

### 7.2 Out of scope (explicit non-goals)
- Accounts, profiles, cloud sync
- Analytics/telemetry, ads, tracking SDKs
- Subscriptions
- Push notifications
- Timers, achievements, progress tracking
- External links (except possibly a parent-gated “Support” mail link—**not in MVP**)
- Any claims of developmental outcomes

---

## 8) Core UX Requirements (Invariants)

These rules must **never** be violated:

1. **Baby mode has no visible navigation UI**  
   - No buttons, tabs, menus, links, toolbars.
2. **No baby-accessible scene switching**  
   - No swipe gestures to change scenes.
3. **No child-visible text**  
   - No instructions on the baby mode surface.
4. **Audio OFF by default**  
   - Parent can enable; default must remain OFF.
5. **No rapid flashing**  
   - Avoid strobe patterns and high-frequency flashes.
6. **Parent controls require deliberate action**  
   - Parent Gate = hidden hotspot + 6-second continuous press
   - Then biometric confirmation before showing menu/purchase options
7. **Purchases are behind Parent Gate + biometric**  
   - No purchase prompts can appear in baby mode.

---

## 9) User Flows (Step-by-step)

### Flow A: First Launch (Parent)
1. App opens directly into **Scene 1: Snowglobe** (free)
2. No onboarding overlays appear automatically
3. Parent unlocks Parent Gate (top-right hold 6 seconds)
4. Face ID/Touch ID prompt appears
5. Parent Menu opens:
   - shows scenes grid (some locked)
   - “Unlock All Scenes” button
   - sound toggle (OFF)
   - Guided Access status indicator and help
6. Parent taps “Lock” to return to baby mode

**Acceptance:** A child cannot discover the menu easily; parent can open it reliably.

### Flow B: Normal Handoff Use
1. Parent opens app
2. Parent optionally enables Guided Access (system setting)
3. Parent hands device to child
4. Child interacts with the scene

**Acceptance:** No accidental purchases; no scene changes.

### Flow C: Purchase Unlock
1. Parent opens Parent Menu via Parent Gate + biometrics
2. Parent taps “Unlock All Scenes”
3. StoreKit purchase sheet appears
4. Purchase succeeds; locked scenes unlock immediately
5. Parent taps “Lock” and hands device over

**Acceptance:** Purchase is never triggered by the child.

### Flow D: Restore Purchase
1. Parent opens Parent Menu
2. Parent taps “Restore Purchases”
3. App syncs entitlements; unlocks scenes if owned

**Acceptance:** Works on fresh install (same Apple ID).

---

## 10) Information Architecture (Screens)

### Baby Mode Surface
- **AppContainerView** displays active scene fullscreen.
- Overlays (invisible by default):
  - ParentGateOverlay (hotspot + progress ring)

### Parent Mode
- ParentMenuView (bottom sheet overlay)
- GuidedAccessHelpView (modal sheet from parent menu)

---

## 11) Detailed Feature Specs

### 11.1 Parent Gate
**Hotspot location:** Top-right corner  
**Size:** 
- iPhone: ~80x80pt touch region (tunable)
- iPad: ~110x110pt touch region (tunable)
**Gesture:** Continuous press and hold for **6 seconds**  
**Progress indicator:** 
- Subtle circular ring (thin, low contrast)
- Visible only while holding
**Cancellation:** 
- Any lift before 6 seconds cancels and resets progress immediately
**Completion:** 
- After 6 seconds, prompt for Face ID/Touch ID via LocalAuthentication
- If auth success → set `appState.parentUnlocked = true`
- If auth fails/cancel → remain locked

**Edge cases:**
- If device has no biometrics, fall back to device passcode auth prompt
- If auth unavailable, allow entry only after hold (acceptable fallback)

### 11.2 Parent Menu
**Presentation:** Bottom sheet overlay; dismiss only via “Lock” button  
**Sections:**
1. **Scenes Grid**
   - Thumbnail tiles with labels (parent only)
   - Locked scenes show lock icon/badge
2. **Unlock**
   - “Unlock All Scenes — $2.99” button (locked state only)
   - “Restore Purchases” button
3. **Settings**
   - Sound toggle (default OFF)
4. **Guided Access**
   - Status: ON/OFF (read-only)
   - “How to enable Guided Access” button → Help View
5. **Lock**
   - Primary action button to return to baby mode

**Constraints:**
- No nested settings
- No scrolling required on typical iPhone screens (use compact layout)
- iPad layout uses a wider sheet or centered card

### 11.3 Guided Access Help View
Content must be parent-focused, simple, and accurate:
- Where to enable Guided Access in Settings
- How to start/stop it (triple-click side button)
- Mention Face ID/passcode exit behavior

**Do not** deep-link into Settings in MVP (optional later).

---

## 12) Scene Specifications (MVP)

All scenes:
- Fullscreen
- No UI
- Calm color palette (avoid strobe)
- Subtle physics; no “reward” events
- Support multi-touch gracefully
- Work across rotation and iPad sizing

### Scene 1 (FREE): Shakeable Snowglobe
**Core interaction:**
- Motion (shake/tilt) influences particle velocity and drift direction
- Touch adds gentle swirl or small burst of particles (subtle)

**Visual:**
- Soft “snow” particles
- Background: muted gradient or faint globe vignette

**Performance:**
- Particle cap (e.g., 200–600 depending on device)
- Adaptive quality: reduce particles on older devices if needed

### Scene 2: Water Ripples
**Core interaction:**
- Touch creates ripple rings that expand and fade
- Multiple touches can create multiple ripples; cap simultaneous ripples (e.g., 12)

**Visual:**
- Calm blue/teal water-like gradient
- Ripples drawn via Canvas circles with alpha falloff

### Scene 3: Color Mixer
**Core interaction:**
- 1 touch: show a colored blob that follows finger
- 2 touches: blend two colors where they overlap
- If >2 touches: treat as 2 primary touches + ignore extras or average

**Visual:**
- Soft blobs / gradients
- Slow transitions (avoid “snap” changes)

### Scene 4: Floating Bubbles
**Core interaction:**
- Tap pops bubble (subtle pop animation, no sound by default)
- Motion gently lifts or drifts bubbles upward
- Cap bubble count (e.g., 30)

**Visual:**
- Transparent circles with subtle highlights
- Calm background

### Scene 5: Magnetic Particles (SpriteKit)
**Core interaction:**
- Finger acts like an attractor
- Particles orbit or drift toward touch point
- Motion gently biases direction

**Implementation:**
- SpriteKit scene embedded in SwiftUI
- Physics tuned for calm motion, not chaotic bursts

### Scene 6: Aurora / Soft Light Orbs
**Core interaction:**
- Passive flowing aurora bands or soft orbs
- Touch gently repels or nudges light

**Visual:**
- Very calm, slow movement
- Designed for wind-down

### Scene 7: Static Calm Scene
**Core interaction:**
- Minimal movement; mostly static
- Touch produces only a faint glow/ripple that fades

**Purpose:**
- “Emergency brake” for overstimulation
- Should be the calmest screen in the app

---

## 13) Technical Requirements

### 13.1 Language & UI framework
- Swift, SwiftUI
- Use Canvas for most scenes (simple and performant)
- Use SpriteKit only for Magnetic Particles

### 13.2 Motion
- CoreMotion device motion updates at ~60Hz
- Publish userAcceleration and rotationRate
- Start updates on app launch; stop when app backgrounded

### 13.3 StoreKit 2
- Non-consumable product: `unlock_all_scenes` (example ID)
- Entitlement persisted locally (StoreKit transaction verification)
- Restore purchases supported

### 13.4 No external dependencies
- No third-party packages
- No network calls

---

## 14) Data, Privacy, and Security

### 14.1 Data stored locally (UserDefaults)
- `activeScene` (string)
- `soundEnabled` (bool)
- `isPurchased` (bool, derived from StoreKit entitlement but cached)

### 14.2 Explicitly not collected
- No analytics events
- No device identifiers
- No location data
- No crash reporting SDKs (in MVP)

### 14.3 Purchase safety
- Purchase buttons only visible behind Parent Gate + biometrics
- No auto-purchase prompts

---

## 15) Accessibility & Safety

- Respect Reduce Motion (optional enhancement): if enabled, reduce animation intensity
- Avoid seizure-risk flashing patterns
- Ensure Parent Gate hotspot is not too large (avoid accidental unlock)

---

## 16) Performance Requirements & Budgets

**Target:** Smooth on modern devices, reasonable on older supported devices.

Recommended caps:
- Snowglobe particles: 200–600
- Bubbles: <= 30
- Ripples: <= 12 active

Constraints:
- Avoid continuous heavy allocations per frame
- Prefer structs and preallocated buffers where possible
- Use TimelineView(.animation) or CADisplayLink-friendly patterns

---

## 17) Error Handling

### StoreKit errors
- If purchase fails/cancels: show a simple parent-only message in menu (“Purchase canceled”)
- If restore finds nothing: show parent-only message (“No purchases found”)

### Motion unavailable
- If CoreMotion unavailable: scenes still work with touch-only interactions

### Biometric unavailable
- Fall back to passcode prompt if possible; otherwise allow access after 6s hold (acceptable fallback)

---

## 18) QA & Testing Plan

### 18.1 Manual test checklist (must pass)
**Navigation safety**
- In baby mode, cannot switch scenes
- In baby mode, cannot trigger purchases
- Parent Gate requires deliberate hold; accidental taps don’t unlock

**Rotation**
- All scenes render correctly on rotation
- Parent Menu layout adapts

**iPad**
- Layout correct on iPad (sheet sizing, hotspot scaling)

**Performance**
- Each scene runs 10 minutes without crash
- No severe frame drops in normal use

**Guided Access**
- Status shows correctly (ON/OFF)
- Help instructions accurate

**IAP**
- Purchase unlocks paid scenes
- Restore works on reinstall (same Apple ID)

### 18.2 Unit tests (optional in MVP)
- AppState persistence sanity
- PurchaseManager state transitions

---

## 19) Release Criteria

Ship v1 when:
- All acceptance criteria in Section 20 are met
- App Store metadata matches parent utility positioning
- App Review Notes included

---

## 20) Acceptance Criteria (Definition of Done)

1. Child cannot open Parent Menu or change scenes accidentally.
2. Parent can open Parent Menu reliably:
   - 6-second hold + biometric confirmation.
3. 7 scenes implemented and stable across iPhone/iPad and rotation.
4. IAP ($2.99) unlocks paid scenes; restore works.
5. Guided Access status shows and help screen is present.
6. App runs 10+ minutes continuous use without crash.
7. No ads, tracking, analytics, SDKs, or network calls.
8. App Store submission is **NOT** Kids category and copy is parent-first.

---

## 21) App Store Metadata (Draft)

### App name
**BabySafe Visuals**

### Subtitle
**Calm, parent-controlled visuals for quick handoff**

### Keywords (examples; keep parent-first)
parenting, guided access, calm, handoff, visuals, safe, fullscreen, utility

### Description (final)
BabySafe Visuals is a simple parenting utility that helps you safely hand your iPhone or iPad to a young child for a few minutes.

It features calm, fullscreen interactive scenes (like a shakeable snowglobe and gentle ripple effects) with a deliberate Parent Gate so settings, scene switching, and purchases stay in the adult’s control.

For a stronger lock, BabySafe Visuals is designed to pair with iOS Guided Access, which lets you pin your device to a single app before handing it over.

**Features**
- Calm, fullscreen visual scenes for short, supervised handoff
- Parent Gate + Face ID/Touch ID confirmation for adult-only controls
- Guided Access status + step-by-step help
- No ads. No tracking. No accounts.

**Note:** Guided Access is an iOS feature you enable in Settings.

### Privacy nutrition label
- Data collected: **None**
- Tracking: **None**

---

## 22) App Review Notes (Final)

Paste into App Store Connect → App Review Notes:

> This is a parent-controlled utility designed for supervised handoff.  
> **Parent Gate:** Press and hold the **top-right corner** for **6 seconds** to open the Parent Menu, then confirm with Face ID/Touch ID.  
> Parent Menu contains scene selection, the in-app purchase, and Guided Access info. Children cannot access purchasing UI without the Parent Gate.  
> The app displays Guided Access status using `UIAccessibility.isGuidedAccessEnabled` and includes instructions for enabling Guided Access (system feature).  
> No accounts, ads, analytics, tracking, or data collection.

---

## 23) Implementation Notes (for AI agent)

### 23.1 Required folder structure
```
BabySafeVisuals/
  App/
  Core/
    ParentGate/
    GuidedAccess/
    Purchases/
  Scenes/
    Snowglobe/
    WaterRipples/
    ColorMixer/
    Bubbles/
    MagneticParticles/
    AuroraOrbs/
    CalmStatic/
```

### 23.2 Implementation order (recommended)
1) Core architecture (AppState, MotionManager, scene registry)
2) Parent Gate overlay + biometric
3) Parent Menu + scene selection + Guided Access status/help
4) Snowglobe scene (free)
5) Remaining scenes
6) StoreKit IAP + restore + scene locking

### 23.3 Agent constraints
- Implement one ticket at a time.
- Do not add features not explicitly specified here.
- Keep the app compiling after each ticket.
