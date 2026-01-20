import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/agora_config.dart';
import '../services/call_request_service.dart';
import '../services/agora_rtm_service.dart';
import '../services/user_service.dart';

class CallScreen extends StatefulWidget {
  final Map<String, dynamic> speaker;
  final String channelName;
  final String? callRequestId; // Optional call request ID
  final bool isCallee; // True if this user is receiving the call (admin), false if initiating (user)

  const CallScreen({
    required this.speaker,
    required this.channelName,
    this.callRequestId,
    this.isCallee = false, // Default: caller/initiator
    super.key,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

enum CallState {
  initializing,
  connecting,
  connected,
  reconnecting,
  error,
  disconnected,
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  bool muted = false;
  bool speakerOn = false;
  int seconds = 0;
  Timer? timer;
  Timer? _coinDeductionTimer; // Timer for deducting coins every 10 seconds
  CallState _callState = CallState.initializing;
  String? _errorMessage;
  int? _localUid;
  int? _remoteUid;
  bool _isConnected = false;
  bool _isEndingCall = false; // Prevent multiple calls to _endCall
  bool _isInitializing = false; // Prevent multiple initialization attempts
  final CallRequestService _callRequestService = CallRequestService();
  final AgoraRtmService _rtmService = AgoraRtmService();
  final UserService _userService = UserService();
  String? _currentCallId;
  String? _currentAdminId;
  bool _isFailoverInProgress = false;
  int _totalCoinsDeducted = 0; // Track total coins deducted during call
  int? _coinsPerMin; // Store coins per minute
  String? _userRole; // Store user role

  @override
  void initState() {
    super.initState();
    _currentAdminId = widget.speaker['uid'] ?? widget.speaker['id'];
    _initRtmAndAgora();
  }

  Future<void> _initRtmAndAgora() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    debugPrint('CallScreen: Initializing call, isCallee: ${widget.isCallee}');
    
    // If this is the callee (admin receiving call), directly join the RTC channel
    if (widget.isCallee) {
      debugPrint('CallScreen: Callee mode - directly joining RTC channel: ${widget.channelName}');
      _coinsPerMin = 5; // Default, could be passed via widget
      _startRtcCall();
      return;
    }

    // CALLER FLOW: Initialize RTM, route call, send invite
    
    // 1. Initialize RTM
    await _rtmService.initialize(currentUser.uid);
    _rtmService.onCallAccepted = (adminId) {
      debugPrint("Call accepted by $adminId");
      _startRtcCall(); // Only start RTC after acceptance to save coins/battery
    };
    _rtmService.onCallRejected = (adminId) {
      debugPrint("Call rejected by $adminId. Rolling over...");
      _handleFailover();
    };

    // 2. Initial Routing
    try {
      final routeRes = await _callRequestService.routeCall(
        userId: currentUser.uid,
        callerName: currentUser.displayName ?? "User",
      );
      _currentCallId = routeRes['callId'];
      _currentAdminId = routeRes['adminId'];
      _coinsPerMin = routeRes['coinsPerMin'] ?? 5;

      // 3. Send first invite
      _sendInvite();
      
      // Start a timeout for acceptance (e.g., 30 seconds)
      Timer(const Duration(seconds: 30), () {
        if (_callState == CallState.initializing && !_isFailoverInProgress) {
          debugPrint("Call timeout for $_currentAdminId. Rolling over...");
          _handleFailover();
        }
      });

    } catch (e) {
      debugPrint("Routing error: $e");
      _handleError(0, "Failed to route call");
    }
  }

  Future<void> _sendInvite() async {
    if (_currentAdminId == null) {
      debugPrint('CallScreen: No admin ID to send invite to');
      return;
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // Update UI to show "Calling..."
    if (mounted) {
      setState(() {
        _callState = CallState.connecting;
      });
    }
    
    debugPrint('CallScreen: Sending call invite to $_currentAdminId');
    
    // Try to send RTM invite
    final success = await _rtmService.sendCallInvite(
      _currentAdminId!,
      widget.channelName,
      currentUser?.displayName ?? "User",
    );
    
    if (!success) {
      debugPrint('CallScreen: RTM invite failed, starting call directly (testing mode)');
      // For testing: If RTM fails, start the call directly anyway
      // In production, you might want to show an error or retry
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connecting directly to call...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      // Start call directly without waiting for admin acceptance
      _startRtcCall();
    } else {
      debugPrint('CallScreen: RTM invite sent, waiting for admin response...');
    }
  }

  Future<void> _handleFailover() async {
    if (_currentCallId == null || _currentAdminId == null || _isFailoverInProgress) return;
    
    setState(() => _isFailoverInProgress = true);
    
    try {
      final nextRes = await _callRequestService.failoverCall(
        callId: _currentCallId!,
        failedAdminId: _currentAdminId!,
      );
      
      _currentAdminId = nextRes['nextAdminId'];
      _isFailoverInProgress = false;
      
      // Send invite to next admin
      _sendInvite();
      
    } catch (e) {
      debugPrint("Failover failed: $e");
      _handleError(0, "No admins available");
    }
  }

  Future<void> _startRtcCall() async {
    await _initAgora();
  }

  Future<void> _initAgora() async {
    // Prevent multiple SIMULTANEOUS initialization attempts
    // But allow re-initialization for new calls
    if (_isInitializing) {
      debugPrint('CallScreen: Agora initialization already in progress');
      return;
    }

    _isInitializing = true;
    debugPrint('CallScreen: Starting Agora initialization for channel: ${widget.channelName}');

    try {
      if (mounted) {
      setState(() {
        _callState = CallState.initializing;
        _errorMessage = null;
      });
      }

      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (!micPermission.isGranted) {
        throw Exception('Microphone permission denied');
      }

      // Initialize Agora engine - ensure we don't have an existing engine
      if (_engine != null) {
        try {
          await _engine!.leaveChannel();
          await _engine!.release();
        } catch (e) {
          debugPrint('Error cleaning up existing engine: $e');
        }
        _engine = null;
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(
        RtcEngineContext(
          appId: AgoraConfig.appId,
          logConfig: LogConfig(
            level: kDebugMode ? LogLevel.logLevelInfo : LogLevel.logLevelWarn,
          ),
        ),
      );

      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            final uid = connection.localUid;
            debugPrint('Successfully joined channel with uid: $uid');
            if (mounted) {
            setState(() {
              _localUid = uid;
              _callState = CallState.connected;
              _isConnected = true;
            });
            _startTimer();
              _initializeCoinDeduction();
            }
          },
          onError: (ErrorCodeType errCode, String msg) {
            debugPrint('Agora error: $errCode - $msg');
            // Check for specific error types
            if (errCode == ErrorCodeType.errInvalidToken) {
              _handleInvalidTokenError();
            } else {
              // ErrorCodeType is an enum - use index as approximate error code
              final errorCode = errCode.index;
              _handleError(errorCode, msg);
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user joined: $remoteUid');
            if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
            });
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('User offline: $remoteUid, reason: $reason');
            if (mounted) {
            setState(() {
              _remoteUid = null;
            });
            }
            if (mounted && !_isEndingCall) {
              // Auto-end call when other user leaves
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Other user left the call'),
                  duration: Duration(seconds: 2),
                ),
              );
              // End call after a brief delay
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted && !_isEndingCall) {
                  _endCall();
                }
              });
            }
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            debugPrint('Connection state changed: $state, reason: $reason');
            _handleConnectionStateChange(state, reason);
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint('Token will expire soon, refreshing...');
            _refreshToken();
          },
        ),
      );

      // Enable audio
      await _engine!.enableAudio();
      await _engine!.setDefaultAudioRouteToSpeakerphone(speakerOn);

      if (mounted) {
      setState(() {
        _callState = CallState.connecting;
      });
      }

      // Generate unique UID for this user
      final uid = AgoraConfig.generateUid();

      // Get the actual channel name to use (may be different in dev mode with temp token)
      final actualChannelName = AgoraConfig.getChannelName(widget.channelName);

      // Get token
      final token = await AgoraConfig.getToken(actualChannelName, uid);

      debugPrint('Joining channel: $actualChannelName with uid: $uid');

      // Check if already in a channel before joining
      if (_isConnected) {
        debugPrint('Already connected to channel, leaving first...');
        try {
          await _engine!.leaveChannel();
        } catch (e) {
          debugPrint('Error leaving existing channel: $e');
        }
      }

      // Join channel - use empty string if no token (Agora accepts this for development)
      await _engine!.joinChannel(
        token: token.isEmpty ? '' : token,
        channelId: actualChannelName,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
        ),
      );

      _isInitializing = false;
    } catch (e) {
      _isInitializing = false;
      debugPrint('Error initializing Agora: $e');
      
      // Clean up engine on error
      if (_engine != null) {
        try {
          await _engine!.release();
        } catch (releaseError) {
          debugPrint('Error releasing engine on error: $releaseError');
        }
        _engine = null;
      }

      if (mounted) {
      setState(() {
        _callState = CallState.error;
        _errorMessage = e.toString();
      });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        // Auto-close after showing error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context, 0);
          }
        });
      }
    }
  }

  void _handleInvalidTokenError() {
    if (mounted) {
    setState(() {
      _callState = CallState.error;
      _errorMessage = 'Invalid token. Token authentication is required.';
    });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Token required: Your Agora project requires token authentication.\n'
            'Get a temporary token from Agora Console → Your Project → Temporary Token',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ),
      );
    }
  }

  void _handleError(int errCode, String msg) {
    if (mounted) {
    setState(() {
      _callState = CallState.error;
      _errorMessage = 'Error $errCode: $msg';
    });
    }

    // Handle specific error codes
    // Common Agora error codes: 17=ERR_JOIN_CHANNEL_REJECTED, 101=ERR_INVALID_APP_ID
    if (errCode == 17) {
      // ERR_JOIN_CHANNEL_REJECTED
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to join call. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (errCode == 101) {
      // ERR_INVALID_APP_ID
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid app configuration. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call error: $msg (Code: $errCode)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _handleConnectionStateChange(
    ConnectionStateType state,
    ConnectionChangedReasonType reason,
  ) {
    if (!mounted) return;
    
    switch (state) {
      case ConnectionStateType.connectionStateConnecting:
        setState(() {
          _callState = CallState.connecting;
        });
        break;
      case ConnectionStateType.connectionStateConnected:
        setState(() {
          _callState = CallState.connected;
          _isConnected = true;
        });
        break;
      case ConnectionStateType.connectionStateReconnecting:
        setState(() {
          _callState = CallState.reconnecting;
        });
        break;
      case ConnectionStateType.connectionStateDisconnected:
        setState(() {
          _callState = CallState.disconnected;
          _isConnected = false;
        });
        break;
      case ConnectionStateType.connectionStateFailed:
        setState(() {
          _callState = CallState.error;
          _errorMessage = 'Connection failed';
        });
        break;
    }
  }

  Future<void> _refreshToken() async {
    if (_engine == null) return;
    try {
      final uid = _localUid ?? AgoraConfig.generateUid();
      final token = await AgoraConfig.getToken(widget.channelName, uid);
      if (token.isNotEmpty) {
        await _engine!.renewToken(token);
        debugPrint('Token refreshed successfully');
      }
    } catch (e) {
      debugPrint('Failed to refresh token: $e');
    }
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
      setState(() => seconds++);
      }
    });
  }

  /// Initialize coin deduction system - deducts coins every 10 seconds
  Future<void> _initializeCoinDeduction() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || _currentCallId == null) return;

      _coinsPerMin ??= 5;
      
      // Get user role via UserService
      _userRole = await UserService().getUserRole(currentUser.uid);

      // Only charge regular users, not admins
      if (_userRole != 'user') {
        debugPrint('Admin user - no coin deduction');
        return;
      }

      // Calculate coins per 10 seconds
      final coinsPer10Sec = (_coinsPerMin! / 6.0).ceil(); // coinsPerMin / 60 * 10

      debugPrint('Starting coin deduction: $coinsPer10Sec coins every 10 seconds');

      // Start timer to deduct coins every 10 seconds
      _coinDeductionTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
        if (_isEndingCall || !mounted) {
          _coinDeductionTimer?.cancel();
          return;
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          int currentBalance = prefs.getInt("wallet_balance") ?? 0;

          // Check if user has enough balance
          if (currentBalance < coinsPer10Sec) {
            debugPrint('Insufficient balance. Ending call.');
            if (mounted) {
              _showInsufficientBalancePopup();
            }
            return;
          }

          // Deduct coins
          final newBalance = currentBalance - coinsPer10Sec;
          _totalCoinsDeducted += coinsPer10Sec;

          // Update SharedPreferences
          await prefs.setInt("wallet_balance", newBalance);

          // Update MongoDB via UserService
          try {
            await _userService.updateWallet(
              uid: currentUser.uid,
              amount: coinsPer10Sec.toDouble(),
              operation: 'subtract',
            );
          } catch (e) {
            debugPrint('Failed to update wallet in MongoDB: $e');
          }

          debugPrint('Deducted $coinsPer10Sec coins (Total: $_totalCoinsDeducted). New balance: $newBalance');
        } catch (e) {
          debugPrint('Error deducting coins: $e');
        }
      });
    } catch (e) {
      debugPrint('Error initializing coin deduction: $e');
    }
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _showInsufficientBalancePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_wallet, size: 40, color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Low Balance!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Your coins are finished. Please recharge to continue talking to your friends.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _endCall();
              // In a real app, you'd navigate to the payment/recharge screen here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Add Coins', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // Auto-end call after a delay if they don't click
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isEndingCall) {
        Navigator.of(context, rootNavigator: true).pop(); // Close dialog
        _endCall();
      }
    });
  }

  Future<void> _endCall() async {
    if (_isEndingCall) return; // Prevent multiple calls
    _isEndingCall = true;
    
    debugPrint('CallScreen: Ending call...');
    
    timer?.cancel();
    _coinDeductionTimer?.cancel(); // Stop coin deduction timer
    
    // Clear RTM callbacks to prevent interference with future calls
    _rtmService.onCallAccepted = null;
    _rtmService.onCallRejected = null;
    
    // Complete call request with duration and total coins deducted
    if (_currentCallId != null && seconds > 0) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Use the total coins already deducted during the call
          final coinsCharged = _totalCoinsDeducted;
          
          // Complete call request via Node.js
          await _callRequestService.updateCallStatus(
            callId: _currentCallId!,
            status: 'completed',
            durationSeconds: seconds,
            coinsCharged: coinsCharged,
          );
          
          debugPrint('Call completed locally: duration=$seconds seconds, total coins deducted=$coinsCharged');
        }
      } catch (e) {
        debugPrint('Error completing call request: $e');
      }
    }
    
    // Clean up Agora RTC engine
    if (_engine != null) {
      try {
        debugPrint('CallScreen: Leaving channel...');
        await _engine!.leaveChannel();
      } catch (e) {
        debugPrint('Error leaving channel: $e');
      }
      try {
        debugPrint('CallScreen: Releasing engine...');
        await _engine!.release();
      } catch (e) {
        debugPrint('Error releasing engine: $e');
      }
      _engine = null;
    }
    
    // Reset state flags for potential reuse
    _isInitializing = false;
    _isConnected = false;
    
    // Clear token cache so next call gets fresh token
    AgoraConfig.clearTokenCache();
    
    debugPrint('CallScreen: Call ended, resources cleaned up');
    
    if (mounted) {
      Navigator.pop(context, seconds);
    }
  }

  @override
  void dispose() {
    debugPrint('CallScreen: dispose() called');
    timer?.cancel();
    _coinDeductionTimer?.cancel();
    
    // Clear RTM callbacks
    _rtmService.onCallAccepted = null;
    _rtmService.onCallRejected = null;
    
    // If engine wasn't cleaned up yet, do it synchronously
    if (_engine != null && !_isEndingCall) {
      debugPrint('CallScreen: Cleaning up engine in dispose');
      _engine!.leaveChannel().catchError((e) => debugPrint('Error leaving channel in dispose: $e'));
      _engine!.release().catchError((e) => debugPrint('Error releasing engine in dispose: $e'));
      _engine = null;
    }
    
    // Clear token cache
    AgoraConfig.clearTokenCache();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.speaker['name'] ?? widget.speaker['username'] ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context, seconds),
        ),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minimal Avatar
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF7F7F7),
            ),
            child: const Icon(Icons.person, size: 64, color: Colors.black12),
          ),
          const SizedBox(height: 32),

          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (_callState != CallState.connected)
             Padding(
               padding: const EdgeInsets.only(bottom: 24),
               child: _buildConnectionStatus(),
             ),

          // Timer
          Text(
            _formatTime(seconds),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _callState == CallState.connected ? Colors.black54 : Colors.grey[300],
            ),
          ),


          const Spacer(),

          /// 🔵 Call Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(
                icon: muted ? Icons.mic_off : Icons.mic,
                label: muted ? "Muted" : "Mute",
                color: muted ? Colors.grey : Colors.blue,
                onTap: () {
                  if (mounted) {
                  setState(() => muted = !muted);
                  _engine?.muteLocalAudioStream(muted);
                  }
                },
              ),
              const SizedBox(width: 24),
              _controlButton(
                icon: speakerOn ? Icons.volume_up : Icons.volume_mute,
                label: "Speaker",
                color: speakerOn ? Colors.blue : Colors.grey,
                onTap: () {
                  if (mounted) {
                  setState(() => speakerOn = !speakerOn);
                  _engine?.setEnableSpeakerphone(speakerOn);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 40),

          /// 🔴 End Call Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(28),
            ),
            onPressed: _endCall,
            child: const Icon(Icons.call_end, size: 34, color: Colors.white),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// 🔹 Pill Widget
  Widget _pill(String text, {Color color = Colors.blue}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 🔹 Control Button
  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha((0.15 * 255).round()),
            ),
            child: Icon(icon, size: 30, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    String statusText;
    Color statusColor;
    bool showSpinner = true;

    switch (_callState) {
      case CallState.initializing:
        statusText = 'Initializing...';
        statusColor = Colors.blue;
        showSpinner = true;
        break;
      case CallState.connecting:
        statusText = 'Connecting...';
        statusColor = Colors.orange;
        showSpinner = true;
        break;
      case CallState.reconnecting:
        statusText = 'Reconnecting...';
        statusColor = Colors.orange;
        showSpinner = true;
        break;
      case CallState.error:
        statusText = _errorMessage ?? 'Connection error';
        statusColor = Colors.red;
        showSpinner = false;
        break;
      case CallState.disconnected:
        statusText = 'Disconnected';
        statusColor = Colors.red;
        showSpinner = false;
        break;
      case CallState.connected:
        statusText = _remoteUid == null
            ? 'Waiting for other user...'
            : 'Connected';
        statusColor = Colors.green;
        showSpinner = _remoteUid == null;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
