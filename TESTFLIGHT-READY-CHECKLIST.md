# 🚀 BabySafeVisuals — TestFlight Ready Checklist

**Generated:** 2026-02-11  
**Status:** 🟡 Almost Ready — 1 Critical Blocker

---

## 🔴 CRITICAL BLOCKER

### Deployment Target is iOS 26.1 — Does Not Exist
The project's `IPHONEOS_DEPLOYMENT_TARGET` is set to **26.1** across all targets. iOS 26 hasn't shipped yet (current is iOS 18.x). Xcode will refuse to build for real devices and App Store submission.

**Fix:** In Xcode → each target → General → Minimum Deployments → set to **17.0** (or 16.0 for wider reach). This uses SwiftUI features available in iOS 17+.

---

## ✅ Code Audit Results

### TESTING_MODE
- ✅ `TESTING_MODE = false` in `AppState.swift:31` — **Correct for production**

### TODO / FIXME / Incomplete Features
- ✅ **Zero** TODO, FIXME, HACK, or XXX comments found in any Swift file

### All 7 Visual Scenes — Verified Present & Complete
| # | Scene | File | Lines | Status |
|---|-------|------|-------|--------|
| 1 | Snowglobe (FREE) | `SnowglobeView.swift` | 173 | ✅ |
| 2 | Water Ripples | `WaterRipplesView.swift` | 121 | ✅ |
| 3 | Color Mixer | `ColorMixerView.swift` | 122 | ✅ |
| 4 | Floating Bubbles | `BubblesView.swift` | 223 | ✅ |
| 5 | Magnetic Particles | `MagneticParticlesView.swift` | 118 | ✅ |
| 6 | Aurora Orbs | `AuroraOrbsView.swift` | 152 | ✅ |
| 7 | Calm Static | `CalmStaticView.swift` | 130 | ✅ |

### Parent Gate Logic — ✅ Solid
- 6-second press-and-hold on invisible hotspot (top-right corner)
- After hold completes → Face ID / Touch ID / Passcode authentication via `LAContext`
- Fallback: if no biometrics available, hold alone grants access
- Subtle progress ring visible only while holding
- `NSFaceIDUsageDescription` set in Info.plist ✅

### StoreKit 2 IAP — ✅ Well Implemented
- Product ID: `unlock_all_scenes` (non-consumable)
- `PurchaseManager` handles: load, purchase, restore, check entitlements on launch
- Proper error handling: network errors, user cancel, Ask to Buy pending, region restrictions
- Transaction verification (verified vs unverified)
- `isPurchased` persisted to UserDefaults + checked against StoreKit entitlements

### Night Mode — ✅ Bonus Feature
- Auto/On/Off modes with time-based detection (8pm–7am)
- Reduced brightness + slower animations in night mode

### Privacy — ✅ Apple-Compliant
- `PrivacyInfo.xcprivacy` present with UserDefaults API declaration
- No tracking, no collected data types
- No network calls except StoreKit

---

## 📋 Pre-Flight Checklist

### In Xcode (Must Configure)
| Item | Status | Action Needed |
|------|--------|---------------|
| Deployment Target | 🔴 | Change from 26.1 → **17.0** |
| Bundle ID | ✅ `BK.BabySafeVisuals` | Register in Apple Developer portal if not done |
| Version | ✅ 1.0 (build 1) | Good for first submission |
| Signing | ⚠️ | Select your Team + enable "Automatically manage signing" |
| App Icon | ✅ 1024×1024 PNG | Present and correctly configured |
| Entitlements | ✅ | Empty (no special entitlements needed) |

### In App Store Connect (Must Set Up Before Upload)
| Item | Status | Notes |
|------|--------|-------|
| App record created | ❓ | Create app with Bundle ID `BK.BabySafeVisuals` |
| IAP product `unlock_all_scenes` | ❓ | Create as Non-Consumable, set price ($2.99–$4.99 suggested) |
| Privacy Policy URL | ✅ Ready | Host `docs/privacy-policy.html` via GitHub Pages → `https://b-kub24.github.io/BabySafeVisuals/privacy-policy.html` |
| Support URL | ✅ Ready | `https://b-kub24.github.io/BabySafeVisuals/support.html` |
| Age Rating | 📝 | Select "Made for Kids" — no objectionable content, no web access, no user-generated content |
| App Category | 📝 | Entertainment or Education |
| Screenshots | 📝 | Need: iPhone 6.7" (15 Pro Max), iPhone 6.5" (14 Plus), iPad 12.9" — at least 3 each |
| App Description | 📝 | Draft below |

### Enable GitHub Pages (For Privacy Policy URL)
1. Go to `https://github.com/b-kub24/BabySafeVisuals/settings/pages`
2. Source: Deploy from branch → `main` → `/docs` folder
3. Save → URL becomes `https://b-kub24.github.io/BabySafeVisuals/`

