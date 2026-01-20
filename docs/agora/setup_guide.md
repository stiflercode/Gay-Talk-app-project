# Agora Setup Guide

## What You Need to Configure in Agora Console

### 1. **Agora Console Setup** (https://console.agora.io)

#### Step 1: Verify Your App ID
- Your current App ID: `8535558d328344fb8aa1ddbcf2a4d8ed`
- Go to Agora Console → Projects → Your Project
- Verify this App ID matches your project

#### Step 2: Get App Certificate (For Production)
- Go to: **Projects → Your Project → Config**
- Find **"App Certificate"**
- Copy it and add to `lib/services/agora_config.dart`:
  ```dart
  static const String appCertificate = "YOUR_APP_CERTIFICATE_HERE";
  ```

#### Step 3: Token Authentication (IMPORTANT)

**For Development/Testing:**
- You can use **NO TOKEN** (current setup) - works for testing only
- Agora allows this for development but **NOT for production**

**For Production:**
- You MUST implement token-based authentication
- Two options:

  **Option A: Temporary Token (Quick Testing)**
  1. Go to Agora Console → Your Project → Temporary Token
  2. Generate a token for your channel
  3. Add to `agora_config.dart`:
     ```dart
     static const String tempToken = "YOUR_TEMP_TOKEN";
     ```
  4. ⚠️ **Note:** Temporary tokens expire after 24 hours

  **Option B: Server-Side Token Generation (Recommended for Production)**
  1. Set up a backend server (Node.js, Python, etc.)
  2. Use Agora's token generation SDK on your server
  3. Create an API endpoint that generates tokens
  4. Update `getToken()` method to fetch from your server

### 2. **Code Changes Made**

✅ **Unique UIDs**: Each user now gets a unique UID based on their Firebase UID
✅ **Dynamic Token Support**: Code now supports token generation
✅ **Better Error Handling**: Added error callbacks for debugging

### 3. **Testing Your Setup**

1. **Test with No Token (Development):**
   - Current code works without token for testing
   - Both users join the same channel name
   - Make sure both users have the same `channelName`

2. **Test with Temporary Token:**
   - Get token from Agora Console
   - Add to `tempToken` in `agora_config.dart`
   - Test calls between two devices

3. **Test with Server Token (Production):**
   - Implement token server
   - Update `getToken()` to call your API
   - Test end-to-end

### 4. **Common Issues & Solutions**

**Issue: "Token expired"**
- Solution: Generate a new temporary token or implement server-side generation

**Issue: "Users can't hear each other"**
- Check: Both users are joining the same channel name
- Check: Both users have unique UIDs (now fixed in code)
- Check: Microphone permissions are granted

**Issue: "Join channel failed"**
- Check: App ID is correct
- Check: Token is valid (if using tokens)
- Check: Network connection

### 5. **Production Checklist**

- [ ] App Certificate added to config
- [ ] Server-side token generation implemented
- [ ] Token endpoint secured (authentication required)
- [ ] Tested with multiple users simultaneously
- [ ] Error handling tested
- [ ] Token expiration handling implemented

### 6. **Channel Naming**

Current implementation uses: `channel_${userId}`
- Both users must join the **same channel name** to talk
- The channel name is based on the **callee's UID** (the person being called)
- Make sure both users use the same channel name when connecting

### 7. **Next Steps**

1. **For Development:** Current setup should work (no token needed)
2. **For Production:** 
   - Implement server-side token generation
   - Use Agora's token generation libraries:
     - Node.js: `agora-access-token`
     - Python: `agora-token-builder`
     - Java: `agora-token-builder`

### 8. **Resources**

- Agora Documentation: https://docs.agora.io/
- Token Generation Guide: https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter
- Flutter SDK: https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter

