const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Fixed routes - specific paths first, parameterized routes last
router.post('/update', userController.createOrUpdateUser);
router.post('/profile', userController.updateProfile);
router.post('/wallet', userController.updateWallet);
router.get('/list', userController.getUsersByRole);
router.get('/role/:uid', userController.getUserRole);
router.get('/:uid', userController.getUser); // This must be LAST (catches all)

module.exports = router;
