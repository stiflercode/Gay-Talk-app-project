import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Service for handling Razorpay payments via Node.js backend
class PaymentService {
  // Use centralized API config for automatic emulator/physical device detection
  static String get baseUrl => ApiConfig.paymentUrl;
  
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

  /// Create a Razorpay order
  /// Returns order details including orderId and keyId for Razorpay Checkout
  static Future<Map<String, dynamic>> createOrder({
    required int amount,
    required int coins,
    required String userId,
    String currency = 'INR',
  }) async {
    try {
      final response = await _makeAuthenticatedRequest((headers) =>
        http.post(
          Uri.parse('$baseUrl/createOrder'),
          headers: headers,
          body: jsonEncode({
            'amount': amount,
            'currency': currency,
            'userId': userId,
            'coins': coins,
          }),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        )
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Create order failed: Status ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        try {
          final error = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(error['error'] ?? error['message'] ?? 'Failed to create order');
        } catch (e) {
          throw Exception('Failed to create order: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Create order error: $e');
      rethrow;
    }
  }

  /// Verify payment and update wallet
  /// Returns new wallet balance
  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String userId,
    required int coins,
  }) async {
    try {
      final response = await _makeAuthenticatedRequest((headers) =>
        http.post(
          Uri.parse('$baseUrl/verifyPayment'),
          headers: headers,
          body: jsonEncode({
            'orderId': orderId,
            'paymentId': paymentId,
            'signature': signature,
            'userId': userId,
            'coins': coins,
          }),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        )
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Failed to verify payment');
      }
    } catch (e) {
      debugPrint('Verify payment error: $e');
      rethrow;
    }
  }

  /// Get Razorpay key from backend (public endpoint, no auth required)
  static Future<String> getRazorpayKey() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/key'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['keyId'] as String;
      } else {
        throw Exception('Failed to get Razorpay key');
      }
    } catch (e) {
      debugPrint('Get key error: $e');
      rethrow;
    }
  }
}
