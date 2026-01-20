# Quick Setup Guide - Razorpay Integration

## What's Been Done ✅

1. ✅ Razorpay Flutter SDK added to `pubspec.yaml`
2. ✅ Firebase Functions created for payment processing
3. ✅ Payment service created (`lib/services/payment_service.dart`)
4. ✅ UPI verify screen updated to use Razorpay
5. ✅ Wallet system integrated with Firestore

## What You Need to Do

### 1. Install Dependencies

```bash
# Install Flutter dependencies
flutter pub get

# Install Firebase Functions dependencies
cd functions
npm install
cd ..
```

### 2. Get Your Razorpay MID and Keys

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Navigate to **Settings** → **API Keys**
3. Copy your **Key ID** and **Key Secret**

### 3. Configure Firebase Functions

Set your Razorpay credentials:

```bash
firebase functions:config:set razorpay.key_id="YOUR_KEY_ID" razorpay.key_secret="YOUR_KEY_SECRET"
```

### 4. Deploy Firebase Functions

```bash
firebase deploy --only functions
```

After deployment, you'll see URLs like:
```
✔  functions[createOrder(us-central1)]: Successful create operation.
✔  functions[verifyPayment(us-central1)]: Successful create operation.
✔  functions[getPaymentHistory(us-central1)]: Successful create operation.
```

Copy the base URL (e.g., `https://us-central1-gaytalks-b929a.cloudfunctions.net`)

### 5. Update Flutter App Configuration

Edit `lib/services/payment_service.dart` and replace the `functionsBaseUrl`:

```dart
static String get functionsBaseUrl {
  const url = String.fromEnvironment(
    'FIREBASE_FUNCTIONS_URL',
    defaultValue: 'https://us-central1-gaytalks-b929a.cloudfunctions.net', // Your URL here
  );
  return url;
}
```

Or set it when running:
```bash
flutter run --dart-define=FIREBASE_FUNCTIONS_URL=https://your-region-your-project.cloudfunctions.net
```

### 6. Test the Integration

1. Run the app: `flutter run`
2. Go to Wallet page
3. Select a recharge pack
4. Click "Pay ₹X" button
5. Complete payment via Razorpay
6. Verify wallet balance updates

## File Structure

```
lib/
  services/
    payment_service.dart          # Payment API client
  screens/
    upi_verify_screen.dart        # Updated with Razorpay integration

functions/
  index.js                        # Firebase Functions (createOrder, verifyPayment, getPaymentHistory)
  package.json                    # Node.js dependencies
```

## Important Notes

- **Never commit** your Razorpay Key Secret to version control
- Always use Firebase Config or environment variables for secrets
- Payment verification happens on the backend for security
- Wallet balance is synced between local storage and Firestore

## Troubleshooting

**Payment not working?**
- Check Firebase Functions logs: `firebase functions:log`
- Verify Razorpay credentials are set correctly
- Ensure Firebase Functions URL is correct in `payment_service.dart`

**Functions not deploying?**
- Make sure you're in the project root
- Check Node.js version: `node --version` (should be 18+)
- Verify Firebase CLI is installed: `firebase --version`

## Next Steps

1. Test with Razorpay test mode first
2. Switch to live mode when ready for production
3. Update Razorpay webhook URLs if needed (optional)
4. Monitor payment transactions in Razorpay Dashboard

