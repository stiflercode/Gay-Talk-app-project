const functions = require('firebase-functions');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');
const cors = require('cors')({ origin: true });
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

admin.initializeApp();

// Razorpay configuration
// Priority: Firebase Config > Environment Variables > Test Credentials (fallback)
// For LIVE mode: Set via Firebase Functions config:
//   firebase functions:config:set razorpay.key_id="rzp_live_XXX" razorpay.key_secret="YOUR_SECRET"
// For TEST mode: Uses fallback test credentials below
const RAZORPAY_KEY_ID = functions.config().razorpay?.key_id || 
                        process.env.RAZORPAY_KEY_ID || 
                        'rzp_test_RxJw6Un202MDDY';
const RAZORPAY_KEY_SECRET = functions.config().razorpay?.key_secret || 
                             process.env.RAZORPAY_KEY_SECRET || 
                             '1cQ28U1Xws2JwvbQIG1PFTSE';

const razorpay = new Razorpay({
  key_id: RAZORPAY_KEY_ID,
  key_secret: RAZORPAY_KEY_SECRET,
});

/**
 * Create a Razorpay order
 * POST /createOrder
 * Body: { amount, currency, userId, coins }
 */
exports.createOrder = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
      const { amount, currency = 'INR', userId, coins } = req.body;

      if (!amount || !userId || !coins) {
        return res.status(400).json({ error: 'Missing required fields: amount, userId, coins' });
      }

      // Verify user authentication
      const idToken = req.headers.authorization?.split('Bearer ')[1];
      if (!idToken) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
        if (decodedToken.uid !== userId) {
          return res.status(403).json({ error: 'Forbidden' });
        }
      } catch (error) {
        return res.status(401).json({ error: 'Invalid token' });
      }

      // Create Razorpay order
      // Receipt must be max 40 characters (Razorpay requirement)
      const shortUserId = userId.substring(0, 10); // Take first 10 chars of userId
      const timestamp = Date.now().toString().slice(-8); // Last 8 digits of timestamp
      const receipt = `ord_${shortUserId}_${timestamp}`; // Max length: 3 + 10 + 1 + 8 = 22 chars
      
      const options = {
        amount: amount * 100, // Convert to paise (Razorpay expects amount in smallest currency unit)
        currency: currency,
        receipt: receipt,
        notes: {
          userId: userId,
          coins: coins.toString(),
        },
      };

      const order = await razorpay.orders.create(options);

      // Store order in Firestore for tracking
      await admin.firestore().collection('orders').doc(order.id).set({
        userId: userId,
        amount: amount,
        coins: coins,
        currency: currency,
        status: 'created',
        razorpayOrderId: order.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.status(200).json({
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        keyId: RAZORPAY_KEY_ID, // Frontend needs this for Razorpay Checkout
      });
    } catch (error) {
      console.error('Error creating order:', error);
      return res.status(500).json({ error: 'Failed to create order', message: error.message });
    }
  });
});

/**
 * Verify payment and update wallet
 * POST /verifyPayment
 * Body: { orderId, paymentId, signature, userId, coins }
 */
