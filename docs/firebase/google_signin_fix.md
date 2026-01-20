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
46:6C:89:22:5C:E6:E3:59:B5:9F:C8:B4:EF:D5:1F:A7:0E:F3:72:69
```

#### Release SHA-1 (for production):
```
C5:3E:78:B5:BD:45:3E:F7:14:5B:1C:AC:7C:AB:35:2F:DD:98:1E:46
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
- **Debug SHA-1**: `46:6C:89:22:5C:E6:E3:59:B5:9F:C8:B4:EF:D5:1F:A7:0E:F3:72:69`
- **Release SHA-1**: `C5:3E:78:B5:BD:45:3E:F7:14:5B:1C:AC:7C:AB:35:2F:DD:98:1E:46`
- **Package Name**: `com.gumbotech.gaytalks`




