<p align="center">
  <img src="assets/images/logo.png" alt="GayTalk Logo" width="200"/>
</p>

<h1 align="center">GayTalk</h1>

<p align="center">
  <strong>Real-time Voice Communication Platform</strong>
</p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#prerequisites">Prerequisites</a> •
  <a href="#installation">Installation</a> •
  <a href="#configuration">Configuration</a>
</p>

---

## Overview

GayTalk is a sophisticated real-time voice communication platform built with Flutter and powered by Agora's industry-leading RTC technology. The application provides seamless, low-latency voice calling capabilities with a robust backend infrastructure.

## Features

- **Real-time Voice Calls** — Crystal-clear audio powered by Agora RTC Engine
- **Secure Authentication** — Firebase-based authentication with Google Sign-In support
- **In-App Wallet** — Integrated payment system with Razorpay
- **Push Notifications** — Real-time call notifications via Firebase Cloud Messaging
- **Cross-Platform** — Native support for iOS and Android

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Client (Flutter)                       │
├─────────────────────────────────────────────────────────────┤
│  Screens  │  Services  │  Widgets  │  Utilities            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend (Node.js/Express)                │
├─────────────────────────────────────────────────────────────┤
│  Controllers  │  Routes  │  Models  │  Middleware          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     External Services                       │
├──────────────┬──────────────┬──────────────┬───────────────┤
│    Agora     │   Firebase   │   Razorpay   │   MongoDB     │
│  (RTC/RTM)   │  (Auth/FCM)  │  (Payments)  │  (Database)   │
└──────────────┴──────────────┴──────────────┴───────────────┘
```

## Tech Stack

| Layer | Technology | Version |
|-------|------------|---------|
| **Mobile** | Flutter, Dart | 3.9.2+ |
| **Backend** | Node.js, Express.js | 18.x+ |
| **Database** | MongoDB | 6.x+ |
| **Authentication** | Firebase Auth | Latest |
| **Voice/Video** | Agora RTC Engine | 6.2.2 |
| **Signaling** | Agora RTM | 2.2.1 |
| **Payments** | Razorpay | 1.3.1 |
| **Notifications** | Firebase Cloud Messaging | Latest |

---

## Prerequisites

Before you begin, ensure you have the following installed on your development machine:

### Required Software

| Software | Version | Download |
|----------|---------|----------|
| Flutter SDK | 3.9.2+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.0+ | Included with Flutter |
| Node.js | 18.x+ | [nodejs.org](https://nodejs.org/) |
| npm | 9.x+ | Included with Node.js |
| MongoDB | 6.x+ | [mongodb.com](https://www.mongodb.com/try/download/community) |
| Xcode | 14+ | Mac App Store (for iOS) |
| Android Studio | Latest | [developer.android.com](https://developer.android.com/studio) |

### Verify Installation

```bash
# Verify Flutter
flutter --version

# Verify Node.js
node --version

# Verify npm
npm --version

# Verify MongoDB
mongod --version

# Run Flutter doctor
flutter doctor
```

---

## Installation

### Step 1: Clone the Repository

```bash
git clone <repository-url>
cd gaytalk
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

### Step 3: Install Backend Dependencies

```bash
cd backend
npm install
cd ..
```

---

## Configuration

### 1. MongoDB Setup

#### Option A: Local MongoDB

1. **Install MongoDB Community Edition**
   ```bash
   # macOS (using Homebrew)
   brew tap mongodb/brew
   brew install mongodb-community@7.0

   # Start MongoDB
   brew services start mongodb-community@7.0
   ```

2. **Verify MongoDB is running**
   ```bash
   mongosh
   # You should see the MongoDB shell prompt
   ```

3. **Create the database**
   ```bash
   mongosh
   use gaytalk
   ```

#### Option B: MongoDB Atlas (Cloud)

