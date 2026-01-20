import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'personal_details_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const routeName = '/dashboard';
  final SharedPreferences prefs;
  const DashboardScreen({required this.prefs, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _name;
  late int _age;
  late String _gender;
  final AuthService _auth = AuthService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _name = widget.prefs.getString('name') ?? widget.prefs.getString('user_name') ?? 'User';
    _age = widget.prefs.getInt('age') ?? 18;
    _gender = widget.prefs.getString('gender') ?? 'male';
    _loadRemoteProfileIfNeeded();
  }

  Future<void> _loadRemoteProfileIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await _userService.getUser(user.uid);
      final data = snap.data();
      if (data != null) {
        setState(() {
          _name = (data['name'] ?? data['displayName'] ?? _name) as String;
          _age = (data['age'] ?? _age) as int;
          _gender = (data['gender'] ?? _gender) as String;
        });
      }
    } catch (e) {
      // ignore - show local data
    }
  }

  void _signOut() async {
    await _auth.signOut();
    // clear local lightweight saved user fields if desired:
    // await SharedPreferences.getInstance().then((p) => p.remove('user_email'));
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome, $_name', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Age: $_age'),
          Text('Gender: $_gender'),
          SizedBox(height: 16),
          ElevatedButton(onPressed: () => Navigator.of(context).pushNamed(PersonalDetailsScreen.routeName), child: Text('Edit Profile')),
          SizedBox(height: 8),
          ElevatedButton(onPressed: _signOut, child: Text('Sign Out')),
        ]),
      ),
    );
  }
}
