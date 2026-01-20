# Production Setup Guide

## Overview

This guide will help you set up the Agora calling system for production use.

## Prerequisites

1. Agora account with App ID and App Certificate
2. Backend server (Node.js, Python, etc.) for token generation
3. Firebase Authentication configured

## Step 1: Get Agora Credentials

1. Go to [Agora Console](https://console.agora.io)
2. Navigate to **Projects** → Your Project
3. Copy your **App ID** (already configured: `8535558d328344fb8aa1ddbcf2a4d8ed`)
4. Copy your **App Certificate** (needed for server-side token generation)

## Step 2: Set Up Backend Token Server

You need to create a backend API endpoint that generates Agora tokens. Here are examples for different platforms:

### Node.js Example

```javascript
// server.js
const express = require('express');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const admin = require('firebase-admin');

const app = express();
app.use(express.json());

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const AGORA_APP_ID = '8535558d328344fb8aa1ddbcf2a4d8ed';
const AGORA_APP_CERTIFICATE = 'YOUR_APP_CERTIFICATE';

// Token generation endpoint
app.post('/api/agora/token', async (req, res) => {
  try {
    // Verify Firebase token
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    const { channelName, uid, expireTime = 3600 } = req.body;

    // Generate Agora token
    const currentTime = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTime + expireTime;

    const token = RtcTokenBuilder.buildTokenWithUid(
      AGORA_APP_ID,
      AGORA_APP_CERTIFICATE,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    res.json({ token });
  } catch (error) {
    console.error('Token generation error:', error);
    res.status(500).json({ error: 'Failed to generate token' });
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

### Python Example (Flask)

```python
# server.py
from flask import Flask, request, jsonify
from agora_token_builder import RtcTokenBuilder, RtcRole
import firebase_admin
from firebase_admin import auth, credentials
import time

app = Flask(__name__)

# Initialize Firebase Admin
cred = credentials.Certificate('path/to/serviceAccountKey.json')
firebase_admin.initialize_app(cred)

AGORA_APP_ID = '8535558d328344fb8aa1ddbcf2a4d8ed'
AGORA_APP_CERTIFICATE = 'YOUR_APP_CERTIFICATE'

@app.route('/api/agora/token', methods=['POST'])
def generate_token():
    try:
        # Verify Firebase token
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Unauthorized'}), 401

        id_token = auth_header.split('Bearer ')[1]
        decoded_token = auth.verify_id_token(id_token)

        data = request.json
        channel_name = data.get('channelName')
        uid = data.get('uid')
        expire_time = data.get('expireTime', 3600)

        # Generate Agora token
        current_time = int(time.time())
        privilege_expired_ts = current_time + expire_time

        token = RtcTokenBuilder.buildTokenWithUid(
            AGORA_APP_ID,
            AGORA_APP_CERTIFICATE,
            channel_name,
            uid,
            RtcRole.PUBLISHER,
            privilege_expired_ts
        )

        return jsonify({'token': token})
    except Exception as e:
        print(f'Token generation error: {e}')
        return jsonify({'error': 'Failed to generate token'}), 500

if __name__ == '__main__':
    app.run(port=3000)
```

## Step 3: Configure Flutter App

### Option A: Environment Variables (Recommended)

Create a `.env` file or use build-time environment variables:

```bash
# For production build
flutter build apk --dart-define=AGORA_PRODUCTION=true --dart-define=AGORA_TOKEN_SERVER_URL=https://your-api.com/api/agora/token

# For iOS
flutter build ios --dart-define=AGORA_PRODUCTION=true --dart-define=AGORA_TOKEN_SERVER_URL=https://your-api.com/api/agora/token
```

### Option B: Direct Configuration

Update `lib/services/agora_token_service.dart`:

```dart
static const String tokenServerUrl = 'https://your-api.com/api/agora/token';
```

Update `lib/services/agora_config.dart`:

```dart
static const bool isProduction = true; // Set to true for production
```

## Step 4: Install Backend Dependencies

### Node.js
```bash
npm install express agora-access-token firebase-admin
```

### Python
```bash
pip install flask agora-token-builder firebase-admin
```

## Step 5: Security Considerations

1. **Never expose App Certificate in client code** - Only use it on your server
2. **Verify Firebase tokens** - Always authenticate users before generating tokens
3. **Use HTTPS** - Always use HTTPS for your token server
4. **Rate limiting** - Implement rate limiting on your token endpoint
5. **Token expiration** - Set appropriate token expiration times (recommended: 1 hour)

## Step 6: Testing

1. **Test token generation:**
   ```bash
   curl -X POST https://your-api.com/api/agora/token \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
     -d '{"channelName":"test","uid":12345}'
   ```

2. **Test in app:**
   - Make a call between two devices
   - Verify both users can hear each other
   - Check that tokens are being generated and used correctly

## Step 7: Monitoring

Monitor your token server for:
- Request rate
- Error rates
- Token generation success rate
- Response times

## Troubleshooting

### Token Expired
- Check token expiration time
- Implement token refresh (already handled in code)

### Connection Failed
- Verify App ID is correct
- Check network connectivity
- Verify token server is accessible

### Users Can't Hear Each Other
- Ensure both users join the same channel name
- Check microphone permissions
- Verify audio routing settings

## Production Checklist

- [ ] App Certificate configured on server
- [ ] Token server deployed and accessible
- [ ] Firebase Authentication configured
- [ ] HTTPS enabled on token server
- [ ] Rate limiting implemented
- [ ] Error logging configured
- [ ] Monitoring set up
- [ ] Tested with multiple concurrent users
- [ ] Token refresh working
- [ ] Error handling tested

## Additional Resources

- [Agora Token Documentation](https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter)
- [Agora Token Builder SDKs](https://docs.agora.io/en/video-calling/develop/integrate-token-generation)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

