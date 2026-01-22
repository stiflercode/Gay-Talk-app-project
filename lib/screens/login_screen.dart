
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'language_selection_screen.dart';
import 'personal_details_screen.dart';
import 'home_page.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  final SharedPreferences prefs;
  LoginScreen({required this.prefs, Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  bool _loading = false;
  int _logoTapCount = 0; // Track logo taps for hidden email login

  Future<void> _signIn() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      // Attempt Google sign-in and backend login (returns user data from backend)
      final userData = await _auth.signInWithGoogle();
      debugPrint('👤 Sign-in response userData: $userData');

      if (userData == null) {

        // User cancelled the flow
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in cancelled')),
        );
        return;
      }

      // Save lightweight info locally
      await widget.prefs.setString('email', userData['email'] ?? '');
      await widget.prefs.setString('name', userData['displayName'] ?? '');

      // Check if user profile is complete (from backend response)
      final profileComplete = userData['profileComplete'] ?? false;
      final language = userData['language'];
      final hasLanguage = language != null && language.toString().trim().isNotEmpty;

      if (!mounted) return;
      
      if (profileComplete) {
        // Fully registered: go to Home
        Navigator.of(context).pushReplacementNamed(HomePage.routeName);
      } else if (!hasLanguage) {
        // No language selected yet: go to Language selection
        Navigator.of(context).pushReplacementNamed(LanguageSelectionScreen.routeName);
      } else {
        // Language selected but profile not complete: go to Personal Details
        Navigator.of(context).pushReplacementNamed(PersonalDetailsScreen.routeName);
      }
    } catch (e) {
      // Show an error to the user
      if (mounted) {
        final msg = e is Exception ? e.toString() : 'Sign in failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _continueWithoutGoogle() {
    // If user continues without Google, route based on local prefs if you want.
    // We'll check local 'first_time' as fallback for non-auth flows.
    final bool isFirstTime = widget.prefs.getBool('first_time') ?? true;
    if (isFirstTime) {
      widget.prefs.setBool('first_time', false);
      Navigator.of(context).pushReplacementNamed(LanguageSelectionScreen.routeName);
    } else {
      Navigator.of(context).pushReplacementNamed(HomePage.routeName);
    }
  }

  /// Show email/password login dialog (unlocked after 5 logo taps)
  void _showEmailLoginDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSignUp = false;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isSignUp ? 'Sign Up' : 'Sign In'),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          setDialogState(() {
                            isSignUp = !isSignUp;
                          });
                        },
                  child: Text(isSignUp ? 'Sign In Instead' : 'Sign Up Instead'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text;

                          if (email.isEmpty || password.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter email and password'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (password.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password must be at least 6 characters'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                          });

                          try {
                            Map<String, dynamic>? userData;
                            if (isSignUp) {
                              // Sign up
                              userData = await _auth.signUpWithEmailAndPassword(email, password);
                            } else {
                              // Sign in
                              userData = await _auth.signInWithEmailAndPassword(email, password);
                            }

                            if (userData != null && mounted) {
                              // Save lightweight info locally
                              await widget.prefs.setString('email', userData['email'] ?? '');
                              await widget.prefs.setString('name', userData['displayName'] ?? '');

                              // Check if user profile is complete (from backend response)
                              final profileComplete = userData['profileComplete'] ?? false;
                              final language = userData['language'];
                              final hasLanguage = language != null && language.toString().trim().isNotEmpty;

                              if (mounted) {
                                Navigator.of(context).pop(); // Close dialog
                                if (profileComplete || hasLanguage) {
                                  // Already registered: go to Home
                                  Navigator.of(context).pushReplacementNamed(HomePage.routeName);
                                } else {
                                  // Not registered: go to Language selection
                                  Navigator.of(context).pushReplacementNamed(LanguageSelectionScreen.routeName);
                                }
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              setDialogState(() {
                                isLoading = false;
                              });
                              
                              // Parse error message for better user experience
                              String errorMessage = e.toString();
                              if (errorMessage.contains('not allowed') || 
                                  errorMessage.contains('sign-in provider is disabled')) {
                                errorMessage = 'Email/Password authentication is not enabled.\n'
                                    'Please enable it in Firebase Console:\n'
                                    'Authentication → Sign-in method → Email/Password';
                              } else if (errorMessage.contains('email-already-in-use')) {
                                errorMessage = 'This email is already registered. Please sign in instead.';
                              } else if (errorMessage.contains('user-not-found')) {
                                errorMessage = 'No account found with this email. Please sign up first.';
                              } else if (errorMessage.contains('wrong-password')) {
                                errorMessage = 'Incorrect password. Please try again.';
                              } else if (errorMessage.contains('invalid-email')) {
                                errorMessage = 'Invalid email address. Please check and try again.';
                              } else if (errorMessage.contains('weak-password')) {
                                errorMessage = 'Password is too weak. Please use a stronger password.';
                              } else {
                                errorMessage = errorMessage.replaceAll('Exception: ', '');
                                errorMessage = errorMessage.replaceAll('Failed to sign in: ', '');
                                errorMessage = errorMessage.replaceAll('Failed to sign up: ', '');
                              }
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isSignUp ? 'Sign Up' : 'Sign In'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom - 32,
              ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 12),
              Column(
                children: [
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Rectangular app logo (fills rectangle) - tap 5 times to unlock email login
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _logoTapCount++;
                      });
                      // Reset counter after 3 seconds of no taps
                      Future.delayed(const Duration(seconds: 3), () {
                        if (mounted) {
                          setState(() {
                            _logoTapCount = 0;
                          });
                        }
                      });
                      // Show email login dialog after 5 taps
                      if (_logoTapCount >= 5) {
                        _logoTapCount = 0; // Reset counter
                        _showEmailLoginDialog();
                      }
                    },
                    child: Container(
                    width: 350,
                    height: 270,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),

              Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    icon: SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset('assets/images/google.png'),
                    ),
                    label: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign up with Google'),
                    onPressed: _loading ? null : _signIn,
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  const Text(
                    'Terms of Service · Privacy Policy',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
