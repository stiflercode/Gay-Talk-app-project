const Razorpay = require('razorpay');
const crypto = require('crypto');
const User = require('../models/User');

// Initialize Razorpay
let razorpay;
try {
    if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_ID !== 'rzp_test_placeholder') {
        razorpay = new Razorpay({
            key_id: process.env.RAZORPAY_KEY_ID,
            key_secret: process.env.RAZORPAY_KEY_SECRET,
        });
        console.log('✅ Razorpay initialized');
    } else {
        console.warn('⚠️  Razorpay keys not configured. Payment features will fail.');
    }
} catch (error) {
    console.error('❌ Razorpay initialization error:', error.message);
}

// Create Razorpay order
exports.createOrder = async (req, res) => {
    try {
        // Use authenticated user ID from token
        const userId = req.user.uid;
        const { amount, coins, currency = 'INR' } = req.body;

        if (!amount || !coins) {
            return res.status(400).json({ error: 'Missing required fields: amount, coins' });
        }

        // Amount should be in paise (smallest currency unit)
        const amountInPaise = Math.round(amount * 100);

        const options = {
            amount: amountInPaise,
            currency,
            receipt: `receipt_${Date.now()}_${userId.substring(0, 8)}`,
            notes: {
                userId,
                coins: coins.toString(),
            },
        };

        const order = await razorpay.orders.create(options);

        console.log(`💳 Order created for ${userId}: ₹${amount} = ${coins} coins`);

        res.json({
            orderId: order.id,
            amount: order.amount,
            currency: order.currency,
            keyId: process.env.RAZORPAY_KEY_ID,
        });
    } catch (error) {
        console.error('Create order error:', error);
        res.status(500).json({ error: 'Failed to create order', details: error.message });
    }
};

// Verify payment and update wallet
exports.verifyPayment = async (req, res) => {
    try {
        // Use authenticated user ID from token
        const userId = req.user.uid;
        const { orderId, paymentId, signature, coins } = req.body;

        if (!orderId || !paymentId || !signature || !coins) {
            return res.status(400).json({ error: 'Missing required fields' });
        }

        // Verify signature
        const body = orderId + '|' + paymentId;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(body.toString())
            .digest('hex');

        if (expectedSignature !== signature) {
            console.error(`❌ Invalid payment signature for user ${userId}`);
            return res.status(400).json({ error: 'Invalid signature' });
        }

        // Signature verified, update wallet balance
        const user = await User.findOne({ uid: userId });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // TODO: Add idempotency check here to prevent double-spending
        // Store processed payment IDs in database and check before adding coins

        const newBalance = (user.walletBalance || 0) + coins;
        user.walletBalance = newBalance;
        await user.save();

        console.log(`✅ Payment verified for ${userId}: Added ${coins} coins, new balance: ${newBalance}`);

        res.json({
            success: true,
            newBalance,
            message: `Added ${coins} coins to wallet`,
        });
    } catch (error) {
        console.error('Verify payment error:', error);
        res.status(500).json({ error: 'Failed to verify payment', details: error.message });
    }
};

// Get Razorpay key (for client)
exports.getKey = async (req, res) => {
    res.json({ keyId: process.env.RAZORPAY_KEY_ID });
};
