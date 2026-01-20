# Deployment Instructions - Razorpay Integration

## ✅ Credentials Configured

Your Razorpay test credentials have been set:
- **Key ID**: `rzp_test_RxJw6Un202MDDY`
- **Key Secret**: `1cQ28U1Xws2JwvbQIG1PFTSE`

## Step 1: Deploy Firebase Functions

Run this command to deploy the payment functions:

```bash
firebase deploy --only functions
```

This will deploy:
- `createOrder` - Creates Razorpay orders
- `verifyPayment` - Verifies payments and updates wallet
- `getPaymentHistory` - Gets payment history

After deployment, you'll see URLs like:
```
✔  functions[createOrder(us-central1)]: Successful create operation.
✔  functions[verifyPayment(us-central1)]: Successful create operation.
✔  functions[getPaymentHistory(us-central1)]: Successful create operation.
```

**Note**: The default region is `us-central1`. If your functions deploy to a different region, update the URL in `lib/services/payment_service.dart`.

## Step 2: Verify Functions URL

The payment service is configured to use:
```
https://us-central1-gaytalks-b929a.cloudfunctions.net
```

If your functions deployed to a different region, update `lib/services/payment_service.dart`:

```dart
defaultValue: 'https://<your-region>-gaytalks-b929a.cloudfunctions.net',
```

Or set it via environment variable:
```bash
flutter run --dart-define=FIREBASE_FUNCTIONS_URL=https://<region>-gaytalks-b929a.cloudfunctions.net
```

## Step 3: Test the Payment Flow

1. Run the app: `flutter run`
2. Navigate to Wallet page
3. Select a recharge pack (50, 100, 200, or 500 coins)
4. Click "Pay ₹X" button
5. Complete payment using Razorpay test mode:
   - Use test card: `4111 1111 1111 1111`
   - CVV: Any 3 digits
   - Expiry: Any future date
   - Or use UPI: `success@razorpay`
6. Verify wallet balance updates after successful payment

## Test Cards for Razorpay

### Successful Payment
- Card: `4111 1111 1111 1111`
- CVV: Any 3 digits
- Expiry: Any future date
- Name: Any name

### Failed Payment
- Card: `4000 0000 0000 0002`
- CVV: Any 3 digits
- Expiry: Any future date

### UPI Test
- UPI ID: `success@razorpay` (for success)
- UPI ID: `failure@razorpay` (for failure)

## Troubleshooting

### Functions not deploying?
1. Check Firebase CLI is installed: `firebase --version`
2. Verify you're logged in: `firebase login`
3. Check project is linked: `firebase projects:list`
4. Ensure Node.js 18+ is installed: `node --version`

### Payment not working?
1. Check Firebase Functions logs: `firebase functions:log`
2. Verify the functions URL is correct
3. Check Razorpay credentials are set: `firebase functions:config:get`
4. Ensure user is authenticated in the app

### Functions URL incorrect?
1. Check deployment output for actual URLs
2. Update `lib/services/payment_service.dart` with correct URL
3. Or use environment variable when running

## Production Setup

When ready for production:

1. Get production Razorpay keys from dashboard
2. Update Firebase config:
   ```bash
   firebase functions:config:set razorpay.key_id="rzp_live_XXX" razorpay.key_secret="YOUR_LIVE_SECRET"
   ```
3. Redeploy functions: `firebase deploy --only functions`
4. Test with real payments

## Security Notes

- ✅ Credentials are stored in Firebase Functions config (secure)
- ✅ Payment verification happens on backend (secure)
- ✅ User authentication required for all endpoints
- ✅ Payment signatures are verified server-side

