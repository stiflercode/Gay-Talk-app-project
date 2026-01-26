import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Config
import 'config/api_config.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/personal_details_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_page.dart';
import 'screens/wallet_page.dart';
import 'screens/profile_screen.dart';
import 'screens/upi_verify_screen.dart';
import 'services/notification_service.dart';

void main() async {
  try {
    debugPrint('🚀 App starting...');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('✅ Flutter binding initialized');

    // 1. CRITICAL: Initialize Firebase first
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized');
    
    // 1.5. CRITICAL: Register background message handler BEFORE runApp
    // This must be done early so FCM can call it when app is terminated
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background message handler registered');

    // 2. Load preferences
    debugPrint('💾 Loading shared preferences...');
    final prefs = await SharedPreferences.getInstance();
    debugPrint('✅ Shared preferences loaded');
    
    // 3. Initialize API config
    debugPrint('🌐 Initializing API config...');
    await ApiConfig.initialize();
    debugPrint('✅ API config initialized');

    // Launch UI
    debugPrint('🎨 Starting app UI...');
    runApp(MyApp(prefs: prefs));

    // 4. DEFERRED: Non-critical services
    _initializeBackgroundServices();
    
    debugPrint('🚀 Initial UI launched!');
  } catch (e, stackTrace) {
    debugPrint('❌ FATAL ERROR: $e');
    _showErrorApp(e);
  }
}

Future<void> _initializeBackgroundServices() async {
  try {
    // Initialize notification service (creates notification channel, etc.)
    await NotificationService().initialize();
    
    // Request notification permissions explicitly
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
    
    // Get and log FCM token (useful for debugging)
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 FCM Token: ${token?.substring(0, 20)}...');
    
    debugPrint('✅ Background services ready');
  } catch (e) {
    debugPrint('⚠️ Background init error: $e');
  }
}

void _showErrorApp(Object e) {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              const Text('App Initialization Failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Error: $e', style: const TextStyle(fontSize: 14, color: Colors.red), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    ),
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MyApp({required this.prefs, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Casual Talks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black, // Primary color black for text/accents
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Color(0xFFF7F7F7), // Light grey for secondary backgrounds
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (_) => SplashScreen(prefs: prefs),
        LoginScreen.routeName: (_) => LoginScreen(prefs: prefs),
        LanguageSelectionScreen.routeName: (_) => LanguageSelectionScreen(prefs: prefs),
        PersonalDetailsScreen.routeName: (_) => PersonalDetailsScreen(prefs: prefs),
        DashboardScreen.routeName: (_) => DashboardScreen(prefs: prefs),
        HomePage.routeName: (ctx) => HomePage(prefs: prefs),
        WalletPage.routeName: (ctx) => WalletPage(prefs: prefs),
        ProfileScreen.routeName: (ctx) => ProfileScreen(prefs: prefs),
        UPIVerifyScreen.routeName: (ctx) => UPIVerifyScreen(prefs: prefs, coins: 50, amount: 50), // default placeholder

      },
    );
  }
}
