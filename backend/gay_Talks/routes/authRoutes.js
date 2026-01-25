const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateUser } = require('../middleware/auth');

// Public routes (no authentication required)
router.post('/login', authController.login);
router.post('/refresh', authController.refreshToken);

// Protected routes (require authentication)
router.post('/logout', authenticateUser, authController.logout);
router.get('/verify', authenticateUser, authController.verifyTokenEndpoint);

module.exports = router;
