import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_widget.dart';
import '../bloc/teams_bloc.dart';
import '../bloc/teams_event.dart';
import '../bloc/teams_state.dart';
import '../../domain/entities/team_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'add_staff_page.dart';

class MyTeamPage extends StatefulWidget {
  const MyTeamPage({super.key});

  @override
  State<MyTeamPage> createState() => _MyTeamPageState();
}

class _MyTeamPageState extends State<MyTeamPage> {
  bool _hasFetchedMembers = false;

  @override
  void initState() {
    super.initState();
    context.read<TeamsBloc>().add(const GetMyTeamEvent());
  }

  // Mobile-optimized: always 2 columns
  int _getCrossAxisCount(double width) {
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddStaffPage(),
            ),
          );
        },
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
      body: BlocBuilder<TeamsBloc, TeamsState>(
        builder: (context, state) {
          
          if (state is TeamsLoading) {
            return const LoadingWidget(message: 'Loading teams...');
          } 
          
          if (state is TeamsError) {
            return TeamsErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<TeamsBloc>().add(const GetMyTeamEvent());
              },
            );
          } 
          
          if (state is TeamsLoaded) {
            if (state.teams.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.group_off,
                title: 'No Teams',
                message: 'You are not assigned to any team yet.',
              );
            }

            final firstTeam = state.teams.first;
            
            if (!_hasFetchedMembers) {
              _hasFetchedMembers = true;
              context.read<TeamsBloc>().add(GetTeamMembersEvent(teamId: firstTeam.id));
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                _hasFetchedMembers = false;
                context.read<TeamsBloc>().add(const RefreshTeamsEvent());
              },
              child: _buildTeamMembersContent(context, firstTeam.id),
            );
          }

          if (state is TeamMembersLoaded) {
            return _buildTeamMembersDisplay(context, state.members);
          }

          return const LoadingWidget(message: 'Loading...');
        },
      ),
    );
  }

  Widget _buildTeamMembersContent(BuildContext context, int teamId) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading team members...'),
        ],
      ),
    );
  }

  Widget _buildTeamMembersDisplay(BuildContext context, List<UserEntity> members) {
    
    if (members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No team members found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _hasFetchedMembers = false;
        context.read<TeamsBloc>().add(const RefreshTeamsEvent());
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Team Members',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final member = members[index];
                  return _buildTeamMemberCard(member);
                },
                childCount: members.length,
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(UserEntity member) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image section - fills upper portion (60%)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
              ),
              child: member.photoUrl != null && member.photoUrl!.isNotEmpty
                  ? Image.network(
                      member.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderAvatar();
                      },
                    )
                  : _buildPlaceholderAvatar(),
            ),
          ),
          // Details section - lower portion (40%)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    member.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  // Employee ID
                  if (member.employeeNumber != null)
                    Text(
                      'ID: ${member.employeeNumber}',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 3),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppConstants.primaryColorValue).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      member.role,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Color(AppConstants.primaryColorValue),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // Phone
                  if (member.phone != null && member.phone!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 9,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            member.phone!,
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Center(
      child: Icon(
        Icons.person,
        size: 40,
        color: const Color(AppConstants.primaryColorValue).withOpacity(0.3),
      ),
    );
  }
}