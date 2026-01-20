import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/payment_service.dart';
import 'package:flutter/foundation.dart';

class UPIVerifyScreen extends StatefulWidget {
  static const routeName = '/upi_verify';
  final SharedPreferences prefs;
  final int coins;
  final int amount;
  const UPIVerifyScreen({required this.prefs, required this.coins, required this.amount, Key? key}) : super(key: key);

  @override
  State<UPIVerifyScreen> createState() => _UPIVerifyScreenState();
}

class _UPIVerifyScreenState extends State<UPIVerifyScreen> {
  final Razorpay _razorpay = Razorpay();
  bool _processing = false;
  String? _orderId;
  String? _razorpayKeyId;

  @override
  void initState() {
    super.initState();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('Payment Success: ${response.paymentId}');
    
    if (_orderId == null || _razorpayKeyId == null) {
      _showError('Order information missing');
      return;
    }

    setState(() => _processing = true);

    try {
      // Verify payment with backend (MongoDB) - backend updates wallet balance
      final result = await PaymentService.verifyPayment(
        orderId: _orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
        coins: widget.coins,
      );

      // Update local balance from backend response
      final newBalance = result['newBalance'] as int;
      final oldBalance = widget.prefs.getInt('wallet_balance') ?? 0;
      await widget.prefs.setInt('wallet_balance', newBalance);

      // No Firestore sync needed - backend already updated MongoDB

      if (mounted) {
        setState(() => _processing = false);
        // Show success dialog with coin increment
        _showSuccessDialog(oldBalance, widget.coins, newBalance);
      }
    } catch (e) {
      debugPrint('Payment verification error: $e');
      if (mounted) {
        setState(() => _processing = false);
        _showError('Payment verification failed: ${e.toString()}');
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    _showError('Payment failed: ${response.message}');
    setState(() => _processing = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessDialog(int oldBalance, int coinsAdded, int newBalance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.shade50,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Coin increment display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Previous Balance:',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            '$oldBalance Coins',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/images/coins.png',
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Coins Added:',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                          Text(
                            '+$coinsAdded Coins',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Balance:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$newBalance Coins',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(true); // Return to wallet page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _initiatePayment() async {
    if (_processing) return;

    setState(() => _processing = true);

    try {
      // Create order via Firebase Functions
      final orderData = await PaymentService.createOrder(
        amount: widget.amount,
        coins: widget.coins,
      );

      _orderId = orderData['orderId'] as String;
      _razorpayKeyId = orderData['keyId'] as String;
      final orderAmount = orderData['amount'] as int;

      // Open Razorpay Checkout
      final options = {
        'key': _razorpayKeyId,
        'amount': orderAmount,
        'name': 'GayTalk',
        'description': 'Wallet Top-up: ${widget.coins} Coins',
        'prefill': {
          'contact': '',
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
        },
        'external': {
          'wallets': ['paytm', 'phonepe', 'gpay', 'bhim'],
        },
        'order_id': _orderId,
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Payment initiation error: $e');
      String errorMessage = 'Failed to initiate payment';
      if (e.toString().contains('User not authenticated')) {
        errorMessage = 'Please login to continue';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please check your internet connection';
      } else if (e.toString().contains('Failed to create order')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      _showError(errorMessage);
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.prefs.getInt('wallet_balance') ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Information')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Top centered wallet logo + balance
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
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
                Text(
                  'Current Balance: $balance Coins',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Topup: ${widget.coins} Coins for ₹${widget.amount}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose A Recharge pack',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _packChip(50, 50),
                _packChip(100, 100),
                _packChip(200, 189),
                _packChip(500, 449),
              ],
            ),
            const SizedBox(height: 24),

            // Payment button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processing ? null : _initiatePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Pay ₹${widget.amount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Secure payment via Razorpay',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _packChip(int coins, int price) {
    final selected = coins == widget.coins && price == widget.amount;
    return GestureDetector(
      onTap: () {
        // Replace current route with new UPIVerifyScreen with new pack selection
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => UPIVerifyScreen(
              prefs: widget.prefs,
              coins: coins,
              amount: price,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
          color: selected ? Colors.blue.shade50 : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/coins.png', width: 22, height: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$coins Coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('₹$price', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
