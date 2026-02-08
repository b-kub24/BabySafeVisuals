# BabySafe Visuals

A calm, parent-controlled iOS app for safe device handoff to young children.

🌐 **Website:** [https://b-kub24.github.io/BabySafeVisuals/](https://b-kub24.github.io/BabySafeVisuals/)  
🔐 **Privacy Policy:** [https://b-kub24.github.io/BabySafeVisuals/privacy-policy.html](https://b-kub24.github.io/BabySafeVisuals/privacy-policy.html)  
💬 **Support:** [https://b-kub24.github.io/BabySafeVisuals/support.html](https://b-kub24.github.io/BabySafeVisuals/support.html)

## Features

- **7 Interactive Scenes:** Snowglobe (free), Water Ripples, Color Mixer, Floating Bubbles, Magnetic Particles, Aurora Orbs, Calm Static
- **Parent Gate:** 6-second hold + Face ID/Touch ID to access settings
- **No Ads, No Tracking:** Privacy-first design
- **Guided Access Compatible:** Works perfectly with iOS Guided Access
- **One-time Purchase:** $2.99 unlocks all premium scenes

## Quick Start (TestFlight)

### 1. Clone & Open
```bash
git clone https://github.com/b-kub24/BabySafeVisuals.git
cd BabySafeVisuals/BabySafeVisuals
open BabySafeVisuals.xcodeproj
```

### 2. Configure in Xcode
1. Select the project in the navigator
2. Under **Signing & Capabilities**:
   - Set your **Team** (Apple Developer account)
   - Set **Bundle Identifier**: `com.yourcompany.BabySafeVisuals`
3. Set **Version**: `1.0.0` and **Build**: `1`

### 3. Build & Test
1. Connect your iPhone/iPad
2. Select your device as the build target
3. Press `⌘R` to build and run
4. Test all scenes, Parent Gate (hold top-right 6 seconds), and purchase flow

### 4. Upload to TestFlight
1. Select **Any iOS Device (arm64)** as destination
2. **Product → Archive**
3. In Organizer: **Distribute App → App Store Connect → Upload**
4. Wait for processing (~15 min)
5. In App Store Connect → TestFlight → Enable the build

## App Store Connect Setup

### In-App Purchase
1. Go to **In-App Purchases** → **+**
2. Type: **Non-Consumable**
3. Reference Name: `Unlock All Scenes`
4. Product ID: `unlock_all_scenes` ← **Must match exactly**
5. Price: **$2.99** (Tier 3)

### Privacy Labels
- Data Collected: **None**
- Tracking: **No**

### App Store URLs
Use these URLs in App Store Connect:
- **Privacy Policy URL:** `https://b-kub24.github.io/BabySafeVisuals/privacy-policy.html`
- **Support URL:** `https://b-kub24.github.io/BabySafeVisuals/support.html`

## App Review Notes

Paste this into App Store Connect:

> This is a parent-controlled utility designed for supervised handoff.
> 
> **Parent Gate:** Press and hold the **top-right corner** for **6 seconds** to open the Parent Menu, then confirm with Face ID/Touch ID.
> 
> Parent Menu contains scene selection, the in-app purchase, and Guided Access info. Children cannot access purchasing UI without the Parent Gate.
> 
> No accounts, ads, analytics, tracking, or data collection.

## Project Structure

```
BabySafeVisuals/
├── App/
│   ├── BabySafeVisualsApp.swift    # App entry point
│   ├── AppState.swift              # Global state
│   ├── AppContainerView.swift      # Main container
│   ├── MotionManager.swift         # Device motion
│   └── SceneDefinition.swift       # Scene enum
├── Core/
│   ├── ParentGate/
│   │   ├── ParentGateOverlay.swift # 6-sec hold + biometrics
│   │   └── ParentMenuView.swift    # Settings sheet
│   ├── GuidedAccess/
│   │   ├── GuidedAccessStatus.swift
│   │   └── GuidedAccessHelpView.swift
│   └── Purchases/
│       └── PurchaseManager.swift   # StoreKit 2
└── Scenes/
    ├── Snowglobe/                  # FREE
    ├── WaterRipples/
    ├── ColorMixer/
    ├── Bubbles/
    ├── MagneticParticles/
    ├── AuroraOrbs/
    └── CalmStatic/
```

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI
- **Graphics:** Canvas, SpriteKit (Magnetic Particles only)
- **Motion:** CoreMotion
- **Purchases:** StoreKit 2
- **Auth:** LocalAuthentication (Face ID/Touch ID)
- **Minimum iOS:** 17.0

## License

Proprietary. All rights reserved.
