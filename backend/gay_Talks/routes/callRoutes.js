const express = require('express');
const router = express.Router();
const callController = require('../controllers/callController');
const { authenticateUser } = require('../middleware/auth');

// All call routes require authentication
router.post('/route', authenticateUser, callController.getRouting);
router.post('/next', authenticateUser, callController.getNextAdmin);
router.post('/update', authenticateUser, callController.updateStatus);

module.exports = router;
