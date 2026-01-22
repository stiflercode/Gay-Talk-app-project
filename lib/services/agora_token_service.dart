import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Service for fetching Agora tokens from Node.js backend
/// 
/// Production-ready: Uses Node.js backend to generate Agora tokens securely.
/// The token generation happens server-side with proper authentication.
class AgoraTokenService {
  // Token generation endpoint (Node.js backend)
  static String get tokenServerUrl => '${ApiConfig.agoraUrl}/rtc-token';
  
  // RTM token endpoint
  static String get rtmTokenUrl => '${ApiConfig.agoraUrl}/rtm-token';

  // Cache token to avoid repeated requests
  static String? _cachedToken;
  static DateTime? _tokenExpiry;
  static String? _cachedChannelName;
  static int? _cachedUid;

  // Singleton AuthService instance
  static final AuthService _authService = AuthService();

  /// Get authorization headers with JWT token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Handle API response and retry with token refresh if needed
  static Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    // First attempt with current token
    var headers = await _getAuthHeaders();
    var response = await request(headers);

    // If unauthorized, try refreshing token and retry once
    if (response.statusCode == 401) {
      debugPrint('⚠️ Token expired, attempting refresh...');
      final refreshed = await _authService.refreshAccessToken();
      
      if (refreshed) {
        // Retry request with new token
        headers = await _getAuthHeaders();
        response = await request(headers);
      }
    }

    return response;
  }

  /// Fetches a RTC token from your backend server for voice/video calls
  /// 
  /// Your server should:
  /// 1. Authenticate the user (verify JWT token)
  /// 2. Generate Agora token using Agora SDK
  /// 3. Return token in format: {"token": "..."}
  static Future<String> fetchTokenFromServer({
    required String channelName,
    required int uid,
    int expireTime = 3600, // 1 hour default
  }) async {
    // Check cache first
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        _cachedChannelName == channelName &&
        _cachedUid == uid &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      debugPrint('Using cached Agora RTC token');
      return _cachedToken!;
    }

    try {
      debugPrint('Fetching RTC token from: $tokenServerUrl');
      
      // Make authenticated request to your token server
      final response = await _makeAuthenticatedRequest((headers) =>
        http.post(
          Uri.parse(tokenServerUrl),
          headers: headers,
          body: jsonEncode({
            'channelName': channelName,
            'uid': uid,
            'role': 'publisher',
            'expireTime': expireTime,
          }),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Token request timeout');
          },
        )
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          throw Exception('Invalid token response from server');
        }

        // Cache the token
        _cachedToken = token;
        _cachedChannelName = channelName;
        _cachedUid = uid;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expireTime - 300)); // Refresh 5 min before expiry

        debugPrint('Successfully fetched Agora RTC token from Node.js backend');
        return token;
      } else {
        debugPrint('Token server error: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Token server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching RTC token from server: $e');
      rethrow;
    }
  }

  /// Fetches a RTM token from your backend server for messaging
  static Future<String?> fetchRtmTokenFromServer({
    required String uid,
  }) async {
    try {
      debugPrint('Fetching RTM token from: $rtmTokenUrl');
      
      final response = await _makeAuthenticatedRequest((headers) =>
        http.post(
          Uri.parse(rtmTokenUrl),
          headers: headers,
          body: jsonEncode({
            'uid': uid,
          }),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('RTM Token request timeout');
          },
        )
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;

        if (token == null || token.isEmpty) {
          debugPrint('Invalid RTM token response from server');
          return null;
        }

        debugPrint('Successfully fetched Agora RTM token from Node.js backend');
        return token;
      } else {
        debugPrint('RTM Token server error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching RTM token from server: $e');
      return null;
    }
  }

  /// Clear cached token (useful for logout or errors)
  static void clearCache() {
    _cachedToken = null;
    _tokenExpiry = null;
    _cachedChannelName = null;
    _cachedUid = null;
  }

  /// Check if token is expired
  static bool isTokenExpired() {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }
}
