import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/notification_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final Map<String, dynamic> callRequest;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallScreen({
    required this.callRequest,
    required this.onAccept,
    required this.onReject,
    super.key,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ringAnimation;
  Timer? _autoRejectTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingRingtone = false;

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for avatar
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Ring animation
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    
    _ringAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );

    // Auto-reject after 30 seconds if not answered
    _autoRejectTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _stopRingtone();
        widget.onReject();
        Navigator.pop(context);
      }
    });

    // Start playing ringtone
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    if (_isPlayingRingtone) return;
    
    try {
      _isPlayingRingtone = true;
      // Set player to loop mode
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Try to play a ringtone file if it exists
      // Note: Add a ringtone.mp3 file to assets/sounds/ directory for custom ringtone
      // For now, the notification will handle the sound
      try {
        // Try to play ringtone from assets, fallback silently if fails
        await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'), volume: 1.0);
      } catch (e) {
        debugPrint('Note: Custom ringtone not found, using system notification sound.');
        _isPlayingRingtone = false;
      }
    } catch (e) {
      debugPrint('Audio player error: $e');
      _isPlayingRingtone = false;
    }
  }

  Future<void> _stopRingtone() async {
    if (!_isPlayingRingtone) return;
    
    try {
      _isPlayingRingtone = false;
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
  }

  @override
  void dispose() {
    _stopRingtone();
    NotificationService().stopRingtone(); // Stop ringtone from notification service
    _pulseController.dispose();
    _ringController.dispose();
    _autoRejectTimer?.cancel();
    NotificationService().cancelIncomingCallNotification();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callerName = widget.callRequest['callerName'] ?? 'Unknown Caller';
    final coinsPerMin = widget.callRequest['coinsPerMin'] ?? 5;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            
            // Incoming Call Text
            AnimatedBuilder(
              animation: _ringAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _ringAnimation.value),
                  child: const Text(
                    'Incoming Call',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // Caller Avatar with Pulse Animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF7F7F7),
                      border: Border.all(
                        color: Colors.black12,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.black26,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Caller Name
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Call Rate
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '$coinsPerMin Coins/min',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Reject Button
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _stopRingtone();
                        widget.onReject();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Decline', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                  ],
                ),
                
                // Accept Button
                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _stopRingtone();
                        widget.onAccept();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Accept', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

