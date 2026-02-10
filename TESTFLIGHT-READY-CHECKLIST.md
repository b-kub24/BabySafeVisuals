# ✈️ BabySafeVisuals - TestFlight Ready Checklist

**Target Date:** 2026-02-11  
**Current Status:** PRE-TESTFLIGHT  
**Prepared By:** Claude (Subagent)

---

## 📱 PHASE 1: PRE-FLIGHT CHECKS (Do This First!)

### ✅ 1.1 Verify Apple Developer Account Setup

**Before you start, confirm:**
- [ ] Apple Developer Program membership is **active** ($99/year)
- [ ] You have access to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] You can log into [developer.apple.com](https://developer.apple.com)

**If not:**
1. Go to developer.apple.com → Enroll
2. Pay $99 USD annual fee
3. Wait ~24 hours for approval
4. ⚠️ **Can't proceed without this**

---

### ✅ 1.2 Create App in App Store Connect

**Steps:**
1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** (top-left) → **New App**
3. Fill in:
   - **Platforms:** iOS
   - **Name:** `BabySafe Visuals` (or `BabySafeVisuals` - check availability)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select **BK.BabySafeVisuals** (or create new if needed)
   - **SKU:** `babysafe-visuals-001` (your internal reference)
   - **User Access:** Full Access

**⚠️ CRITICAL:** The Bundle ID must match what's in Xcode!

**Current Bundle ID in Xcode:** `BK.BabySafeVisuals`

**If Bundle ID doesn't exist in dropdown:**
1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
2. Click **+** → **App IDs**
3. **Description:** BabySafeVisuals
4. **Bundle ID:** `BK.BabySafeVisuals` (explicit)
5. **Capabilities:** Enable **In-App Purchase**
6. Save and return to App Store Connect

---

### ✅ 1.3 Configure In-App Purchase

**This is CRITICAL - the app will break without this!**

**Steps:**
1. In App Store Connect → Your App → **In-App Purchases**
2. Click **+** → **Non-Consumable**
3. Fill in **EXACTLY**:
   - **Reference Name:** `Unlock All Scenes`
   - **Product ID:** `unlock_all_scenes` ← **MUST MATCH CODE**
   - **Price:** Tier 3 ($2.99 USD)
4. **Review Information:**
   - **Display Name:** `Unlock All Scenes`
   - **Description:** `Unlock all 6 premium interactive scenes for your baby.`
5. **Review Screenshot:**
   - Upload any screenshot from the app (required for review)
6. Click **Save**
7. **Submit for Review** (separate from app review)

**Verification:**
- Product ID `unlock_all_scenes` exactly matches `PurchaseManager.swift` line 9
- Price is set to Tier 3 ($2.99)
- Status shows "Ready to Submit" or "Waiting for Review"

**⚠️ If this doesn't match:** Purchase button will show "Product not found"

---

### ✅ 1.4 Set Up Sandbox Tester Account

**Why:** To test IAP without spending real money.

**Steps:**
1. App Store Connect → **Users and Access** → **Sandbox Testers**
2. Click **+** → Create tester
3. Fill in:
   - **Email:** Use a **NEW email** (can't be your real Apple ID)
   - **Password:** Make it memorable
   - **Country:** United States (or your region)
4. Save

**Testing IAP Later:**
1. On your iPhone → Settings → App Store → Sandbox Account
2. Sign in with your sandbox tester email
3. Launch BabySafe Visuals → test purchase

---

## 🛠️ PHASE 2: XCODE CONFIGURATION

### ✅ 2.1 Open Project in Xcode

**On your Mac:**
```bash
cd ~/path/to/BabySafeVisuals/BabySafeVisuals
open BabySafeVisuals.xcodeproj
```

**Select the project** (top of navigator) → **BabySafeVisuals** target

---

### ✅ 2.2 Configure Signing & Capabilities

**Location:** Project → **BabySafeVisuals** target → **Signing & Capabilities** tab

**Settings:**
- [ ] **Automatically manage signing:** ✅ CHECKED
- [ ] **Team:** Select your Apple Developer team (should be your name)
- [ ] **Bundle Identifier:** `BK.BabySafeVisuals` (should auto-fill)
- [ ] **Signing Certificate:** Should show "Apple Development" or "Apple Distribution"

**If you see errors:**
- "Failed to register bundle identifier" → Bundle ID already exists, good!
- "No signing certificate found" → Xcode → Preferences → Accounts → Download Manual Profiles

**Capabilities:**
- [ ] **In-App Purchase:** Should already be enabled (check if present)

---

### ✅ 2.3 Set Version & Build Number

**Location:** Project → **BabySafeVisuals** target → **General** tab

**Settings:**
- [ ] **Version:** `1.0` (MARKETING_VERSION - already set ✅)
- [ ] **Build:** `1` (CURRENT_PROJECT_VERSION - already set ✅)

**For future updates:**
- TestFlight uploads require unique build numbers
- Version 1.0 can have builds 1, 2, 3, etc.
- Version 1.1 resets to build 1

---

### ✅ 2.4 Verify App Icon

**Location:** Project navigator → **Assets.xcassets** → **AppIcon**

**Check:**
- [ ] Click **AppIcon** in left panel
- [ ] Verify "Single Size" or all slots filled
- [ ] Preview should show a 1024x1024 icon

**Current Status:** ✅ `AppIcon.png` exists (1024x1024)

**If Xcode shows warnings:**
1. Select AppIcon asset
2. Attributes Inspector (right panel)
3. Enable **"Single Size (iOS 11.0+)"**
4. Drag `AppIcon.png` into the 1024x1024 slot

---

## 📦 PHASE 3: BUILD & ARCHIVE

### ✅ 3.1 Clean Build Folder

**Why:** Ensures no cached artifacts interfere.

**Steps:**
1. Xcode menu → **Product** → **Clean Build Folder** (⇧⌘K)
2. Wait for "Clean Succeeded"

---

### ✅ 3.2 Select Archive Destination

**Location:** Xcode toolbar (top-left, next to Play/Stop buttons)

**Settings:**
- [ ] Click destination dropdown → Select **"Any iOS Device (arm64)"**
- **DO NOT** select a physical device or simulator for archiving

**Why:** App Store requires a generic iOS device build (arm64 architecture).

---

### ✅ 3.3 Archive the App

**Steps:**
1. Xcode menu → **Product** → **Archive** (⌘B won't work - must use Archive)
2. Wait ~2-5 minutes (first build takes longer)
3. **If successful:** Organizer window opens automatically
4. **If failed:** Check error console (likely signing or missing capability issue)

**Common Archive Errors:**

| Error | Fix |
|-------|-----|
| "Signing requires a development team" | Set Team in Signing & Capabilities |
| "Provisioning profile doesn't include IAP" | Enable In-App Purchase capability |
| "Bundle identifier is unavailable" | Change Bundle ID or register it on developer.apple.com |

---

### ✅ 3.4 Validate Archive (Optional but Recommended)

**In Organizer window:**
1. Select your archive → Click **Validate App**
2. Choose **Automatically manage signing**
3. Wait ~1-2 minutes for validation
4. **If errors:** Fix them before uploading (usually IAP/capability issues)
5. **If successful:** Proceed to upload

**Why:** Catches issues before uploading (saves time).

---

## 🚀 PHASE 4: UPLOAD TO APP STORE CONNECT

### ✅ 4.1 Distribute to App Store Connect

**In Organizer window:**
1. Select your archive
2. Click **Distribute App**
3. Choose **App Store Connect** → Next
4. Choose **Upload** → Next
5. **Signing:** Select "Automatically manage signing" → Next
6. **Review:** Check all settings → **Upload**
7. Wait ~3-10 minutes for upload to complete

**What happens:**
- Xcode compresses and encrypts the binary
- Uploads to Apple's servers (~50-150 MB)
- Apple processes the build (scanning for malware, etc.)

**If upload fails:**
- Check internet connection
- Try again (sometimes Apple's servers timeout)
- Check App Store Connect → Activity → see error details

---

### ✅ 4.2 Wait for Processing

**Time:** ~10-30 minutes (sometimes up to 1 hour)

**Steps:**
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click your app → **TestFlight** tab
3. **iOS Builds** section will show:
   - "Processing" (yellow) → Wait
   - "Ready to Submit" (green) → Success!
   - "Invalid Binary" (red) → Check email for error details

**While waiting:**
- ☕ Take a break (you earned it!)
- 📱 Check your email (Apple sends status updates)
- 🚫 Don't submit another build (wait for this one to process)

**Processing checks:**
- Scans for malware/viruses
- Validates entitlements and capabilities
- Checks for common rejection reasons (private APIs, etc.)

---

## 🧪 PHASE 5: TESTFLIGHT SETUP

### ✅ 5.1 Enable Build for Testing

**Once processing completes:**
1. App Store Connect → Your App → **TestFlight** tab
2. **iOS Builds** → Click on your build (Version 1.0, Build 1)
3. **Build Details:**
   - [ ] Review build info (version, size, upload date)
   - [ ] Click **Provide Export Compliance Information**
4. **Export Compliance:**
   - "Does your app use encryption?" → **NO** (or select "Exempt")
   - Explanation: "Uses standard HTTPS libraries only (StoreKit, URLSession)"
5. **Save**

**Status should change to:** "Ready to Test"

---

### ✅ 5.2 Add Internal Testers (Optional)

**If you want to test yourself:**
1. TestFlight tab → **Internal Testing** → **+** (Add Group)
2. Create group: "Internal Testers"
3. **Add Testers:**
   - Click **+ Testers** → Add your email (must be App Store Connect user)
4. **Select Build:** Choose Version 1.0 (Build 1)
5. Save

**Testers will receive:**
- Email with TestFlight link
- Automatic updates when you upload new builds

---

### ✅ 5.3 Install TestFlight App on Device

**On your iPhone/iPad:**
1. App Store → Search "TestFlight" → Install (free, by Apple)
2. Open TestFlight app
3. Sign in with your Apple ID
4. BabySafe Visuals should appear in "Apps Available to Test"
5. Tap **Install**

**Testing checklist:**
- [ ] App launches successfully
- [ ] Parent gate works (hold 6 seconds + Face ID)
- [ ] All scenes render correctly
- [ ] IAP purchase flow (using sandbox account)
- [ ] Restore purchases works
- [ ] Offline mode works (airplane mode)

---

## 📝 PHASE 6: APP STORE METADATA (For Future Release)

**⚠️ NOT REQUIRED FOR TESTFLIGHT** - but prepare this now for smoother public launch.

### ✅ 6.1 App Information

**Location:** App Store Connect → Your App → **App Information** tab

**Required Fields:**
- [ ] **Subtitle:** "Safe visuals for babies & toddlers"
- [ ] **Privacy Policy URL:** `https://b-kub24.github.io/BabySafeVisuals/privacy-policy.html` ✅
- [ ] **Category:**
  - Primary: **Education**
  - Secondary: **Entertainment**
- [ ] **Content Rights:** Check "I own or have rights to use..."
- [ ] **Age Rating:** 4+ (no objectionable content)

---

### ✅ 6.2 Prepare App Store Listing (Draft)

**Location:** App Store Connect → Your App → **1.0 Prepare for Submission**

**Copy this draft:**

**Name:**
```
BabySafe Visuals
```

**Subtitle:**
```
Safe, calming scenes for babies
```

**Promotional Text:**
```
Turn your device into a safe, engaging toy for your baby. No ads, no tracking, just beautiful interactive scenes.
```

**Description:**
```
BabySafe Visuals is a parent-controlled app designed for safe device handoff to babies and toddlers.

✨ FEATURES:
• 7 interactive scenes (Snowglobe, Water Ripples, Bubbles, and more)
• Responds to touch, tilt, and shake
• Secure parent gate (6-second hold + Face ID/Touch ID)
• No ads, no analytics, no data collection
• Works perfectly with iOS Guided Access mode
• One-time purchase unlocks all premium scenes

🔒 PARENT CONTROLS:
• Hidden parent gate in top-right corner
• Requires 6-second hold + biometric authentication
• Guided Access compatibility for full device lockdown

🎨 SCENES:
• Snowglobe (FREE) - Shake to create a snowstorm
• Water Ripples - Touch creates beautiful ripples
• Color Mixer - Mix colors by dragging your finger
• Floating Bubbles - Pop bubbles that float up
• Magnetic Particles - Move your device to attract particles
• Aurora Orbs - Swirl glowing orbs of light
• Calm Static - Gentle, soothing visual noise

💡 PERFECT FOR:
• Long car rides or flights
• Waiting rooms and restaurants
• Calm-down time before bed
• Sensory stimulation for babies 6+ months

🔐 PRIVACY:
Zero data collection. Your photos stay on your device. No tracking, no accounts, no external servers.

🛡️ SAFE BY DESIGN:
Designed with child safety experts. Parent gate prevents accidental purchases or settings changes.

One-time purchase unlocks all premium scenes forever. No subscriptions, no hidden fees.
```

**Keywords:**
```
baby,toddler,safe,parent,control,visual,calm,sensory,lock,guided
```

**Support URL:**
```
https://b-kub24.github.io/BabySafeVisuals/support.html
```

**Marketing URL (optional):**
```
https://b-kub24.github.io/BabySafeVisuals/
```

---

### ✅ 6.3 Screenshots (Required Before Public Release)

**⚠️ You'll need to capture these on your Mac:**

**Required Sizes:**
- **6.7" Display** (iPhone 16 Pro Max) - 1-10 screenshots
- **12.9" iPad Pro** - 1-10 screenshots (if targeting iPad)

**Recommended Screenshots:**
1. Snowglobe scene (showing snowflakes falling)
2. Water Ripples (mid-touch interaction)
3. Bubbles (showing colorful bubbles)
4. Parent Menu (showing scene grid)
5. Feature highlight (showing parent gate or Guided Access info)

**How to capture:**
1. Run app on device or simulator (matching required size)
2. Navigate to each scene
3. Press **Volume Up + Side Button** (on device) or **⌘S** (in simulator)
4. Screenshots save to Photos app or Desktop

**Upload:**
- App Store Connect → App Store → Screenshots & Preview
- Drag images into size categories
- Order them (first image is primary)

---

## 🎯 PHASE 7: APP REVIEW PREPARATION

### ✅ 7.1 App Review Information

**Location:** App Store Connect → App Store → App Review Information

**Fill in:**
- [ ] **Sign-In Required:** NO
- [ ] **Demo Account:** Not applicable
- [ ] **Contact Information:**
  - First Name: Brent
  - Last Name: Kubitschek
  - Email: [email protected]
- [ ] **Notes:**

**Copy this into Notes field:**
```
This is a parent-controlled utility app designed for supervised handoff to young children.

HOW TO ACCESS PARENT CONTROLS:
1. Press and hold the TOP-RIGHT CORNER of the screen for 6 SECONDS
2. Confirm with Face ID/Touch ID
3. Parent Menu opens with scene selection and settings

TESTING THE PARENT GATE:
- The parent gate is intentionally hidden (no visible button)
- Hold top-right corner for 6 seconds
- Progress ring appears during hold
- Face ID/Touch ID prompt appears after hold completes

IN-APP PURCHASE:
- Product ID: "unlock_all_scenes"
- Price: $2.99
- Unlocks 6 premium scenes (Snowglobe is free)
- Parent gate prevents child access to purchase UI

GUIDED ACCESS:
- App is designed to work with iOS Guided Access
- Instructions provided in Parent Menu
- Not enforced (cannot be enforced programmatically)

PRIVACY:
- Zero data collection
- No analytics, ads, or tracking
- All processing happens on-device
- No external servers

Test device can be used without Guided Access enabled - the parent gate still functions.
```

---

### ✅ 7.2 Age Rating Questionnaire

**Location:** App Store Connect → App Store → Age Rating

**Answer these:**
- Cartoon or Fantasy Violence: **None**
- Realistic Violence: **None**
- Sexual Content or Nudity: **None**
- Profanity or Crude Humor: **None**
- Medical/Treatment Information: **None**
- Alcohol, Tobacco, or Drug Use: **None**
- Simulated Gambling: **None**
- Horror/Fear Themes: **None**
- Mature/Suggestive Themes: **None**
- Unrestricted Web Access: **No**
- Gambling: **No**

**Result:** Should be rated **4+**

---

### ✅ 7.3 Content Rights & Privacy Questions

**Location:** App Store Connect → App Store → Pricing and Availability

**Answer:**
- [ ] **Do you own rights to this content?** YES
- [ ] **Privacy Policy URL:** `https://b-kub24.github.io/BabySafeVisuals/privacy-policy.html`

**Privacy Section (App Privacy):**
1. Click **Edit** next to "App Privacy"
2. **Do you collect data from this app?** → **NO**
3. Save

**Result:** Your App Privacy label will show "No Data Collected" ✅

---

## ✅ FINAL TESTFLIGHT CHECKLIST

**Before sending to testers:**
- [ ] Build uploaded and processed successfully
- [ ] Export compliance answered (encryption = NO)
- [ ] Internal testers added (if desired)
- [ ] TestFlight build shows "Ready to Test"
- [ ] Tested on physical device with sandbox IAP
- [ ] All scenes work correctly
- [ ] Parent gate works (hold + Face ID)
- [ ] Purchase and restore work

**Before submitting for App Review (future):**
- [ ] App Store metadata complete (name, description, keywords)
- [ ] Screenshots uploaded for all required sizes
- [ ] Privacy policy URL live and accessible
- [ ] Support URL live and accessible
- [ ] In-App Purchase approved and "Ready to Submit"
- [ ] App Review notes filled in with testing instructions
- [ ] Age rating complete (4+)
- [ ] Pricing set (free with IAP)

---

## 🚨 COMMON ISSUES & FIXES

### Issue: "No signing certificate found"
**Fix:**
1. Xcode → Preferences → Accounts
2. Select your Apple ID → **Download Manual Profiles**
3. Return to Signing & Capabilities → Select Team again

---

### Issue: "Product not found" in app
**Fix:**
1. Verify IAP Product ID matches: `unlock_all_scenes`
2. Check IAP status in App Store Connect (must be approved)
3. Restart Xcode and rebuild
4. Use sandbox tester account (not your real Apple ID)

---

### Issue: "Build is invalid"
**Fix:**
1. Check email from Apple for specific error
2. Common causes:
   - Missing capabilities (enable In-App Purchase)
   - Invalid bundle ID (must match App Store Connect)
   - Missing app icon

---

### Issue: "Archive option is grayed out"
**Fix:**
1. Select destination → **"Any iOS Device (arm64)"**
2. NOT a simulator or physical device
3. Clean Build Folder (⇧⌘K) and try again

---

## 📊 TIMELINE ESTIMATE

| Phase | Time | Can Start |
|-------|------|-----------|
| Apple Developer enrollment | 24 hours | Immediately |
| App Store Connect setup | 30 minutes | After enrollment |
| In-App Purchase setup | 15 minutes | After app created |
| Xcode configuration | 15 minutes | Anytime |
| Archive & upload | 30 minutes | After Xcode config |
| Build processing | 10-60 minutes | After upload |
| TestFlight testing | Ongoing | After processing |

**Total time to first TestFlight build:** ~2-4 hours (excluding Apple approval wait)

---

## 🎉 NEXT STEPS AFTER TESTFLIGHT

**Once TestFlight is working:**
1. ✅ Share TestFlight link with friends/family for beta testing
2. 📸 Gather feedback and collect screenshots
3. 🐛 Fix any bugs found during testing
4. 📝 Complete App Store metadata (description, screenshots)
5. 🚀 Submit for App Review when ready

**App Review timeline:**
- Typical: 24-48 hours
- Can take up to 7 days
- Rejection rate for well-prepared apps: ~10%

---

## 📞 NEED HELP?

**If stuck:**
1. Check RED-TEAM-REPORT.md for security/technical issues
2. Apple Developer Forums: https://developer.apple.com/forums/
3. App Store Connect Help: https://developer.apple.com/support/app-store-connect/

**Common resources:**
- [TestFlight Beta Testing Guide](https://developer.apple.com/testflight/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

**Good luck with your TestFlight launch! 🚀**

*Checklist prepared by Claude (Subagent) - 2026-02-10*
