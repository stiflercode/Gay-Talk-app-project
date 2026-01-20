# GayTalk - Complete Project Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Architecture Overview](#architecture-overview)
4. [Project Structure](#project-structure)
5. [Core Features](#core-features)
6. [Dependencies](#dependencies)
7. [Configuration & Setup](#configuration--setup)
8. [User Flows](#user-flows)
9. [API Integration](#api-integration)
10. [Database Structure](#database-structure)
11. [Security & Authentication](#security--authentication)
12. [Deployment](#deployment)

---

## Project Overview

**GayTalk** (also known as "Casual Talks") is a Flutter-based mobile application that enables real-time audio communication between users and admins. The app implements a coin-based payment system where regular users can purchase coins and use them to make audio calls to admin users (speakers/consultants).

### Main Purpose
- Connect users with admin speakers for paid audio consultations
- Provide a secure, real-time communication platform
- Manage payments and wallet transactions seamlessly
- Support multiple languages for diverse user base

### Key Characteristics
- **Platform**: Cross-platform mobile app (iOS & Android)
- **Version**: 2.0.0+2
- **Package Name**: `com.gumbotech.gaytalks`
- **Firebase Project**: `gaytalks-b929a`

---

## Technology Stack

### Frontend
- **Flutter**: ^3.9.2 (Dart SDK)
- **UI Framework**: Material Design
- **State Management**: StatefulWidget with setState (local state management)

### Backend Services
- **Firebase Core**: ^3.6.0 - Firebase initialization
- **Firebase Auth**: ^5.3.1 - User authentication
- **Cloud Firestore**: ^5.4.3 - NoSQL database
- **Firebase Storage**: ^12.3.2 - File storage
- **Firebase Messaging**: ^15.1.3 - Push notifications
- **Firebase Functions**: Node.js 20 - Serverless backend

### Real-Time Communication
- **Agora RTC Engine**: ^6.2.2 - Audio/video calling
- **Agora App ID**: `09b3df9a6e874153924cb08d71d73b9b`

### Payment Integration
- **Razorpay Flutter**: ^1.3.1 - Payment gateway
- **Test Key ID**: `rzp_test_RxJw6Un202MDDY`

### Additional Libraries
- **google_sign_in**: ^6.2.1 - Google OAuth
- **shared_preferences**: ^2.0.15 - Local storage
- **image_picker**: ^1.1.2 - Image selection
- **permission_handler**: ^11.3.0 - Runtime permissions
- **flutter_local_notifications**: ^17.2.2 - Local notifications
- **audioplayers**: ^6.1.0 - Audio playback
- **http**: ^1.2.0 - HTTP requests
- **intl**: ^0.19.0 - Internationalization
- **url_launcher**: ^6.1.10 - URL handling

---

## Architecture Overview

### Application Architecture

The app follows a **service-oriented architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (Screens & Widgets - UI Components)                    │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                     Service Layer                        │
│  (Business Logic & External Service Integration)        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  (Firebase, Local Storage, External APIs)               │
└─────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

1. **Stateful Widgets**: Uses Flutter's built-in state management for simplicity
2. **Service Classes**: Encapsulate business logic and API calls
3. **Firebase Backend**: Serverless architecture for scalability
4. **Token-Based Auth**: Secure authentication using Firebase ID tokens
5. **Real-Time Sync**: Firestore streams for live data updates

---

## Project Structure

### Directory Layout

```
gaytalk/
├── lib/                          # Main application code
│   ├── main.dart                 # App entry point
│   ├── firebase_options.dart     # Firebase configuration
│   ├── screens/                  # UI screens
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── language_selection_screen.dart
│   │   ├── personal_details_screen.dart
│   │   ├── home_page.dart
│   │   ├── wallet_page.dart
│   │   ├── call_screen.dart
│   │   ├── connecting_screen.dart
│   │   ├── incoming_call_screen.dart
│   │   ├── upi_verify_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── privacy_policy_screen.dart
│   │   └── terms_of_service_screen.dart
│   ├── services/                 # Business logic services
│   │   ├── auth_service.dart
│   │   ├── user_service.dart
│   │   ├── payment_service.dart
│   │   ├── agora_config.dart
│   │   ├── agora_token_service.dart
│   │   ├── call_request_service.dart
│   │   └── notification_service.dart
│   ├── widgets/                  # Reusable widgets
│   │   └── language_card.dart
│   └── utilities/                # Helper functions
│       └── validators.dart
├── functions/                    # Firebase Cloud Functions
│   ├── index.js                  # Function definitions
│   └── package.json              # Node.js dependencies
├── android/                      # Android-specific code
├── ios/                          # iOS-specific code
├── assets/                       # Static assets
│   ├── images/                   # Image files
│   └── sounds/                   # Audio files
└── pubspec.yaml                  # Flutter dependencies

```

### File Organization Principles

1. **Screens**: Each screen is a separate file in `lib/screens/`
2. **Services**: Business logic separated into service classes
3. **Widgets**: Reusable UI components in `lib/widgets/`
4. **Utilities**: Helper functions and validators
5. **Assets**: Images and sounds organized by type

---

## Core Features

### 1. User Authentication

**What it does**: Allows users to sign in using Google OAuth or email/password authentication.

**How it works**:
- Uses Firebase Authentication for secure user management
- Supports Google Sign-In for quick onboarding
- Hidden email/password login (tap logo 5 times to reveal)
- Stores user data in Firestore after authentication

**Key Files**:
- `lib/screens/login_screen.dart` - Login UI
- `lib/services/auth_service.dart` - Authentication logic

**Key Functions**:
```dart
// Sign in with Google
Future<User?> signInWithGoogle()

// Sign in with email/password
Future<User?> signInWithEmailAndPassword(String email, String password)

// Sign up with email/password
Future<User?> signUpWithEmailAndPassword(String email, String password)
```

**Beginner Explanation**:
- **Firebase Auth** is like a security guard that checks if users are who they say they are
- **Google Sign-In** lets users log in with their Google account (like "Sign in with Google" buttons you see on websites)
- **ID Token** is like a temporary pass that proves you're logged in

### 2. User Onboarding Flow

**What it does**: Guides new users through initial setup including language selection and profile creation.

**How it works**:
1. User signs in → Check if profile exists
2. If new user → Language selection screen
3. Then → Personal details screen (name, age, gender, phone, username)
4. Finally → Home page

**Key Files**:
- `lib/screens/language_selection_screen.dart`
- `lib/screens/personal_details_screen.dart`

**Supported Languages**:
- English
- Hindi (हिंदी)
- Tamil (தமிழ்)
- Kannada (ಕನ್ನಡ)
- Marathi (मराठी)

### 3. Real-Time Audio Calling (Agora Integration)

**What it does**: Enables high-quality audio calls between users and admins using Agora's RTC engine.

**How it works**:
1. User initiates call → Creates call request in Firestore
2. Admin receives notification → Can accept/reject
3. If accepted → Both join Agora channel with unique channel name
4. Agora handles audio streaming in real-time
5. Call ends → Duration calculated, coins deducted

**Key Files**:
- `lib/screens/call_screen.dart` - Active call UI
- `lib/screens/connecting_screen.dart` - Call connection screen
- `lib/services/agora_config.dart` - Agora configuration
- `lib/services/agora_token_service.dart` - Token generation

**Key Concepts**:

**Agora RTC Engine**: A real-time communication engine that handles audio/video streaming
- Think of it like Zoom or WhatsApp's calling technology
- Requires an **App ID** (identifies your app) and **Token** (security key for each call)

**Channel**: A virtual room where users meet for calls
- Each call has a unique channel name (like a room number)
- Users join the same channel to talk to each other

**UID (User ID)**: A unique number identifying each participant in a call
- Generated randomly for each call session

**Token Generation**:
```dart
// Production: Fetch from Firebase Functions
static Future<String> getToken(String channelName, int uid) async {
  return await AgoraTokenService.fetchTokenFromServer(
    channelName: channelName,
    uid: uid,
  );
}
```

**Beginner Explanation**:
- **Agora** is like a phone company that connects calls
- **Channel** is like a conference room - everyone in the same room can talk
- **Token** is like a key card to enter the room - it expires after some time for security

### 4. Wallet & Payment System (Razorpay Integration)

**What it does**: Manages user wallet balance and processes payments for coin purchases.

**How it works**:
1. User selects a recharge pack (e.g., 100 coins for ₹100)
2. App creates order via Firebase Functions
3. Razorpay checkout opens for payment
4. User completes payment
5. Backend verifies payment signature
6. Wallet balance updated in Firestore
7. Transaction recorded for history

**Key Files**:
- `lib/screens/wallet_page.dart` - Wallet UI
- `lib/screens/upi_verify_screen.dart` - Payment processing
- `lib/services/payment_service.dart` - Payment logic
- `functions/index.js` - Backend payment functions

**Recharge Packs**:
```dart
[
  {'coins': 50, 'price': 50},
  {'coins': 100, 'price': 100},
  {'coins': 200, 'price': 200},
  {'coins': 500, 'price': 500},
  {'coins': 1000, 'price': 1000},
  {'coins': 2000, 'price': 2000},
]
```

**Payment Flow**:
```
User → Select Pack → Create Order (Firebase Function)
     → Razorpay Checkout → Payment → Verify Signature
     → Update Wallet → Show Success
```

**Key Functions**:
```dart
// Create Razorpay order
Future<Map<String, dynamic>> createOrder({
  required int amount,
  required int coins,
  String currency = 'INR',
})

// Verify payment and update wallet
Future<Map<String, dynamic>> verifyPayment({
  required String orderId,
  required String paymentId,
  required String signature,
  required int coins,
})
```

**Beginner Explanation**:
- **Razorpay** is like a digital cash register that accepts payments
- **Order ID** is like a receipt number for tracking
- **Signature** is like a seal that proves the payment is genuine
- **Coins** are virtual currency users buy to make calls

### 5. User Roles & Call Request System

**What it does**: Implements a two-tier user system with regular users and admins.

**User Types**:
1. **Regular Users** (`role: 'user'`)
   - Can only see and call admins
   - Get charged coins per minute for calls
   - Cannot receive calls

2. **Admins** (`role: 'admin'`)
   - Can receive calls from users
   - See all users in admin dashboard
   - Don't get charged for calls
   - View call logs and history

**How it works**:
1. User initiates call → Creates `callRequest` document
2. Firestore trigger → Sends FCM notification to admin
3. Admin receives incoming call screen
4. Admin accepts → Both join Agora channel
5. Call ends → Status updated to 'completed', user charged

**Call Request Lifecycle**:
```
pending → accepted → (call in progress) → completed
        ↘ rejected
        ↘ cancelled (by user)
```

**Key Files**:
- `lib/services/call_request_service.dart` - Call request management
- `lib/screens/incoming_call_screen.dart` - Admin incoming call UI
- `lib/services/user_service.dart` - User role management

**Key Functions**:
```dart
// Create call request
Future<String> createCallRequest({
  required String callerId,
  required String callerName,
  required String adminId,
  required String adminName,
  required String channelName,
  required int coinsPerMin,
})

// Accept/Reject call
Future<void> acceptCallRequest(String requestId)
Future<void> rejectCallRequest(String requestId)

// Complete call and charge user
Future<void> completeCallRequest(
  String requestId,
  int durationSeconds,
  int coinsCharged
)
```

**Beginner Explanation**:
- **Call Request** is like ringing someone's doorbell - they can choose to answer or not
- **Admin** is like a consultant or expert who gets paid for their time
- **Status** tracks where the call is in its lifecycle (like tracking a package delivery)

### 6. Push Notifications (Firebase Cloud Messaging)

**What it does**: Sends real-time notifications for incoming calls and important events.

**How it works**:
1. App registers for notifications on startup
2. FCM token stored in user's Firestore document
3. When call request created → Firebase Function triggers
4. Function sends notification to admin's FCM token
5. Admin receives notification with ringtone
6. Notification shows incoming call screen

**Key Files**:
- `lib/services/notification_service.dart` - Notification handling
- `functions/index.js` - FCM notification trigger

**Notification Types**:
- **Incoming Call**: High-priority notification with custom ringtone
- **Foreground**: Shows local notification when app is open
- **Background**: Handled by Firebase automatically

**Key Functions**:
```dart
// Initialize notification service
Future<void> initialize()

// Show incoming call notification
Future<void> showIncomingCallNotification({
  required String callerName,
  required String callRequestId,
})

// Get FCM token
Future<String?> getFCMToken()
```

**Beginner Explanation**:
- **FCM (Firebase Cloud Messaging)** is like a postal service for app notifications
- **FCM Token** is like your home address - it tells where to send notifications
- **Ringtone** plays when notification arrives to alert the user

### 7. Local Data Storage

**What it does**: Stores user preferences and session data locally on the device.

**How it works**:
- Uses `SharedPreferences` for key-value storage
- Stores user profile, language preference, wallet balance
- Persists across app restarts
- Syncs with Firestore for backup

**Stored Data**:
```dart
- 'user_email': User's email
- 'user_name': User's display name
- 'name': User's full name
- 'age': User's age
- 'gender': User's gender
- 'phone': Phone number
- 'username': Username
- 'lang': Selected language code
- 'wallet_balance': Current coin balance
```

**Beginner Explanation**:
- **SharedPreferences** is like a notepad that saves information on your phone
- Data stays even if you close the app
- Faster than fetching from server every time

---

## Dependencies

### Production Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| firebase_core | ^3.6.0 | Firebase initialization |
| firebase_auth | ^5.3.1 | User authentication |
| cloud_firestore | ^5.4.3 | NoSQL database |
| firebase_storage | ^12.3.2 | File storage |
| firebase_messaging | ^15.1.3 | Push notifications |
| google_sign_in | ^6.2.1 | Google OAuth |
| agora_rtc_engine | ^6.2.2 | Audio/video calls |
| razorpay_flutter | ^1.3.1 | Payment processing |
| shared_preferences | ^2.0.15 | Local storage |
| image_picker | ^1.1.2 | Image selection |
| permission_handler | ^11.3.0 | Runtime permissions |
| flutter_local_notifications | ^17.2.2 | Local notifications |
| audioplayers | ^6.1.0 | Audio playback |
| http | ^1.2.0 | HTTP requests |
| intl | ^0.19.0 | Date/number formatting |
| url_launcher | ^6.1.10 | Open URLs |
| flutter_spinkit | ^5.2.1 | Loading animations |
| cupertino_icons | ^1.0.8 | iOS-style icons |

### Development Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_test | SDK | Testing framework |
| flutter_lints | ^5.0.0 | Code quality |
| flutter_launcher_icons | ^0.13.1 | App icon generation |

### Firebase Functions Dependencies (Node.js)

```json
{
  "firebase-admin": "^12.0.0",
  "firebase-functions": "^4.5.0",
  "razorpay": "^2.9.2",
  "cors": "^2.8.5",
  "agora-access-token": "^2.0.4"
}
```

---

## Configuration & Setup

### Environment Variables

The app uses environment variables for configuration:

```dart
// Agora Configuration
AGORA_PRODUCTION=true              // Use production mode (default: true)
AGORA_TEMP_TOKEN=""                // Temporary token for development
AGORA_DEV_CHANNEL="test"           // Dev channel name

// Firebase Functions
FIREBASE_FUNCTIONS_URL="https://us-central1-gaytalks-b929a.cloudfunctions.net"

// Agora Token Server
AGORA_TOKEN_SERVER_URL=""          // Custom token server (optional)
```

### Firebase Configuration

**Project Details**:
- Project ID: `gaytalks-b929a`
- Region: `us-central1`
- Storage Bucket: `gaytalks-b929a.firebasestorage.app`

**Platform-Specific Configuration**:

**Android**:
- Package: `com.gumbotech.gaytalks`
- App ID: `1:567596572384:android:058fa5ab4a199ff49d7a85`
- Min SDK: 21

**iOS**:
- Bundle ID: `com.gumbotech.gaytalks`
- App ID: `1:567596572384:ios:4aa9323b4b12b9829d7a85`

### Agora Configuration

```dart
// App ID (from Agora Console)
static const String appId = "09b3df9a6e874153924cb08d71d73b9b";

// Production mode (uses server-side tokens)
static const bool isProduction = true;
```

**Agora App Certificate**: Stored in Firebase Functions environment
- Used for server-side token generation
- Never exposed in client code

### Razorpay Configuration

**Test Credentials** (for development):
```
Key ID: rzp_test_RxJw6Un202MDDY
Key Secret: 1cQ28U1Xws2JwvbQIG1PFTSE
```

**Live Credentials** (for production):
Set via Firebase Functions config:
```bash
firebase functions:config:set razorpay.key_id="rzp_live_XXX"
firebase functions:config:set razorpay.key_secret="YOUR_SECRET"
```

### Required Permissions

**Android** (`AndroidManifest.xml`):
```xml
<!-- Audio/Video -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

**iOS** (`Info.plist`):
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for audio calls</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access for video calls</string>
```

### Setup Steps

1. **Install Flutter Dependencies**:
```bash
flutter pub get
```

2. **Install Firebase Functions Dependencies**:
```bash
cd functions
npm install
cd ..
```

3. **Configure Firebase**:
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

4. **Deploy Firebase Functions**:
```bash
firebase deploy --only functions
```

5. **Run the App**:
```bash
flutter run
```

---

## User Flows

### New User Registration Flow

```
1. App Launch
   ↓
2. Splash Screen (700ms)
   ↓
3. Login Screen
   ↓
4. User taps "Sign up with Google"
   ↓
5. Google Sign-In Dialog
   ↓
6. Authentication Success
   ↓
7. Check if user registered (Firestore query)
   ↓
8. If NEW → Language Selection Screen
   ↓
9. Select Language (e.g., English)
   ↓
10. Personal Details Screen
    ↓
11. Enter: Name, Age, Gender, Phone, Username
    ↓
12. Save to Firestore & SharedPreferences
    ↓
13. Navigate to Home Page
```

### Existing User Login Flow

```
1. App Launch
   ↓
2. Splash Screen
   ↓
3. Check SharedPreferences for 'name'
   ↓
4. If EXISTS → Direct to Home Page
   ↓
5. If NOT → Login Screen
```

### Making a Call Flow (User Perspective)

```
1. Home Page (shows list of admins)
   ↓
2. User taps "Talk" button on an admin
   ↓
3. Check wallet balance (sufficient coins?)
   ↓
4. Create call request in Firestore
   ↓
5. Show "Calling... Waiting for admin to answer"
   ↓
6. Listen for call request status change
   ↓
7. Admin accepts → Navigate to Connecting Screen
   ↓
8. Initialize Agora engine
   ↓
9. Request microphone permission
   ↓
10. Generate Agora token from server
    ↓
11. Join Agora channel
    ↓
12. Call Screen (active call)
    ↓
13. Call ends → Calculate duration & coins
    ↓
14. Deduct coins from wallet
    ↓
15. Update call request status to 'completed'
    ↓
16. Return to Home Page
```

### Receiving a Call Flow (Admin Perspective)

```
1. Home Page (admin view - shows call logs)
   ↓
2. User creates call request
   ↓
3. Firebase Function triggers
   ↓
4. FCM notification sent to admin
   ↓
5. Incoming Call Screen appears
   ↓
6. Shows: Caller name, coins per minute
   ↓
7. Admin has 30 seconds to respond
   ↓
8. Admin taps "Accept" button
   ↓
9. Update call request status to 'accepted'
   ↓
10. Navigate to Connecting Screen
    ↓
11. Join Agora channel
    ↓
12. Call Screen (active call)
    ↓
13. Call ends → No charge for admin
    ↓
14. Update call request to 'completed'
    ↓
15. Return to Home Page
```

### Wallet Recharge Flow

```
1. User taps wallet icon in Home Page
   ↓
2. Wallet Page shows current balance
   ↓
3. User selects a recharge pack (e.g., 100 coins for ₹100)
   ↓
4. Taps "Pay ₹100" button
   ↓
5. App calls Firebase Function: createOrder
   ↓
6. Function creates Razorpay order
   ↓
7. Returns: orderId, amount, keyId
   ↓
8. Razorpay Checkout opens
   ↓
9. User completes payment (UPI/Card/Wallet)
   ↓
10. Razorpay returns: paymentId, signature
    ↓
11. App calls Firebase Function: verifyPayment
    ↓
12. Function verifies signature with Razorpay
    ↓
13. Updates wallet balance in Firestore
    ↓
14. Records transaction in 'transactions' collection
    ↓
15. Returns new balance to app
    ↓
16. Update local SharedPreferences
    ↓
17. Show success message
    ↓
18. Wallet Page refreshes with new balance
```

---

## API Integration

### Firebase Cloud Functions

The app uses Firebase Cloud Functions for server-side operations. All functions are deployed at:
`https://us-central1-gaytalks-b929a.cloudfunctions.net`

#### 1. Create Order (`/createOrder`)

**Purpose**: Creates a Razorpay order for payment processing

**Method**: POST

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <Firebase_ID_Token>
```

**Request Body**:
```json
{
  "amount": 100,
  "currency": "INR",
  "userId": "user_uid_here",
  "coins": 100
}
```

**Response** (Success - 200):
```json
{
  "orderId": "order_xxxxxxxxxxxxx",
  "amount": 10000,
  "currency": "INR",
  "keyId": "rzp_test_xxxxx"
}
```

**Response** (Error - 400/401/500):
```json
{
  "error": "Error message here"
}
```

**How it works**:
1. Verifies Firebase ID token
2. Creates order in Razorpay
3. Stores order in Firestore `orders` collection
4. Returns order details for Razorpay Checkout

#### 2. Verify Payment (`/verifyPayment`)

**Purpose**: Verifies payment signature and updates wallet balance

**Method**: POST

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <Firebase_ID_Token>
```

**Request Body**:
```json
{
  "orderId": "order_xxxxxxxxxxxxx",
  "paymentId": "pay_xxxxxxxxxxxxx",
  "signature": "signature_hash_here",
  "userId": "user_uid_here",
  "coins": 100
}
```

**Response** (Success - 200):
```json
{
  "success": true,
  "message": "Payment verified and wallet updated",
  "newBalance": 150,
  "coins": 100
}
```

**How it works**:
1. Verifies Firebase ID token
2. Validates payment signature using HMAC SHA256
3. Fetches payment details from Razorpay
4. Updates user's wallet balance in Firestore
5. Records transaction in `transactions` collection
6. Updates order status to 'completed'

**Signature Verification**:
```javascript
const crypto = require('crypto');
const text = `${orderId}|${paymentId}`;
const generatedSignature = crypto
  .createHmac('sha256', RAZORPAY_KEY_SECRET)
  .update(text)
  .digest('hex');

if (generatedSignature !== signature) {
  return error('Invalid payment signature');
}
```

#### 3. Get Payment History (`/getPaymentHistory`)

**Purpose**: Retrieves user's payment transaction history

**Method**: GET

**Headers**:
```
Authorization: Bearer <Firebase_ID_Token>
```

**Query Parameters**:
```
userId=user_uid_here
```

**Response** (Success - 200):
```json
{
  "transactions": [
    {
      "id": "transaction_id",
      "userId": "user_uid",
      "amount": 100,
      "coins": 100,
      "type": "credit",
      "status": "completed",
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

#### 4. Generate Agora Token (`/generateAgoraToken`)

**Purpose**: Generates secure Agora RTC token for audio calls

**Method**: POST

**Headers**:
```
Content-Type: application/json
Authorization: Bearer <Firebase_ID_Token>
```

**Request Body**:
```json
{
  "channelName": "channel_12345",
  "uid": 123456,
  "expireTime": 3600
}
```

**Response** (Success - 200):
```json
{
  "token": "006xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "channelName": "channel_12345",
  "uid": 123456,
  "expireTime": 3600
}
```

**How it works**:
1. Verifies Firebase ID token
2. Validates channel name and UID
3. Generates Agora token using Agora SDK
4. Token expires after specified time (default: 1 hour)

**Token Generation Code**:
```javascript
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

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
```

#### 5. Send Call Request Notification (`sendCallRequestNotification`)

**Purpose**: Automatically sends FCM notification when call request is created

**Trigger**: Firestore onCreate trigger on `callRequests/{requestId}`

**How it works**:
1. Triggered when new document added to `callRequests` collection
2. Fetches admin's FCM token from Firestore
3. Sends high-priority notification to admin
4. Includes call details in notification data

**Notification Payload**:
```javascript
{
  notification: {
    title: 'Incoming Call',
    body: 'Call from John Doe'
  },
  data: {
    type: 'incoming_call',
    callRequestId: 'request_id',
    callerId: 'caller_uid',
    callerName: 'John Doe',
    channelName: 'channel_12345'
  },
  android: {
    priority: 'high',
    notification: {
      channelId: 'incoming_calls',
      sound: 'ringtone',
      priority: 'max'
    }
  }
}
```

### External APIs

#### Razorpay API

**Base URL**: `https://api.razorpay.com/v1/`

**Authentication**: Basic Auth (Key ID + Key Secret)

**Used Endpoints**:
- `POST /orders` - Create order
- `GET /payments/{paymentId}` - Fetch payment details

**Note**: All Razorpay API calls are made from Firebase Functions, not directly from the app.

#### Agora API

**SDK Integration**: Uses `agora_rtc_engine` Flutter package

**Key Methods**:
```dart
// Initialize engine
await engine.initialize(RtcEngineContext(appId: appId));

// Join channel
await engine.joinChannel(
  token: token,
  channelId: channelName,
  uid: uid,
  options: ChannelMediaOptions(
    clientRoleType: ClientRoleType.clientRoleBroadcaster,
    publishMicrophoneTrack: true,
  ),
);

// Leave channel
await engine.leaveChannel();

// Release engine
await engine.release();
```

---

## Database Structure

### Firestore Collections

#### 1. `users` Collection

Stores user profile information and settings.

**Document ID**: User's Firebase UID

**Schema**:
```javascript
{
  uid: string,                    // Firebase user ID
  email: string,                  // User's email
  displayName: string,            // Display name from auth
  photoURL: string,               // Profile photo URL
  name: string,                   // Full name
  age: number,                    // User's age
  gender: string,                 // 'male', 'female', 'other'
  phone: string,                  // Phone number
  username: string,               // Unique username
  role: string,                   // 'user' or 'admin' (default: 'user')
  walletBalance: number,          // Current coin balance
  fcmToken: string,               // Firebase Cloud Messaging token
  lastSeen: timestamp,            // Last activity timestamp
  createdAt: timestamp,           // Account creation time
  languages: array<string>,       // Preferred languages
  coinsPerMin: number,            // For admins: rate per minute
  maxCharge: number,              // For admins: maximum charge
}
```

**Indexes Required**:
- `role` (Ascending)
- `uid` (Ascending)

**Example Document**:
```json
{
  "uid": "abc123xyz",
  "email": "user@example.com",
  "displayName": "John Doe",
  "name": "John Doe",
  "age": 25,
  "gender": "male",
  "phone": "+919876543210",
  "username": "johndoe",
  "role": "user",
  "walletBalance": 150,
  "fcmToken": "fcm_token_here",
  "lastSeen": "2024-01-15T10:30:00Z",
  "languages": ["en", "hi"]
}
```

#### 2. `callRequests` Collection

Tracks call requests between users and admins.

**Document ID**: Auto-generated

**Schema**:
```javascript
{
  requestId: string,              // Same as document ID
  callerId: string,               // User initiating call
  callerName: string,             // Caller's display name
  adminId: string,                // Admin receiving call
  adminName: string,              // Admin's display name
  channelName: string,            // Agora channel name
  coinsPerMin: number,            // Rate for this call
  status: string,                 // 'pending', 'accepted', 'rejected', 'completed', 'cancelled'
  createdAt: timestamp,           // Request creation time
  acceptedAt: timestamp | null,   // When admin accepted
  endedAt: timestamp | null,      // When call ended
  duration: number,               // Call duration in seconds
  coinsCharged: number,           // Total coins deducted
}
```

**Indexes Required**:
- Composite: `adminId` (Ascending) + `status` (Ascending) + `createdAt` (Descending)
- Composite: `callerId` (Ascending) + `status` (Ascending) + `createdAt` (Descending)

**Status Flow**:
```
pending → accepted → completed
        ↘ rejected
        ↘ cancelled
```

**Example Document**:
```json
{
  "requestId": "req_12345",
  "callerId": "user_abc",
  "callerName": "John Doe",
  "adminId": "admin_xyz",
  "adminName": "Dr. Smith",
  "channelName": "channel_12345",
  "coinsPerMin": 5,
  "status": "completed",
  "createdAt": "2024-01-15T10:00:00Z",
  "acceptedAt": "2024-01-15T10:00:05Z",
  "endedAt": "2024-01-15T10:05:00Z",
  "duration": 300,
  "coinsCharged": 25
}
```

#### 3. `orders` Collection

Stores Razorpay order information.

**Document ID**: Razorpay Order ID

**Schema**:
```javascript
{
  userId: string,                 // User who created order
  amount: number,                 // Amount in rupees
  coins: number,                  // Coins to be credited
  currency: string,               // 'INR'
  status: string,                 // 'created', 'completed', 'failed'
  razorpayOrderId: string,        // Razorpay order ID
  createdAt: timestamp,           // Order creation time
  completedAt: timestamp | null,  // Payment completion time
}
```

#### 4. `transactions` Collection

Records all wallet transactions.

**Document ID**: Auto-generated

**Schema**:
```javascript
{
  userId: string,                 // User ID
  type: string,                   // 'credit' or 'debit'
  amount: number,                 // Amount in rupees
  coins: number,                  // Coins credited/debited
  balanceBefore: number,          // Balance before transaction
  balanceAfter: number,           // Balance after transaction
  description: string,            // Transaction description
  orderId: string | null,         // Related order ID (for credits)
  callRequestId: string | null,   // Related call ID (for debits)
  status: string,                 // 'completed', 'pending', 'failed'
  createdAt: timestamp,           // Transaction time
}
```

**Example Document**:
```json
{
  "userId": "user_abc",
  "type": "credit",
  "amount": 100,
  "coins": 100,
  "balanceBefore": 50,
  "balanceAfter": 150,
  "description": "Wallet recharge",
  "orderId": "order_12345",
  "status": "completed",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

### Firestore Security Rules

**Important**: The app currently uses default Firestore rules. For production, implement proper security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Call requests
    match /callRequests/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        (request.auth.uid == resource.data.callerId ||
         request.auth.uid == resource.data.adminId);
    }

    // Orders - read only for owner
    match /orders/{orderId} {
      allow read: if request.auth != null &&
        request.auth.uid == resource.data.userId;
      allow write: if false; // Only server can write
    }

    // Transactions - read only for owner
    match /transactions/{transactionId} {
      allow read: if request.auth != null &&
        request.auth.uid == resource.data.userId;
      allow write: if false; // Only server can write
    }
  }
}
```

---

## Security & Authentication

### Authentication Flow

1. **Firebase Authentication**: Primary authentication system
   - Google Sign-In (OAuth 2.0)
   - Email/Password authentication
   - Generates Firebase ID tokens

2. **ID Token Verification**: All API calls require valid Firebase ID token
   ```dart
   final idToken = await user.getIdToken();
   headers: {
     'Authorization': 'Bearer $idToken',
   }
   ```

3. **Server-Side Validation**: Firebase Functions verify tokens
   ```javascript
   const decodedToken = await admin.auth().verifyIdToken(idToken);
   if (decodedToken.uid !== userId) {
     return res.status(403).json({ error: 'Forbidden' });
   }
   ```

### Security Best Practices Implemented

✅ **Token-Based Authentication**: All API calls authenticated with Firebase ID tokens

✅ **Server-Side Payment Verification**: Payment signatures verified on server

✅ **Secure Token Generation**: Agora tokens generated server-side, never exposed

✅ **HTTPS Only**: All API calls use HTTPS

✅ **CORS Enabled**: Firebase Functions use CORS for web security

✅ **Input Validation**: All user inputs validated before processing

### Security Considerations

⚠️ **Firestore Rules**: Currently using default rules - should implement proper security rules for production

⚠️ **API Keys in Code**: Some API keys visible in code (Agora App ID) - acceptable for client-side SDKs

⚠️ **Role Management**: User roles stored in Firestore - consider server-side validation for role changes

⚠️ **Rate Limiting**: No rate limiting implemented - consider adding for production

### Data Privacy

- **User Data**: Stored in Firestore with user consent
- **Payment Data**: Handled by Razorpay (PCI DSS compliant)
- **Call Data**: Not recorded - only metadata stored
- **FCM Tokens**: Stored for push notifications only

### Permissions Required

**Android**:
- Microphone (for audio calls)
- Camera (for future video calls)
- Internet (for connectivity)
- Notifications (for incoming calls)

**iOS**:
- Microphone access
- Camera access (future)
- Notifications

All permissions requested at runtime with proper explanations.

---

## Deployment

### Prerequisites

1. **Flutter SDK**: Version 3.9.2 or higher
2. **Firebase CLI**: For deploying functions
3. **Android Studio / Xcode**: For building apps
4. **Firebase Project**: Configured and ready
5. **Razorpay Account**: For payment processing
6. **Agora Account**: For audio calling

### Development Setup

1. **Clone Repository**:
```bash
git clone https://github.com/rpyaduvanshi950/gaytalk.git
cd gaytalk
```

2. **Install Dependencies**:
```bash
flutter pub get
cd functions
npm install
cd ..
```

3. **Configure Firebase**:
   - Download `google-services.json` from Firebase Console
   - Place in `android/app/`
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`

4. **Run App**:
```bash
flutter run
```

### Production Deployment

#### 1. Deploy Firebase Functions

```bash
# Login to Firebase
firebase login

# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:createOrder
```

#### 2. Configure Production Credentials

**Razorpay Live Keys**:
```bash
firebase functions:config:set razorpay.key_id="rzp_live_XXX"
firebase functions:config:set razorpay.key_secret="YOUR_SECRET"
```

**Agora Certificate**:
```bash
firebase functions:config:set agora.app_certificate="YOUR_CERTIFICATE"
```

#### 3. Build Android APK/AAB

**Debug Build**:
```bash
flutter build apk --debug
```

**Release Build**:
```bash
flutter build apk --release
# or for Play Store
flutter build appbundle --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

#### 4. Build iOS App

```bash
flutter build ios --release
```

Then open in Xcode and archive for App Store.

#### 5. Update Firestore Security Rules

Deploy production security rules:
```bash
firebase deploy --only firestore:rules
```

### Environment-Specific Configuration

**Development**:
- Use test Razorpay keys
- Use temporary Agora tokens (optional)
- Enable debug logging

**Production**:
- Use live Razorpay keys
- Server-side Agora token generation
- Disable debug logging
- Enable crash reporting

### Continuous Integration

Consider setting up CI/CD with:
- GitHub Actions
- Fastlane (for iOS/Android automation)
- Firebase App Distribution (for beta testing)

### Monitoring & Analytics

**Firebase Analytics**: Track user behavior
**Firebase Crashlytics**: Monitor crashes
**Firebase Performance**: Monitor app performance

### Version Management

Current version: `2.0.0+2`

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

Update in `pubspec.yaml`:
```yaml
version: 2.0.0+2
```

---

## Troubleshooting

### Common Issues

#### 1. Google Sign-In Not Working

**Problem**: Google Sign-In fails or returns null

**Solutions**:
- Verify `google-services.json` is in `android/app/`
- Check SHA-1 fingerprint is added in Firebase Console
- Ensure Google Sign-In is enabled in Firebase Authentication
- Clear app data and try again

#### 2. Agora Call Not Connecting

**Problem**: Call screen shows error or doesn't connect

**Solutions**:
- Verify Agora App ID is correct
- Check token generation is working (check logs)
- Ensure microphone permission is granted
- Verify internet connectivity
- Check Firebase Functions are deployed

#### 3. Payment Verification Failing

**Problem**: Payment completes but wallet not updated

**Solutions**:
- Check Firebase Functions logs for errors
- Verify Razorpay credentials are correct
- Ensure signature verification is working
- Check Firestore write permissions

#### 4. Notifications Not Received

**Problem**: Admin doesn't receive incoming call notifications

**Solutions**:
- Verify FCM token is stored in Firestore
- Check notification permissions are granted
- Ensure Firebase Functions trigger is working
- Test with Firebase Console (Cloud Messaging)

#### 5. Build Errors

**Problem**: App fails to build

**Solutions**:
```bash
# Clean build
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for conflicts
flutter doctor
```

### Debug Tools

**Flutter DevTools**:
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Firebase Emulator** (for local testing):
```bash
firebase emulators:start
```

**Logs**:
```bash
# Flutter logs
flutter logs

# Firebase Functions logs
firebase functions:log
```

---

## Glossary for Beginners

**Flutter**: A framework for building mobile apps that work on both iOS and Android from a single codebase.

**Dart**: The programming language used by Flutter.

**Firebase**: Google's platform for building mobile and web apps, providing backend services like database, authentication, and hosting.

**Firestore**: Firebase's NoSQL cloud database that stores data in documents and collections.

**Widget**: Building blocks of Flutter UI - everything in Flutter is a widget (buttons, text, layouts, etc.).

**StatefulWidget**: A widget that can change its appearance based on user interaction or data changes.

**Async/Await**: Keywords for handling asynchronous operations (like network requests) without blocking the app.

**Stream**: A sequence of asynchronous events - like a river of data that flows over time.

**Token**: A secure string that proves identity or grants access (like a digital key).

**API**: Application Programming Interface - a way for different software to communicate.

**SDK**: Software Development Kit - a collection of tools for building apps.

**OAuth**: A secure way to log in using another service (like "Sign in with Google").

**Push Notification**: A message sent to your phone even when the app is closed.

**Cloud Function**: Code that runs on a server (in the cloud) instead of on the user's device.

**Real-Time Communication (RTC)**: Technology for live audio/video calls over the internet.

---

## Additional Resources

### Official Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Agora Documentation](https://docs.agora.io/)
- [Razorpay Documentation](https://razorpay.com/docs/)

### Learning Resources

- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Firebase Codelabs](https://firebase.google.com/codelabs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

### Community

- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)
- [Firebase Community](https://firebase.google.com/community)

---

## Project Summary

**GayTalk** is a comprehensive Flutter application that demonstrates:

✅ **Modern Mobile Development**: Cross-platform app with native performance

✅ **Real-Time Communication**: High-quality audio calls using Agora

✅ **Secure Authentication**: Firebase Auth with Google Sign-In

✅ **Payment Integration**: Razorpay for seamless transactions

✅ **Cloud Backend**: Firebase Firestore and Cloud Functions

✅ **Push Notifications**: FCM for real-time alerts

✅ **User Management**: Role-based access (users and admins)

✅ **Wallet System**: Coin-based payment model

This project serves as an excellent reference for building production-ready mobile applications with Flutter and Firebase, incorporating industry-standard practices for authentication, payments, and real-time communication.

---

**Last Updated**: January 2024
**Version**: 2.0.0
**Maintained By**: GumboTech


