# Firebase Package Name Update Guide

## Overview
You need to update your Firebase project to use the new package name `com.gumbotech.gaytalks` instead of `com.example.gaytalk`.

## Option 1: Add New Android App (Recommended)

This is the recommended approach as Firebase doesn't allow changing package names for existing apps.

### Steps:

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project: `gaytalks-b929a`

2. **Add New Android App**
   - Click on the gear icon (⚙️) next to "Project Overview"
   - Click "Project settings"
   - Scroll down to "Your apps" section
   - Click the "Add app" button (or the Android icon if you see platform options)
   - Select "Android" platform

3. **Register the New App**
   - **Android package name**: Enter `com.gumbotech.gaytalks`
   - **App nickname** (optional): Enter something like "GayTalks - New Package"
   - **Debug signing certificate SHA-1** (optional): You can add this later if needed
   - Click "Register app"

4. **Download google-services.json**
   - After registering, Firebase will show you a download button for `google-services.json`
   - Click "Download google-services.json"
   - **Important**: Replace the existing file at:
     ```
     android/app/google-services.json
     ```
   - Make sure to backup your old file first if you want to keep it

5. **Update iOS Bundle ID (if needed)**
   - In the same Firebase Console, go to your iOS app settings
   - If you need to update the iOS bundle ID to `com.gumbotech.gaytalks`, you may need to:
     - Add a new iOS app with the new bundle ID, OR
     - Update the existing iOS app's bundle ID (if allowed)

## Option 2: Update Existing App (If Available)

Some Firebase projects allow updating the package name, but this is less common.

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project: `gaytalks-b929a`

2. **Find Your Android App**
   - Go to Project Settings
   - Under "Your apps", find the Android app with package name `com.example.gaytalk`

3. **Update Package Name**
   - Click on the app
   - Look for an "Edit" or "Settings" option
   - If available, update the package name to `com.gumbotech.gaytalks`
   - Save changes

4. **Download Updated google-services.json**
   - Download the updated `google-services.json`
   - Replace the file at `android/app/google-services.json`

## After Updating Firebase

### 1. Update firebase_options.dart (if using FlutterFire CLI)

If you're using FlutterFire CLI, regenerate the `firebase_options.dart` file:

```bash
# Install FlutterFire CLI if not already installed
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will automatically:
- Detect your new package name
- Update `firebase_options.dart` with the correct configuration
- Ensure all platforms are properly configured

### 2. Verify the Configuration

After downloading the new `google-services.json`, verify it contains the new package name:

```bash
# Check the package name in google-services.json
grep -A 2 "package_name" android/app/google-services.json
```

You should see `"package_name": "com.gumbotech.gaytalks"` in the file.

### 3. Clean and Rebuild

After updating the Firebase configuration:

```bash
# Clean the build
flutter clean

# Get dependencies
flutter pub get

# Rebuild the app
flutter build apk  # or flutter run
```

## Important Notes

⚠️ **Data Migration**: If you're using Firebase services (Firestore, Authentication, etc.), note that:
- Adding a new app with a new package name creates a **separate app** in Firebase
- User data, authentication, etc. are tied to the package name
- You may need to migrate data or handle both package names during transition

⚠️ **OAuth Clients**: The `google-services.json` file contains OAuth client IDs. Make sure:
- The new app has the correct OAuth clients configured
- Google Sign-In will work with the new package name
- You may need to add the new package name to your OAuth consent screen in Google Cloud Console

⚠️ **SHA-1 Certificate**: For Google Sign-In to work properly, you may need to:
- Add your app's SHA-1 certificate fingerprint to Firebase
- Go to Project Settings → Your apps → Android app → Add fingerprint
- Get your SHA-1: `keytool -list -v -keystore <path-to-keystore> -alias <alias>`

## Quick Checklist

- [ ] Added new Android app in Firebase Console with package name `com.gumbotech.gaytalks`
- [ ] Downloaded new `google-services.json` file
- [ ] Replaced `android/app/google-services.json` with the new file
- [ ] Updated iOS bundle ID if needed
- [ ] Regenerated `firebase_options.dart` using `flutterfire configure` (optional but recommended)
- [ ] Verified package name in `google-services.json`
- [ ] Cleaned and rebuilt the project
- [ ] Tested Firebase services (Auth, Firestore, etc.)

## Troubleshooting

**Issue**: Firebase services not working after update
- **Solution**: Make sure you've replaced `google-services.json` and cleaned the build

**Issue**: Google Sign-In not working
- **Solution**: Add SHA-1 certificate fingerprint to Firebase Console

**Issue**: Old package name still in use
- **Solution**: Check that you've updated all references and cleaned the build cache

