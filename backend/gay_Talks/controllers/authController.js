const admin = require('firebase-admin');
const mongoose = require('mongoose');
const User = require('../models/User');
const { generateAccessToken, generateRefreshToken, verifyToken } = require('../utils/jwtUtils');

/**
 * Login endpoint - Verifies Firebase ID token and returns JWT tokens
 * POST /api/auth/login
 * Body: { firebaseToken: string, fcmToken?: string }
 */
exports.login = async (req, res) => {
    try {
        console.log('📡 Incoming login request...');
        const { firebaseToken, fcmToken } = req.body;

        if (!firebaseToken) {
            return res.status(400).json({
                success: false,
                error: 'MISSING_TOKEN',
                message: 'Firebase ID token is required'
            });
        }

        // Verify Firebase ID token
        let decodedToken;
        try {
            if (!admin.apps.length) {
                console.warn('⚠️  FIREBASE NOT INITIALIZED: Using Mock Login for development');
                // Mock decoded token for development
                decodedToken = {
                    uid: 'DEV_USER_' + Date.now(),
                    email: 'dev@example.com',
                    email_verified: true,
                    name: 'Developer User',
                    picture: 'https://via.placeholder.com/150'
                };
            } else {
                decodedToken = await admin.auth().verifyIdToken(firebaseToken);
            }
        } catch (error) {
            console.error('❌ Firebase token verification failed:', error.message);
            return res.status(401).json({
                success: false,
                error: 'INVALID_FIREBASE_TOKEN',
                message: 'Invalid or expired Firebase token'
            });
        }

        // Extract user info from Firebase token
        const { uid, email, email_verified, name, picture } = decodedToken;

        // Create or update user in MongoDB
        let user;
        if (mongoose.connection.readyState !== 1) {
            console.warn('⚠️  MONGODB NOT CONNECTED: Using Mock User storage');
            user = {
                uid: decodedToken.uid,
                email: decodedToken.email,
                displayName: decodedToken.name,
                photoURL: decodedToken.picture,
                role: 'user',
                walletBalance: 100, // Give some free coins for testing
                profileComplete: false,
                language: '',
                save: async () => { } // Dummy save
            };
        } else {
            const updateData = {
                email,
                emailVerified: email_verified,
                lastSeen: new Date()
            };

            if (name) updateData.displayName = name;
            if (picture) updateData.photoURL = picture;
            if (fcmToken) updateData.fcmToken = fcmToken;

            // Use findOneAndUpdate with upsert to create or update user
            user = await User.findOneAndUpdate(
                { uid },
                {
                    $set: updateData,
                    $setOnInsert: {
                        role: 'user',
                        walletBalance: 0,
                        createdAt: new Date()
                    }
                },
                {
                    new: true,
                    upsert: true,
                    runValidators: true
                }
            );
        }

        // Generate JWT tokens
        const accessToken = generateAccessToken(user);
        const refreshToken = generateRefreshToken(user);

        // Update user's refresh token in database (for token revocation if needed)
        user.refreshToken = refreshToken;
        await user.save();

        console.log(`✅ User logged in and saved to DB: ${uid} (${email})`);
        if (mongoose.connection.readyState === 1) {
            console.log('📊 Active DB:', mongoose.connection.name);
            console.log('📊 Collection:', User.collection.name);
        }

        // Return tokens and user info
        res.json({
            success: true,
            message: 'Login successful',
            data: {
                accessToken,
                refreshToken,
                user: {
                    uid: user.uid,
                    email: user.email,
                    displayName: user.displayName,
                    role: user.role,
                    walletBalance: user.walletBalance,
                    profileComplete: user.profileComplete,
                    language: user.language,
                    photoURL: user.photoURL
                }
            }
        });

    } catch (error) {
        console.error('❌ Login error:', error);
        res.status(500).json({
            success: false,
            error: 'LOGIN_FAILED',
            message: 'An error occurred during login'
        });
    }
};

/**
 * Refresh token endpoint - Issues new access token using refresh token
 * POST /api/auth/refresh
 * Body: { refreshToken: string }
 */
exports.refreshToken = async (req, res) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({
                success: false,
                error: 'MISSING_TOKEN',
                message: 'Refresh token is required'
            });
        }

        // Verify refresh token
        let decoded;
        try {
            decoded = verifyToken(refreshToken);
        } catch (error) {
            return res.status(401).json({
                success: false,
                error: error.message,
                message: 'Invalid or expired refresh token'
            });
        }

        // Check if it's a refresh token
        if (decoded.type !== 'refresh') {
            return res.status(401).json({
                success: false,
                error: 'INVALID_TOKEN_TYPE',
                message: 'Token is not a refresh token'
            });
        }

        // Get user from database
        const user = await User.findOne({ uid: decoded.uid });

        if (!user) {
            return res.status(404).json({
                success: false,
                error: 'USER_NOT_FOUND',
                message: 'User not found'
            });
        }

        // Verify refresh token matches the one stored in database
        if (user.refreshToken !== refreshToken) {
            return res.status(401).json({
                success: false,
                error: 'TOKEN_REVOKED',
                message: 'Refresh token has been revoked'
            });
        }

        // Generate new access token
        const newAccessToken = generateAccessToken(user);

        console.log(`✅ Token refreshed for user: ${user.uid}`);

        res.json({
            success: true,
            message: 'Token refreshed successfully',
            data: {
                accessToken: newAccessToken
            }
        });

    } catch (error) {
        console.error('❌ Token refresh error:', error);
        res.status(500).json({
            success: false,
            error: 'REFRESH_FAILED',
            message: 'An error occurred during token refresh'
        });
    }
};

/**
 * Logout endpoint - Revokes refresh token
 * POST /api/auth/logout
 * Headers: Authorization: Bearer <access-token>
 */
exports.logout = async (req, res) => {
    try {
        // req.user is set by authenticateUser middleware
        const uid = req.user.uid;

        // Clear refresh token from database
        await User.findOneAndUpdate(
            { uid },
            { $unset: { refreshToken: 1 } }
        );

        console.log(`✅ User logged out: ${uid}`);

        res.json({
            success: true,
            message: 'Logout successful'
        });

    } catch (error) {
        console.error('❌ Logout error:', error);
        res.status(500).json({
            success: false,
            error: 'LOGOUT_FAILED',
            message: 'An error occurred during logout'
        });
    }
};

/**
 * Verify token endpoint - Checks if access token is valid
 * GET /api/auth/verify
 * Headers: Authorization: Bearer <access-token>
 */
exports.verifyTokenEndpoint = async (req, res) => {
    // If we reach here, the token is valid (middleware already verified it)
    res.json({
        success: true,
        message: 'Token is valid',
        data: {
            user: req.user
        }
    });
};
