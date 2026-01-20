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

// Top-level function for background message handling (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // The notification will be shown automatically by FCM
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (works if google-services.json / plist added)
  await Firebase.initializeApp();
  // If you used FlutterFire CLI, replace above with:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize API config (detects emulator vs physical device)
  await ApiConfig.initialize();

  // Set up background message handler (must be called before runApp)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
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
