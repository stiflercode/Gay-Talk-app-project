import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Centralized API configuration that automatically detects
/// whether the app is running on an emulator or physical device
class ApiConfig {
  // Change this IP when your network changes
  static const String _physicalDeviceIp = '192.168.29.41';
  static const String _emulatorIp = '10.0.2.2';
  static const int _port = 3001;
  
  // Cached value for isEmulator check
  static bool? _isEmulatorCached;
  
  /// Initialize the config - call this from main() before runApp()
  static Future<void> initialize() async {
    await _detectEmulator();
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
  /// - Emulator: Uses 10.0.2.2 (Android's localhost alias)
  /// - Physical device: Uses the computer's actual IP address
  static String get baseUrl {
    final ip = isEmulator ? _emulatorIp : _physicalDeviceIp;
    return 'http://$ip:$_port/api';
  }
  
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
    debugPrint('Is Emulator: $isEmulator');
    debugPrint('Base URL: $baseUrl');
    debugPrint('User URL: $userUrl');
    debugPrint('========================');
  }
}
