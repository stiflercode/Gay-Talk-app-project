# Quick Firebase Service Account Setup

I've created a **template file** with your project details already filled in!

## ✅ What's Already Done

Based on your Flutter app's Firebase configuration, I've pre-filled:
- ✅ Project ID: `gey-talk`
- ✅ Client email format
- ✅ Auth URIs
- ✅ Certificate URLs

## 🚀 Quick Setup (2 Steps)

### Step 1: Download the Real Key from Firebase Console

1. Go to https://console.firebase.google.com/project/gey-talk/settings/serviceaccounts/adminsdk
2. Click **"Generate New Private Key"**
3. Click **"Generate Key"** to download

### Step 2: Replace the Template

The downloaded file will have the complete credentials. Just rename it:

```bash
cd backend
# Delete the template
rm firebase-service-account.TEMPLATE.json

# Rename your downloaded file
mv ~/Downloads/gey-talk-firebase-adminsdk-xxxxx.json firebase-service-account.json
```

**OR** you can copy the `private_key`, `private_key_id`, and `client_id` from the downloaded file into the template and rename it to `firebase-service-account.json`.

## ✅ Verify It Works

```bash
npm start
```

You should see:
```
✅ Firebase Admin SDK initialized
✅ MongoDB Connected
🚀 Server running on port 3001
```

## 🔒 Security Note

- ✅ This file is in `.gitignore` - won't be committed
- ❌ NEVER share this file or commit it to git
- 🔄 The template is safe to commit (no real credentials)

That's it! Your backend will now verify JWT tokens from your Flutter app.
