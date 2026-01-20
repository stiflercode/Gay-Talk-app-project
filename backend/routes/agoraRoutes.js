const express = require('express');
const router = express.Router();
const agoraController = require('../controllers/agoraController');

router.post('/rtm-token', agoraController.generateRtmToken);
router.post('/rtc-token', agoraController.generateRtcToken);

module.exports = router;
