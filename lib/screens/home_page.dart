// lib/screens/home_page.dart

import 'dart:convert';
import 'dart:math';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'wallet_page.dart';
import 'login_screen.dart';
import 'connecting_screen.dart';
import 'incoming_call_screen.dart';
import 'call_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';
import '../services/user_service.dart';
import '../services/call_request_service.dart';
import '../services/notification_service.dart';
import '../services/agora_rtm_service.dart';
import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';
  final SharedPreferences prefs;

  const HomePage({required this.prefs, Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _balance = 0; // Initialize with default value
  final UserService _userService = UserService();
  final CallRequestService _callRequestService = CallRequestService();
  String? _currentUserRole;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnlineStatus(true);
    // Initialize balance synchronously first
    _balance = widget.prefs.getInt("wallet_balance") ?? 0;
    _initializeWallet();
    _loadUserRole();
    // Don't call _setupCallRequestListener here - wait until we know if user is admin
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      final role = await _userService.getUserRole(user.uid);
      if (mounted) {
        setState(() {
          _currentUserRole = role;
        });
        
        // If admin, start RTM immediately
        if (role == 'admin') {
          _setupCallRequestListener();
        }
      }
      // Save FCM token for push notifications
      _saveFCMToken();
    }
  }

  Future<void> _saveFCMToken() async {
    try {
      final token = await NotificationService().getFCMToken();
      if (token != null && _currentUserId != null) {
        await _userService.updateFCMToken(_currentUserId!, token);
        debugPrint('FCM token saved for user: $_currentUserId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  final AgoraRtmService _rtmService = AgoraRtmService();
  bool _isShowingIncomingCall = false;

  void _setupCallRequestListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('HomePage: Cannot setup RTM - no user logged in');
      return;
    }

    // Only admins need to listen for incoming calls
    if (_currentUserRole != 'admin') {
      debugPrint('HomePage: Skipping RTM setup - user is not admin (role: $_currentUserRole)');
      return;
    }

    debugPrint('HomePage: 🔧 Setting up RTM call listener for ADMIN: ${user.uid}');

    // 1. Define the callback handler
    void handleIncomingCall(String callerId, String callerName, String channelId) {
      debugPrint('HomePage: 🔔 INCOMING CALL from $callerName ($callerId) on channel $channelId');
      
      // Trigger a system notification as well for better visibility/ringing
      NotificationService().showIncomingCallNotification(
        callerName: callerName,
        callRequestId: channelId, // Use channelId as payload
      );

      if (mounted && !_isShowingIncomingCall) {
        _isShowingIncomingCall = true;
        _showIncomingCall({
          'callerId': callerId,
          'callerName': callerName,
          'channelName': channelId,
          'coinsPerMin': 5,
        });
      }
    }

    // 2. Set the callback BEFORE initializing RTM (important!)
    _rtmService.onIncomingCall = handleIncomingCall;

    // 3. Initialize/ensure RTM connection
    _rtmService.ensureConnected(user.uid).then((_) {
      // Re-register callback after connection in case it was cleared
      _rtmService.onIncomingCall = handleIncomingCall;
      
      if (mounted) {
        setState(() {}); // Refresh connection dot
        if (_rtmService.isConnected) {
          debugPrint('HomePage: ✅ RTM connected and ready for calls');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Ready for incoming calls'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint('HomePage: ⚠️ RTM connection failed');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Signaling connection failed. Tap green/red dot to retry.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }).catchError((e) {
      debugPrint('HomePage: ❌ RTM initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showIncomingCall(Map<String, dynamic> request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callRequest: request,
          onAccept: () async {
            // Signal acceptance via RTM
            await _rtmService.sendCallAccept(request['callerId']);
            _isShowingIncomingCall = false;
            
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    speaker: {
                      'uid': request['callerId'],
                      'name': request['callerName'],
                    },
                    channelName: request['channelName'],
                    isCallee: true, // Admin is receiving the call, not initiating
                  ),
                ),
              );
            }
          },
          onReject: () async {
            // Signal rejection via RTM
            await _rtmService.sendCallReject(request['callerId']);
            _isShowingIncomingCall = false;
          },
        ),
      ),
    ).then((_) {
      _isShowingIncomingCall = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_currentUserRole == 'admin') {
      _setUserOnlineStatus(false);
    }
    _rtmService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserOnlineStatus(true);
      // Always ensure RTM is connected for admins on resume
      if (_currentUserRole == 'admin') {
        debugPrint('HomePage: App resumed, ensuring RTM connection for admin');
        _setupCallRequestListener();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _setUserOnlineStatus(false);
    }
  }

  Future<void> _setUserOnlineStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Logic: Only Admins "status" really matters for calling, but good for all users
      // To save reads/writes, maybe just check if user is admin?
      // For now, update for everyone.
      await _userService.updateOnlineStatus(user.uid, isOnline);
    }
  }

  // 🔄 Always read from SharedPreferences
  Future<void> _initializeWallet() async {
    final first = widget.prefs.getBool('initialized') ?? false;
    if (!first) {
      await widget.prefs.setInt("wallet_balance", 50);
      await widget.prefs.setBool("initialized", true);
    }
    await _refreshBalance();
  }

  // 🔄 Single source of truth
  Future<void> _refreshBalance() async {
    final b = widget.prefs.getInt("wallet_balance") ?? 0;
    if (mounted) {
      setState(() => _balance = b);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await widget.prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, LoginScreen.routeName);
  }

  // ---------------- CALL HANDLER ----------------

  Future<void> _onTalkPressed(Map<String, dynamic> speaker) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String adminId = speaker['uid'] ?? speaker['id'] ?? '';
    final String channelId = "channel_${currentUser.uid}"; // Simplified channel ID

    // Check balance if role is user
    final userRole = _currentUserRole ?? await _userService.getUserRole(currentUser.uid);
    if (userRole == 'user') {
      final int coinsPerMin = speaker['coinsPerMin'] ?? 5;
      if (_balance < coinsPerMin) {
        // PRD: Show wallet popup when balance is insufficient
        final result = await Navigator.pushNamed(context, WalletPage.routeName);
        // Refresh balance after returning from wallet
        await _refreshBalance();
        // If still insufficient after returning, don't proceed
        if (_balance < coinsPerMin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Add more coins to make a call")),
          );
          return;
        }
      }
    }

    // Navigate to CallScreen which handles RTM signaling and routing
    final durationSec = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          speaker: speaker, // This is the "Masked" speaker
          channelName: channelId,
        ),
      ),
    );

    // Refresh balance after call
    await _refreshBalance();

    if (durationSec != null && durationSec > 0 && mounted) {
      final minutes = (durationSec / 60).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Call ended • $minutes min")),
      );
    }
  }

  // ---------------- HISTORY ----------------

  Future<List<Map<String, dynamic>>> _getLocalLogs() async {
    final raw = widget.prefs.getString("call_logs") ?? "[]";
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),

      // 🔵 APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        // Wrap the title row to avoid overflow on small widths
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_short.png', height: 28),
            const SizedBox(width: 8),
            Image.asset('assets/images/name.png', height: 24),
          ],
          ),
        ),

        // 💰 WALLET & LOGOUT
        actions: [
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () async {
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _signOut();
              }
            },
          ),
          // Wallet Button
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, WalletPage.routeName);
              await _refreshBalance(); // 🔥 key fix
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4CC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    "$_balance Coins",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  // RTM Status Dot (Clickable for admins)
                  GestureDetector(
                    onTap: _currentUserRole == 'admin' ? () {
                      debugPrint('HomePage: Manual RTM reconnect triggered');
                      _setupCallRequestListener();
                    } : null,
                    child: StreamBuilder<void>(
                      stream: Stream.periodic(const Duration(seconds: 3)),
                      builder: (context, _) {
                        final isConnected = _rtmService.isConnected;
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected ? Colors.green : Colors.red,
                            boxShadow: [
                              if (!isConnected && _currentUserRole == 'admin')
                                BoxShadow(color: Colors.red.withAlpha(100), blurRadius: 4, spreadRadius: 1),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: _currentUserRole == 'admin' 
        ? _buildAdminCallLogsView()
        : _buildUserListView(),
    );
  }

  /// Build admin view - shows call logs instead of users
  Widget _buildAdminCallLogsView() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _callRequestService.getCallLogsForAdmin(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final callLogs = snapshot.data ?? [];

        if (callLogs.isEmpty) {
          return Column(
            children: [
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_disabled, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No call logs yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You will see completed calls here',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              _buildFooterLinks(),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: callLogs.length + 1, // +1 for footer
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            // Footer with links
            if (index == callLogs.length) {
              return _buildFooterLinks();
            }
            final log = callLogs[index];
            final callerName = log['callerName'] ?? 'Unknown';
            final duration = log['duration'] ?? 0;
            final coinsCharged = log['coinsCharged'] ?? 0;
            final endedAtRaw = log['endedAt'];
            // Handle various date formats from backend
            DateTime? endedAt;
            if (endedAtRaw is DateTime) {
              endedAt = endedAtRaw;
            } else if (endedAtRaw is String) {
              endedAt = DateTime.tryParse(endedAtRaw);
            }
            final minutes = (duration / 60).toStringAsFixed(1);

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blueAccent, width: 1.5),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFEAF0FF),
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$minutes min call',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        if (endedAt != null)
                          Text(
                            _formatDate(endedAt),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FFF8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+$coinsCharged coins',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build user view - shows admins they can call
  Widget _buildUserListView() {
    return StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getUsersStream(),
        builder: (context, snapshot) {
          if (_getUsersStream() == null) {
            return const Center(child: Text('Please login to see users'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No admins available'));
          }

          final users = snapshot.data!.map((data) {
            final uid = data['uid'] ?? data['id'] ?? '';
            // Use the rating from backend if available (masked listeners have preset ratings)
            // Otherwise generate consistent random rating based on user UID
            final rating = data['rating'] ?? _generateRandomRating(uid);
            
            return {
              'id': data['id'] ?? '',
              'uid': uid,
              'maskId': data['maskId'], // Masked listener ID (e.g., "listener_1")
              'isMasked': data['isMasked'] ?? false, // Flag: true if this is a virtual identity
              'name': data['name'] ?? data['displayName'] ?? data['username'] ?? 'User',
              'username': data['username'] ?? '',
              'status': data['isOnline'] == true ? 'Online' : 'Offline',
              'languages': data['languages'] is List ? List<String>.from(data['languages']) : ['English'],
              'rating': rating,
              'coinsPerMin': data['coinsPerMin'] ?? 5,
              'maxCharge': data['maxCharge'] ?? 500,
            };
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length + 1, // +1 for footer
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              // Footer with links (last item)
              if (index == users.length) {
                return _buildFooterLinks();
              }

              // 👤 SPEAKER CARD - matching screenshot design
              final s = users[index];
              final languages = (s['languages'] as List?)?.join(', ') ?? 'English';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB3D4FC), width: 1.5),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Avatar, Name/Online, Star rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: const CircleAvatar(
                            radius: 23,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person_outline, color: Colors.grey, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name and Online status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['name'] ?? 'Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Online',
                                style: TextStyle(
                                  color: Color(0xFF2196F3),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _pill('Listener'),
                                  const SizedBox(width: 6),
                                  _pill(languages),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Star rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 14, color: Color(0xFFFFB300)),
                              const SizedBox(width: 4),
                              Text(
                                '${s['rating'] ?? 4.8}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Bottom row: Talk button + Coins/min
                    Row(
                      children: [
                        // Talk button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _onTalkPressed(s),
                            icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                            label: const Text(
                              'Talk',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Coins per min badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/coins.png',
                                width: 18,
                                height: 18,
                                errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on, color: Colors.orange, size: 18),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${s['coinsPerMin'] ?? 5} Coins/min',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
    );
  }

  Stream<List<Map<String, dynamic>>>? _getUsersStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return null;
    }
    
    // Get user role and filter accordingly
    if (_currentUserRole == null) {
      _userService.getUserRole(currentUser.uid).then((role) {
        if (mounted) {
          setState(() {
            _currentUserRole = role;
          });
        }
      });
      // Return empty stream while loading role
      return Stream.value([]);
    }
    
    // For regular users: Return MASKED listeners (virtual identities)
    // Users will see "Listener 1", "Listener 2" etc. but calls route to real admins
    if (_currentUserRole == 'user') {
      debugPrint('📋 User role detected - fetching masked listeners');
      return _userService.getMaskedListeners();
    }
    
    // For admins: Return real user list (they don't need to see other admins)
    return _userService.getUsersByRole(currentUser.uid, _currentUserRole ?? 'user');
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  /// Generate a consistent random rating for a user based on their UID
  /// Returns a rating between 4.0 and 5.0 (good ratings)
  double _generateRandomRating(String uid) {
    // Use UID hash to generate consistent random number
    final hash = uid.hashCode;
    // Generate a value between 0 and 1
    final random = (hash.abs() % 1000) / 1000.0;
    // Map to rating range 4.0 to 5.0
    final rating = 4.0 + (random * 1.0);
    // Round to 1 decimal place
    return double.parse(rating.toStringAsFixed(1));
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Build footer with Terms of Service and Privacy Policy links
  Widget _buildFooterLinks() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TermsOfServiceScreen(),
                ),
              );
            },
            child: const Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Text(
            ' • ',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
            child: const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
