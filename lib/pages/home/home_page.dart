import 'package:bm_security/pages/maps/maps.dart';
import 'package:bm_security/pages/my_team/my_team.dart';
import 'package:bm_security/pages/profile/profile.dart';
import 'package:bm_security/pages/requisitions/completed/completed.dart';
import 'package:bm_security/pages/requisitions/inProgress/inProgress.dart';
import 'package:bm_security/pages/requisitions/pending/pending.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/pages/login/login_page.dart';
import 'package:bm_security/services/api_service.dart';
import 'package:bm_security/services/requisitions/requisitions_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/menu_tile.dart';
import '../sos/sos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String userName;
  late String userPhone;
  final int _pendingJourneyPlans = 0;
  final int _pendingCashRequests = 0;
  final int _inProgressCashRequests = 0;
  final int _completedCashRequests = 0;
  int _pendingVisitorRequests = 0;
  bool _isLoading = true;
  final RequisitionsService _requisitionsService = RequisitionsService();
  int _pendingCount = 0;
  int _inProgressCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCounts();
  }

  void _loadUserData() {
    final box = GetStorage();
    final user = box.read('user');

    setState(() {
      if (user != null && user is Map<String, dynamic>) {
        userName = user['name'] ?? 'User';
        userPhone = user['phoneNumber'] ?? 'No phone number';
      } else {
        userName = 'User';
        userPhone = 'No phone number';
      }
    });
  }

  Future<void> _loadCounts() async {
    if (!mounted) return;
    
    try {
      // Reset counts before loading
      setState(() {
        _pendingCount = 0;
        _inProgressCount = 0;
      });
      
      // Load pending requests
      List<dynamic> pendingRequests = [];
      try {
        pendingRequests = await _requisitionsService.getMyAssignedRequests();
      } catch (error) {
        print('Error loading pending requests: $error');
      }
          
      // Load in-progress requests
      List<dynamic> inProgressRequests = [];
      try {
        inProgressRequests = await _requisitionsService.getInProgressRequests();
      } catch (error) {
        print('Error loading in-progress requests: $error');
      }

      if (mounted) {
        setState(() {
          _pendingCount = pendingRequests.length;
          _inProgressCount = inProgressRequests.length;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error in _loadCounts: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _pendingCount = 0;
          _inProgressCount = 0;
          _isLoading = false;
        });
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load request counts. Pull down to refresh.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    _loadUserData();
    _loadCounts();
  }

  Future<void> _logout() async {
    try {
      // Show confirmation dialog
      final shouldLogout = await showDialog<bool>(
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
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (shouldLogout != true) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Clear all stored data
      final box = GetStorage();
      await box.erase();

      // Close loading indicator
      if (!mounted) return;
      Navigator.pop(context);

      // Navigate to login page and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      if (!mounted) return;

      // Close loading indicator if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makeCall(String phoneNumber, String contactName) async {
    try {
      final url = 'tel:$phoneNumber';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone call to $contactName'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error making phone call: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showCallDialog() async {
    // List of emergency contacts
    final emergencyContacts = [
      {'name': 'Security Office', 'phone': '+254700123456'},
      {'name': 'Estate Manager', 'phone': '+254711987654'},
      {'name': 'Maintenance', 'phone': '+254722345678'},
      {'name': 'Emergency Services', 'phone': '999'},
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.call, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Emergency Contacts'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: emergencyContacts.length,
            itemBuilder: (context, index) {
              final contact = emergencyContacts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    index == 3 ? Icons.emergency : Icons.person,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(contact['name']!),
                subtitle: Text(contact['phone']!),
                trailing: IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () {
                    Navigator.pop(context);
                    _makeCall(contact['phone']!, contact['name']!);
                  },
                ),
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(contact['phone']!, contact['name']!);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _refreshData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing dashboard...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Grid menu items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 1.0,
                  mainAxisSpacing: 1.0,
                  children: [
                    // User Profile Tile
                    MenuTile(
                      title: 'Driver',
                      subtitle: '$userName\n$userPhone',
                      icon: Icons.person,
                      onTap: () {
                        // TODO: Navigate to profile page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilePage()),
                        );
                      },
                    ),
                    MenuTile(
                      title: 'PENDING',
                      icon: Icons.pending_outlined,
                      badgeCount: _isLoading ? null : _pendingCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PendingRequisitionsPage()),
                        );
                      },
                    ),

                    MenuTile(
                      title: 'IN PROGRESS',
                      icon: Icons.watch_later_outlined,
                      badgeCount: _isLoading ? null : _inProgressCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const InProgressPage()),
                        );
                      },
                    ),

                    MenuTile(
                      title: 'COMPLETED',
                      icon: Icons.done_all_outlined,
                      badgeCount: _isLoading ? null : _completedCashRequests,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CompletedPage()),
                        );
                      },
                    ),

                    MenuTile(
                      title: 'SOS',
                      icon: Icons.emergency_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SOSPage()),
                        );
                      },
                    ),
                    MenuTile(
                      title: 'My Team',
                      icon: Icons.group,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MyTeamPage()),
                        );
                      },
                    ),

                    MenuTile(
                      title: 'Maps',
                      icon: Icons.map,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MapsPage()),
                        );
                      },
                    ),

                    MenuTile(
                      title: 'Call',
                      icon: Icons.call,
                      onTap: () {
                        _showCallDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Powered by logo and watermark
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Powered by ',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Colors.orange
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Cit Logistics',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.copyright,
                        size: 10,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${DateTime.now().year} Security Management System',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ), // Watermark
          ],
        ),
      ),
    );
  }
}
