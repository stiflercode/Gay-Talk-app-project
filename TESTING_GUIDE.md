# Testing Guide - Physical Device & Emulator

## Overview

This guide will help you test the GayTalk app on both:
1. **Physical Android Device** (connected via USB)
2. **Android Emulator** (running on your computer)

Both will connect to the **production backend**: `https://gaytalks.gumbotech.in/api`

---

## Prerequisites

### ✅ Backend Must Be Running

Ensure your production backend is running and accessible:

```bash
# Test backend health
curl https://gaytalks.gumbotech.in/api/../health
```

Expected response:
```json
{
  "status": "OK",
  "services": {
    "firebase": "connected",
    "mongodb": "connected"
  }
}
```

If backend is not running, start it:
```bash
cd backend/gay_Talks
pm2 start server.js --name gaytalk-backend
# or
node server.js
```

---

## Setup Instructions

### 1. Check Connected Devices

```bash
flutter devices
```

You should see:
- Your physical device (e.g., "SM-G991B" or similar)
- Android emulator (if running)
- Windows, Chrome, Edge (web platforms)

### 2. Start Android Emulator (if not running)

**Option A: Using Android Studio**
1. Open Android Studio
2. Click "Device Manager" (phone icon on right sidebar)
3. Click ▶️ (Play) on any emulator
4. Wait for emulator to boot

**Option B: Using Command Line**
```bash
# List available emulators
emulator -list-avds

# Start an emulator (replace with your emulator name)
emulator -avd Pixel_5_API_33
```

### 3. Connect Physical Device

1. **Enable Developer Options** on your phone:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   - Developer Options will be enabled

2. **Enable USB Debugging**:
   - Go to Settings → Developer Options
   - Enable "USB Debugging"

3. **Connect via USB**:
   - Connect phone to computer with USB cable
   - Allow USB debugging when prompted on phone

4. **Verify connection**:
   ```bash
   flutter devices
   ```
   Your phone should appear in the list

---

## Running the App

### Option 1: Run on Physical Device

```bash
# Navigate to project directory
cd c:\Users\shrey\OneDrive\Desktop\gaytalk_codebase_updated

# Run on connected physical device
flutter run
```

Flutter will automatically detect and use your physical device.

**To specify device explicitly:**
```bash
# List devices with IDs
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Option 2: Run on Emulator

```bash
# Make sure emulator is running first
# Then run:
flutter run
```

If you have multiple devices, Flutter will ask you to choose.

**To specify emulator explicitly:**
```bash
flutter run -d emulator-5554
```

### Option 3: Run on Both Simultaneously

**Terminal 1 (Physical Device):**
```bash
flutter run -d <physical-device-id>
```

**Terminal 2 (Emulator):**
```bash
flutter run -d emulator-5554
```

---

## Testing Checklist

### 🔐 Authentication Testing

#### Test 1: Google Sign-In
- [ ] Tap "Sign up with Google"
- [ ] Select Google account
- [ ] Check console logs for:
  - `Environment: PRODUCTION`
  - `Base URL: https://gaytalks.gumbotech.in/api`
  - `🔐 Logging in to backend with Firebase token...`
  - `✅ Backend login successful`
  - `✅ JWT tokens saved to local storage`
- [ ] Verify navigation to Language Selection (new user) or Home (existing user)

#### Test 2: Email/Password Sign-In (Hidden Feature)
- [ ] Tap logo 5 times quickly
- [ ] Email/password dialog appears
- [ ] Enter test credentials
- [ ] Sign in successfully
- [ ] Check console logs for JWT tokens

#### Test 3: Token Refresh
- [ ] After login, wait a few minutes
- [ ] Navigate between screens
- [ ] Make API calls (view profile, wallet, etc.)
- [ ] Check console logs for automatic token refresh (if token expired)

#### Test 4: Logout
- [ ] Tap logout button
- [ ] Check console logs for:
  - `✅ Backend logout successful`
  - `✅ JWT tokens cleared from local storage`
- [ ] Verify navigation to login screen
- [ ] Verify cannot access protected screens

### 📱 App Functionality Testing

#### Test 5: User Profile
- [ ] View profile information
- [ ] Update profile (name, language, etc.)
- [ ] Check console logs for API calls with JWT authentication

#### Test 6: Wallet
- [ ] View wallet balance
- [ ] Add funds (test payment)
- [ ] Check console logs for payment API calls

#### Test 7: Calling
- [ ] Initiate a call
- [ ] Check Agora token generation
- [ ] Verify call connects properly

#### Test 8: Multi-Device Testing
- [ ] Login on physical device
- [ ] Login on emulator with DIFFERENT account
- [ ] Verify both work independently
- [ ] Test calls between devices (if possible)

---

## Console Logs to Monitor

### ✅ Successful Login
```
=== API Configuration ===
Environment: PRODUCTION
Base URL: https://gaytalks.gumbotech.in/api
Auth URL: https://gaytalks.gumbotech.in/api/auth
========================
🔐 Logging in to backend with Firebase token...
✅ Backend login successful
   User: user@example.com
   Role: user
✅ JWT tokens saved to local storage
```

### ✅ API Call with Authentication
```
✅ Authenticated user: firebase-uid (user@example.com)
```

