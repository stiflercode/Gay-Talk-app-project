const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticateUser } = require('../middleware/auth');

// Payment routes require authentication
router.post('/createOrder', authenticateUser, paymentController.createOrder);
router.post('/verifyPayment', authenticateUser, paymentController.verifyPayment);
router.get('/key', paymentController.getKey); // Public endpoint

module.exports = router;