exports.verifyPayment = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
      const { orderId, paymentId, signature, userId, coins } = req.body;

      if (!orderId || !paymentId || !signature || !userId || !coins) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      // Verify user authentication
      const idToken = req.headers.authorization?.split('Bearer ')[1];
      if (!idToken) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
        if (decodedToken.uid !== userId) {
          return res.status(403).json({ error: 'Forbidden' });
        }
      } catch (error) {
        return res.status(401).json({ error: 'Invalid token' });
      }

      // Verify payment signature
      const crypto = require('crypto');
      const text = `${orderId}|${paymentId}`;
      const generatedSignature = crypto
        .createHmac('sha256', RAZORPAY_KEY_SECRET)
        .update(text)
        .digest('hex');

      if (generatedSignature !== signature) {
        return res.status(400).json({ error: 'Invalid payment signature' });
      }

      // Fetch payment details from Razorpay
      const payment = await razorpay.payments.fetch(paymentId);

      if (payment.status !== 'captured' && payment.status !== 'authorized') {
        return res.status(400).json({ error: 'Payment not successful', status: payment.status });
      }

      // Get order from Firestore
      const orderDoc = await admin.firestore().collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        return res.status(404).json({ error: 'Order not found' });
      }

      const orderData = orderDoc.data();
      if (orderData.status === 'completed') {
        return res.status(400).json({ error: 'Order already processed' });
      }

      // Update order status
      await admin.firestore().collection('orders').doc(orderId).update({
        status: 'completed',
        paymentId: paymentId,
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update user wallet balance
      const userRef = admin.firestore().collection('users').doc(userId);
      const userDoc = await userRef.get();
      const currentBalance = userDoc.exists && userDoc.data().walletBalance
        ? userDoc.data().walletBalance
        : 0;

      const newBalance = currentBalance + parseInt(coins);

      await userRef.set(
        {
          walletBalance: newBalance,
          lastTopUp: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // Create transaction record
      await admin.firestore().collection('transactions').add({
        userId: userId,
        orderId: orderId,
        paymentId: paymentId,
        amount: orderData.amount,
        coins: coins,
        type: 'topup',
        status: 'completed',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.status(200).json({
        success: true,
        message: 'Payment verified and wallet updated',
        newBalance: newBalance,
        coins: coins,
      });
    } catch (error) {
      console.error('Error verifying payment:', error);
      return res.status(500).json({ error: 'Failed to verify payment', message: error.message });
    }
  });
});

/**
 * Get payment history for a user
 * GET /getPaymentHistory?userId=xxx
 */
exports.getPaymentHistory = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'GET') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
      const userId = req.query.userId;
      if (!userId) {
        return res.status(400).json({ error: 'Missing userId' });
      }

      // Verify user authentication
      const idToken = req.headers.authorization?.split('Bearer ')[1];
      if (!idToken) {
        return res.status(401).json({ error: 'Unauthorized' });
      }

      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
        if (decodedToken.uid !== userId) {
          return res.status(403).json({ error: 'Forbidden' });
        }
      } catch (error) {
        return res.status(401).json({ error: 'Invalid token' });
      }

      const transactions = await admin
        .firestore()
        .collection('transactions')
        .where('userId', '==', userId)
        .orderBy('createdAt', 'desc')
        .limit(50)
        .get();

      const history = transactions.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      return res.status(200).json({ transactions: history });
    } catch (error) {
      console.error('Error fetching payment history:', error);
      return res.status(500).json({ error: 'Failed to fetch payment history', message: error.message });
    }
  });
});

/**
 * Generate Agora RTC token for video/audio calls
 * POST /generateAgoraToken
 * Body: { channelName, uid, expireTime }
 * Headers: Authorization: Bearer <Firebase ID Token>
 */
