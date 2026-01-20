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

import 'login_screen.dart';
import 'personal_details_screen.dart';
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

    Timer(const Duration(milliseconds: 700), () async {
      final route = await decideInitialRoute(widget.prefs);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(route);
    });
  }

  Future<String> decideInitialRoute(SharedPreferences prefs) async {
    final hasName = prefs.getString('name')?.isNotEmpty ?? false;
    final hasLang = prefs.getString('lang') != null;

    if (hasName) return HomePage.routeName;                     // <-- Go to HOME
    if (hasLang) return PersonalDetailsScreen.routeName;        // Language set but no profile yet
    return LoginScreen.routeName;                               // First time user
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rectangle Logo
            Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12), // optional
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/logo.png",
                  fit: BoxFit.cover, // fills the rectangle fully
                ),
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
          ],
        ),
      ),
    );
  }
}
