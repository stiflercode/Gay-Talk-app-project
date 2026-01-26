import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class UserService {
  // Use centralized API config for automatic emulator/physical device detection
  static String get baseUrl => ApiConfig.userUrl;
  
  // HTTP client with timeout to prevent infinite loading
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 10);

  final AuthService _authService = AuthService();

  /// Get authorization headers with JWT token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Handle API response and retry with token refresh if needed
  Future<http.Response> _makeAuthenticatedRequest(
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

  /// Update isOnline status
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      await _makeAuthenticatedRequest((headers) => 
        http.post(
          Uri.parse('$baseUrl/update'),
          headers: headers,
          body: jsonEncode({
            'uid': uid,
            'isOnline': isOnline,
          }),
        ).timeout(_timeout)
      );
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  /// Update FCM token for a user
  Future<void> updateFCMToken(String uid, String fcmToken) async {
    try {
      await _makeAuthenticatedRequest((headers) =>
        http.post(
          Uri.parse('$baseUrl/update'),
          headers: headers,
          body: jsonEncode({
            'uid': uid,
            'fcmToken': fcmToken,
          }),
        ).timeout(_timeout)
      );
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Get user role
  Future<String> getUserRole(String uid) async {
    try {
      final response = await _makeAuthenticatedRequest((headers) =>
        http.get(
          Uri.parse('$baseUrl/role/$uid'),
          headers: headers,
        ).timeout(_timeout)
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['role'] ?? 'user';
      }
    } catch (e) {
      debugPrint('Error getting user role: $e');
    }
    return 'user';
  }

  /// Get users filtered by role
  Stream<List<Map<String, dynamic>>> getUsersByRole(String excludeUid, String currentUserRole) {
    final roleFilter = currentUserRole == 'user' ? 'admin' : '';
    
    return Stream.fromFuture(() async {
      try {
        final response = await _makeAuthenticatedRequest((headers) =>
          http.get(
            Uri.parse('$baseUrl/list?excludeUid=$excludeUid&role=$roleFilter'),
            headers: headers,
          )
        );
        
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint('Error fetching users: $e');
      }
      return <Map<String, dynamic>>[];
    }());
  }

  /// Get user by UID
  Future<UserSnapshot> getUser(String uid) async {
    try {
      final response = await _makeAuthenticatedRequest((headers) =>
        http.get(
          Uri.parse('$baseUrl/$uid'),
          headers: headers,
        ).timeout(_timeout)
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exists'] == true && data['user'] != null) {
          return UserSnapshot(data['user']);
        }
      }
    } catch (e) {
      debugPrint('Error getting user: $e');
    }
    return UserSnapshot(null);
  }

  /// Check if user is registered (has language or profileComplete)
  Future<bool> isUserRegistered(String uid) async {
    try {
      final snapshot = await getUser(uid);
      if (!snapshot.exists) return false;
      
      final data = snapshot.data();
      if (data == null) return false;
      
      // Check if profile is complete or language is set
      if (data['profileComplete'] == true) return true;
      final lang = data['language'];
      if (lang != null && lang is String && lang.trim().isNotEmpty) return true;
      
      return false;
    } catch (e) {
      debugPrint('Error checking registration status: $e');
      return false;
    }
  }

  /// Update user profile (language, displayName, profileComplete)
  Future<bool> updateProfile({
    required String uid,
    String? language,
    String? displayName,
    bool? profileComplete,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest((headers) =>
        http.post(
          Uri.parse('$baseUrl/profile'),
          headers: headers,
          body: jsonEncode({
            'uid': uid,
            'language': language,
            'displayName': displayName,
            'profileComplete': profileComplete,
          }),
        ).timeout(_timeout)
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  /// Update wallet balance
  Future<double> updateWallet({
    required String uid,
    required double amount,
    required String operation, // 'add', 'subtract', or 'set'
  }) async {
    try {
      final response = await _makeAuthenticatedRequest((headers) =>
        http.post(
          Uri.parse('$baseUrl/wallet'),
          headers: headers,
          body: jsonEncode({
            'uid': uid,
            'amount': amount,
            'operation': operation,
          }),
        ).timeout(_timeout)
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['walletBalance'] ?? 0).toDouble();
      }
    } catch (e) {
      debugPrint('Error updating wallet: $e');
    }
    return 0;
  }

  /// Get wallet balance
  Future<double> getWalletBalance(String uid) async {
    try {
      final snapshot = await getUser(uid);
      if (snapshot.exists) {
        final data = snapshot.data();
        final val = data?['walletBalance'];
        if (val is int) return val.toDouble();
        if (val is double) return val;
        return 0.0;
      }
    } catch (e) {
      debugPrint('Error getting wallet balance: $e');
    }
    return 0;
  }

  /// Get masked listeners (virtual identities for Hunt Group feature)
  /// Users see these virtual identities, but calls route to real admins behind the scenes
  Stream<List<Map<String, dynamic>>> getMaskedListeners() {
    return Stream.fromFuture(() async {
      try {
        final response = await _makeAuthenticatedRequest((headers) =>
          http.get(
            Uri.parse('$baseUrl/masked-listeners'),
            headers: headers,
          ).timeout(_timeout)
        );
        
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          debugPrint('📋 Fetched ${data.length} masked listeners');
          return data.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint('Error fetching masked listeners: $e');
      }
      // Return default masked listener if API fails
      return <Map<String, dynamic>>[
        {
          'maskId': 'listener_1',
          'uid': 'listener_1',
          'id': 'listener_1',
          'displayName': 'Listener 1',
          'name': 'Listener 1',
          'languages': ['English', 'Hindi'],
          'rating': 4.9,
          'coinsPerMin': 5,
          'isOnline': true,
          'isMasked': true,
        }
      ];
    }());
  }
}

/// Wrapper class to mimic Firestore DocumentSnapshot interface
class UserSnapshot {
  final Map<String, dynamic>? _data;
  
  UserSnapshot(this._data);
  
  Map<String, dynamic>? data() => _data;
  
  bool get exists => _data != null;
}
