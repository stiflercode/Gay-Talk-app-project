const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { authenticateUser } = require('../middleware/auth');

// All user routes require authentication
router.post('/update', authenticateUser, userController.createOrUpdateUser);
router.post('/profile', authenticateUser, userController.updateProfile);
router.post('/wallet', authenticateUser, userController.updateWallet);
router.get('/list', authenticateUser, userController.getUsersByRole);
router.get('/role/:uid', authenticateUser, userController.getUserRole);

// Masked listeners - virtual identities for Hunt Group feature
router.get('/masked-listeners', authenticateUser, userController.getMaskedListeners);
router.post('/masked-listeners', authenticateUser, userController.updateMaskedListeners);

router.get('/:uid', authenticateUser, userController.getUser); // This must be LAST (catches all)

module.exports = router;
