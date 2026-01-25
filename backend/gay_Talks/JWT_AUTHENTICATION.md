# JWT Authentication System

## Overview

The GayTalk app now uses a **backend-controlled JWT authentication system** instead of relying solely on Firebase tokens. This provides better security, control, and flexibility for API access.

## Architecture

### Authentication Flow

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Flutter   │      │   Firebase   │      │   Backend   │
│     App     │─────▶│     Auth     │      │   (Node.js) │
└─────────────┘      └──────────────┘      └─────────────┘
       │                     │                      │
       │  1. Google Sign-In  │                      │
       │────────────────────▶│                      │
       │                     │                      │
       │  2. Firebase Token  │                      │
       │◀────────────────────│                      │
       │                     │                      │
       │  3. POST /api/auth/login                   │
       │     { firebaseToken }                      │
       │───────────────────────────────────────────▶│
       │                     │                      │
       │                     │  4. Verify Firebase  │
       │                     │     Token            │
       │                     │◀─────────────────────│
       │                     │                      │
       │  5. JWT Tokens      │                      │
       │     { accessToken,  │                      │
       │       refreshToken, │                      │
       │       user }        │                      │
       │◀───────────────────────────────────────────│
       │                     │                      │
       │  6. Store JWT Tokens                       │
       │     in SharedPreferences                   │
       │                     │                      │
       │  7. Use JWT for all API calls              │
       │     Authorization: Bearer <JWT>            │
       │───────────────────────────────────────────▶│
```

### Key Components

#### Backend (Node.js)

1. **JWT Utils** (`utils/jwtUtils.js`)
   - `generateAccessToken()` - Creates JWT access tokens (7 days expiry)
   - `generateRefreshToken()` - Creates refresh tokens (30 days expiry)
   - `verifyToken()` - Verifies and decodes JWT tokens
   - `extractToken()` - Extracts token from Authorization header

2. **Auth Controller** (`controllers/authController.js`)
   - `POST /api/auth/login` - Verifies Firebase token, creates/updates user, returns JWT tokens
   - `POST /api/auth/refresh` - Refreshes access token using refresh token
   - `POST /api/auth/logout` - Revokes refresh token
   - `GET /api/auth/verify` - Verifies if JWT token is valid

3. **Auth Middleware** (`middleware/auth.js`)
   - `authenticateUser()` - Verifies JWT tokens for protected routes
   - `optionalAuth()` - Optional authentication for public/private endpoints

4. **User Model** (`models/User.js`)
   - Added `refreshToken` field for token storage
   - Added `emailVerified` and `photoURL` fields

#### Frontend (Flutter)

1. **AuthService** (`lib/services/auth_service.dart`)
   - `signInWithGoogle()` - Signs in with Google and gets JWT tokens
   - `signInWithEmailAndPassword()` - Signs in with email/password and gets JWT tokens
   - `loginWithBackend()` - Exchanges Firebase token for JWT tokens
   - `refreshAccessToken()` - Refreshes expired access tokens
   - `logout()` - Logs out and clears tokens
   - `getAccessToken()` - Retrieves stored JWT access token
   - `getRefreshToken()` - Retrieves stored JWT refresh token

2. **Updated Services**
   - `UserService` - All API calls now use JWT authentication
   - `PaymentService` - Payment operations use JWT tokens
   - `AgoraTokenService` - Agora token generation uses JWT auth
   - All services automatically refresh tokens on 401 errors

## API Endpoints

### Authentication Endpoints

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "firebaseToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
  "fcmToken": "optional-fcm-token"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "uid": "firebase-user-id",
      "email": "user@example.com",
      "displayName": "John Doe",
      "role": "user",
      "walletBalance": 0,
      "profileComplete": false,
      "language": null
    }
  }
}
```

#### Refresh Token
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### Logout
```http
POST /api/auth/logout
Authorization: Bearer <access-token>
```

**Response:**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

#### Verify Token
```http
GET /api/auth/verify
Authorization: Bearer <access-token>
```

**Response:**
```json
{
  "success": true,
  "message": "Token is valid",
  "data": {
    "user": {
      "uid": "firebase-user-id",
      "email": "user@example.com",
      "role": "user"
    }
  }
}
```

### Protected Endpoints

All other API endpoints now require JWT authentication:

