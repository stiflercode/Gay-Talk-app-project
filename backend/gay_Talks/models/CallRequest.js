const mongoose = require('mongoose');

const CallRequestSchema = new mongoose.Schema({
    callerId: {
        type: String,
        required: true
    },
    callerName: String,
    // The admin we are CURRENTLY trying to ring
    currentAdminId: String,
    // The original admin intended (for UI masking)
    originalAdminId: String,

    // Track which admins have already been tried/rejected for this call session
    attemptedAdminIds: [String],

    status: {
        type: String,
        enum: ['pending', 'ringing', 'accepted', 'rejected', 'completed', 'cancelled', 'failed'],
        default: 'pending'
    },

    channelName: String,
    coinsPerMin: {
        type: Number,
        default: 5
    },
    startedAt: Date,
    endedAt: Date,
    durationSeconds: Number,
    coinsCharged: Number,
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('CallRequest', CallRequestSchema);
