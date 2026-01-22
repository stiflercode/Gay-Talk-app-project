import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utilities/validators.dart';
import '../services/user_service.dart';
import 'home_page.dart';

class PersonalDetailsScreen extends StatefulWidget {
  static const routeName = '/details';
  final SharedPreferences prefs;
  PersonalDetailsScreen({required this.prefs, Key? key}) : super(key: key);

  @override
  _PersonalDetailsScreenState createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male'; // Default matches screenshot capitalization if needed, or keep logic internal
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.prefs.getString('name') ?? widget.prefs.getString('user_name') ?? '';
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final age = int.tryParse(ageStr);

    if (age == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid age')));
      return;
    }

    // Save locally
    await widget.prefs.setString('name', name);
    await widget.prefs.setInt('age', age);
    await widget.prefs.setString('gender', _gender);
    // Mark profile as completely onboarding-done locally if needed, but 'profileComplete' in firestore is key

    // Save to backend
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Update profile with name and mark as complete
        await _userService.updateProfile(
          uid: user.uid,
          displayName: name,
          profileComplete: true, // Mark as complete so they don't see this again
        );
      } catch (e) {
        debugPrint('Failed to save personal details to server: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved locally but failed to save remotely')),
          );
        }
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(HomePage.routeName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Widget _buildGenderChip(String label) {
    // Screenshot shows outlined chips. Selected state might be slightly different or just outlined.
    // Usually "I am" -> [Male] [Female] [Other]
    // If selected, maybe blue border? If not, grey border?
    // Let's assume standard choice chip behavior but styled to match the white pill look.
    
    final isSelected = _gender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = label),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isSelected ? Colors.black : Colors.grey.shade400, // Screenshot shows black/dark grey when active maybe? Or just grey.
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Personal Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), // Or handle specially
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What\'s Your Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: Validator.notEmpty,
              ),
              
              const SizedBox(height: 24),
              
              const Text('Your Age', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '18',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: Validator.age,
              ),

              const SizedBox(height: 24),

              const Text('I am', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildGenderChip('Male'),
                  _buildGenderChip('Female'),
                  _buildGenderChip('Other'),
                ],
              ),

              const SizedBox(height: 48), // Spacer at bottom
              
              // We might need a "Save" or "Next" button? Screenshot cuts off at bottom.
              // Assuming there should be one as per previous code.
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
