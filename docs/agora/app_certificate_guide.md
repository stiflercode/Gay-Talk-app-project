# Agora App Certificate - Complete Guide

## What is an App Certificate?

The **App Certificate** is a security key provided by Agora that is used to generate secure tokens for your video/audio calls. Think of it as a "secret password" that only your server knows.

### Why is it needed?

- **Security**: Prevents unauthorized users from joining your channels
- **Token Generation**: Required to generate production-ready tokens on your server
- **Production Requirement**: Agora requires token-based authentication for production apps (not just temporary tokens)

### Important Security Note ⚠️

- **NEVER** expose the App Certificate in your Flutter app code
- **ONLY** use it on your server (Firebase Functions)
- Keep it secret and secure

## How to Find Your App Certificate

### Step-by-Step Instructions

#### Step 1: Log in to Agora Console

1. Go to [https://console.agora.io](https://console.agora.io)
2. Sign in with your Agora account credentials

#### Step 2: Navigate to Your Project

1. Once logged in, you'll see the **Projects** page
2. Find and click on your project (the one with App ID: `09b3df9a6e874153924cb08d71d73b9b`)
3. Click on the project name to open it

#### Step 3: Go to Project Settings

1. In your project dashboard, look for a menu or navigation
2. Click on **"Config"** or **"Settings"** or **"Project Management"**
3. You might see tabs like: Overview, Config, Usage, etc.
4. Click on **"Config"** tab

#### Step 4: Find the App Certificate

1. In the Config/Settings page, you'll see several fields:
   - **App ID**: `09b3df9a6e874153924cb08d71d73b9b` (you already have this)
   - **App Certificate**: This is what you need!

2. The App Certificate will look like a long string of characters, for example:
   ```
   a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
   ```

3. **If you don't see an App Certificate:**
   - You may need to **enable** it first
   - Look for a button like "Enable App Certificate" or "Generate App Certificate"
   - Click it to generate one
   - ⚠️ **Note**: Once generated, you can only view it once, so copy it immediately!

#### Step 5: Copy the App Certificate

1. Click the **"Show"** or **"Copy"** button next to the App Certificate
2. **Copy the entire string** (it's usually 32-64 characters long)
3. **Save it securely** - you'll need it for Firebase Functions configuration

## Alternative: If You Can't Find It

### Option 1: Check "App Secret" (Old Name)

Some Agora Console versions might call it **"App Secret"** instead of "App Certificate". They're the same thing - use whichever one you find.

### Option 2: Generate a New One

If you can't find it or it's not enabled:

1. In the Config page, look for **"Edit"** or **"Configure"** button
2. Find the **"App Certificate"** section
3. Click **"Enable"** or **"Generate"**
4. Copy it immediately (you might only see it once!)

### Option 3: Contact Agora Support

If you still can't find it:
- Go to [Agora Support](https://agoraio.zendesk.com)
- They can help you locate or regenerate your App Certificate

## Visual Guide (What to Look For)

In the Agora Console, you should see something like:

```
┌─────────────────────────────────────┐
│ Project Configuration               │
├─────────────────────────────────────┤
│ App ID:                              │
│ 09b3df9a6e874153924cb08d71d73b9b    │
│                                      │
│ App Certificate:                    │
│ [Show] [Copy]                       │
│ ••••••••••••••••••••••••••••••••   │
│                                      │
│ [Enable App Certificate]            │
└─────────────────────────────────────┘
```

## After You Get the App Certificate

### Step 1: Configure Firebase Functions

Set it in Firebase Functions config:

```bash
firebase functions:config:set agora.app_certificate="YOUR_APP_CERTIFICATE_HERE"
```

Replace `YOUR_APP_CERTIFICATE_HERE` with the actual certificate string you copied.

### Step 2: Verify Configuration

Check that it's set correctly:

```bash
firebase functions:config:get
```

You should see:
```json
{
  "agora": {
    "app_certificate": "your-certificate-here"
  }
}
```

### Step 3: Deploy Functions

```bash
firebase deploy --only functions
```

## Security Best Practices

✅ **DO:**
- Store App Certificate in Firebase Functions config (secure)
- Use environment variables for local development
- Keep it secret and never commit it to Git
- Rotate it periodically if compromised

❌ **DON'T:**
- Put App Certificate in Flutter app code
- Commit it to version control (Git)
- Share it publicly
- Use it in client-side code

## Troubleshooting

### "App Certificate not found in console"
- Make sure you're looking in the correct project
- Check if you need to enable it first
- Try refreshing the page or logging out and back in

### "App Certificate field is empty"
- You may need to generate/enable it first
- Click "Enable App Certificate" button
- Copy it immediately after generation

### "Invalid App Certificate error"
- Make sure you copied the entire string (no spaces, no line breaks)
- Verify it's the correct certificate for your App ID
- Check for typos when pasting into Firebase config

## Quick Reference

- **What it is**: Security key for generating Agora tokens
- **Where to find**: Agora Console → Your Project → Config/Settings
- **Format**: Long string of alphanumeric characters (32-64 chars)
- **Where to use**: Firebase Functions (server-side only)
- **Where NOT to use**: Flutter app code (client-side)

## Need Help?

If you're still having trouble finding your App Certificate:

1. Check Agora's official documentation: [Agora Console Guide](https://docs.agora.io/en/Video/get-started/get-app-id-and-certificate)
2. Contact Agora Support: [support.agora.io](https://agoraio.zendesk.com)
3. Check your project's email for setup instructions

---

**Remember**: The App Certificate is like a password - keep it secret and secure! 🔒