1. Go to [MongoDB Atlas](https://www.mongodb.com/atlas)
2. Create a free cluster
3. Create a database user with read/write permissions
4. Whitelist your IP address (or allow access from anywhere for development)
5. Get your connection string:
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/gaytalk?retryWrites=true&w=majority
   ```

---

### 2. Firebase Setup

#### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Enter project name: `gaytalk`
4. Disable Google Analytics (optional)
5. Click **"Create project"**

#### Step 2: Enable Authentication

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable the following providers:
   - **Email/Password**
   - **Google**

#### Step 3: Configure Google Sign-In

1. Go to **Authentication** → **Sign-in method** → **Google**
2. Enable Google Sign-In
3. Add your support email
4. Save

#### Step 4: Add Android App

1. In Firebase Console, click **"Add app"** → **Android**
2. Enter package name: `com.example.gaytalk`
3. Enter app nickname: `GayTalk Android`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

#### Step 5: Add iOS App

1. In Firebase Console, click **"Add app"** → **iOS**
2. Enter bundle ID: `com.example.gaytalk`
3. Enter app nickname: `GayTalk iOS`
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/GoogleService-Info.plist`

#### Step 6: Configure Cloud Firestore

1. Go to **Firestore Database** → **Create database**
2. Select **"Start in test mode"** (for development)
3. Choose a location closest to your users
4. Click **"Enable"**

#### Step 7: Enable Cloud Messaging (FCM)

1. Go to **Project Settings** → **Cloud Messaging**
2. Note your **Server Key** (for backend notifications)
3. For iOS, upload your APNs certificate or key

#### Step 8: Generate Firebase Options

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for Flutter
flutterfire configure --project=<your-firebase-project-id>
```

This will generate `lib/firebase_options.dart` automatically.

---

### 3. Agora Setup

#### Step 1: Create Agora Account

1. Go to [Agora Console](https://console.agora.io/)
2. Sign up for a free account
3. Verify your email

#### Step 2: Create a Project

1. Click **"Create a Project"**
2. Enter project name: `gaytalk`
3. Select **"Secured mode: APP ID + Token"**
4. Click **"Submit"**

#### Step 3: Get Credentials

1. Go to your project dashboard
2. Copy the following:
   - **App ID**: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
   - **App Certificate**: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (click to reveal)

#### Step 4: Enable Required Products

1. Go to your project → **Features**
2. Ensure the following are enabled:
   - **RTC (Real-Time Communication)**
   - **RTM (Real-Time Messaging)**

#### Step 5: Configure Token Server

The backend handles token generation. Tokens are required for:
- Joining voice channels (RTC)
- RTM login and messaging

---

### 4. Razorpay Setup

#### Step 1: Create Razorpay Account

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Sign up for an account
3. Complete KYC verification (required for live mode)

#### Step 2: Get API Keys

1. Go to **Settings** → **API Keys**
2. Generate a new key pair:
   - **Key ID**: `rzp_test_xxxxxxxxxxxx` (test) or `rzp_live_xxxxxxxxxxxx` (live)
   - **Key Secret**: `xxxxxxxxxxxxxxxxxxxxxxxx`

#### Step 3: Configure Webhooks (Optional)

1. Go to **Settings** → **Webhooks**
2. Add a new webhook for payment events:
   - URL: `https://your-backend-url/api/payment/webhook`
   - Events: `payment.captured`, `payment.failed`

---

### 5. Express.js Backend Setup

#### Step 1: Create Environment File

```bash
cd backend
cp env.example .env
```

#### Step 2: Configure Environment Variables

Edit `backend/.env` with your credentials:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017/gaytalk
# For Atlas: mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/gaytalk

# Agora Configuration
AGORA_APP_ID=your_agora_app_id_here
AGORA_APP_CERTIFICATE=your_agora_app_certificate_here

# Razorpay Configuration
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxx
RAZORPAY_KEY_SECRET=your_razorpay_key_secret

# Firebase Admin SDK (Optional - for server-side notifications)
FIREBASE_PROJECT_ID=your-firebase-project-id
```

#### Step 3: Initialize Database

```bash
cd backend
node init-db.js
```

#### Step 4: Seed Initial Data (Optional)

```bash
node seed-users.js
```

---

### 6. Flutter App Configuration

#### Step 1: Update API Base URL

Edit `lib/services/` files to point to your backend:

```dart
// For local development
const String baseUrl = 'http://localhost:3000';

// For Android Emulator
const String baseUrl = 'http://10.0.2.2:3000';

// For iOS Simulator
const String baseUrl = 'http://localhost:3000';

// For physical device (use your machine's IP)
const String baseUrl = 'http://192.168.x.x:3000';
```

#### Step 2: Configure Razorpay Key

Update the Razorpay key in your payment service:

```dart
const String razorpayKey = 'rzp_test_xxxxxxxxxxxx';
```

---

## Running the Application

### Start Backend Server

```bash
cd backend
npm run dev
```

The server will start at `http://localhost:3000`

### Run Flutter App

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

---

## Project Structure

```
gaytalk/
├── lib/                    # Flutter application source
│   ├── main.dart           # Application entry point
│   ├── firebase_options.dart # Firebase configuration
│   ├── screens/            # UI screens
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── wallet_page.dart
│   │   └── incoming_call_screen.dart
│   ├── services/           # Business logic and API services
│   │   ├── auth_service.dart
│   │   ├── call_request_service.dart
│   │   ├── payment_service.dart
│   │   └── user_service.dart
│   ├── widgets/            # Reusable UI components
│   └── utilities/          # Helper functions and constants
├── backend/                # Node.js backend server
│   ├── server.js           # Server entry point
│   ├── controllers/        # Request handlers
│   │   ├── agoraController.js
│   │   ├── callController.js
│   │   └── userController.js
│   ├── models/             # Database models
│   │   └── User.js
│   ├── routes/             # API route definitions
│   │   ├── agoraRoutes.js
│   │   ├── callRoutes.js
│   │   └── userRoutes.js
│   ├── .env                # Environment variables (not in git)
│   └── package.json        # Node.js dependencies
├── docs/                   # Project documentation
├── scripts/                # Utility scripts
├── tools/                  # External tools
├── android/                # Android-specific configuration
├── ios/                    # iOS-specific configuration
├── assets/                 # Static assets
│   ├── images/             # Image assets
│   └── sounds/             # Audio assets
├── pubspec.yaml            # Flutter dependencies
└── README.md               # This file
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Register new user |
| `POST` | `/api/auth/login` | User login |
| `GET` | `/api/users` | Get all users |
| `GET` | `/api/users/:id` | Get user by ID |
| `POST` | `/api/agora/token` | Generate Agora RTC token |
| `POST` | `/api/agora/rtm-token` | Generate Agora RTM token |
| `POST` | `/api/call/initiate` | Initiate a call |
| `POST` | `/api/call/accept` | Accept incoming call |
| `POST` | `/api/call/reject` | Reject incoming call |
| `POST` | `/api/payment/create-order` | Create Razorpay order |
| `POST` | `/api/payment/verify` | Verify payment |

---

## Troubleshooting

### Common Issues

<details>
<summary><strong>MongoDB Connection Failed</strong></summary>

```
Error: MongoNetworkError: connect ECONNREFUSED 127.0.0.1:27017
```

**Solution:**
1. Ensure MongoDB is running:
   ```bash
   brew services start mongodb-community
   ```
2. Check MongoDB status:
   ```bash
   brew services list
   ```
</details>

<details>
<summary><strong>Firebase Initialization Error</strong></summary>

```
Error: No Firebase App '[DEFAULT]' has been created
```

**Solution:**
1. Ensure `firebase_options.dart` exists in `lib/`
2. Verify Firebase is initialized in `main.dart`:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
</details>

<details>
<summary><strong>Agora Token Error</strong></summary>

```
Error: Invalid token or token expired
```

**Solution:**
1. Verify Agora App ID and Certificate in backend `.env`
2. Ensure token server is generating tokens correctly
3. Check token expiration time (default: 24 hours)
</details>

<details>
<summary><strong>Android Build Failed</strong></summary>

```
Error: Execution failed for task ':app:processDebugGoogleServices'
```

**Solution:**
1. Ensure `google-services.json` is in `android/app/`
2. Verify the package name matches Firebase configuration
</details>

<details>
<summary><strong>iOS Build Failed</strong></summary>

```
Error: No such module 'Firebase'
```

**Solution:**
1. Run `cd ios && pod install --repo-update`
2. Open `ios/Runner.xcworkspace` (not `.xcodeproj`)
3. Clean build folder: `flutter clean && flutter pub get`
</details>

---

## Documentation

Additional documentation is available in the [`docs/`](./docs) directory:

| Document | Description |
|----------|-------------|
| [Project Overview](./docs/project_overview.md) | Complete project overview |
| [Development Setup](./docs/guides/development_setup.md) | Local development guide |
| [Production Setup](./docs/guides/production_setup.md) | Deployment instructions |
| [Deploy Instructions](./docs/guides/deployment_instructions.md) | Step-by-step deployment |
| [Agora Setup](./docs/agora/setup_guide.md) | Voice calling configuration |
| [Agora Token Troubleshooting](./docs/agora/token_troubleshooting.md) | Token troubleshooting |
| [Agora Production Checklist](./docs/agora/production_ready.md) | Production checklist |
| [Razorpay Setup](./docs/razorpay/setup_guide.md) | Payment integration guide |
| [Razorpay Live Setup](./docs/razorpay/live_mode_setup.md) | Live payment configuration |
| [Firebase Package Update](./docs/firebase/package_name_update.md) | Firebase configuration |
| [Google Sign-In Fix](./docs/firebase/google_signin_fix.md) | Authentication troubleshooting |
| [User Admin System](./docs/guides/user_admin_system.md) | Admin panel documentation |

---

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## License

This project is proprietary software. All rights reserved.

---

<p align="center">
  <sub>Built with ❤️ using Flutter and Agora</sub>
</p>