### ✅ Token Refresh
```
⚠️ Token expired, attempting refresh...
🔄 Refreshing access token...
✅ Access token refreshed successfully
```

### ❌ Error Scenarios to Test

**No Internet Connection:**
```
❌ Backend login error: SocketException: Failed to connect
```
- Verify error message shown to user
- Verify app doesn't crash

**Invalid Token:**
```
❌ Token verification error: INVALID_TOKEN
```
- Verify user is logged out
- Verify navigation to login screen

**Backend Down:**
```
❌ Failed to connect to backend
```
- Verify graceful error handling
- Verify retry mechanism

---

## Debugging Tips

### View Logs in Real-Time

**Physical Device:**
```bash
flutter run -d <device-id> --verbose
```

**Emulator:**
```bash
flutter run -d emulator-5554 --verbose
```

### Filter Logs

**Windows PowerShell:**
```bash
flutter run | Select-String "Backend|JWT|Token|Auth"
```

**View Only Errors:**
```bash
flutter run | Select-String "Error|Failed|❌"
```

### Hot Reload

While app is running:
- Press `r` in terminal for hot reload (quick UI changes)
- Press `R` for hot restart (full app restart)
- Press `q` to quit

### Clear App Data

If you encounter issues:

**Physical Device:**
1. Go to Settings → Apps → GayTalk
2. Tap "Storage"
3. Tap "Clear Data"
4. Reinstall app

**Emulator:**
```bash
flutter clean
flutter run
```

---

## Common Issues & Solutions

### Issue 1: "No devices found"

**Solution:**
```bash
# Check ADB devices
adb devices

# If empty, reconnect USB or restart emulator
# Then run:
flutter devices
```

### Issue 2: "Failed to connect to backend"

**Solution:**
1. Check backend is running: `curl https://gaytalks.gumbotech.in/api/../health`
2. Check internet connection on device/emulator
3. Verify URL in `lib/config/api_config.dart`

### Issue 3: "Build failed"

**Solution:**
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run
```

### Issue 4: "Google Sign-In not working"

**Solution:**
1. Check `google-services.json` is in `android/app/`
2. Verify SHA-1 fingerprint is added to Firebase Console
3. Check Firebase Authentication is enabled

### Issue 5: "Token verification failed"

**Solution:**
1. Check backend logs for JWT_SECRET
2. Verify backend is using correct Firebase service account
3. Clear app data and login again

---

## Performance Testing

### Test on Physical Device
- [ ] App launches quickly (< 3 seconds)
- [ ] Login completes in < 5 seconds
- [ ] API calls respond in < 2 seconds
- [ ] No UI freezing or lag
- [ ] Smooth animations

### Test on Emulator
- [ ] App runs smoothly (may be slower than physical device)
- [ ] No crashes or ANRs
- [ ] Memory usage acceptable

---

## Network Testing

### Test Different Network Conditions

**Good Connection (WiFi):**
- [ ] All features work smoothly
- [ ] API calls fast

**Slow Connection (Mobile Data):**
- [ ] App handles slow responses gracefully
- [ ] Loading indicators shown
- [ ] Timeouts handled properly

**No Connection:**
- [ ] Appropriate error messages
- [ ] App doesn't crash
- [ ] Can retry when connection restored

---

## Quick Commands Reference

```bash
# List all devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run with verbose logging
flutter run --verbose

# Build release APK
flutter build apk --release

# Install APK on device
flutter install

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Check for issues
flutter doctor

# View logs
flutter logs
```

---

## Testing Workflow

### Recommended Testing Order

1. **Start Backend** (if not running)
   ```bash
   curl https://gaytalks.gumbotech.in/api/../health
   ```

2. **Connect Devices**
   - Start emulator
   - Connect physical device via USB
   - Verify: `flutter devices`

3. **Run on Physical Device**
   ```bash
   flutter run -d <physical-device-id>
   ```
   - Test login
   - Test main features
   - Monitor console logs

4. **Run on Emulator** (in new terminal)
   ```bash
   flutter run -d emulator-5554
   ```
   - Test with different account
   - Test same features
   - Compare behavior

5. **Test Multi-Device Scenarios**
   - Login on both devices
   - Test calls between devices
   - Test simultaneous usage

6. **Test Edge Cases**
   - Logout and login again
   - Clear app data and reinstall
   - Test with no internet
   - Test with slow internet

---

## Success Criteria

Your testing is successful when:

✅ App runs on both physical device and emulator  
✅ Login works with Google and Email/Password  
✅ JWT tokens are generated and stored  
✅ All API calls use JWT authentication  
✅ Token refresh works automatically  
✅ Logout clears tokens properly  
✅ No crashes or errors  
✅ Console logs show correct authentication flow  
✅ Both devices can use app simultaneously  

---

## Next Steps After Testing

Once testing is complete:

1. **Fix any issues found**
2. **Build release APK**:
   ```bash
   flutter build apk --release
   ```
3. **Test release build** on physical device
4. **Deploy to Play Store** (if ready)

---

## Support

If you encounter issues:
1. Check console logs for error messages
2. Review `JWT_AUTHENTICATION.md` for authentication details
3. Test backend health endpoint
4. Clear app data and retry
5. Check Firebase Console for authentication status

Happy Testing! 🚀
