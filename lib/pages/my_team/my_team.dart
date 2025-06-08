import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/utils/auth_config.dart';

class MyTeamPage extends StatefulWidget {
  const MyTeamPage({super.key});

  @override
  State<MyTeamPage> createState() => _MyTeamPageState();
}

class _MyTeamPageState extends State<MyTeamPage> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _teamMembers = [];
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  final _storage = GetStorage();
  final String _baseUrl = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchTeamMembers();
  }

  Future<void> _fetchTeamMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final token = _storage.read('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/assigned-staff'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _teamMembers = data['assignedStaff'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load team members');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTeamMembers,
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _fetchTeamMembers,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTeamMembers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_teamMembers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No team members assigned yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _teamMembers.length,
      itemBuilder: (context, index) {
        final member = _teamMembers[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: member['photoUrl'] != null
                          ? Image.network(
                              member['photoUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          member['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        member['role'] ?? 'Not specified',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member['emplNo'] ?? 'Not specified',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
