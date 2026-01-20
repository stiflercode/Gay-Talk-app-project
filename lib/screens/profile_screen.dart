import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/user_service.dart';
import 'wallet_page.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  final SharedPreferences prefs;

  const ProfileScreen({required this.prefs, super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final _nameController = TextEditingController();
  
  User? _currentUser;
  bool _isLoading = false;
  String _currentLanguage = 'en';
  int _balance = 0;

  // Language map for display
  final Map<String, String> _languageLabels = {
    'en': 'English',
    'hi': 'Hindi',
    'hi-en': 'Hinglish',
    'ta': 'Tamil',
    'kn': 'Kannada',
    'mr': 'Marathi',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) return;

    // Load locally first
    _nameController.text = _currentUser?.displayName ?? '';
    _currentLanguage = widget.prefs.getString('lang') ?? 'en';
    _balance = widget.prefs.getInt('wallet_balance') ?? 0;

    // Fetch fresh from server
    try {
      final userSnapshot = await _userService.getUser(_currentUser!.uid);
      if (userSnapshot.exists) {
        final data = userSnapshot.data();
        if (data != null && mounted) {
            setState(() {
              if (data['displayName'] != null) _nameController.text = data['displayName'];
              if (data['language'] != null) {
                _currentLanguage = data['language'];
                widget.prefs.setString('lang', _currentLanguage);
              }
            });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Update Name
      await _userService.updateProfile(
        uid: _currentUser!.uid,
        displayName: _nameController.text.trim(),
        language: _currentLanguage,
      );
      
      // Update Firebase Auth Display Name
      await _currentUser!.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await GoogleSignIn().disconnect();
    } catch (e) {
      debugPrint('Google disconnect error: $e');
    }
    await FirebaseAuth.instance.signOut();
    await widget.prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
  }
  
  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _languageLabels.length,
                  itemBuilder: (context, index) {
                    final code = _languageLabels.keys.elementAt(index);
                    final label = _languageLabels.values.elementAt(index);
                    return ListTile(
                      title: Text(label, textAlign: TextAlign.center),
                      onTap: () {
                        setState(() => _currentLanguage = code);
                        Navigator.pop(context);
                        _updateProfile(); // Auto-save on selection
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading && _currentUser == null
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Pic Placeholder
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7), // Light grey
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha((0.05 * 255).round()), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.person, size: 50, color: Colors.black26),
                  ),
                  const SizedBox(height: 24),
                  
                  // Name Field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: const Color(0xFFF7F7F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  
                  // Language Selector
                  GestureDetector(
                    onTap: _showLanguageSelector,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Language', style: TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(
                                _languageLabels[_currentLanguage] ?? 'English',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wallet Card
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, WalletPage.routeName);
                      // Refresh state when coming back
                      final bal = widget.prefs.getInt('wallet_balance') ?? 0;
                      setState(() => _balance = bal);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.white),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('$_balance Coins', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Top Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  TextButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
    );
  }
}
