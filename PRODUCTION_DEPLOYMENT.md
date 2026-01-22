# Production Deployment Guide

## Base URL Configuration

The app is now configured to use the production backend:

**Production URL:** `https://gaytalks.gumbotech.in/api`

## API Endpoints

All endpoints are now accessible at:

### Authentication
- `POST https://gaytalks.gumbotech.in/api/auth/login`
- `POST https://gaytalks.gumbotech.in/api/auth/refresh`
- `POST https://gaytalks.gumbotech.in/api/auth/logout`
- `GET https://gaytalks.gumbotech.in/api/auth/verify`

### User Management
- `POST https://gaytalks.gumbotech.in/api/user/update`
- `POST https://gaytalks.gumbotech.in/api/user/profile`
- `POST https://gaytalks.gumbotech.in/api/user/wallet`
- `GET https://gaytalks.gumbotech.in/api/user/list`
- `GET https://gaytalks.gumbotech.in/api/user/role/:uid`
- `GET https://gaytalks.gumbotech.in/api/user/:uid`

### Call Management
- `POST https://gaytalks.gumbotech.in/api/call/route`
- `POST https://gaytalks.gumbotech.in/api/call/next`
- `POST https://gaytalks.gumbotech.in/api/call/update`

### Payment
- `POST https://gaytalks.gumbotech.in/api/payment/createOrder`
- `POST https://gaytalks.gumbotech.in/api/payment/verifyPayment`
- `GET https://gaytalks.gumbotech.in/api/payment/key`

### Agora Tokens
- `POST https://gaytalks.gumbotech.in/api/agora/rtm-token`
- `POST https://gaytalks.gumbotech.in/api/agora/rtc-token`

## Flutter App Configuration

### Current Setup (Production Mode)

File: `lib/config/api_config.dart`

```dart
/// Set to true for local development, false for production
static const bool useLocalDevelopment = false;

/// Production base URL (HTTPS)
static const String _productionBaseUrl = 'https://gaytalks.gumbotech.in/api';
```

### Switching to Local Development

If you need to test with local backend:

1. Open `lib/config/api_config.dart`
2. Change `useLocalDevelopment` to `true`:
   ```dart
   static const bool useLocalDevelopment = true;
   ```
3. Update your local IP if needed:
   ```dart
   static const String _localDeviceIp = '192.168.29.41'; // Your IP
   ```
4. Rebuild the app

### Switching Back to Production

1. Open `lib/config/api_config.dart`
2. Change `useLocalDevelopment` to `false`:
   ```dart
   static const bool useLocalDevelopment = false;
   ```
3. Rebuild the app

## Backend Deployment Checklist

Ensure your production backend has:

### ✅ Environment Variables

Create `.env` file on production server:

```bash
# Server Configuration
PORT=3001
NODE_ENV=production

# MongoDB Configuration
MONGODB_URI=mongodb+srv://geytalkdb:h2ue79FCi1vo2NlV@cluster0.uj68wxm.mongodb.net/gaytalk?retryWrites=true&w=majority

# JWT Configuration (IMPORTANT: Use a strong secret!)
JWT_SECRET=<generate-with-command-below>

# Agora Configuration
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_app_certificate

# Razorpay Configuration
RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxx
RAZORPAY_KEY_SECRET=your_razorpay_key_secret

# Firebase Configuration
FIREBASE_PROJECT_ID=gey-talk
```

### Generate JWT Secret

Run this command on your server:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

Copy the output and set it as `JWT_SECRET` in your `.env` file.

### ✅ Firebase Service Account

Ensure `firebase-service-account.json` is present on the server:

```bash
backend/gay_Talks/firebase-service-account.json
```

Download from: Firebase Console → Project Settings → Service Accounts → Generate New Private Key

### ✅ HTTPS/SSL Configuration

Your domain `gaytalks.gumbotech.in` should have:
- Valid SSL certificate (Let's Encrypt recommended)
- HTTPS enabled
- HTTP → HTTPS redirect

### ✅ CORS Configuration

If needed, update CORS settings in `server.js`:

```javascript
const cors = require('cors');

app.use(cors({
  origin: ['https://gaytalks.gumbotech.in', 'http://localhost:3000'],
  credentials: true
}));
```

### ✅ Dependencies Installed

```bash
cd backend/gay_Talks
npm install
```

Ensure `jsonwebtoken` is installed:
```bash
npm list jsonwebtoken
```

### ✅ Start Production Server

Using PM2 (recommended):
```bash
pm2 start server.js --name gaytalk-backend
pm2 save
pm2 startup
```

Or using node:
```bash
NODE_ENV=production node server.js
```

## Testing Production Setup

### 1. Test Health Endpoint

```bash
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

### 2. Test Login Endpoint

```bash
curl -X POST https://gaytalks.gumbotech.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "firebaseToken": "your-firebase-token-here"
  }'
```

Expected response:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": { ... }
  }
}
```

### 3. Test Flutter App

1. Build and run the app:
   ```bash
   flutter run --release
   ```

2. Sign in with Google or Email/Password

3. Check console logs for:
   - `Environment: PRODUCTION`
   - `Base URL: https://gaytalks.gumbotech.in/api`
   - `✅ Backend login successful`

## Monitoring

### Backend Logs

Using PM2:
```bash
pm2 logs gaytalk-backend
```

Look for:
- `✅ MongoDB Connected`
- `✅ Firebase Admin SDK initialized`
- `🚀 Server running on port 3001`
- `✅ User logged in: <uid> (<email>)`

### Common Issues

#### "Failed to connect to backend"
- Check if backend server is running
- Verify SSL certificate is valid
- Check firewall/security group settings

#### "Invalid Firebase token"
- Ensure Firebase service account is correct
- Verify Firebase project ID matches

#### "Token verification failed"
- Check JWT_SECRET is set correctly
- Ensure JWT_SECRET hasn't changed (would invalidate all tokens)

#### "MongoDB connection failed"
- Verify MONGODB_URI is correct
- Check MongoDB Atlas IP whitelist (allow all: 0.0.0.0/0)

## Security Recommendations

1. **Use strong JWT_SECRET** (64+ characters, random)
2. **Enable HTTPS only** (no HTTP in production)
3. **Implement rate limiting** on auth endpoints
4. **Monitor failed login attempts**
5. **Regularly rotate JWT_SECRET** (invalidates all tokens)
6. **Keep dependencies updated** (`npm audit fix`)
7. **Use environment variables** (never commit secrets)
8. **Enable MongoDB authentication**
9. **Restrict MongoDB IP access**
10. **Use Firebase security rules**

## Rollback Plan

If issues occur in production:

1. **Revert to previous version:**
   ```bash
   git checkout <previous-commit>
   pm2 restart gaytalk-backend
   ```

2. **Switch app to local backend temporarily:**
   - Set `useLocalDevelopment = true` in `api_config.dart`
   - Deploy hotfix update

3. **Check logs for errors:**
   ```bash
   pm2 logs gaytalk-backend --lines 100
   ```

## Support

For issues or questions:
- Check logs: `pm2 logs gaytalk-backend`
- Review documentation: `JWT_AUTHENTICATION.md`
- Test endpoints with curl/Postman
- Verify environment variables are set correctly
