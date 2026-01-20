// lib/screens/wallet_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'upi_verify_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class WalletPage extends StatefulWidget {
  static const routeName = '/wallet';
  final SharedPreferences prefs;
  const WalletPage({required this.prefs, Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late int _balance;
  bool _loading = false;
  final UserService _userService = UserService();

  final List<Map<String, dynamic>> _packs = [
    {'coins': 50, 'price': 50},
    {'coins': 100, 'price': 100},
    {'coins': 200, 'price': 189},
    {'coins': 500, 'price': 449},
  ];

  @override
  void initState() {
    super.initState();
    _balance = widget.prefs.getInt('wallet_balance') ?? 0;
    _maybeSyncFromServer();
  }

  Future<void> _maybeSyncFromServer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      // Use UserService to get wallet balance from MongoDB backend
      final wb = await _userService.getWalletBalance(user.uid);
      final wbInt = wb.toInt();
      await widget.prefs.setInt('wallet_balance', wbInt);
      if (mounted) setState(() => _balance = wbInt);
    } catch (_) {
      // ignore network errors
    }
  }

  void _onSelectPack(Map<String, dynamic> pack) async {
    // Store old balance for comparison
    final oldBalance = _balance;
    
    // open UPI verify passing pack details
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UPIVerifyScreen(prefs: widget.prefs, coins: pack['coins'], amount: pack['price'])),
    );

    // if purchase completed, refresh balance and show update
    if (result == true && mounted) {
      final newBalance = widget.prefs.getInt('wallet_balance') ?? _balance;
      final coinsAdded = newBalance - oldBalance;
      
      setState(() => _balance = newBalance);
      
      // Show snackbar with increment if coins were added
      if (coinsAdded > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Image.asset('assets/images/coins.png', width: 20, height: 20),
                const SizedBox(width: 8),
                Text(
                  'Wallet updated! Balance: $_balance Coins (+$coinsAdded)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // responsive column count
    final width = MediaQuery.of(context).size.width;
    final crossAxis = width > 800 ? 3 : (width > 600 ? 2 : 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Centered wallet logo above balance
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wallet logo circle
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/images/wallet.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Current Balance', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                Text('$_balance Coins', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('Choose A Recharge Pack', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const SizedBox(height: 12),

            // Packs grid (responsive, no overflow)
            Expanded(
              child: GridView.builder(
                itemCount: _packs.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxis,
                  childAspectRatio: 1.9,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, i) {
                  final p = _packs[i];
                  return GestureDetector(
                    onTap: () => _onSelectPack(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.shade300, width: 2),
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          // coin image in a safe sized circle
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade50,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Image.asset('assets/images/coins.png', fit: BoxFit.contain),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p['coins']} Coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('₹${p['price']}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
