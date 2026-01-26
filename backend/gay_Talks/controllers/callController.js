const AdminGroup = require('../models/AdminGroup');
const User = require('../models/User');
const CallRequest = require('../models/CallRequest');
// const admin = require('firebase-admin'); // For FCM

// 1. Get Primary Routing
// Request: { callerName: "...", maskedListenerId: "listener_1" (optional) }
// returns: { adminId: "uid", callId: "new_id", maskedListenerId: "...", maskedListenerName: "..." }
exports.getRouting = async (req, res) => {
    try {
        // Use authenticated user ID from token
        const userId = req.user.uid;
        const { callerName, maskedListenerId } = req.body;

        // Find the default admin group
        const group = await AdminGroup.findOne({ groupId: 'default' });

        if (!group || group.adminIds.length === 0) {
            return res.status(404).json({ error: 'No admin group configured' });
        }

        // Get the masked listener info (for UI display on user side)
        let maskedListenerName = 'Listener';
        let maskedCoinsPerMin = 5;
        if (maskedListenerId && group.maskedListeners && group.maskedListeners.length > 0) {
            const maskedListener = group.maskedListeners.find(l => l.maskId === maskedListenerId);
            if (maskedListener) {
                maskedListenerName = maskedListener.displayName || 'Listener';
                maskedCoinsPerMin = maskedListener.coinsPerMin || 5;
            }
        }

        // Find admins who are actually online AND not busy
        const onlineAdmins = await User.find({
            uid: { $in: group.adminIds },
            isOnline: true,
            isBusy: { $ne: true } // Exclude busy admins
        });

        let primaryAdminId;

        if (onlineAdmins.length > 0) {
            // Pick the first available online admin
            primaryAdminId = onlineAdmins[0].uid;
            console.log(`✅ FOUND ONLINE ADMIN: ${primaryAdminId} (masked as: ${maskedListenerName})`);
        } else {
            // Fallback: Pick first admin even if offline 
            primaryAdminId = group.adminIds[0];
            console.warn(`⚠️ NO ONLINE ADMINS FOUND! Fallback to: ${primaryAdminId}`);
        }

        // Create a call record
        const callRequest = new CallRequest({
            callerId: userId,
            callerName: callerName,
            currentAdminId: primaryAdminId,
            originalAdminId: primaryAdminId, // Keep this constant for UI
            maskedListenerId: maskedListenerId || 'listener_1', // The virtual identity user sees
            maskedListenerName: maskedListenerName, // Display name of masked listener
            attemptedAdminIds: [primaryAdminId],
            status: 'ringing',
            channelName: `channel_${userId}`,
            coinsPerMin: maskedCoinsPerMin // Use masked listener's rate
        });

        await callRequest.save();

        console.log(`📞 Call initiated by ${userId} to admin ${primaryAdminId}`);

        // 🔔 Send FCM push notification to admin
        try {
            console.log(`🔔 Attempting to send FCM to admin: ${primaryAdminId}`);
            const adminUser = await User.findOne({ uid: primaryAdminId });

            if (!adminUser) {
                console.error(`❌ Admin user ${primaryAdminId} not found in database!`);
            } else if (!adminUser.fcmToken) {
                console.error(`❌ Admin ${primaryAdminId} has NO FCM token registered!`);
            } else {
                console.log(`📱 Admin FCM Token found: ${adminUser.fcmToken.substring(0, 15)}...`);
                const admin = require('firebase-admin');
                if (admin.apps.length > 0) {
                    console.log('🚀 Sending FCM via Firebase Admin...');
                    // FCM Message with BOTH notification and data payloads
                    // - notification: Handled by Android system when app is killed (shows notification + sound)
                    // - data: Handled by our app when running (custom UI + ringtone)
                    // DATA + NOTIFICATION payload
                    // Including 'notification' ensures Android system wakes the app even if KILLED
                    const message = {
                        token: adminUser.fcmToken,

                        notification: {
                            title: '📞 Incoming Call',
                            body: `Call from ${callerName || 'User'}`,
                        },

                        data: {
                            type: 'incoming_call',
                            callerId: userId,
                            callerName: callerName || 'User',
                            channelName: callRequest.channelName,
                            callId: callRequest._id.toString(),
                            maskedListenerId: callRequest.maskedListenerId || '',
                            timestamp: Date.now().toString(),
                            click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        },

                        android: {
                            priority: 'high',
                            ttl: 30000,
                            notification: {
                                channelId: 'incoming_calls', // Matches our Flutter channel
                                priority: 'max',
                                visibility: 'public',
                                sound: 'default',
                                sticky: true,
                                tag: 'incoming_call',
                            }
                        },

                        apns: {
                            headers: {
                                'apns-priority': '10',
                                'apns-push-type': 'alert',
                                'apns-expiration': String(Math.floor(Date.now() / 1000) + 30),
                            },
                            payload: {
                                aps: {
                                    alert: {
                                        title: '📞 Incoming Call',
                                        body: `Call from ${callerName || 'User'}`,
                                    },
                                    sound: 'default',
                                    badge: 1,
                                    'content-available': 1,
                                    category: 'INCOMING_CALL',
                                    'interruption-level': 'time-sensitive',
                                },
                            },
                        },
                    };

                    const response = await admin.messaging().send(message);
                    console.log(`🔔 FCM HIGH-PRIORITY notification sent! Message ID: ${response}`);
                    console.log(`📱 Targeted Admin: ${primaryAdminId}`);
                } else {
                    console.warn('⚠️ Firebase Admin not initialized, skipping FCM notification');
                }
            }
        } catch (fcmError) {
            console.error('❌ FCM NOTIFICATION ERROR!');
            console.error('Error Code:', fcmError.code);
            console.error('Error Message:', fcmError.message);
            if (fcmError.stack) console.error('Stack:', fcmError.stack);
            // Don't fail the call if FCM fails
        }

        res.json({
            success: true,
            callId: callRequest._id,
            adminId: primaryAdminId,
            originalAdminId: primaryAdminId,
            maskedListenerId: callRequest.maskedListenerId,
            maskedListenerName: maskedListenerName,
            channelName: callRequest.channelName,
            coinsPerMin: maskedCoinsPerMin,
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
