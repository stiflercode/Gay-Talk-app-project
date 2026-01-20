# Razorpay Payment Integration Setup

This guide will help you set up Razorpay payment gateway with Firebase Functions for wallet top-ups.

## Prerequisites

1. Razorpay account with MID (Merchant ID) and API keys
2. Firebase project with Functions enabled
3. Node.js 18+ installed locally

## Step 1: Get Razorpay Credentials

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Navigate to **Settings** → **API Keys**
3. Generate a new Key ID and Key Secret (or use existing ones)
4. Copy your **Key ID** and **Key Secret**

## Step 2: Install Firebase Functions Dependencies

```bash
cd functions
npm install
```

## Step 3: Configure Razorpay in Firebase Functions

You have two options to set Razorpay credentials:

### Option A: Using Firebase Config (Recommended for Production)

```bash
firebase functions:config:set razorpay.key_id="YOUR_KEY_ID" razorpay.key_secret="YOUR_KEY_SECRET"
```

### Option B: Using Environment Variables (For Local Development)

Create a `.env` file in the `functions` directory:

```
RAZORPAY_KEY_ID=your_key_id_here
RAZORPAY_KEY_SECRET=your_key_secret_here
```

Then update `functions/index.js` to read from environment variables if config is not set.

## Step 4: Deploy Firebase Functions

```bash
firebase deploy --only functions
```

After deployment, note the function URLs. They will look like:
- `https://<region>-<project-id>.cloudfunctions.net/createOrder`
- `https://<region>-<project-id>.cloudfunctions.net/verifyPayment`
- `https://<region>-<project-id>.cloudfunctions.net/getPaymentHistory`

## Step 5: Configure Flutter App

Update `lib/services/payment_service.dart` with your Firebase Functions URL:

```dart
static String get functionsBaseUrl {
  const url = String.fromEnvironment(
    'FIREBASE_FUNCTIONS_URL',
    defaultValue: 'https://<region>-<project-id>.cloudfunctions.net', // Replace with your URL
  );
  return url;
}
```

Or set it via environment variable when running:

```bash
flutter run --dart-define=FIREBASE_FUNCTIONS_URL=https://<region>-<project-id>.cloudfunctions.net
```

## Step 6: Add Razorpay Package

The Razorpay Flutter package is already added to `pubspec.yaml`. Run:

```bash
flutter pub get
```

## Step 7: Android Configuration

Add Razorpay to your `android/app/build.gradle`:

```gradle
dependencies {
    // ... existing dependencies
    implementation 'com.razorpay:checkout:1.6.26'
}
```

## Step 8: Test the Integration

1. Run the app
2. Navigate to Wallet page
3. Select a recharge pack
4. Click "Pay ₹X" button
5. Complete payment via Razorpay checkout
6. Verify wallet balance is updated

## API Endpoints

### Create Order
- **URL**: `POST /createOrder`
- **Headers**: `Authorization: Bearer <Firebase_ID_Token>`
- **Body**: 
  ```json
  {
    "amount": 100,
    "currency": "INR",
    "userId": "user_uid",
    "coins": 100
  }
  ```
- **Response**:
  ```json
  {
    "orderId": "order_xxx",
    "amount": 10000,
    "currency": "INR",
    "keyId": "rzp_test_xxx"
  }
  ```

### Verify Payment
- **URL**: `POST /verifyPayment`
- **Headers**: `Authorization: Bearer <Firebase_ID_Token>`
- **Body**:
  ```json
  {
    "orderId": "order_xxx",
    "paymentId": "pay_xxx",
    "signature": "signature_xxx",
    "userId": "user_uid",
    "coins": 100
  }
  ```
- **Response**:
  ```json
  {
    "success": true,
    "message": "Payment verified and wallet updated",
    "newBalance": 150,
    "coins": 100
  }
  ```

### Get Payment History
- **URL**: `GET /getPaymentHistory?userId=xxx`
- **Headers**: `Authorization: Bearer <Firebase_ID_Token>`
- **Response**:
  ```json
  {
    "transactions": [...]
  }
  ```

## Security Notes

1. **Never expose Key Secret** in client-side code
2. Always verify payment signatures on the backend
3. Use Firebase Authentication to secure endpoints
4. Store sensitive credentials in Firebase Config or environment variables

## Troubleshooting

### Payment fails with "Invalid signature"
- Ensure Key Secret is correctly set in Firebase Functions
- Verify the signature calculation matches Razorpay's algorithm

### Functions not deploying
- Check Node.js version (should be 18+)
- Verify Firebase CLI is installed: `firebase --version`
- Check Firebase project is linked: `firebase projects:list`

### Payment succeeds but wallet not updated
- Check Firebase Functions logs: `firebase functions:log`
- Verify Firestore permissions allow writes
- Check user authentication token is valid

## Support

For Razorpay issues, refer to:
- [Razorpay Documentation](https://razorpay.com/docs/)
- [Razorpay Flutter SDK](https://github.com/razorpay/razorpay-flutter)

For Firebase Functions issues:
- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)

