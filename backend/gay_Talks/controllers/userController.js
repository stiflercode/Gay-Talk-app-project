const User = require('../models/User');

// Create or update user
exports.createOrUpdateUser = async (req, res) => {
    try {
        const { uid, email, displayName, role, fcmToken, name, age, gender, phone, username, profileComplete, isOnline } = req.body;

        const updateData = {
            email,
            lastSeen: new Date()
        };

        // Only set fields that are provided
        if (displayName !== undefined) updateData.displayName = displayName;
        if (name !== undefined) updateData.name = name;
        if (name !== undefined) updateData.displayName = name; // Sync displayName with name
        if (age !== undefined) updateData.age = age;
        if (gender !== undefined) updateData.gender = gender;
        if (username !== undefined) updateData.username = username;
        if (role !== undefined && role !== null) updateData.role = role;
        if (fcmToken !== undefined) updateData.fcmToken = fcmToken;
        if (profileComplete !== undefined) updateData.profileComplete = profileComplete;
        if (req.body.language !== undefined) updateData.language = req.body.language;
        if (req.body.isOnline !== undefined) updateData.isOnline = req.body.isOnline;

        // If role is provided in updateData, don't set it in $setOnInsert
        const setOnInsert = {
            walletBalance: 0
        };

        if (role === undefined || role === null) {
            setOnInsert.role = 'user';
        }

        // Use $setOnInsert to set defaults only when creating new documents
        let user = await User.findOneAndUpdate(
            { uid },
            {
                $set: updateData,
                $setOnInsert: setOnInsert
            },
            { new: true, upsert: true }
        );

        console.log(`✅ User created/updated in DB: ${uid}`);
        if (require('mongoose').connection.readyState === 1) {
            console.log('📊 Active DB:', require('mongoose').connection.name);
        }
        res.json({ success: true, user });
    } catch (error) {
        console.error('User update error:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
};

// Get user by UID
exports.getUser = async (req, res) => {
    try {
        const mongoose = require('mongoose');
        if (mongoose.connection.readyState !== 1) {
            console.warn('⚠️  MONGODB NOT CONNECTED: Returning Mock user info');
            return res.json({
                exists: true,
                user: {
                    uid: req.params.uid,
                    email: 'dev@example.com',
                    displayName: 'Developer User',
                    role: 'user',
                    walletBalance: 100,
                    profileComplete: false
                }
            });
        }

        const user = await User.findOne({ uid: req.params.uid });
        if (!user) {
            return res.json({ exists: false, user: null });
        }
        res.json({ exists: true, user });
    } catch (error) {
        console.error('Get user error:', error);
        res.status(500).json({ error: 'Failed to fetch user' });
    }
};

// Get user role
exports.getUserRole = async (req, res) => {
    try {
        const mongoose = require('mongoose');
        if (mongoose.connection.readyState !== 1) {
            return res.json({ role: 'user' });
        }

        const user = await User.findOne({ uid: req.params.uid });
        res.json({ role: user ? user.role : 'user' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch role' });
    }
};

// Get users by role
exports.getUsersByRole = async (req, res) => {
    try {
        const mongoose = require('mongoose');
        if (mongoose.connection.readyState !== 1) {
            console.warn('⚠️  MONGODB NOT CONNECTED: Returning Mock user list');
            return res.json([
                { uid: 'admin_1', displayName: 'Mock Admin 1', role: 'admin', isOnline: true },
                { uid: 'admin_2', displayName: 'Mock Admin 2', role: 'admin', isOnline: false },
            ]);
        }

        const { role, excludeUid } = req.query;
        let query = {};
        if (role) query.role = role;
        if (excludeUid) query.uid = { $ne: excludeUid };

        const users = await User.find(query);
        res.json(users);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch users' });
    }
};

// Update user profile (language, name, etc.)
exports.updateProfile = async (req, res) => {
    try {
        const { uid, language, displayName, profileComplete } = req.body;

        const mongoose = require('mongoose');
        if (mongoose.connection.readyState !== 1) {
            console.warn('⚠️  MONGODB NOT CONNECTED: Mocking profile update');
            return res.json({
                success: true,
                user: { uid, language, displayName, profileComplete }
            });
        }

        const updateData = {};
        if (language !== undefined) updateData.language = language;
        if (displayName !== undefined) updateData.displayName = displayName;
        if (profileComplete !== undefined) updateData.profileComplete = profileComplete;
        updateData.lastSeen = new Date();

        const user = await User.findOneAndUpdate(
            { uid },
            updateData,
            { new: true, upsert: true }
        );

        console.log(`✅ Profile updated in DB for uid: ${uid}`);
        if (require('mongoose').connection.readyState === 1) {
            console.log('📊 Active DB:', require('mongoose').connection.name);
        }
        res.json({ success: true, user });
    } catch (error) {
        console.error('Profile update error:', error);
        res.status(500).json({ error: 'Failed to update profile' });
    }
};

// Update wallet balance
exports.updateWallet = async (req, res) => {
    try {
        // Use authenticated user ID from token (not from request body)
        const uid = req.user.uid;
        const { amount, operation } = req.body;
        // operation: 'add', 'subtract', or 'set'

        const user = await User.findOne({ uid });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        let newBalance = user.walletBalance || 0;

        if (operation === 'add') {
            newBalance += amount;
        } else if (operation === 'subtract') {
            newBalance -= amount;
            if (newBalance < 0) newBalance = 0;
        } else if (operation === 'set') {
            // Only allow 'set' operation for admin users
            // For now, we'll disable it for security
            return res.status(403).json({ error: 'Set operation not allowed' });
        }

        user.walletBalance = newBalance;
        await user.save();

        console.log(`💰 Wallet updated for ${uid}: ${operation} ${amount} = ${newBalance}`);

        res.json({ success: true, walletBalance: newBalance });
    } catch (error) {
        console.error('Wallet update error:', error);
        res.status(500).json({ error: 'Failed to update wallet' });
    }
};

// Get masked listeners (virtual identities that users see)
// These are NOT real admin accounts - they are fictional identities
// Calls to any masked listener are routed to available real admins
const AdminGroup = require('../models/AdminGroup');

exports.getMaskedListeners = async (req, res) => {
    try {
        const mongoose = require('mongoose');

        // Find the default admin group
        const group = await AdminGroup.findOne({ groupId: 'default' });

        if (!group) {
            // Return default masked listeners if no group configured
            return res.json([
                {
                    maskId: 'listener_1',
                    uid: 'listener_1', // For compatibility with frontend
                    id: 'listener_1',
                    displayName: 'Listener 1',
                    name: 'Listener 1',
                    languages: ['English', 'Hindi'],
                    rating: 4.9,
                    coinsPerMin: 5,
                    isOnline: true,
                    isMasked: true // Flag to indicate this is a masked identity
                }
            ]);
        }

        // Check if any real admins are online
        const onlineAdmins = await User.find({
            uid: { $in: group.adminIds },
            isOnline: true
        });
        const hasOnlineAdmin = onlineAdmins.length > 0;

        // If no masked listeners configured, create default ones
        if (!group.maskedListeners || group.maskedListeners.length === 0) {
            const defaultListeners = [
                {
                    maskId: 'listener_1',
                    uid: 'listener_1',
                    id: 'listener_1',
                    displayName: 'Listener 1',
                    name: 'Listener 1',
                    languages: ['English', 'Hindi'],
                    rating: 4.9,
                    coinsPerMin: 5,
                    isOnline: hasOnlineAdmin, // Show online if any admin is online
                    isMasked: true
                }
            ];
            return res.json(defaultListeners);
        }

        // Return configured masked listeners
        const maskedListeners = group.maskedListeners
            .filter(listener => listener.isActive !== false)
            .map(listener => ({
                maskId: listener.maskId,
                uid: listener.maskId, // For frontend compatibility
                id: listener.maskId,
                displayName: listener.displayName,
                name: listener.displayName,
                languages: listener.languages || ['English'],
                rating: listener.rating || 4.8,
                coinsPerMin: listener.coinsPerMin || 5,
                isOnline: hasOnlineAdmin, // All masked listeners show online if any admin is online
                isMasked: true
            }));

        console.log(`📋 Returning ${maskedListeners.length} masked listeners (${onlineAdmins.length} real admins online)`);
        res.json(maskedListeners);

    } catch (error) {
        console.error('Get masked listeners error:', error);
        res.status(500).json({ error: 'Failed to fetch listeners' });
    }
};

// Admin endpoint: Create or update masked listeners
exports.updateMaskedListeners = async (req, res) => {
    try {
        const { listeners } = req.body;

        // Validate that caller is admin
        const callerUser = await User.findOne({ uid: req.user.uid });
        if (!callerUser || callerUser.role !== 'admin') {
            return res.status(403).json({ error: 'Admin access required' });
        }

        // Find or create the default admin group
        let group = await AdminGroup.findOne({ groupId: 'default' });

        if (!group) {
            group = new AdminGroup({
                groupId: 'default',
                name: 'Main Hunt Group',
                adminIds: [req.user.uid],
                maskedListeners: []
            });
        }

        // Update masked listeners
        group.maskedListeners = listeners.map((l, index) => ({
            maskId: l.maskId || `listener_${index + 1}`,
            displayName: l.displayName || `Listener ${index + 1}`,
            languages: l.languages || ['English'],
            rating: l.rating || 4.8,
            coinsPerMin: l.coinsPerMin || 5,
            isActive: l.isActive !== false
        }));

        await group.save();

        console.log(`✅ Updated ${group.maskedListeners.length} masked listeners`);
        res.json({ success: true, maskedListeners: group.maskedListeners });

    } catch (error) {
        console.error('Update masked listeners error:', error);
        res.status(500).json({ error: 'Failed to update listeners' });
    }
};
