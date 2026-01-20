import 'dart:convert';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AgoraRtmService {
  static const String appId = "150c2f1929d34588a6584a43ab6c7d48";
  // Use centralized API config for automatic emulator/physical device detection
  static String get baseUrl => ApiConfig.agoraUrl;
  
  RtmClient? _client;
  String? _currentUserId;
  bool _isLoggedIn = false;
  
  // Callbacks
  Function(String callerId, String callerName, String channelId)? onIncomingCall;
  Function(String adminId)? onCallAccepted;
  Function(String adminId)? onCallRejected;

  /// Check if RTM is connected and logged in
  bool get isConnected => _isLoggedIn && _client != null;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Fetch RTM token from backend with timeout
  Future<String?> _fetchRtmToken(String userId) async {
    try {
      debugPrint('RTM: Fetching token from $baseUrl/rtm-token for user: $userId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/rtm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': userId}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('RTM: Token fetched successfully');
        return data['token'];
      } else {
        debugPrint('RTM: Failed to fetch token - Status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('RTM: Error fetching token: $e');
      return null;
    }
  }

  Future<void> initialize(String userId) async {
    // Prevent duplicate initialization
    if (_isLoggedIn && _currentUserId == userId) {
      debugPrint('RTM: Already logged in as $userId');
      return;
    }
    
    // Logout if logged in as different user
    if (_isLoggedIn && _currentUserId != userId) {
      await logout();
    }
    
    try {
      _currentUserId = userId;
      debugPrint('RTM: Initializing for user: $userId');
      debugPrint('RTM: Using App ID: $appId');
      
      // Create RTM client using the new 2.x API
      final (status, client) = await RTM(appId, userId);
      
      if (status.error) {
        debugPrint('RTM Creation Error: ${status.errorCode} - ${status.reason}');
        return;
      }
      
      _client = client;
      debugPrint('RTM: Client created successfully');
      
      // Add event listeners using the new 2.x API
      _client?.addListener(
        message: (MessageEvent event) {
          debugPrint("RTM: Message received from ${event.publisher}");
          _handleMessage(event);
        },
        linkState: (LinkStateEvent event) {
          debugPrint('RTM: Connection state changed to ${event.currentState}');
          if (event.currentState == RtmLinkState.connected) {
            debugPrint('RTM: Successfully connected!');
          }
        },
        presence: (PresenceEvent event) {
          debugPrint('RTM: Presence event - ${event.type}');
        },
      );

      // Fetch RTM token from backend
      final token = await _fetchRtmToken(userId);
      
      if (token == null) {
        debugPrint('RTM: Failed to get token, cannot login');
        return;
      }

      debugPrint('RTM: Attempting login with token...');
      
      // Login to RTM with token
      final (loginStatus, _) = await _client!.login(token);
      
      if (loginStatus.error) {
        debugPrint('RTM Login Error: ${loginStatus.errorCode} - ${loginStatus.reason}');
        return;
      }
      
      _isLoggedIn = true;
      debugPrint('RTM: ✅ Successfully logged in as: $userId');
    } catch (e) {
      debugPrint('RTM Initialization Error: $e');
    }
  }

  void _handleMessage(MessageEvent event) {
    // Extract message text from the event
    String messageText = '';
    if (event.message != null) {
      // The message is stored as bytes, decode to string
      messageText = utf8.decode(event.message!);
    }
    
    final peerId = event.publisher ?? '';
    
    debugPrint('RTM: Received message: "$messageText" from $peerId');
    
    if (messageText.contains("type:call_invite")) {
      debugPrint('RTM: 📞 Incoming call invite detected!');
      final parts = messageText.split('|');
      String channel = "";
      String name = "";
      for (var p in parts) {
        if (p.startsWith("channel:")) channel = p.split(':')[1];
        if (p.startsWith("name:")) name = p.split(':')[1];
      }
      debugPrint('RTM: Call from $name, channel: $channel');
      onIncomingCall?.call(peerId, name, channel);
    } else if (messageText == "type:call_accept") {
      debugPrint('RTM: ✅ Call accepted by $peerId');
      onCallAccepted?.call(peerId);
    } else if (messageText == "type:call_reject") {
      debugPrint('RTM: ❌ Call rejected by $peerId');
      onCallRejected?.call(peerId);
    }
  }

  Future<bool> sendCallInvite(String adminId, String channelName, String myName) async {
    if (_client == null || !_isLoggedIn) {
      debugPrint('RTM: Cannot send invite - Client not initialized or not logged in');
      return false;
    }
    
    final msg = "type:call_invite|channel:$channelName|name:$myName";
    
    debugPrint('RTM: Sending call invite to $adminId');
    debugPrint('RTM: Message: $msg');
    
    // Retry logic for sending messages
    int retries = 0;
    const maxRetries = 3;
    
    while (retries < maxRetries) {
      final (status, _) = await _client!.publish(
        adminId, // Target user ID for P2P messaging
        msg,
        channelType: RtmChannelType.user,
      );
      
      if (status.error) {
        debugPrint('RTM: Send Error (attempt ${retries + 1}): ${status.errorCode} - ${status.reason}');
        retries++;
        
        if (retries < maxRetries) {
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * retries));
        }
      } else {
        debugPrint('RTM: ✅ Call invite sent successfully to $adminId');
        return true;
      }
    }
    
    debugPrint('RTM: ❌ Failed to send call invite after $maxRetries attempts');
    return false;
  }

  Future<bool> sendCallAccept(String callerId) async {
    if (_client == null || !_isLoggedIn) {
      debugPrint('RTM: Cannot send accept - not connected');
      return false;
    }
    
    debugPrint('RTM: Sending call accept to $callerId');
    
    final (status, _) = await _client!.publish(
      callerId,
      "type:call_accept",
      channelType: RtmChannelType.user,
    );
    
    if (status.error) {
      debugPrint('RTM: Send Accept Error: ${status.errorCode} - ${status.reason}');
      return false;
    }
    
    debugPrint('RTM: ✅ Call accept sent to $callerId');
    return true;
  }

  Future<bool> sendCallReject(String callerId) async {
    if (_client == null || !_isLoggedIn) {
      debugPrint('RTM: Cannot send reject - not connected');
      return false;
    }
    
    debugPrint('RTM: Sending call reject to $callerId');
    
    final (status, _) = await _client!.publish(
      callerId,
      "type:call_reject",
      channelType: RtmChannelType.user,
    );
    
    if (status.error) {
      debugPrint('RTM: Send Reject Error: ${status.errorCode} - ${status.reason}');
      return false;
    }
    
    debugPrint('RTM: ✅ Call reject sent to $callerId');
    return true;
  }

  Future<void> logout() async {
    if (_client != null && _isLoggedIn) {
      debugPrint('RTM: Logging out...');
      await _client?.logout();
      _isLoggedIn = false;
      debugPrint('RTM: Logged out');
    }
  }
  
  Future<void> dispose() async {
    await logout();
    _client = null;
    _currentUserId = null;
  }
}
