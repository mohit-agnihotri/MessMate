# MessMate App — Setup Guide

This guide walks you through every one-time configuration step needed to run the full app.

---

## 1. Firebase Setup (Already Done)
Your app is already linked to Firebase. If you ever need to re-link:
- Run `flutterfire configure` in the project root.

---

## 2. Google Maps API Key Setup

### Step A: Create the API Key
1. Go to https://console.cloud.google.com/
2. Select your project (linked to Firebase)
3. Go to APIs & Services -> Library
4. Enable: **Maps SDK for Android** and **Maps SDK for iOS**
5. Go to APIs & Services -> Credentials -> Create Credentials -> API Key

### Step B: Restrict the Key (MANDATORY before production)
1. Click the key you just created -> Edit
2. Application Restrictions -> Android apps
3. Add: Package name = `com.example.mess_app`, SHA-1 = (get from `keytool -list -v -keystore ~/.android/debug.keystore`)
4. API Restrictions -> Restrict key -> select Maps SDK for Android only

### Step C: Add the Key to the App
- **Android:** Open `android/app/src/main/AndroidManifest.xml`
  Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual key.

- **iOS:** Open `ios/Runner/AppDelegate.swift`
  Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` inside `GMSServices.provideAPIKey(...)`.

### Step D: Set Quota Limits (MANDATORY — quotas actively stop usage, budgets do NOT)
1. Go to: APIs & Services -> Maps SDK for Android -> Quotas
2. Set "Requests per day" to a safe limit (e.g., 500 for testing, 5000 for production launch)
3. Go to Billing -> Budgets & Alerts -> Create Budget
4. Set a monthly budget of ₹0 (or your comfortable limit)
5. Add email alerts at 50%, 90%, 100%
**NOTE:** Budget alerts are NOTIFICATIONS ONLY. Only quota limits enforce a hard cap on usage.

---

## 3. Running the Dish Seeder Script (One-Time Only)

### Step A: Get a Free Pexels API Key
1. Go to https://www.pexels.com/api/
2. Sign up (free) -> Get your API Key

### Step B: Get Firebase Service Account Key
1. Go to Firebase Console -> Project Settings -> Service Accounts
2. Click "Generate New Private Key"
3. Save the downloaded JSON as `scripts/serviceAccountKey.json`
   **NEVER commit this file to Git!**

### Step C: Configure Environment
```
cd scripts
copy .env.example .env
# Edit .env and set your PEXELS_API_KEY
```

### Step D: Install Dependencies and Run
```
cd scripts
npm install
node seed_firebase_dishes.js
```

The script will:
- Process all 1000 dishes
- Skip any dish that already has a valid imageUrl in Firestore
- Call Pexels only for dishes missing an image
- Print a summary: Added / Skipped / Failed counts
- Safe to re-run multiple times — completely idempotent

---

## 4. iOS Maps Setup
In `ios/Runner/AppDelegate.swift`, add:
```swift
import GoogleMaps
// In application(_:didFinishLaunchingWithOptions:):
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
```

In `ios/Podfile`, ensure minimum iOS version is 14.0:
```
platform :ios, '14.0'
```
