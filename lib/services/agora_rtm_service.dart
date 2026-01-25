import 'dart:convert';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

import 'agora_token_service.dart';

class AgoraRtmService {
  static const String appId = "150c2f1929d34588a6584a43ab6c7d48";
  
  // Singleton pattern
  static final AgoraRtmService _instance = AgoraRtmService._internal();
  factory AgoraRtmService() => _instance;
  AgoraRtmService._internal();

  RtmClient? _client;
  String? _currentUserId;
  bool _isLoggedIn = false;
  bool _isInitializing = false;
  
  // Callbacks
  Function(String callerId, String callerName, String channelId)? onIncomingCall;
  Function(String adminId)? onCallAccepted;
  Function(String adminId)? onCallRejected;

  /// Check if RTM is connected and logged in
  bool get isConnected => _isLoggedIn && _client != null;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Fetch RTM token from backend using the authenticated service
  Future<String?> _fetchRtmToken(String userId) async {
    return await AgoraTokenService.fetchRtmTokenFromServer(uid: userId);
  }

  Future<void> initialize(String userId) async {
    // Prevent concurrent initialization
    if (_isInitializing) return;
    
    // Check if we are already logged in as the SAME user
    if (_isLoggedIn && _currentUserId == userId && _client != null) {
      debugPrint('RTM: [Singleton] Already correctly logged in as $userId');
      return;
    }
    
    _isInitializing = true;

    try {
      // If we have an existing client but it's for a different user, logout and destroy it
      if (_client != null && _currentUserId != userId) {
        debugPrint('RTM: [Singleton] Switching user from $_currentUserId to $userId. Destroying old client.');
        await logout();
        _client = null; // Forces recreation for the new user ID
      }
      
      _currentUserId = userId;
      debugPrint('RTM: [Singleton] Initializing for user: $userId');
      
      // Create RTM client if not exists (either for first time or after user switch)
      if (_client == null) {
        debugPrint('RTM: 🛠️ Creating new RTM client for $userId');
        final (status, client) = await RTM(appId, userId);
        if (status.error) {
          debugPrint('RTM: ❌ Client Creation ERROR: ${status.errorCode}');
          _isInitializing = false;
          return;
        }
        _client = client;
        
        // Add persistent listeners to the new client
        _client?.addListener(
          message: (MessageEvent event) {
            debugPrint("RTM: ✉️ Message from ${event.publisher}");
            _handleMessage(event);
          },
          linkState: (LinkStateEvent event) {
            debugPrint('RTM: 🔗 Link State: ${event.currentState} (Previous: ${event.previousState}, Reason: ${event.reason})');
            if (event.currentState == RtmLinkState.connected) {
              _isLoggedIn = true;
            } else if (event.currentState == RtmLinkState.disconnected) {
              _isLoggedIn = false;
            }
          },
        );
      }

      // Fetch RTM token
      final token = await _fetchRtmToken(userId);
      if (token == null || token.isEmpty) {
        debugPrint('RTM: ❌ No token from backend for $userId');
        _isInitializing = false;
        return;
      }

      // Login
      debugPrint('RTM: 🔑 Logging in...');
      final (loginStatus, _) = await _client!.login(token);
      if (loginStatus.error) {
        debugPrint('RTM: ❌ Login ERROR: ${loginStatus.errorCode}');
        _isLoggedIn = false;
      } else {
        _isLoggedIn = true;
        debugPrint('RTM: ✅ Logged in successfully as: $userId');
      }
    } catch (e) {
      debugPrint('RTM: 💥 Initialization error: $e');
      _isLoggedIn = false;
    } finally {
      _isInitializing = false;
    }
  }

  void _handleMessage(MessageEvent event) {
    if (event.message == null) return;
    
    try {
      final text = utf8.decode(event.message!);
      final peerId = event.publisher ?? '';
      
      debugPrint('RTM: 📬 Received: "$text" from $peerId');
      
      if (text.contains("type:call_invite")) {
        final parts = text.split('|');
        String channel = "";
        String name = "";
        for (var p in parts) {
          if (p.startsWith("channel:")) channel = p.split(':')[1];
          if (p.startsWith("name:")) name = p.split(':')[1];
        }
        debugPrint('RTM: 📞 CALL INVITATION parsed - Name: $name, Channel: $channel');
        if (channel.isNotEmpty) {
          onIncomingCall?.call(peerId, name, channel);
        } else {
          debugPrint('RTM: ⚠️ Received invite with empty channel. Ignoring.');
        }
      } else if (text.contains("type:call_accept")) {
        debugPrint('RTM: ✅ Call accepted by $peerId');
        onCallAccepted?.call(peerId);
      } else if (text.contains("type:call_reject")) {
        debugPrint('RTM: ❌ Call rejected by $peerId');
        onCallRejected?.call(peerId);
      } else {
        debugPrint('RTM: ℹ️ Received unknown message type: $text');
      }
    } catch (e) {
      debugPrint('RTM: 💥 Error decoding message: $e');
    }
  }

  Future<bool> sendCallInvite(String adminId, String channelName, String myName) async {
    if (!_isLoggedIn || _client == null) return false;
    final msg = "type:call_invite|channel:$channelName|name:$myName";
    
    debugPrint('RTM: 📢 Sending invite to $adminId');
    final (status, _) = await _client!.publish(adminId, msg, channelType: RtmChannelType.user);
    return !status.error;
  }

  Future<bool> sendCallAccept(String callerId) async {
    if (!_isLoggedIn || _client == null) return false;
    final (status, _) = await _client!.publish(callerId, "type:call_accept", channelType: RtmChannelType.user);
    return !status.error;
  }

  Future<bool> sendCallReject(String callerId) async {
    if (!_isLoggedIn || _client == null) return false;
    final (status, _) = await _client!.publish(callerId, "type:call_reject", channelType: RtmChannelType.user);
    return !status.error;
  }

  Future<void> logout() async {
    if (_client != null && _isLoggedIn) {
      await _client?.logout();
      _isLoggedIn = false;
    }
  }

  /// Dispose the RTM service - cleanup callbacks but keep singleton alive
  void dispose() {
    // Clear callbacks when the owning widget is disposed
    // Don't logout or destroy the client since this is a singleton
    // The client will be reused when the user comes back
    debugPrint('RTM: dispose() called - clearing callbacks');
    // We intentionally don't clear callbacks here to allow background reception
    // The callbacks should be re-set by the new widget instance
  }

  /// Force reconnect if disconnected
  Future<void> ensureConnected(String userId) async {
    if (!_isLoggedIn || _client == null) {
      debugPrint('RTM: Not connected, re-initializing...');
      await initialize(userId);
    } else if (_currentUserId != userId) {
      debugPrint('RTM: Different user, re-initializing...');
      await logout();
      await initialize(userId);
    } else {
      debugPrint('RTM: Already connected as $userId');
    }
  }
}

