# Razorpay Live Mode Setup Guide

## Overview
This guide will help you switch from Razorpay test mode to live/production mode with real payments.

## Prerequisites
You should have:
- ✅ Razorpay Live API Key (Key ID) - starts with `rzp_live_`
- ✅ Razorpay Live Secret Key (Key Secret)
- ✅ Razorpay Merchant ID (MID) - usually embedded in your account

## Step 1: Get Your Live Credentials

1. Log in to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Make sure you're in **Live Mode** (toggle in top right)
3. Go to **Settings** → **API Keys**
4. Copy your:
   - **Key ID** (e.g., `rzp_live_XXXXXXXXXXXX`)
   - **Key Secret** (e.g., `xxxxxxxxxxxxxxxxxxxxxxxx`)

## Step 2: Configure Firebase Functions

Set your live Razorpay credentials in Firebase Functions:

```bash
firebase functions:config:set razorpay.key_id="YOUR_LIVE_KEY_ID" razorpay.key_secret="YOUR_LIVE_SECRET_KEY"
```

**Example:**
```bash
firebase functions:config:set razorpay.key_id="rzp_live_ABC123XYZ" razorpay.key_secret="your_secret_key_here"
```

## Step 3: Verify Configuration

Check that your credentials are set correctly:

```bash
firebase functions:config:get
```

You should see:
```json
{
  "razorpay": {
    "key_id": "rzp_live_...",
    "key_secret": "..."
  }
}
```

## Step 4: Deploy Firebase Functions

Deploy the updated functions:

```bash
cd functions
npm install  # Make sure dependencies are up to date
cd ..
firebase deploy --only functions
```

## Step 5: Test Live Payment (Small Amount First!)

⚠️ **IMPORTANT**: Test with a small amount first (e.g., ₹1) to verify everything works!

1. Run your app: `flutter run`
2. Go to Wallet page
3. Select a small recharge pack
4. Complete a real payment
5. Verify:
   - Payment appears in Razorpay Dashboard
   - Wallet balance updates correctly
   - Transaction is recorded in Firestore

## Step 6: Verify in Razorpay Dashboard

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Navigate to **Payments** → **All Payments**
3. You should see your test payment
4. Check payment status and details

## Important Notes

### Security
- ✅ Never commit your live Key Secret to version control
- ✅ Always use Firebase Functions config for production
- ✅ The Key Secret is only stored in Firebase Functions (server-side)

### Differences: Test vs Live

| Feature | Test Mode | Live Mode |
|---------|-----------|-----------|
| Key ID Format | `rzp_test_...` | `rzp_live_...` |
| Payments | Fake/test | Real money |
| Dashboard | Test dashboard | Live dashboard |
| Refunds | Automatic | Manual/API |

### Troubleshooting

**Issue**: Payment fails with "Invalid Key"
- **Solution**: Verify your Key ID and Secret are correct and you're in Live Mode

**Issue**: Functions not using live keys
- **Solution**: 
  1. Check config: `firebase functions:config:get`
  2. Redeploy: `firebase deploy --only functions`
  3. Check function logs: `firebase functions:log`

**Issue**: Payment succeeds but wallet not updated
- **Solution**: Check Firebase Functions logs for errors in `verifyPayment`

## Rollback to Test Mode

If you need to switch back to test mode:

```bash
firebase functions:config:set razorpay.key_id="rzp_test_RxJw6Un202MDDY" razorpay.key_secret="1cQ28U1Xws2JwvbQIG1PFTSE"
firebase deploy --only functions
```

## Support

- Razorpay Support: https://razorpay.com/support/
- Razorpay Docs: https://razorpay.com/docs/
- Firebase Functions Docs: https://firebase.google.com/docs/functions


