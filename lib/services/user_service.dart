import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class UserService {
  // Use centralized API config for automatic emulator/physical device detection
  static String get baseUrl => ApiConfig.userUrl;
  
  // HTTP client with timeout to prevent infinite loading
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 10);

  /// Creates or updates user doc via HTTP backend (MongoDB)
  Future<void> createOrUpdateUser(User user, {
    String? role, 
    String? fcmToken,
    String? name,
    int? age,
    String? gender,
    String? phone,
    String? username,
    bool? isProfileComplete,
    String? language,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': user.uid,
          'email': user.email,
          'displayName': name ?? user.displayName,
          'role': role,
          'fcmToken': fcmToken,
          'name': name,
          'age': age,
          'gender': gender,
          'phone': phone,
          'username': username,
          'profileComplete': isProfileComplete,
          'language': language,
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        debugPrint('User updated in MongoDB successfully: ${user.uid}');
      } else {
        debugPrint('Failed to update user: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
    }
  }

  /// Update isOnline status
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'isOnline': isOnline,
        }),
      ).timeout(_timeout);
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  /// Update FCM token for a user
  Future<void> updateFCMToken(String uid, String fcmToken) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'fcmToken': fcmToken,
        }),
      ).timeout(_timeout);
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Get user role
  Future<String> getUserRole(String uid) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/role/$uid')).timeout(_timeout);
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
        final response = await http.get(
          Uri.parse('$baseUrl/list?excludeUid=$excludeUid&role=$roleFilter'),
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
      final response = await http.get(Uri.parse('$baseUrl/$uid')).timeout(_timeout);
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
      final response = await http.post(
        Uri.parse('$baseUrl/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'language': language,
          'displayName': displayName,
          'profileComplete': profileComplete,
        }),
      ).timeout(_timeout);
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
      final response = await http.post(
        Uri.parse('$baseUrl/wallet'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'amount': amount,
          'operation': operation,
        }),
      ).timeout(_timeout);
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
}

/// Wrapper class to mimic Firestore DocumentSnapshot interface
class UserSnapshot {
  final Map<String, dynamic>? _data;
  
  UserSnapshot(this._data);
  
  Map<String, dynamic>? data() => _data;
  
  bool get exists => _data != null;
}
