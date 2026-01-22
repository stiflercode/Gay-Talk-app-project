import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import 'personal_details_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  static const routeName = '/language';
  final SharedPreferences prefs;
  LanguageSelectionScreen({required this.prefs, Key? key}) : super(key: key);

  // India flag emoji for all languages since they're Indian languages
  static const String flagEmoji = '🇮🇳';

  final List<Map<String, String>> languages = [
    {'code': 'en', 'label': 'English', 'native': 'English'},
    {'code': 'hi', 'label': 'Hindi', 'native': 'हिंदी'},
    {'code': 'hi-en', 'label': 'Hinglish', 'native': 'Hinglish'},
    {'code': 'ta', 'label': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'kn', 'label': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'mr', 'label': 'Marathi', 'native': 'मराठी'},
  ];

  Future<void> _saveLanguage(BuildContext context, String code) async {
    // 1) Save locally
    await prefs.setString('lang', code);

    // 2) Save to MongoDB backend via UserService
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userService = UserService();
        // Update user profile with selected language
        await userService.updateProfile(
          uid: user.uid,
          language: code,
        );
      } catch (e) {
        debugPrint('Could not save language on server: $e');
        // Non-fatal: continue to next screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Language', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.language, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select your preferred language for the app',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.separated(
                itemCount: languages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final lang = languages[i];
                  final code = lang['code']!;
                  final currentLang = prefs.getString('lang') ?? 'en';
                  final isSelected = currentLang == code;
                  
                  return GestureDetector(
                    onTap: () async {
                      await _saveLanguage(context, code);
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed(PersonalDetailsScreen.routeName);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Use India flag emoji instead of image asset
                          const Text(
                            flagEmoji,
                            style: TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lang['label']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(lang['native']!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                          const Spacer(),
                          if (isSelected) 
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Color(0xFF2196F3), shape: BoxShape.circle),
                              child: const Icon(Icons.check, color: Colors.white, size: 18),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
