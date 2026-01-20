const AdminGroup = require('../models/AdminGroup');
const User = require('../models/User');
const CallRequest = require('../models/CallRequest');
// const admin = require('firebase-admin'); // For FCM

// 1. Get Primary Routing
// returns: { adminId: "uid", callId: "new_id" }
exports.getRouting = async (req, res) => {
    try {
        const { userId, callerName } = req.body;

        // Find the default admin group
        const group = await AdminGroup.findOne({ groupId: 'default' });

        if (!group || group.adminIds.length === 0) {
            return res.status(404).json({ error: 'No admin group configured' });
        }

        // Find admins who are actually online
        const onlineAdmins = await User.find({
            uid: { $in: group.adminIds },
            isOnline: true
        });

        let primaryAdminId;

        if (onlineAdmins.length > 0) {
            // Pick the first online admin
            // In future: Round-robin or least-busy logic
            primaryAdminId = onlineAdmins[0].uid;
            console.log(`Routing call to ONLINE admin: ${primaryAdminId}`);
        } else {
            // Fallback: Pick first admin even if offline (so caller gets "offline" error fast)
            primaryAdminId = group.adminIds[0];
            console.warn(`No online admins found. Fallback to: ${primaryAdminId}`);
        }

        // Create a call record
        const callRequest = new CallRequest({
            callerId: userId,
            callerName: callerName,
            currentAdminId: primaryAdminId,
            originalAdminId: primaryAdminId, // Keep this constant for UI
            attemptedAdminIds: [primaryAdminId],
            status: 'ringing',
            channelName: `channel_${userId}`,
            coinsPerMin: 5 // Default for now
        });

        await callRequest.save();

        res.json({
            success: true,
            callId: callRequest._id,
            adminId: primaryAdminId,
            originalAdminId: primaryAdminId,
            channelName: callRequest.channelName,
            coinsPerMin: 5,
            message: 'Calling primary admin'
        });

    } catch (error) {
        console.error('Routing Error:', error);
        res.status(500).json({ error: 'Failed to route call' });
    }
};

// 2. Failover logic
// Request: { callId: "...", failedAdminId: "..." }
// Response: { nextAdminId: "..." } or { error: "No admins available" }
exports.getNextAdmin = async (req, res) => {
    try {
        const { callId, failedAdminId } = req.body;

        const call = await CallRequest.findById(callId);
        if (!call) return res.status(404).json({ error: 'Call not found' });

        // Mark current attempt as rejected/failed? 
        // Actually, simply adding to attempted list is enough
        if (!call.attemptedAdminIds.includes(failedAdminId)) {
            call.attemptedAdminIds.push(failedAdminId);
        }

        // Get the Admin Group
        const group = await AdminGroup.findOne({ groupId: 'default' });
        const allAdmins = group.adminIds;

        // Find first admin NOT in attemptedAdminIds AND is ONLINE
        const remainingAdminIds = allAdmins.filter(id => !call.attemptedAdminIds.includes(id));

        const onlineAdmins = await User.find({
            uid: { $in: remainingAdminIds },
            isOnline: true
        });

        let nextAdminId;

        if (onlineAdmins.length > 0) {
            nextAdminId = onlineAdmins[0].uid;
        } else {
            // If no online admins left, pick first unattempted one
            nextAdminId = remainingAdminIds.length > 0 ? remainingAdminIds[0] : null;
        }

        if (!nextAdminId) {
            call.status = 'failed';
            await call.save();
            return res.status(404).json({
                error: 'No available admins',
                code: 'BUSY_ALL'
            });
        }

        // Update call request
        call.currentAdminId = nextAdminId;
        await call.save();

        res.json({
            success: true,
            nextAdminId: nextAdminId,
            originalAdminId: call.originalAdminId, // Remind UI to keep showing original
            message: 'Rolling over to next admin'
        });

    } catch (error) {
        console.error('Failover Error:', error);
        res.status(500).json({ error: 'Failover failed' });
    }
};

// 3. Update Call Status
exports.updateStatus = async (req, res) => {
    try {
        const { callId, status, durationSeconds, coinsCharged } = req.body;

        const updateData = { status };
        if (status === 'accepted') updateData.startedAt = new Date();
        if (status === 'completed' || status === 'cancelled' || status === 'rejected') {
            updateData.endedAt = new Date();
            if (durationSeconds) updateData.durationSeconds = durationSeconds;
            if (coinsCharged) updateData.coinsCharged = coinsCharged;
        }

        const call = await CallRequest.findByIdAndUpdate(callId, updateData, { new: true });

        if (!call) return res.status(404).json({ error: 'Call not found' });

        res.json({ success: true, call });
    } catch (error) {
        console.error('Update Status Error:', error);
        res.status(500).json({ error: 'Failed to update status' });
    }
};
