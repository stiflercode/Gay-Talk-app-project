const admin = require('firebase-admin');
const { verifyToken, extractToken } = require('../utils/jwtUtils');
const User = require('../models/User');

/**
 * Authentication middleware to verify JWT tokens (NEW SYSTEM)
 * Extracts and verifies the JWT token from Authorization header
 * Attaches verified user info to req.user
 */
async function authenticateUser(req, res, next) {
    try {
        // Extract token from Authorization header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'No authentication token provided',
                code: 'NO_TOKEN'
            });
        }

        const token = extractToken(authHeader);

        if (!token) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Invalid token format',
                code: 'INVALID_FORMAT'
            });
        }

        // Verify JWT token
        let decoded;
        try {
            decoded = verifyToken(token);
        } catch (error) {
            if (error.message === 'TOKEN_EXPIRED') {
                return res.status(401).json({
                    error: 'Unauthorized',
                    message: 'Token expired. Please refresh your token.',
                    code: 'TOKEN_EXPIRED'
                });
            } else if (error.message === 'INVALID_TOKEN') {
                return res.status(401).json({
                    error: 'Unauthorized',
                    message: 'Invalid token',
                    code: 'INVALID_TOKEN'
                });
            } else {
                return res.status(401).json({
                    error: 'Unauthorized',
                    message: 'Authentication failed',
                    code: 'AUTH_FAILED'
                });
            }
        }

        // Check if it's an access token (not refresh token)
        if (decoded.type !== 'access') {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Invalid token type',
                code: 'INVALID_TOKEN_TYPE'
            });
        }

        // Get user from database to ensure they still exist
        let user;
        const mongoose = require('mongoose');
        if (mongoose.connection.readyState !== 1) {
            console.warn('⚠️  MONGODB NOT CONNECTED: Using Mock User in middleware');
            // Create a temporary mock user from the token info
            user = {
                uid: decoded.uid,
                email: decoded.email,
                displayName: decoded.displayName,
                role: decoded.role || 'user',
                photoURL: decoded.photoURL
            };
        } else {
            user = await User.findOne({ uid: decoded.uid });
        }

        if (!user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'User not found',
                code: 'USER_NOT_FOUND'
            });
        }

        // Attach verified user info to request
        req.user = {
            uid: user.uid,
            email: user.email,
            emailVerified: user.emailVerified,
            displayName: user.displayName,
            role: user.role,
            photoURL: user.photoURL
        };

        console.log(`✅ Authenticated user: ${req.user.uid} (${req.user.email})`);

        // Continue to next middleware/controller
        next();

    } catch (error) {
        console.error('❌ Authentication error:', error.message);

        return res.status(401).json({
            error: 'Unauthorized',
            message: 'Authentication failed',
            code: 'AUTH_FAILED'
        });
    }
}

/**
 * LEGACY: Firebase Authentication middleware (DEPRECATED - for backward compatibility only)
 * This should be removed once all clients are updated to use JWT
 */
async function authenticateUserFirebase(req, res, next) {
    try {
        // Extract token from Authorization header
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'No authentication token provided'
            });
        }

        const token = authHeader.split('Bearer ')[1];

        if (!token) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Invalid token format'
            });
        }

        // Verify token with Firebase Admin SDK
        const decodedToken = await admin.auth().verifyIdToken(token);

        // Attach verified user info to request
        req.user = {
            uid: decodedToken.uid,
            email: decodedToken.email,
            emailVerified: decodedToken.email_verified,
            name: decodedToken.name,
            picture: decodedToken.picture
        };

        console.log(`✅ Authenticated user (Firebase): ${req.user.uid} (${req.user.email})`);

        // Continue to next middleware/controller
        next();

    } catch (error) {
        console.error('❌ Firebase Authentication error:', error.message);

        if (error.code === 'auth/id-token-expired') {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Token expired. Please login again.',
                code: 'TOKEN_EXPIRED'
            });
        }

        if (error.code === 'auth/argument-error') {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Invalid token format',
                code: 'INVALID_TOKEN'
            });
        }

        return res.status(401).json({
            error: 'Unauthorized',
            message: 'Authentication failed',
            code: 'AUTH_FAILED'
        });
    }
}

/**
 * Optional authentication middleware
 * Verifies token if present, but allows request to continue if not
 * Useful for endpoints that have different behavior for authenticated vs anonymous users
 */
async function optionalAuth(req, res, next) {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            // No token provided, continue without user info
            req.user = null;
            return next();
        }

        const token = extractToken(authHeader);

        if (!token) {
            req.user = null;
            return next();
        }

        // Try to verify JWT token
        try {
            const decoded = verifyToken(token);

            if (decoded.type === 'access') {
                const user = await User.findOne({ uid: decoded.uid });

                if (user) {
                    req.user = {
                        uid: user.uid,
                        email: user.email,
                        emailVerified: user.emailVerified,
                        displayName: user.displayName,
                        role: user.role,
                        photoURL: user.photoURL
                    };
                } else {
                    req.user = null;
                }
            } else {
                req.user = null;
            }
        } catch (error) {
            // Token verification failed, continue without user info
            req.user = null;
        }

        next();
    } catch (error) {
        // Any error, continue without user info
        req.user = null;
        next();
    }
}

module.exports = {
    authenticateUser,
    authenticateUserFirebase, // DEPRECATED - for backward compatibility
    optionalAuth
};
