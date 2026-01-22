import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class CallRequestService {
  // Use centralized API config for automatic emulator/physical device detection
  static String get baseUrl => ApiConfig.callUrl;

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

    // If unauthorized (401), try refreshing token and retry once
    if (response.statusCode == 401) {
      debugPrint('⚠️ Token expired in CallRequestService, attempting refresh...');
      final refreshed = await _authService.refreshAccessToken();
      
      if (refreshed) {
        // Retry request with new token
        headers = await _getAuthHeaders();
        response = await request(headers);
      }
    }

    return response;
  }

  /// 1. Get initial routing for a call (Hunt Group logic)
  Future<Map<String, dynamic>> routeCall({
    required String userId,
    required String callerName,
  }) async {
    final response = await _makeAuthenticatedRequest((headers) => 
      http.post(
        Uri.parse('$baseUrl/route'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'callerName': callerName,
        }),
      )
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to route call: ${response.body}');
    }
  }

  /// 2. Get next admin in the hunt group if previous one failed
  Future<Map<String, dynamic>> failoverCall({
    required String callId,
    required String failedAdminId,
  }) async {
    final response = await _makeAuthenticatedRequest((headers) => 
      http.post(
        Uri.parse('$baseUrl/next'),
        headers: headers,
        body: jsonEncode({
          'callId': callId,
          'failedAdminId': failedAdminId,
        }),
      )
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to roll over call: ${response.body}');
    }
  }

  /// 3. Update call status (accepted, completed, etc)
  Future<void> updateCallStatus({
    required String callId,
    required String status,
    int? durationSeconds,
    int? coinsCharged,
  }) async {
    await _makeAuthenticatedRequest((headers) => 
      http.post(
        Uri.parse('$baseUrl/update'),
        headers: headers,
        body: jsonEncode({
          'callId': callId,
          'status': status,
          if (durationSeconds != null) 'durationSeconds': durationSeconds,
          if (coinsCharged != null) 'coinsCharged': coinsCharged,
        }),
      )
    );
  }

  /// 4. Get call logs for admin
  Stream<List<Map<String, dynamic>>> getCallLogsForAdmin(String adminId) {
    return Stream.fromFuture(() async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/logs/admin/$adminId'),
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint('Error fetching admin call logs: $e');
      }
      return <Map<String, dynamic>>[];
    }());
  }

  /// 5. Get call logs for user
  Stream<List<Map<String, dynamic>>> getCallLogsForUser(String userId) {
    return Stream.fromFuture(() async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/logs/user/$userId'),
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint('Error fetching user call logs: $e');
      }
      return <Map<String, dynamic>>[];
    }());
  }
}

