require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Request Logging Middleware
app.use((req, res, next) => {
    console.log(`📡 ${req.method} ${req.url}`);
    if (req.method === 'POST') {
        console.log('📦 Body keys:', Object.keys(req.body));
    }
    next();
});

// Firebase Admin Setup
try {
    const serviceAccountPath = './firebase-service-account.json';
    const fs = require('fs');

    if (fs.existsSync(serviceAccountPath)) {
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id || 'gey-talk'
        });
        console.log('✅ Firebase Admin SDK initialized');
    } else {
        console.warn('⚠️  firebase-service-account.json not found!');
        console.warn('⚠️  Authentication features will not work.');
    }
} catch (error) {
    console.error('❌ Firebase Admin SDK initialization error:', error.message);
}

// Database Connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/gaytalk';

mongoose.connect(MONGODB_URI)
    .then(() => console.log('✅ MongoDB Connected'))
    .catch(err => console.error('❌ MongoDB Connection Error:', err));

// Routes
app.get('/', (req, res) => {
    res.send('GayTalk Backend is Running');
});

// Health check endpoint
app.get('/health', (req, res) => {
    const health = {
        status: 'OK',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        services: {
            firebase: admin.apps.length > 0 ? 'connected' : 'disconnected',
            mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
        },
        version: '1.0.0'
    };

    const httpStatus = health.services.mongodb === 'connected' ? 200 : 503;
    res.status(httpStatus).json(health);
});

// Import Routes
const authRoutes = require('./routes/authRoutes');
const callRoutes = require('./routes/callRoutes');
const userRoutes = require('./routes/userRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const agoraRoutes = require('./routes/agoraRoutes');
app.use('/api/auth', authRoutes);
app.use('/api/call', callRoutes);
app.use('/api/user', userRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/agora', agoraRoutes);

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
