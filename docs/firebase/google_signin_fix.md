# Fix Google Sign-In Error (Code 10)

## Problem
Google Sign-In is failing with error code `10` (DEVELOPER_ERROR) because the new package name `com.gumbotech.gaytalks` doesn't have the proper OAuth client configuration in Firebase.

## Solution: Add SHA-1 Fingerprints to Firebase

### Step 1: Go to Firebase Console
1. Visit: https://console.firebase.google.com/
2. Select your project: `gaytalks-b929a`
3. Click the gear icon (⚙️) → **Project settings**

### Step 2: Find Your Android App
1. Scroll down to **"Your apps"** section
2. Find the Android app with package name: `com.gumbotech.gaytalks`
3. Click on it to expand

### Step 3: Add SHA-1 Fingerprints
Click **"Add fingerprint"** and add BOTH of these:

#### Debug SHA-1 (for development/testing):
```
10:A8:45:65:41:F8:CA:E0:CD:83:55:68:5B:6C:F1:4B:6F:9B:C3:90
```

#### Release SHA-1 (for production):
```
E0:3F:81:69:53:20:82:C7:37:6F:90:1F:E8:3F:AA:24:54:50:B5:A6
```

**Important**: Add both fingerprints! You need the debug one for testing and the release one for production builds.

### Step 4: Download Updated google-services.json
1. After adding the fingerprints, Firebase will automatically generate a new OAuth client
2. Click **"Download google-services.json"** button
3. Replace the file at: `android/app/google-services.json`

### Step 5: Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

## Alternative: Use FlutterFire CLI
If you prefer, you can regenerate the configuration:

```bash
# Install FlutterFire CLI if not already installed
dart pub global activate flutterfire_cli

# Configure Firebase (this will detect your SHA-1 automatically)
flutterfire configure
```

## Verify the Fix
After updating `google-services.json`, check that the `com.gumbotech.gaytalks` entry has:
- An OAuth client with `"client_type": 1` (Android client)
- The `android_info` section with `package_name` and `certificate_hash`

## Quick Reference
- **Debug SHA-1**: `10:A8:45:65:41:F8:CA:E0:CD:83:55:68:5B:6C:F1:4B:6F:9B:C3:90`
- **Release SHA-1**: `E0:3F:81:69:53:20:82:C7:37:6F:90:1F:E8:3F:AA:24:54:50:B5:A6`
- **Package Name**: `com.geytalk.app`




