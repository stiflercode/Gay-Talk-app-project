import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Centralized API configuration
/// 
/// By default, uses production URL: https://gaytalks.gumbotech.in/api
/// For local development, set useLocalDevelopment = true
class ApiConfig {
  // ============================================
  // CONFIGURATION - Change these as needed
  // ============================================
  
  /// Set to true for local development, false for production
  static const bool useLocalDevelopment = true;
  
  /// Production base URL (HTTPS)
  static const String _productionBaseUrl = 'https://gaytalks.gumbotech.in/api';
  
  /// Local development configuration
  // 192.168.29.41 is your computer's local IP address. 
  // Ensure your phone is connected to the SAME Wi-Fi network as your computer.
  static const String _localDeviceIp = '192.168.29.41'; 
  static const String _emulatorIp = '10.0.2.2';
  static const int _localPort = 5000;
  
  // ============================================
  // Internal state
  // ============================================
  
  // Cached value for isEmulator check
  static bool? _isEmulatorCached;
  
  /// Initialize the config - call this from main() before runApp()
  static Future<void> initialize() async {
    if (useLocalDevelopment) {
      await _detectEmulator();
    }
    printConfig();
  }
  
  /// Detect if running on emulator using device_info_plus
  static Future<void> _detectEmulator() async {
    if (_isEmulatorCached != null) return;
    
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        // Check if it's an emulator
        _isEmulatorCached = !androidInfo.isPhysicalDevice;
        debugPrint('ApiConfig: Device is ${_isEmulatorCached! ? "EMULATOR" : "PHYSICAL DEVICE"}');
        debugPrint('ApiConfig: Device model: ${androidInfo.model}');
        debugPrint('ApiConfig: Device brand: ${androidInfo.brand}');
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        _isEmulatorCached = !iosInfo.isPhysicalDevice;
      } else {
        _isEmulatorCached = false;
      }
    } catch (e) {
      debugPrint('ApiConfig: Error detecting emulator: $e');
      _isEmulatorCached = false;
    }
  }
  
  /// Returns the appropriate base URL for the backend API
  /// 
  /// - Production (default): https://gaytalks.gumbotech.in/api
  /// - Local Development: http://[IP]:[PORT]/api
  ///   - Emulator: Uses 10.0.2.2 (Android's localhost alias)
  ///   - Physical device: Uses the computer's actual IP address
  static String get baseUrl {
    if (useLocalDevelopment) {
      final ip = isEmulator ? _emulatorIp : _localDeviceIp;
      return 'http://$ip:$_localPort/api';
    } else {
      return _productionBaseUrl;
    }
  }
  
  /// Authentication service endpoint
  static String get authUrl => '$baseUrl/auth';
  
  /// User service endpoint
  static String get userUrl => '$baseUrl/user';
  
  /// Payment service endpoint
  static String get paymentUrl => '$baseUrl/payment';
  
  /// Call service endpoint
  static String get callUrl => '$baseUrl/call';
  
  /// Agora service endpoint
  static String get agoraUrl => '$baseUrl/agora';
  
  /// Check if running on an Android emulator (sync getter, uses cached value)
  static bool get isEmulator => _isEmulatorCached ?? false;
  
  /// Check if using local development mode
  static bool get isLocalDevelopment => useLocalDevelopment;
  
  /// Manually set emulator mode (call this from main.dart if needed)
  static void setEmulatorMode(bool value) {
    _isEmulatorCached = value;
    debugPrint('ApiConfig: Emulator mode manually set to $value, baseUrl = $baseUrl');
  }
  
  /// Reset cached value (useful for testing)
  static void resetCache() {
    _isEmulatorCached = null;
  }
  
  /// Debug: Print current configuration
  static void printConfig() {
    debugPrint('=== API Configuration ===');
    debugPrint('Environment: ${useLocalDevelopment ? "LOCAL DEVELOPMENT" : "PRODUCTION"}');
    if (useLocalDevelopment) {
      debugPrint('Is Emulator: $isEmulator');
    }
    debugPrint('Base URL: $baseUrl');
    debugPrint('Auth URL: $authUrl');
    debugPrint('User URL: $userUrl');
    debugPrint('========================');
  }
}
