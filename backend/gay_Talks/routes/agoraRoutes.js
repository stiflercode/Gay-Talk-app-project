const express = require('express');
const router = express.Router();
const agoraController = require('../controllers/agoraController');
const { authenticateUser } = require('../middleware/auth');

// Agora token generation requires authentication
router.post('/rtm-token', authenticateUser, agoraController.generateRtmToken);
router.post('/rtc-token', authenticateUser, agoraController.generateRtcToken);

module.exports = router;