exports.generateAgoraToken = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    if (req.method !== 'POST') {
      return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
      const { channelName, uid, expireTime = 3600 } = req.body;

      // Validate required fields
      if (!channelName || uid === undefined || uid === null) {
        return res.status(400).json({ 
          error: 'Missing required fields: channelName and uid are required' 
        });
      }

      // Validate channel name
      if (typeof channelName !== 'string' || channelName.trim().length === 0) {
        return res.status(400).json({ error: 'Invalid channelName' });
      }

      // Validate UID (must be a number or string that can be converted to number)
      const numericUid = typeof uid === 'number' ? uid : parseInt(uid, 10);
      if (isNaN(numericUid) || numericUid < 0 || numericUid > 2147483647) {
        return res.status(400).json({ 
          error: 'Invalid uid: must be a number between 0 and 2147483647' 
        });
      }

      // Validate expireTime
      const numericExpireTime = typeof expireTime === 'number' 
        ? expireTime 
        : parseInt(expireTime, 10);
      if (isNaN(numericExpireTime) || numericExpireTime < 0 || numericExpireTime > 86400) {
        return res.status(400).json({ 
          error: 'Invalid expireTime: must be between 0 and 86400 seconds (24 hours)' 
        });
      }

      // Verify user authentication
      const idToken = req.headers.authorization?.split('Bearer ')[1];
      if (!idToken) {
        return res.status(401).json({ error: 'Unauthorized: Missing authentication token' });
      }

      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        console.error('Token verification error:', error);
        return res.status(401).json({ error: 'Unauthorized: Invalid authentication token' });
      }

      // Get Agora configuration from environment variables
      const AGORA_APP_ID = functions.config().agora?.app_id || 
                          process.env.AGORA_APP_ID || 
                          '09b3df9a6e874153924cb08d71d73b9b';
      
      const AGORA_APP_CERTIFICATE = functions.config().agora?.app_certificate || 
                                   functions.config().agora?.app_cert || // Legacy key support
                                   process.env.AGORA_APP_CERTIFICATE;

      if (!AGORA_APP_CERTIFICATE || AGORA_APP_CERTIFICATE.trim().length === 0) {
        console.error('Agora App Certificate not configured');
        return res.status(500).json({ 
          error: 'Server configuration error: Agora App Certificate not set',
          message: 'Please configure AGORA_APP_CERTIFICATE in Firebase Functions config or environment variables'
        });
      }

      // Calculate token expiration timestamp
      const currentTime = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTime + numericExpireTime;

      // Generate Agora RTC token
      // Using buildTokenWithUid for numeric UIDs (recommended for production)
      const token = RtcTokenBuilder.buildTokenWithUid(
        AGORA_APP_ID,
        AGORA_APP_CERTIFICATE,
        channelName.trim(),
        numericUid,
        RtcRole.PUBLISHER, // User can publish (send audio/video)
        privilegeExpiredTs
      );

      // Log token generation (without exposing sensitive data)
      console.log(`Agora token generated for user ${decodedToken.uid}, channel: ${channelName}, uid: ${numericUid}`);

      return res.status(200).json({
        token: token,
        appId: AGORA_APP_ID,
        channelName: channelName.trim(),
        uid: numericUid,
        expireTime: numericExpireTime,
        expiresAt: privilegeExpiredTs,
      });
    } catch (error) {
      console.error('Error generating Agora token:', error);
      return res.status(500).json({ 
        error: 'Failed to generate Agora token', 
        message: error.message 
      });
    }
  });
});

/**
 * Send FCM notification when a call request is created
 * This triggers automatically when a new call request is added to Firestore
 */
exports.sendCallRequestNotification = functions.firestore
  .document('callRequests/{requestId}')
  .onCreate(async (snap, context) => {
    const requestData = snap.data();
    
    // Only send notification for pending requests
    if (requestData.status !== 'pending') {
      return null;
    }

    const adminId = requestData.adminId;
    const callerName = requestData.callerName || 'Unknown Caller';
    const requestId = context.params.requestId;

    try {
      // Get admin's FCM token from Firestore
      const adminDoc = await admin.firestore().collection('users').doc(adminId).get();
      
      if (!adminDoc.exists) {
        console.log(`Admin ${adminId} not found`);
        return null;
      }

      const adminData = adminDoc.data();
      const fcmToken = adminData?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token found for admin ${adminId}`);
        return null;
      }

      // Prepare notification message
      const message = {
        notification: {
          title: 'Incoming Call',
          body: `Call from ${callerName}`,
        },
        data: {
          type: 'incoming_call',
          callRequestId: requestId,
          callerId: requestData.callerId || '',
          callerName: callerName,
          channelName: requestData.channelName || '',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'incoming_calls',
            sound: 'ringtone', // Use system ringtone
            priority: 'max',
            visibility: 'public',
            importance: 'max',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              interruptionLevel: 'critical',
              badge: 1,
            },
          },
        },
        token: fcmToken,
      };

      // Send FCM notification
      const response = await admin.messaging().send(message);
      console.log(`Successfully sent FCM notification to admin ${adminId}:`, response);
      
      return response;
    } catch (error) {
      console.error('Error sending FCM notification:', error);
      return null;
    }
  });