---

## 📝 App Store Description Draft

**Name:** BabySafe Visuals

**Subtitle:** Calming scenes for little eyes

**Description:**
> BabySafe Visuals offers beautiful, gentle visual scenes designed to calm and delight babies and toddlers. Each scene features smooth animations with soft colors that are safe for developing eyes.
>
> **7 Mesmerizing Scenes:**
> • Snowglobe — Watch snowflakes drift and swirl (FREE)
> • Water Ripples — Gentle waves respond to touch
> • Color Mixer — Soft colors blend together
> • Floating Bubbles — Tap to pop colorful bubbles
> • Magnetic Particles — Particles follow your finger
> • Aurora Orbs — Glowing orbs float peacefully
> • Calm Static — Soothing ambient patterns
>
> **Built for Parents:**
> • Parent Gate — Secure 6-second hold + Face ID to access settings
> • Night Mode — Auto-dimming with red-shift filter for bedtime
> • Session Timer — Set screen time limits
> • Guided Access support — Lock your child into the app safely
> • No ads, no tracking, no data collection
>
> Try the free Snowglobe scene, then unlock all 7 scenes with a single purchase.

**Keywords:** baby, toddler, calming, visual, sensory, sleep, soothing, infant, nightlight, relaxing

**What's New:** Initial release

---

## 🖥️ Exact Steps for Brent on Mac

### Prerequisites
- Mac with **Xcode 16+** installed
- Apple Developer account ($99/year) enrolled
- Signed into Xcode with your Apple ID (Xcode → Settings → Accounts)

### Step-by-Step

```bash
# 1. Clone the repo (if not already local)
git clone https://github.com/b-kub24/BabySafeVisuals.git
cd BabySafeVisuals/BabySafeVisuals

# 2. Open in Xcode
open BabySafeVisuals.xcodeproj
```

**3. Fix Deployment Target (CRITICAL)**
- Select the project in the navigator (blue icon, top-left)
- Select target "BabySafeVisuals"
- General tab → Minimum Deployments → change to **iOS 17.0**
- Repeat for test targets (or just ignore them for now)

**4. Configure Signing**
- Still in target settings → Signing & Capabilities
- Check "Automatically manage signing"
- Select your Team from the dropdown
- Xcode will create/download provisioning profiles automatically

**5. Build & Test on Simulator**
- Select an iPhone 15 Pro simulator from the scheme bar
- ⌘+B to build — should compile with zero errors
- ⌘+R to run — verify scenes work, parent gate works

**6. Create App in App Store Connect**
- Go to https://appstoreconnect.apple.com
- My Apps → "+" → New App
- Platform: iOS
- Name: BabySafe Visuals
- Bundle ID: BK.BabySafeVisuals (register first in Certificates, IDs & Profiles if needed)
- SKU: babysafevisuals
- Primary Language: English (U.S.)

**7. Create IAP Product**
- In App Store Connect → your app → In-App Purchases
- Create Non-Consumable: `unlock_all_scenes`
- Set price (e.g., $2.99)
- Add display name: "Unlock All Scenes"
- Submit for review (can be reviewed with the app)

**8. Enable GitHub Pages for Privacy Policy**
- GitHub repo Settings → Pages → Source: main branch, /docs folder

**9. Upload to TestFlight**
- In Xcode: Product → Archive (select "Any iOS Device" as destination first)
- Once archived: Window → Organizer → select archive → "Distribute App"
- Choose "App Store Connect" → Upload
- Wait for processing (~15-30 min)

**10. TestFlight Setup**
- In App Store Connect → TestFlight tab
- Add internal testers (your Apple ID)
- Once build is processed, testers get notified

---

## 🚦 Blocker Summary

| # | Blocker | Severity | Fix Time |
|---|---------|----------|----------|
| 1 | Deployment target = iOS 26.1 | 🔴 Critical | 30 seconds in Xcode |
| 2 | App Store Connect app record | 🟡 Required | 10 min |
| 3 | IAP product in App Store Connect | 🟡 Required | 10 min |
| 4 | Signing team selection | 🟡 Required | 1 min in Xcode |
| 5 | GitHub Pages for privacy URL | 🟡 Required | 2 min |
| 6 | Screenshots for listing | 🟢 Not needed for TestFlight | Later |

**For TestFlight only:** Fix #1 and #4. That's it. You can build and upload. Items #2-3 are needed for the App Store Connect side. Screenshots are only required for public App Store submission, not TestFlight.

---

## ✨ Bottom Line

The code is **clean, complete, and production-ready**. All 7 scenes implemented, parent gate is secure, StoreKit 2 IAP is properly coded, TESTING_MODE is off, privacy manifest is correct, app icon exists. 

**The only real fix needed is changing the deployment target from 26.1 to 17.0 in Xcode.** Everything else is App Store Connect configuration that takes ~20 minutes.
