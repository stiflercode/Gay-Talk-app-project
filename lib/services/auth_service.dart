// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // JWT token keys for SharedPreferences
  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';

  // Current Firebase user (nullable)
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes for listening
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get stored JWT access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Get stored JWT refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Save JWT tokens to local storage
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    debugPrint('✅ JWT tokens saved to local storage');
  }

  /// Clear JWT tokens from local storage
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    debugPrint('✅ JWT tokens cleared from local storage');
  }

  /// Login to backend with Firebase ID token and get JWT tokens
  /// Returns user data from backend on success
  Future<Map<String, dynamic>?> loginWithBackend(User firebaseUser, {String? fcmToken}) async {
    try {
      debugPrint('🔑 loginWithBackend started');
      // Get Firebase ID token
      final firebaseToken = await firebaseUser.getIdToken();
      
      if (firebaseToken == null) {
        debugPrint('❌ Failed to get Firebase ID token');
        throw Exception('Failed to get Firebase ID token');
      }

      final url = '${ApiConfig.baseUrl}/auth/login';
      debugPrint('🔐 Calling backend: $url');

      // Call backend login endpoint
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebaseToken': firebaseToken,
          'fcmToken': fcmToken,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📡 Backend response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final accessToken = data['data']['accessToken'];
          final refreshToken = data['data']['refreshToken'];
          final user = data['data']['user'];

          await _saveTokens(accessToken, refreshToken);
          debugPrint('✅ Backend login successful');
          return user;
        } else {
          debugPrint('❌ Backend returned success=false: ${data['message']}');
          throw Exception(data['message'] ?? 'Login failed');
        }
      } else {
        debugPrint('❌ Backend returned error status: ${response.statusCode}');
        debugPrint('📄 Response body: ${response.body}');
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['message'] ?? 'Login failed with status ${response.statusCode}');
        } catch (e) {
          throw Exception('Backend error (${response.statusCode}): ${response.body.substring(0, min(response.body.length, 100))}');
        }
      }
    } catch (e) {
      debugPrint('❌ loginWithBackend error: $e');
      rethrow;
    }
  }

  /// Refresh JWT access token using refresh token
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      
      if (refreshToken == null) {
        debugPrint('❌ No refresh token available');
        return false;
      }

      debugPrint('🔄 Refreshing access token...');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final newAccessToken = data['data']['accessToken'];
          
          // Update access token (keep same refresh token)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_accessTokenKey, newAccessToken);
          
          debugPrint('✅ Access token refreshed successfully');
          return true;
        }
      }
      
      debugPrint('❌ Token refresh failed');
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      return false;
    }
  }

  /// Signs in with Google and logs in to backend
  /// Returns the user data from backend on success
  Future<Map<String, dynamic>?> signInWithGoogle({String? fcmToken}) async {
    try {
      debugPrint('🔵 Google Sign-In started');
      
      // Force account picker by signing out first
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('⚠️ Google sign out (before sign in) failed: $e');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('🟡 Google Sign-In cancelled by user');
        return null;
      }

      debugPrint('🟢 Google User: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('🎫 Google Auth tokens received');

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      debugPrint('🔥 Signing in to Firebase with credential...');
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        debugPrint('❌ Firebase user is null after sign-in');
        throw Exception('Firebase sign-in failed');
      }
      debugPrint('✅ Firebase user logged in: ${firebaseUser.uid}');

      // Login to backend and get JWT tokens
      return await loginWithBackend(firebaseUser, fcmToken: fcmToken);
    } catch (e) {
      debugPrint('❌ signInWithGoogle error: $e');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Signs in with email and password and logs in to backend
  Future<Map<String, dynamic>?> signInWithEmailAndPassword(
    String email, 
    String password,
    {String? fcmToken}
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw Exception('Firebase sign-in failed');
      }

      // Login to backend and get JWT tokens
      final userData = await loginWithBackend(firebaseUser, fcmToken: fcmToken);
      
      return userData;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Signs up with email and password and logs in to backend
  Future<Map<String, dynamic>?> signUpWithEmailAndPassword(
    String email, 
    String password,
    {String? fcmToken}
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw Exception('Firebase sign-up failed');
      }

      // Login to backend and get JWT tokens
      final userData = await loginWithBackend(firebaseUser, fcmToken: fcmToken);
      
      return userData;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Logout from backend and clear tokens
  Future<void> logout() async {
    try {
      // Get access token for backend logout
      final accessToken = await getAccessToken();
      
      if (accessToken != null) {
        try {
          // Call backend logout endpoint
          await http.post(
            Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          ).timeout(const Duration(seconds: 5));
          
          debugPrint('✅ Backend logout successful');
        } catch (e) {
          debugPrint('⚠️ Backend logout failed: $e');
          // Continue with local logout even if backend fails
        }
      }
      
      // Clear JWT tokens
      await _clearTokens();
      
      // Sign out from Firebase and Google
      await signOut();
      
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      // Still clear tokens even if there's an error
      await _clearTokens();
      await signOut();
    }
  }

  /// Signs out from both GoogleSignIn and Firebase.
  /// Uses disconnect() instead of signOut() so account picker shows on next login.
  Future<void> signOut() async {
    try {
      // Disconnect completely so user sees account picker on next sign-in
      await _googleSignIn.disconnect();
      await _auth.signOut();
    } catch (e) {
      // Fallback to regular signOut if disconnect fails
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (e2) {
        debugPrint('AuthService.signOut error: $e2');
      }
    }
  }

  /// Check if user has valid JWT tokens
  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Verify if current JWT token is valid by calling backend
  Future<bool> verifyToken() async {
    try {
      final accessToken = await getAccessToken();
      
      if (accessToken == null) {
        return false;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Token verification error: $e');
      return false;
    }
  }
}
