# Firebase Functions for Razorpay Payment Processing

This directory contains Firebase Cloud Functions for handling Razorpay payments.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Set Razorpay credentials:
```bash
firebase functions:config:set razorpay.key_id="YOUR_KEY_ID" razorpay.key_secret="YOUR_KEY_SECRET"
```

3. Deploy functions:
```bash
firebase deploy --only functions
```

## Functions

- **createOrder**: Creates a Razorpay order and stores it in Firestore
- **verifyPayment**: Verifies payment signature and updates user wallet
- **getPaymentHistory**: Retrieves payment history for a user

## Environment Variables

- `RAZORPAY_KEY_ID`: Razorpay Key ID (if not using Firebase Config)
- `RAZORPAY_KEY_SECRET`: Razorpay Key Secret (if not using Firebase Config)

## Testing Locally

```bash
firebase emulators:start --only functions
```

Then use the emulator URL instead of production URL in your Flutter app.

