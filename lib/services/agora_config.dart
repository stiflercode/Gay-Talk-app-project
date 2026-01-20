import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'agora_token_service.dart';

/// Agora configuration and token management
/// 
/// Production mode: Uses server-side token generation
/// Development mode: Can use temporary token or no token (testing only)
class AgoraConfig {
  // Your Agora App ID (from Agora Console) - MUST MATCH BACKEND .env
  static const String appId = "150c2f1929d34588a6584a43ab6c7d48";
  
  // Environment: 'production' or 'development'
  // Set to true to use backend-generated tokens (recommended)
  static const bool isProduction = true;
  
  // For development: You can use a temporary token from Agora Console
  // Get a temporary token from: https://console.agora.io -> Your Project -> Temporary Token
  // ⚠️ WARNING: Only for testing! Tokens expire after 24 hours
  static const String tempToken = String.fromEnvironment(
    'AGORA_TEMP_TOKEN',
    // Keep empty by default; use only when explicitly set for local dev
    defaultValue: '',
  );

  // Channel name for temporary token (must match the channel name used when generating the token)
  // When generating a temporary token in Agora Console, specify this channel name
  static const String devChannelName = String.fromEnvironment(
    'AGORA_DEV_CHANNEL',
    defaultValue: 'test',
  );
  
  // Agora App Certificate (needed for token generation on server)
  // Get this from: Agora Console -> Your Project -> App Certificate
  static const String appCertificate = String.fromEnvironment(
    'AGORA_APP_CERTIFICATE',
    defaultValue: '',
  );
  
  /// Get token for a user
  /// 
  /// Production: Fetches token from your backend server
  /// Development: Uses temporary token or no token (testing only)
  static Future<String> getToken(String channelName, int uid) async {
    if (isProduction) {
      // Production: Fetch from server
      try {
        return await AgoraTokenService.fetchTokenFromServer(
          channelName: channelName,
          uid: uid,
        );
      } catch (e) {
        debugPrint('Failed to fetch token from server: $e');
        // In production, we should not proceed without a token
        throw Exception('Failed to get call token. Please try again.');
      }
    } else {
      // Development: Use temporary token if provided, otherwise no token
      if (tempToken.isNotEmpty) {
        debugPrint('Using temporary token for development');
        return tempToken;
      }
      
      // Development mode: no token (Agora allows this for testing)
      debugPrint('Development mode: Using no token');
      return "";
    }
  }

  /// Get the channel name to use for joining
  /// 
  /// In development mode with a temporary token, uses a fixed channel name
  /// because temporary tokens are generated for a specific channel.
  /// In production, uses the provided channel name.
  static String getChannelName(String originalChannelName) {
    if (isProduction) {
      return originalChannelName;
    } else {
      // In development with temporary token, use the configured channel name
      // This must match the channel name used when generating the temporary token
      if (tempToken.isNotEmpty) {
        debugPrint('Development mode: Using channel name "$devChannelName" for temporary token');
        return devChannelName;
      }
      return originalChannelName;
    }
  }
  
  /// Generate a unique UID for the current user
  /// 
  /// Uses Firebase UID hash to ensure consistent UID per user
  static int generateUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Use a hash of the user's UID to generate a consistent integer UID
      // This ensures the same user always gets the same UID
      return user.uid.hashCode.abs() % 2147483647; // Max 32-bit int
    }
    // Fallback: use timestamp (shouldn't happen in production)
    debugPrint('Warning: No authenticated user, using timestamp-based UID');
    return DateTime.now().millisecondsSinceEpoch % 2147483647;
  }
  
  /// Clear token cache (useful for logout)
  static void clearTokenCache() {
    AgoraTokenService.clearCache();
  }
}
