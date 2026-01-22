// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'login_screen.dart';
// import 'personal_details_screen.dart';
// import 'dashboard_screen.dart';

// class SplashScreen extends StatefulWidget {
//   static const routeName = '/';
//   final SharedPreferences prefs;
//   SplashScreen({required this.prefs, Key? key}) : super(key: key);

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     Timer(Duration(milliseconds: 700), () async {
//       final route = await decideInitialRoute(widget.prefs);
//       Navigator.of(context).pushReplacementNamed(route);
//     });
//   }

//   Future<String> decideInitialRoute(SharedPreferences prefs) async {
//     final hasName = prefs.getString('name')?.isNotEmpty ?? false;
//     final hasLang = prefs.getString('lang') != null;
//     if (hasName) return DashboardScreen.routeName;
//     if (hasLang) return PersonalDetailsScreen.routeName;
//     return LoginScreen.routeName;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircleAvatar(radius: 48, backgroundColor: Colors.pinkAccent, child: Icon(Icons.mic, size: 40, color: Colors.white)),
//             SizedBox(height: 12),
//             Text('Casual Talks', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.purple)),
//             SizedBox(height: 6),
//             Text('Welcome!', style: TextStyle(fontSize: 16, color: Colors.blue)),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'personal_details_screen.dart';
import 'language_selection_screen.dart';
import 'home_page.dart';   // <-- redirect here instead of dashboard

class SplashScreen extends StatefulWidget {
  static const routeName = '/';
  final SharedPreferences prefs;

  const SplashScreen({required this.prefs, super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 1500), () async {
      final route = await decideInitialRoute(widget.prefs);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(route);
    });
  }

  Future<String> decideInitialRoute(SharedPreferences prefs) async {
    debugPrint('🔍 Deciding initial route...');
    
    // 1. Check Firebase Auth first (source of truth for identity)
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('👤 Firebase user: ${currentUser?.uid ?? "NULL"}');

    // First, check if user has valid JWT tokens (new authentication system)
    final accessToken = prefs.getString('jwt_access_token');
    final refreshToken = prefs.getString('jwt_refresh_token');
    
    debugPrint('📝 Access token exists: ${accessToken != null && accessToken.isNotEmpty}');
    debugPrint('📝 Refresh token exists: ${refreshToken != null && refreshToken.isNotEmpty}');
    
    // If not authenticated via Firebase OR no JWT tokens, must login
    if (currentUser == null || accessToken == null || refreshToken == null) {
      debugPrint('❌ Not fully authenticated - redirecting to login');
      
      // If we have half-state, clear it to be safe
      if (accessToken != null || refreshToken != null) {
        debugPrint('🧹 Clearing inconsistent token state');
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
      }
      
      return LoginScreen.routeName;
    }
    
    // 3. User is authenticated, check profile completion
    final hasName = prefs.getString('name')?.isNotEmpty ?? false;
    final hasLang = prefs.getString('lang') != null;
    
    debugPrint('📝 Has name: $hasName');
    debugPrint('📝 Has language: $hasLang');

    if (hasName) {
      debugPrint('✅ Profile complete - redirecting to home');
      return HomePage.routeName;
    }
    
    if (hasLang) {
      debugPrint('⚠️ Language set but no profile - redirecting to personal details');
      return PersonalDetailsScreen.routeName;
    }
    
    // Authenticated but no language/name - go to language selection
    debugPrint('⚠️ Authenticated but fresh account - redirecting to language selection');
    return LanguageSelectionScreen.routeName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Simple icon instead of image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 50,
                color: Colors.purple,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Casual Talks',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ],
        ),
      ),
    );
  }
}
