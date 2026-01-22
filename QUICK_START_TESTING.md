# Quick Start - Testing on Physical Device & Emulator

## 🚀 Quick Setup (5 Minutes)

### Step 1: Verify Backend is Running

Open browser and visit:
```
https://gaytalks.gumbotech.in/api/../health
```

You should see:
```json
{"status":"OK","services":{"firebase":"connected","mongodb":"connected"}}
```

✅ If you see this, backend is ready!  
❌ If not, start your backend server first.

---

### Step 2: Connect Physical Device

1. **On your Android phone:**
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times (enables Developer Options)
   - Go to Settings → Developer Options
   - Enable "USB Debugging"

2. **Connect phone to computer via USB cable**

3. **Allow USB debugging** when prompted on phone

4. **Verify connection:**
   ```bash
   flutter devices
   ```
   You should see your phone in the list!

---

### Step 3: Run on Physical Device

Open terminal and run:

```bash
cd c:\Users\shrey\OneDrive\Desktop\gaytalk_codebase_updated
flutter run
```

Flutter will automatically detect your phone and install the app!

**What to watch for in console:**
```
✅ Environment: PRODUCTION
✅ Base URL: https://gaytalks.gumbotech.in/api
✅ Backend login successful
✅ JWT tokens saved to local storage
```

---

### Step 4: Start Android Emulator

**Option A: Using Android Studio (Recommended)**

1. Open Android Studio
2. Click "Device Manager" icon (phone icon on right side)
3. Click ▶️ Play button on any emulator
4. Wait for emulator to boot (~30 seconds)

**Option B: Create New Emulator (if you don't have one)**

1. Open Android Studio
2. Click "Device Manager"
3. Click "+ Create Device"
4. Select "Pixel 5" → Next
5. Select "Tiramisu" (API 33) → Next → Finish
6. Click ▶️ to start it

---

### Step 5: Run on Emulator

**In a NEW terminal window:**

```bash
cd c:\Users\shrey\OneDrive\Desktop\gaytalk_codebase_updated
flutter run
```

If you have both physical device and emulator connected, Flutter will ask you to choose. Select the emulator.

---

## 🎯 Testing Both Simultaneously

### Terminal 1 - Physical Device
```bash
cd c:\Users\shrey\OneDrive\Desktop\gaytalk_codebase_updated
flutter run
# Select your physical device when prompted
```

### Terminal 2 - Emulator
```bash
cd c:\Users\shrey\OneDrive\Desktop\gaytalk_codebase_updated
flutter run
# Select emulator when prompted
```

Now you can test on both devices at the same time! 🎉

---

## ✅ Quick Testing Checklist

### On Physical Device:
- [ ] App launches successfully
- [ ] Tap "Sign up with Google"
- [ ] Login works
- [ ] Check console shows: `✅ Backend login successful`
- [ ] Navigate to home screen
- [ ] Test wallet, profile, calls

### On Emulator:
- [ ] App launches successfully
- [ ] Login with DIFFERENT Google account
- [ ] Check console shows: `✅ Backend login successful`
- [ ] Test same features
- [ ] Compare with physical device

### Both Devices:
- [ ] Both can login simultaneously
- [ ] Both connect to same backend
- [ ] Both show correct user data
- [ ] No conflicts or errors

---

## 🐛 Quick Troubleshooting

### "No devices found"
```bash
# Check if phone is connected
flutter devices

# If empty, reconnect USB cable and allow USB debugging on phone
```

### "Build failed"
```bash
flutter clean
flutter pub get
flutter run
```

### "Can't connect to backend"
- Check internet connection on device/emulator
- Verify backend is running: https://gaytalks.gumbotech.in/api/../health
- Check console logs for error details

### "Google Sign-In not working"
- Make sure `google-services.json` is in `android/app/`
- Check Firebase Console → Authentication is enabled
- Verify SHA-1 fingerprint is added

---

## 📱 Hot Reload (While App is Running)

While the app is running, you can make changes and see them instantly:

- Press `r` in terminal → Hot reload (fast, for UI changes)
- Press `R` in terminal → Hot restart (full restart)
- Press `q` → Quit app

---

## 🎨 What to Test

### 1. Authentication Flow
- Google Sign-In
- Email/Password Sign-In (tap logo 5 times)
- Logout
- Login again

### 2. User Features
- View profile
- Update profile
- Check wallet balance
- Add funds

### 3. Calling Features
- Initiate call
- Receive call
- End call

### 4. Network Scenarios
- Good WiFi connection
- Mobile data (slower)
- No internet (should show error)

---

## 📊 Console Logs to Monitor

### ✅ Good Logs (What you want to see):
```
=== API Configuration ===
Environment: PRODUCTION
Base URL: https://gaytalks.gumbotech.in/api
========================
🔐 Logging in to backend with Firebase token...
✅ Backend login successful
   User: user@example.com
   Role: user
✅ JWT tokens saved to local storage
✅ Authenticated user: firebase-uid (user@example.com)
```

### ❌ Error Logs (What to investigate):
```
❌ Backend login error: ...
❌ Token verification error: ...
❌ Failed to connect to backend
```

---

## 🚀 Ready to Test!

### Quick Start Commands:

**Physical Device:**
```bash
cd c:\Users\shrey\OneDrive\Desktop\gaytalk_codebase_updated
flutter run
```

**Emulator (after starting it in Android Studio):**
```bash
cd c:\Users\shrey\OneDrive\Desktop\gaytalk_codebase_updated
flutter run
```

**Both at once:**
Open 2 terminal windows and run `flutter run` in each, selecting different devices.

---

## 📚 Need More Help?

- Full testing guide: `TESTING_GUIDE.md`
- Authentication docs: `backend/gay_Talks/JWT_AUTHENTICATION.md`
- Deployment guide: `PRODUCTION_DEPLOYMENT.md`

---

## 🎉 Success!

When you see this on both devices, you're good to go:
- ✅ App running smoothly
- ✅ Login working
- ✅ Console shows `Backend login successful`
- ✅ JWT tokens saved
- ✅ All features accessible

Happy Testing! 🚀
