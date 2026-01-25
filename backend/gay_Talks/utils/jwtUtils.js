const jwt = require('jsonwebtoken');

// JWT Secret - In production, use environment variable
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production';
const JWT_EXPIRES_IN = '7d'; // Token expires in 7 days
const REFRESH_TOKEN_EXPIRES_IN = '30d'; // Refresh token expires in 30 days

/**
 * Generate JWT access token for authenticated user
 * @param {Object} user - User object from MongoDB
 * @returns {string} JWT token
 */
function generateAccessToken(user) {
    const payload = {
        uid: user.uid,
        email: user.email,
        role: user.role || 'user',
        type: 'access'
    };

    return jwt.sign(payload, JWT_SECRET, {
        expiresIn: JWT_EXPIRES_IN,
        issuer: 'gaytalk-backend',
        subject: user.uid
    });
}

/**
 * Generate JWT refresh token for token renewal
 * @param {Object} user - User object from MongoDB
 * @returns {string} Refresh token
 */
function generateRefreshToken(user) {
    const payload = {
        uid: user.uid,
        type: 'refresh'
    };

    return jwt.sign(payload, JWT_SECRET, {
        expiresIn: REFRESH_TOKEN_EXPIRES_IN,
        issuer: 'gaytalk-backend',
        subject: user.uid
    });
}

/**
 * Verify and decode JWT token
 * @param {string} token - JWT token to verify
 * @returns {Object} Decoded token payload
 * @throws {Error} If token is invalid or expired
 */
function verifyToken(token) {
    try {
        return jwt.verify(token, JWT_SECRET, {
            issuer: 'gaytalk-backend'
        });
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            throw new Error('TOKEN_EXPIRED');
        } else if (error.name === 'JsonWebTokenError') {
            throw new Error('INVALID_TOKEN');
        } else {
            throw new Error('TOKEN_VERIFICATION_FAILED');
        }
    }
}

/**
 * Extract token from Authorization header
 * @param {string} authHeader - Authorization header value
 * @returns {string|null} Extracted token or null
 */
function extractToken(authHeader) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return null;
    }
    return authHeader.split('Bearer ')[1];
}

module.exports = {
    generateAccessToken,
    generateRefreshToken,
    verifyToken,
    extractToken,
    JWT_SECRET
};
