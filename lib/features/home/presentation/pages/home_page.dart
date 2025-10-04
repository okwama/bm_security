import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../requests/presentation/pages/pending_requests_page.dart';
import '../../../requests/presentation/pages/in_progress_requests_page.dart';
import '../../../requests/presentation/pages/completed_requests_page.dart';
import '../../../sos/presentation/pages/sos_page.dart';
import '../../../teams/presentation/pages/my_team_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../cash_count/presentation/pages/cash_count_page.dart';
import '../../../../components/menu_tile.dart';
import '../../../requests/presentation/bloc/requests_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int pendingCount = 0;
  int inProgressCount = 0;
  int completedCount = 0;
  bool _isLoadingCounts = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    if (_isLoadingCounts) return;
    
    setState(() {
      _isLoadingCounts = true;
    });

    try {
      // Load real counts from backend
      final requestsBloc = context.read<RequestsBloc>();
      
      // Load pending requests
      requestsBloc.add(const LoadRequestsEvent(status: AppConstants.statusPending));
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Load in-progress requests  
      requestsBloc.add(const LoadRequestsEvent(status: AppConstants.statusInProgress));
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Load completed requests
      requestsBloc.add(const LoadRequestsEvent(status: AppConstants.statusCompleted));
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        setState(() {
          // These will be updated by the BLoC listener
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCounts = false;
        });
      }
    }
  }
  void _navigateToPending() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PendingRequestsPage()),
    ).then((_) {
      // Refresh counts when returning from pending page
      _loadCounts();
    });
  }

  void _navigateToInProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InProgressRequestsPage()),
    ).then((_) {
      // Refresh counts when returning from in-progress page
      _loadCounts();
    });
  }

  void _navigateToCompleted() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CompletedRequestsPage()),
    ).then((_) {
      // Refresh counts when returning from completed page
      _loadCounts();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 12, 90, 153),
        foregroundColor: Colors.grey,
        actions: [
          IconButton(
            icon: _isLoadingCounts 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoadingCounts ? null : () {
              _loadCounts();
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
                context.read<AuthBloc>().add(const LogoutEvent());
                Navigator.of(context).pushReplacementNamed('/login');
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
      body: BlocListener<RequestsBloc, RequestsState>(
        listener: (context, state) {
          if (state is RequestsLoaded) {
            // Update counters based on loaded requests
            final pending = state.requests.where((r) => r.myStatus == AppConstants.statusPending).length;
            final inProgress = state.requests.where((r) => r.myStatus == AppConstants.statusInProgress).length;
            final completed = state.requests.where((r) => r.myStatus == AppConstants.statusCompleted).length;
            
            if (mounted) {
              setState(() {
                pendingCount = pending;
                inProgressCount = inProgress;
                completedCount = completed;
              });
            }
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return _buildHomeContent(context, state.user);
            } else if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            } else {
              return const Center(
                child: Text('Please log in to continue'),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, UserEntity user) {
    return Container(
      color: Colors.grey.shade200,
      child: SafeArea(
        child: Column(
          children: [
            // Grid menu items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 0.0,  // No space - cards touch
                  mainAxisSpacing: 0.0,   // No space - cards touch
                  childAspectRatio: 1.0,  // Square cards for checkerboard
                  children: [
                         // User Profile Tile
                         MenuTile(
                           title: user.role.toUpperCase(),
                           subtitle: user.name,
                           icon: Icons.person,
                           onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const ProfilePage()),
                             );
                           },
                         ),
                    MenuTile(
                      title: 'PENDING',
                      icon: Icons.pending_outlined,
                      badgeCount: pendingCount,
                      onTap: _navigateToPending,
                    ),

                    MenuTile(
                      title: 'IN PROGRESS',
                      icon: Icons.watch_later_outlined,
                      badgeCount: inProgressCount,
                      onTap: _navigateToInProgress,
                    ),

                    MenuTile(
                      title: 'COMPLETED',
                      icon: Icons.done_all_outlined,
                      badgeCount: completedCount,
                      onTap: _navigateToCompleted,
                    ),

                    MenuTile(
                      title: 'SOS',
                      icon: Icons.emergency_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SOSPage()),
                        );
                      },
                    ),
                         MenuTile(
                           title: 'My Team',
                           icon: Icons.group,
                           onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(builder: (context) => const MyTeamPage()),
                             );
                           },
                         ),

                  ],
                ),
              ),
            ),

            // Powered by logo and watermark
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 20),
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
