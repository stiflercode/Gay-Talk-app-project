const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
    uid: {
        type: String,
        required: true,
        unique: true
    },
    email: String,
    displayName: String,
    name: String,
    age: Number,
    gender: String,
    phone: String,
    username: String,
    role: {
        type: String,
        enum: ['user', 'admin'],
        default: 'user'
    },
    walletBalance: {
        type: Number,
        default: 0
    },
    fcmToken: String,
    primaryAdminGroupId: {
        type: String, // Refers to AdminGroup.groupId
        default: 'default'
    },
    // Status tracking for admins
    isOnline: {
        type: Boolean,
        default: false
    },
    isBusy: {
        type: Boolean,
        default: false
    },
    language: {
        type: String,
        default: ''
    },
    profileComplete: {
        type: Boolean,
        default: false
    },
    lastSeen: Date,
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('User', UserSchema);
