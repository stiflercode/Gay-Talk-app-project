const express = require('express');
const router = express.Router();
const callController = require('../controllers/callController');

router.post('/route', callController.getRouting);
router.post('/next', callController.getNextAdmin);
router.post('/update', callController.updateStatus);

module.exports = router;