```http
GET /api/user/:uid
Authorization: Bearer <access-token>

POST /api/user/update
Authorization: Bearer <access-token>

POST /api/call/route
Authorization: Bearer <access-token>

POST /api/payment/createOrder
Authorization: Bearer <access-token>

POST /api/agora/rtc-token
Authorization: Bearer <access-token>
```

## Token Management

### Access Token
- **Expiry:** 7 days
- **Purpose:** Used for all API requests
- **Storage:** SharedPreferences (Flutter)
- **Header:** `Authorization: Bearer <access-token>`

### Refresh Token
- **Expiry:** 30 days
- **Purpose:** Used to get new access tokens
- **Storage:** SharedPreferences (Flutter) + MongoDB (backend)
- **Revocation:** Cleared on logout

### Automatic Token Refresh

All services automatically handle token refresh:

```dart
// If API call returns 401 (Unauthorized)
// 1. Attempt to refresh access token
// 2. Retry the original request with new token
// 3. If refresh fails, user needs to login again
```

## Security Features

1. **Token Expiration:** Access tokens expire after 7 days
2. **Refresh Token Rotation:** Refresh tokens stored in DB for revocation
3. **Token Verification:** All tokens verified with JWT signature
4. **Secure Storage:** Tokens stored in SharedPreferences (encrypted on device)
5. **HTTPS Required:** All API calls should use HTTPS in production

## Environment Variables

Add to `.env` file:

```bash
# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production-use-long-random-string
```

**Generate a secure secret:**
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## Migration Guide

### For Existing Users

1. **First Login After Update:**
   - User signs in with Firebase (Google/Email)
   - Backend creates JWT tokens
   - Tokens stored locally
   - All subsequent API calls use JWT

2. **Token Refresh:**
   - Happens automatically when access token expires
   - User doesn't need to re-login unless refresh token expires

3. **Logout:**
   - Clears JWT tokens from local storage
   - Revokes refresh token on backend
   - Signs out from Firebase

## Testing

### Test Login Flow

1. Start backend server:
```bash
cd backend/gay_Talks
npm start
```

2. Run Flutter app:
```bash
flutter run
```

3. Sign in with Google or Email/Password

4. Check console logs for:
   - `✅ Backend login successful`
   - `✅ JWT tokens saved to local storage`
   - `✅ Authenticated user: <uid> (<email>)`

### Test Token Refresh

1. Wait for access token to expire (or manually set short expiry in `jwtUtils.js`)
2. Make an API call
3. Check console logs for:
   - `⚠️ Token expired, attempting refresh...`
   - `✅ Access token refreshed successfully`

### Test Logout

1. Logout from app
2. Check console logs for:
   - `✅ Backend logout successful`
   - `✅ JWT tokens cleared from local storage`

## Error Handling

### Common Error Codes

- `NO_TOKEN` - No authentication token provided
- `INVALID_TOKEN` - Token is malformed or invalid
- `TOKEN_EXPIRED` - Access token has expired (refresh needed)
- `INVALID_TOKEN_TYPE` - Wrong token type (e.g., refresh token used as access token)
- `USER_NOT_FOUND` - User doesn't exist in database
- `TOKEN_REVOKED` - Refresh token has been revoked
- `INVALID_FIREBASE_TOKEN` - Firebase token verification failed

### Error Response Format

```json
{
  "success": false,
  "error": "TOKEN_EXPIRED",
  "message": "Token expired. Please refresh your token.",
  "code": "TOKEN_EXPIRED"
}
```

## Best Practices

1. **Never log tokens** in production
2. **Use HTTPS** for all API calls
3. **Rotate JWT_SECRET** periodically
4. **Implement rate limiting** on auth endpoints
5. **Monitor failed login attempts**
6. **Clear tokens on logout**
7. **Handle token refresh gracefully**

## Troubleshooting

### "No authentication token provided"
- Check if user is logged in
- Verify token is stored in SharedPreferences
- Check Authorization header format

### "Token expired"
- Token refresh should happen automatically
- If refresh fails, user needs to login again
- Check refresh token expiry (30 days)

### "Invalid token"
- Token might be corrupted
- JWT_SECRET might have changed
- Clear app data and login again

### "User not found"
- User might have been deleted from database
- Login again to recreate user

## Future Enhancements

1. **Token Blacklisting:** Implement Redis for token blacklist
2. **Multi-Device Support:** Track active sessions per user
3. **2FA Support:** Add two-factor authentication
4. **Social Login:** Add more OAuth providers
5. **Session Management:** Allow users to view/revoke active sessions
