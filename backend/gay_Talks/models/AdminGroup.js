const mongoose = require('mongoose');

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
    // We can add time-based routing rules here later
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('AdminGroup', AdminGroupSchema);
