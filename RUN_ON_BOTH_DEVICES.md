# Running on Physical Device + Emulator - Step by Step

## Your Connected Physical Device
- **Device:** SM A505F (Samsung Galaxy A50)
- **Device ID:** RZ8M61C5TGD
- **Android Version:** Android 11 (API 30)
- **Status:** ✅ Connected and Ready!

---

## Step-by-Step Instructions

### Step 1: Start Android Emulator

**Option A: Using Android Studio (Recommended)**
1. Open **Android Studio**
2. Look for **"Device Manager"** icon on the right sidebar (phone icon)
3. Click **▶️ (Play button)** next to any emulator
4. Wait 30-60 seconds for emulator to boot

**Option B: If you don't have an emulator**
1. Open Android Studio
2. Click "Device Manager"
3. Click "+ Create Device"
4. Select "Pixel 5" → Next
5. Select "Tiramisu" (API 33) or "S" (API 31) → Next → Finish
6. Click ▶️ to start it

---

### Step 2: Verify Both Devices are Connected

Once emulator is running, open terminal and run:
```bash
flutter devices
```

You should see:
- ✅ SM A505F (your phone)
- ✅ emulator-5554 (or similar - the emulator)
- Windows, Chrome, Edge (ignore these)

---

### Step 3: Run on Physical Device (Terminal 1)

**Open your FIRST terminal:**

```bash
cd c:\Users\shrey\OneDrive\Desktop\gaytalk_codebase_updated
flutter run -d RZ8M61C5TGD
```

This will:
- Install app on your Samsung phone
- Launch the app
- Show console logs in this terminal

**Keep this terminal open!**

---

### Step 4: Run on Emulator (Terminal 2)

**Open a NEW/SECOND terminal window:**

```bash
cd c:\Users\shrey\OneDrive\Desktop\gaytalk_codebase_updated
flutter run -d emulator-5554
```

(Replace `emulator-5554` with the actual emulator ID from `flutter devices`)

This will:
- Install app on emulator
- Launch the app
- Show console logs in this terminal

**Keep this terminal open too!**

---

## Now You Have Both Running! 🎉

### Terminal 1 (Physical Device)
```
Running on SM A505F...
✅ Environment: PRODUCTION
✅ Base URL: https://gaytalks.gumbotech.in/api
```

### Terminal 2 (Emulator)
```
Running on emulator-5554...
✅ Environment: PRODUCTION
✅ Base URL: https://gaytalks.gumbotech.in/api
```

---

## Testing on Both Devices

### On Physical Device (Samsung Phone):
1. Sign in with your Google account (Account A)
2. Complete onboarding if needed
3. Test features: profile, wallet, calls
4. Watch Terminal 1 for logs

### On Emulator:
1. Sign in with DIFFERENT Google account (Account B)
2. Complete onboarding if needed
3. Test same features
4. Watch Terminal 2 for logs

### Test Both Together:
- Both should work independently
- Both connect to same backend
- Try calling between them (if possible)
- Test simultaneous usage

---

## Hot Reload (While Running)

In each terminal, you can:
- Press **`r`** → Hot reload (fast UI updates)
- Press **`R`** → Hot restart (full app restart)
- Press **`q`** → Quit that device

---

## Console Logs to Monitor

### ✅ What You Want to See:
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
```

### ⚠️ Auto-handled (Normal):
```
⚠️ Token expired, attempting refresh...
✅ Access token refreshed successfully
```

### ❌ Errors (Need attention):
```
❌ Backend login error: ...
❌ Failed to connect to backend
```

---

## Quick Commands Reference

```bash
# Check connected devices
flutter devices

# Run on physical device
flutter run -d RZ8M61C5TGD

# Run on emulator (after starting it)
flutter run -d emulator-5554

# Stop app on device
# Press 'q' in the terminal

# Restart app
# Press 'R' in the terminal

# Hot reload
# Press 'r' in the terminal
```

---

## Troubleshooting

### "Emulator not showing in flutter devices"
- Make sure emulator is fully booted (wait 1-2 minutes)
- Run `flutter devices` again

### "Build failed"
```bash
flutter clean
flutter pub get
flutter run -d RZ8M61C5TGD
```

### "Can't run on both at same time"
- Make sure you're using TWO separate terminal windows
- Each terminal runs one device

### "Physical device disconnected"
- Reconnect USB cable
- Allow USB debugging on phone again
- Run `flutter devices` to verify

---

## Success Checklist

- [ ] Physical device connected (SM A505F)
- [ ] Emulator started and running
- [ ] `flutter devices` shows both
- [ ] Terminal 1 running app on physical device
- [ ] Terminal 2 running app on emulator
- [ ] Both apps show login screen
- [ ] Both can login successfully
- [ ] Console logs show `Backend login successful` on both
- [ ] Both devices work independently

---

## Next Steps

Once both are running:
1. Test login on both
2. Test all features on both
3. Compare behavior
4. Test edge cases (logout, no internet, etc.)
5. Monitor console logs for errors

---

Happy Testing! 🚀📱
