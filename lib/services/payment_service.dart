import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Service for handling Razorpay payments via Node.js backend
class PaymentService {
  // Use centralized API config for automatic emulator/physical device detection
  static String get baseUrl => ApiConfig.paymentUrl;

  /// Create a Razorpay order
  /// Returns order details including orderId and keyId for Razorpay Checkout
  static Future<Map<String, dynamic>> createOrder({
    required int amount,
    required int coins,
    String currency = 'INR',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/createOrder'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'currency': currency,
          'userId': user.uid,
          'coins': coins,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
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
    required int coins,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verifyPayment'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'orderId': orderId,
          'paymentId': paymentId,
          'signature': signature,
          'userId': user.uid,
          'coins': coins,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
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

  /// Get Razorpay key from backend
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
