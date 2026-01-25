const { RtmTokenBuilder, RtmRole } = require('agora-access-token');

exports.generateRtmToken = async (req, res) => {
    try {
        // Use authenticated user ID from token
        const uid = req.user.uid;

        const appId = process.env.AGORA_APP_ID;
        const appCertificate = process.env.AGORA_APP_CERTIFICATE;

        if (!appId || !appCertificate) {
            return res.status(500).json({ error: 'Agora credentials not configured' });
        }

        // Token expires in 24 hours (86400 seconds)
        const expirationTimeInSeconds = 86400;
        const currentTimestamp = Math.floor(Date.now() / 1000);
        const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

        // Build RTM token
        const token = RtmTokenBuilder.buildToken(
            appId,
            appCertificate,
            uid,
            RtmRole.Rtm_User,
            privilegeExpiredTs
        );

        console.log(`🎫 RTM token generated for user: ${uid}`);

        res.json({
            success: true,
            token,
            expiresAt: privilegeExpiredTs
        });
    } catch (error) {
        console.error('RTM Token generation error:', error);
        res.status(500).json({ error: 'Failed to generate RTM token' });
    }
};

// Generate RTC token for video calls
exports.generateRtcToken = async (req, res) => {
    try {
        const { channelName, uid, role } = req.body;

        if (!channelName) {
            return res.status(400).json({ error: 'Channel name is required' });
        }

        const appId = process.env.AGORA_APP_ID;
        const appCertificate = process.env.AGORA_APP_CERTIFICATE;

        if (!appId || !appCertificate) {
            return res.status(500).json({ error: 'Agora credentials not configured' });
        }

        const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

        // Token expires in 1 hour
        const expirationTimeInSeconds = 3600;
        const currentTimestamp = Math.floor(Date.now() / 1000);
        const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

        const rtcRole = role === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;
        const userUid = uid || 0; // 0 means let Agora assign

        const token = RtcTokenBuilder.buildTokenWithUid(
            appId,
            appCertificate,
            channelName,
            userUid,
            rtcRole,
            privilegeExpiredTs
        );

        res.json({
            success: true,
            token,
            channelName,
            uid: userUid,
            expiresAt: privilegeExpiredTs
        });
    } catch (error) {
        console.error('RTC Token generation error:', error);
        res.status(500).json({ error: 'Failed to generate RTC token' });
    }
};
