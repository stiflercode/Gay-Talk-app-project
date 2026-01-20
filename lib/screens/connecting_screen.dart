import 'dart:async';
import 'package:flutter/material.dart';
import 'call_screen.dart';

class ConnectingScreen extends StatefulWidget {
  final Map<String, dynamic> speaker;
  final String channelName;
  final String? callRequestId; // Optional call request ID

  const ConnectingScreen({
    required this.speaker,
    required this.channelName,
    this.callRequestId,
    super.key,
  });

  @override
  State<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends State<ConnectingScreen> {
  late Timer _timer;
  int dots = 1;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && !_isNavigating) {
        setState(() {
          dots = (dots % 3) + 1;
        });
      }
    });

    // Navigate to call screen after a brief delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_isNavigating) {
        _isNavigating = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              speaker: widget.speaker,
              channelName: widget.channelName,
              callRequestId: widget.callRequestId,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.speaker['name'];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF7F7F7),
              ),
              child: const Icon(Icons.phone_in_talk, color: Colors.black, size: 48),
            ),
            const SizedBox(height: 32),
            Text(
              "Connecting to $name${'.'.padRight(dots, '.')}",
              style: const TextStyle(
                color: Colors.black, 
                fontSize: 22,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.black),
          ],
        ),
      ),
    );
  }
}
