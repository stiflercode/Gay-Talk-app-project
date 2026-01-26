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
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] 📡 ${req.method} ${req.url}`);
    if (req.method === 'POST' || req.method === 'PUT') {
        console.log('📦 Body:', JSON.stringify(req.body, null, 2));
    }
    next();
});

// Firebase Admin Setup
try {
    const serviceAccountPath = './firebase-service-account.json';
    const fs = require('fs');

    if (fs.existsSync(serviceAccountPath)) {
        const serviceAccount = require(serviceAccountPath);

        // Fix for potential newline issues in private key
        if (serviceAccount.private_key && typeof serviceAccount.private_key === 'string') {
            serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
        }

        console.log('📂 Service Account loaded for project:', serviceAccount.project_id);
        console.log('🕒 Current Server Time:', new Date().toISOString());

        // Check if year is potentially wrong (e.g., 2026 instead of 2025/2024)
        const currentYear = new Date().getFullYear();
        if (currentYear > 2025) {
            console.error('\n' + '!'.repeat(60));
            console.error('🚨 CRITICAL ERROR: YOUR SYSTEM CLOCK IS WRONG! 🚨');
            console.error(`Current Year is ${currentYear}. Firebase will REJECT all requests.`);
            console.error('Please set your computer date to the CURRENT date/time.');
            console.error('!'.repeat(60) + '\n');
        }

        console.log('🔑 Private Key exists:', !!serviceAccount.private_key);

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
    console.log('🌍 Root endpoint hit!');
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
