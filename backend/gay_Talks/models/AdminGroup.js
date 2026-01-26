const mongoose = require('mongoose');

// Schema for masked listener identities (what users see)
const MaskedListenerSchema = new mongoose.Schema({
    maskId: {
        type: String,
        required: true
    },
    displayName: {
        type: String,
        required: true,
        default: 'Listener'
    },
    languages: [{
        type: String,
        default: 'English'
    }],
    rating: {
        type: Number,
        default: 4.8
    },
    coinsPerMin: {
        type: Number,
        default: 5
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, { _id: false });

const AdminGroupSchema = new mongoose.Schema({
    groupId: {
        type: String,
        required: true,
        unique: true,
        default: 'default' // Since the user said "same for everyone", we can use a default ID.
    },
    name: {
        type: String,
        default: 'Main Hunt Group'
    },
    adminIds: [{
        type: String, // Storing Firebase UIDs of admins in order of priority
        required: true
    }],
    // Masked listeners - virtual identities that users see
    // Calls to any masked listener are routed to available admins in adminIds
    maskedListeners: [MaskedListenerSchema],
    // We can add time-based routing rules here later
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('AdminGroup', AdminGroupSchema);
