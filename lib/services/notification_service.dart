import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:audioplayers/audioplayers.dart';

/// Background message handler - MUST be top-level function (not class method)
/// This runs when app is in background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // 1. Initialize Firebase for the background isolate
    // Ensure Firebase is initialized for this background process
    await Firebase.initializeApp();

    // 2. Initialize NotificationService for this isolate
    // Local notification plugin MUST be initialized in the background isolate to work
    final notificationService = NotificationService();
    await notificationService.initialize();

    debugPrint('🔔 Background FCM received: ${message.messageId}');
    
    // 3. Check if this is an incoming call
    final data = message.data;
    if (data['type'] == 'incoming_call') {
      final callerName = data['callerName'] ?? 'Unknown Caller';
      final callId = data['callId'] ?? '';
      
      debugPrint('📞 Incoming call in background from: $callerName');
      
      // 4. Manually trigger the persistent/insistent notification
      await notificationService.showIncomingCallNotification(
        callerName: callerName,
        callRequestId: callId,
        channelName: data['channelName'],
        callerId: data['callerId'],
      );
    }
  } catch (e) {
    debugPrint('❌ Error in background FCM handler: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;
  
  // Callback for when an incoming call notification is tapped
  Function(Map<String, dynamic>)? onIncomingCallTapped;

  Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permissions with critical alert for iOS
    final NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true, // For critical/time-sensitive alerts (requires entitlement on iOS)
      announcement: true,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    // Set foreground notification presentation options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }

    // Initialize local notifications with platform-specific settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, // Request critical alert permission
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
        // Handle notification tap
        if (details.payload != null && onIncomingCallTapped != null) {
          onIncomingCallTapped!({'callId': details.payload});
        }
      },
    );

    // Create notification channel for incoming calls with HIGH importance
    // Uses default system ringtone for maximum compatibility
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'incoming_calls',
      'Incoming Calls',
      description: 'High priority notifications for incoming voice calls',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.red,
      showBadge: true,
      // Use default system sound - no custom ringtone file needed
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
    debugPrint('✅ NotificationService initialized with high-priority channel');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground FCM received: ${message.messageId}');
    final data = message.data;
    
    if (data['type'] == 'incoming_call') {
      debugPrint('📞 Incoming call from: ${data['callerName']}');
      // Show notification and play ringtone
      showIncomingCallNotification(
        callerName: data['callerName'] ?? 'Unknown Caller',
        callRequestId: data['callId'] ?? '',
        channelName: data['channelName'],
        callerId: data['callerId'],
      );
    } else if (message.notification != null) {
      _showLocalNotificationFromFCM(message);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification opened app: ${message.messageId}');
    final data = message.data;
    
    if (data['type'] == 'incoming_call' && onIncomingCallTapped != null) {
      onIncomingCallTapped!(data);
    }
  }

  void _showLocalNotificationFromFCM(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    _notifications.show(
      message.hashCode,
      notification.title ?? 'Notification',
      notification.body ?? '',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> showIncomingCallNotification({
    required String callerName,
    required String callRequestId,
    String? channelName,
    String? callerId,
  }) async {
    await initialize();
    
    debugPrint('🔔 Showing incoming call notification from: $callerName');

    // Android notification with full-screen intent and insistent flag
    final androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'High priority notifications for incoming voice calls',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      ongoing: true, // Cannot be swiped away
      autoCancel: false,
      fullScreenIntent: true, // Show over lock screen
      category: AndroidNotificationCategory.call, // Treat as phone call
      visibility: NotificationVisibility.public, // Show on lock screen
      // Uses default system sound - no custom ringtone file needed
      vibrationPattern: Int64List.fromList([0, 500, 250, 500, 250, 500, 250, 500]),
      // Keep ringing until user interacts
      additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT = 4
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'accept_call',
          'Accept',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'reject_call',
          'Decline',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    // iOS notification with time-sensitive alert and default sound
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      // Use default system sound - no custom ringtone file needed
      interruptionLevel: InterruptionLevel.timeSensitive,
      categoryIdentifier: 'INCOMING_CALL',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1, // Fixed ID so we can cancel it
      'Incoming Call',
      'Call from $callerName',
      details,
      payload: callRequestId,
    );

    // Also play ringtone audio (for foreground scenario)
    _playIncomingRingtone();
  }

  Future<void> _playIncomingRingtone() async {
    // The system notification will play the default ringtone automatically
    // No custom audio file is needed - using device's default notification sound
    debugPrint('🎵 System default ringtone will play via notification');
    
    // Note: If you want to add a custom ringtone later, 
    // place the file in assets/sounds/ringtone.mp3 and uncomment below:
    // try {
    //   await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    //   await _audioPlayer.setVolume(1.0);
    //   await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
    // } catch (e) {
    //   debugPrint('Custom ringtone error: $e');
    // }
  }

  Future<void> stopRingtone() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.release();
      debugPrint('🔇 Ringtone stopped');
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
  }

  Future<void> cancelIncomingCallNotification() async {
    await _notifications.cancel(1);
    await stopRingtone();
    debugPrint('🔕 Incoming call notification cancelled');
  }

  /// Get FCM token for this device (to be stored in backend for push notifications)
  Future<String?> getFCMToken() async {
    try {
      await initialize();
      final token = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic (useful for admin notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('📢 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }
  
  /// Listen for FCM token refresh
  void listenToTokenRefresh(Function(String) onTokenRefresh) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      onTokenRefresh(newToken);
    });
  }
}

