# 🍎 BabySafeVisuals - Complete Beginner Guide to TestFlight

**For someone who has NEVER used Xcode before.**

This guide tells you exactly what to click, where to click it, and what to type.

---

## ⚠️ BEFORE YOU START

**You need:**
1. A Mac computer (MacBook, iMac, Mac Mini, etc.)
2. An iPhone or iPad for testing
3. An Apple ID
4. $99/year Apple Developer account (if you don't have one yet)

**Time needed:** 2-4 hours total (including waiting time)

---

## 📱 PART 1: SETUP (One-Time)

### Step 1.1: Install Xcode (30-60 minutes)

1. **On your Mac**, click the **Apple icon** (top-left corner) → **App Store**
2. In the search bar, type: `Xcode`
3. Click **GET** or the **cloud icon** next to Xcode (it's free, made by Apple)
4. Wait for download (~12 GB - this takes a while!)
5. Once installed, **open Xcode** from your Applications folder
6. It will ask to install "additional components" → Click **Install**
7. Wait for components to install (~5-10 minutes)

**How to verify:** Xcode opens without errors and shows a "Welcome to Xcode" screen.

---

### Step 1.2: Join Apple Developer Program ($99/year)

**Skip this if you already have an active developer account.**

1. Go to: **https://developer.apple.com/programs/enroll/**
2. Click **Start Your Enrollment**
3. Sign in with your Apple ID (or create one)
4. Follow the steps:
   - Agree to terms
   - Provide your legal name and address
   - Pay $99 USD
5. **Wait 24-48 hours** for Apple to approve your account

**How to verify:** You can log into https://appstoreconnect.apple.com

---

### Step 1.3: Download the BabySafeVisuals Code

1. **On your Mac**, open **Terminal** (search for "Terminal" in Spotlight, or find it in Applications → Utilities)

2. **Copy and paste this entire command** (then press Enter):
```bash
cd ~/Desktop && git clone https://github.com/b-kub24/BabySafeVisuals.git && echo "✅ Download complete!"
```

3. You should see a new folder called **BabySafeVisuals** on your Desktop

**How to verify:** Open Finder → Desktop → BabySafeVisuals folder exists

---

## 🖥️ PART 2: OPEN PROJECT IN XCODE

### Step 2.1: Open the Project

1. Open **Finder** on your Mac
2. Go to **Desktop** → **BabySafeVisuals** → **BabySafeVisuals** (yes, go into it twice)
3. Double-click the file: **BabySafeVisuals.xcodeproj** (it has a blue icon)
4. Xcode will open with the project

**If asked "Trust and Open?"** → Click **Trust and Open**

**How to verify:** Xcode shows the project with files listed on the left side

---

### Step 2.2: Sign In to Xcode with Your Apple ID

1. In Xcode, go to menu: **Xcode** → **Settings...** (or press ⌘,)
2. Click the **Accounts** tab at the top
3. Click the **+** button in the bottom-left
4. Select **Apple ID** → Click **Continue**
5. Enter your Apple ID email and password
6. Click **Sign In**

**You should see:** Your name appears in the accounts list with "Agent" or "Admin" role.

**If you see "No team":** Your developer account may not be active yet. Wait for Apple's approval email.

---

### Step 2.3: Configure Signing

1. In the left sidebar of Xcode, click **BabySafeVisuals** (the blue project icon at the very top)
2. In the center panel, make sure **BabySafeVisuals** target is selected under "TARGETS"
3. Click the **Signing & Capabilities** tab
4. Check the box: **Automatically manage signing** ✅
5. Click the **Team** dropdown → Select your name/team

**Expected result:** 
- A green checkmark appears next to "Signing Certificate"
- No red error messages

**If you see errors:**
- "Failed to create provisioning profile" → Click **Try Again** or wait 1 minute
- "No signing certificate" → Go to Xcode → Settings → Accounts → click your account → click **Download Manual Profiles**

---

## 🌐 PART 3: CREATE APP IN APP STORE CONNECT

### Step 3.1: Create the App

1. Open your web browser and go to: **https://appstoreconnect.apple.com**
2. Sign in with your Apple ID
3. Click **My Apps**
4. Click the **+** button (top-left) → **New App**

**Fill in these fields EXACTLY:**
| Field | What to Type |
|-------|--------------|
| Platforms | ☑️ iOS (check the box) |
| Name | `BabySafe Visuals` |
| Primary Language | English (U.S.) |
| Bundle ID | Select `BK.BabySafeVisuals` from dropdown |
| SKU | `babysafe-visuals-2026` |
| User Access | Full Access |

5. Click **Create**

**If "BK.BabySafeVisuals" doesn't appear in dropdown:**
1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click **+** → Select **App IDs** → Click **Continue**
3. Select **App** → Click **Continue**
4. Fill in:
   - Description: `BabySafeVisuals`
   - Bundle ID: Select "Explicit" and type: `BK.BabySafeVisuals`
5. Scroll down → Check **In-App Purchase** capability ✅
6. Click **Continue** → **Register**
7. Go back to App Store Connect and try again

---

### Step 3.2: Set Up In-App Purchase

**Note: This is required even in testing mode so the app doesn't crash.**

1. In App Store Connect, click your app **BabySafe Visuals**
2. In the left sidebar, click **In-App Purchases**
3. Click **+** button → Select **Non-Consumable**

**Fill in EXACTLY:**
| Field | What to Type |
|-------|--------------|
| Reference Name | `Unlock All Scenes` |
| Product ID | `unlock_all_scenes` |

4. Click **Create**

5. In the "Pricing" section:
   - Click **Add Pricing**
   - Base Country: United States
   - Price: Select **$2.99** (Tier 3)
   - Click **Confirm**

6. In "App Store Localization" section:
   - Click **English (U.S.)**
   - Display Name: `Unlock All Scenes`
   - Description: `Unlock all 6 premium interactive scenes for your baby.`
   - Click **Save**

7. Status should show "Ready to Submit" or "Missing Metadata"

---

### Step 3.3: Create Sandbox Tester (for testing purchases)

1. In App Store Connect, click **Users and Access** (top menu)
2. Click **Sandbox** → **Testers**
3. Click **+** to add a tester

**Fill in:**
| Field | What to Type |
|-------|--------------|
| First Name | `Test` |
| Last Name | `User` |
| Email | A NEW email (can be fake, like `test12345@testing.local`) |
| Password | Something you'll remember |
| Confirm Password | Same as above |
| Secret Question | Any question |
| Secret Answer | Any answer |
| Date of Birth | Any date (make them 18+) |
| App Store Territory | United States |

4. Click **Invite** or **Create**

**Save this email and password** - you'll need it to test purchases later!

---

## 📦 PART 4: BUILD AND UPLOAD TO TESTFLIGHT

### Step 4.1: Select Build Destination

1. In Xcode, look at the **top toolbar** (near the Play ▶️ and Stop ⏹️ buttons)
2. You'll see a dropdown that might say "iPhone 15 Pro" or "Any iOS Device"
3. Click that dropdown
4. Select: **Any iOS Device (arm64)**

**Why:** This creates a build that works on all iPhones, which Apple requires.

---

### Step 4.2: Clean the Project

1. In Xcode menu: **Product** → **Clean Build Folder**
   - Or press: **Shift + Command + K** (⇧⌘K)
2. Wait for "Clean Succeeded" message

---

### Step 4.3: Archive the App

1. In Xcode menu: **Product** → **Archive**
2. Wait 2-5 minutes (you'll see a progress bar)
3. When done, a new window called **Organizer** opens automatically

**If Archive is grayed out:**
- Make sure you selected "Any iOS Device (arm64)" in step 4.1
- Make sure Signing shows no errors (green checkmark)

**If you see build errors:**
- Read the red error messages
- Most common: Signing issues (go back to Part 2, Step 2.3)

---

### Step 4.4: Upload to App Store Connect

In the **Organizer** window:

1. Select your archive (it should be highlighted already)
2. Click **Distribute App** (blue button on the right)
3. Select **App Store Connect** → Click **Next**
4. Select **Upload** → Click **Next**
5. Select **Automatically manage signing** → Click **Next**
6. Review the summary → Click **Upload**

**Wait 3-10 minutes** for the upload to complete.

**You'll see:** "Upload Successful" message

---

### Step 4.5: Wait for Processing

1. Go to: **https://appstoreconnect.apple.com**
2. Click your app → **TestFlight** tab
3. Under "iOS Builds", you'll see your build with status:
   - **Processing** (yellow) → Wait 10-30 minutes
   - **Ready to Test** (after you complete compliance) → Success!

**While waiting:** Check your email - Apple sends updates.

---

## 📋 PART 5: COMPLETE TESTFLIGHT SETUP

### Step 5.1: Export Compliance

Once your build shows in TestFlight:

1. Click on your build (Version 1.0, Build 1)
2. You'll see a yellow banner: "Provide Export Compliance Information"
3. Click **Provide Export Compliance**
4. Question: "Does your app use encryption?"
5. Select: **No** (the app only uses standard Apple HTTPS)
6. Click **Save**

**Build status should change to:** "Ready to Test" ✅

---

### Step 5.2: Add Yourself as Tester

1. In TestFlight tab, click **Internal Testing** (left sidebar)
2. Click **+** next to "Groups" → Create group named: `Internal`
3. Click your new group → **Add Testers**
4. Select your Apple ID → Click **Add**
5. Under "Builds", click **+** → Select your build → Click **Add**

**You'll receive:** An email with a TestFlight invitation

---

## 📱 PART 6: INSTALL ON YOUR IPHONE

### Step 6.1: Install TestFlight App

1. **On your iPhone**, open **App Store**
2. Search for: `TestFlight`
3. Download the free app (it's made by Apple)

---

### Step 6.2: Accept Invitation and Install

**Option A: From Email**
1. Open the email from Apple (subject: "You're invited to test BabySafe Visuals")
2. Tap **View in TestFlight**
3. Tap **Accept** → **Install**

**Option B: From TestFlight App**
1. Open **TestFlight** app on your iPhone
2. BabySafe Visuals should appear under "Available"
3. Tap **Install**

---

### Step 6.3: Test the App!

1. Open **BabySafe Visuals** on your iPhone
2. **Test these features:**
   - [ ] App launches and shows Snowglobe scene
   - [ ] Touch the screen - snow responds
   - [ ] Shake phone - more snow appears
   - [ ] Parent gate: Hold top-right corner for 6 seconds → Face ID prompt appears
   - [ ] Parent menu opens with all scenes
   - [ ] Try each scene - they should all be unlocked (TESTING_MODE is on!)

**🎉 Congratulations! You've successfully deployed to TestFlight!**

---

## ⚠️ IMPORTANT: BEFORE APP STORE SUBMISSION

When you're ready to submit to the real App Store:

1. In Xcode, open: `BabySafeVisuals/App/AppState.swift`
2. Find this line near the top:
```swift
static let TESTING_MODE = true
```
3. Change it to:
```swift
static let TESTING_MODE = false
```
4. Archive and upload again (repeat Part 4)

This re-enables the actual purchase requirement.

---

## 🆕 BONUS: Using Xcode 26.3's New AI Features

**Xcode 26.3** (released Feb 2026) now supports AI coding agents!

### Enable Claude/Codex in Xcode:

1. Open Xcode → **Settings** (⌘,) → **AI** tab
2. Enable **Agentic Coding**
3. Sign in to your Anthropic or OpenAI account
4. Click **Configure MCP** to set up Model Context Protocol

### What it does:
- Claude or Codex can help you write and debug code
- Ask questions about your project in natural language
- Get suggestions for fixing build errors
- Generate UI code from descriptions

---

## 📞 TROUBLESHOOTING

### "Archive" is grayed out
→ Select "Any iOS Device (arm64)" in the destination dropdown

### "No signing certificate found"
→ Xcode → Settings → Accounts → Download Manual Profiles

### "Product not found" in the app
→ Make sure the In-App Purchase Product ID is exactly: `unlock_all_scenes`

### "Build is invalid" after upload
→ Check your email for the specific error from Apple

### App crashes on launch
→ Check Xcode's debug console for error messages

### TestFlight build says "Processing" for over an hour
→ This sometimes happens. Wait up to 24 hours, or try uploading again.

---

## 📊 SUMMARY CHECKLIST

**One-time setup:**
- [ ] Xcode installed
- [ ] Apple Developer account active ($99/year)
- [ ] Project downloaded from GitHub

**App Store Connect:**
- [ ] App created in App Store Connect
- [ ] In-App Purchase "unlock_all_scenes" created
- [ ] Sandbox tester account created

**Xcode:**
- [ ] Signing configured (green checkmark)
- [ ] Destination set to "Any iOS Device (arm64)"
- [ ] Archive created successfully
- [ ] Upload to App Store Connect successful

**TestFlight:**
- [ ] Export compliance completed (encryption = No)
- [ ] Tester added to Internal group
- [ ] Build shows "Ready to Test"
- [ ] TestFlight app installed on iPhone
- [ ] BabySafe Visuals installed via TestFlight

**Testing:**
- [ ] App launches
- [ ] All scenes work (TESTING_MODE enabled)
- [ ] Parent gate works (6 second hold + Face ID)

---

**You did it! 🎉**

For App Store submission, remember to:
1. Set `TESTING_MODE = false`
2. Add screenshots
3. Fill out all App Store metadata
4. Submit for review (24-48 hours)

Good luck!
