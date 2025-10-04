import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../services/http/auth_service.dart';
import '../models/team_model.dart';
import '../../../auth/data/models/user_model.dart';

abstract class TeamsRemoteDataSource {
  Future<List<TeamModel>> getMyTeam();
  Future<TeamModel> getTeamById(int teamId);
  Future<List<TeamModel>> getAllTeams();
  Future<TeamModel> createTeam({
    required String name,
    int? crewCommanderId,
  });
  Future<TeamModel> updateTeam({
    required int teamId,
    String? name,
    int? crewCommanderId,
  });
  Future<void> deleteTeam(int teamId);
  Future<TeamModel> addMemberToTeam({
    required int teamId,
    required int userId,
  });
  Future<TeamModel> removeMemberFromTeam({
    required int teamId,
    required int userId,
  });
  Future<List<UserModel>> getTeamMembers(int teamId);
}

class TeamsRemoteDataSourceImpl implements TeamsRemoteDataSource {
  final http.Client client;
  final String baseUrl;
  final AuthService _authService = AuthService();

  TeamsRemoteDataSourceImpl({
    required this.client,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? AppConstants.baseUrl;

  @override
  Future<List<TeamModel>> getMyTeam() async {
    try {
      print('🌐 Teams Datasource - Calling: $baseUrl/teams/my-team');
      final response = await client.get(
        Uri.parse('$baseUrl/teams/my-team'),
        headers: await _getHeaders(),
      );
      
      print('📡 Teams Datasource - Response status: ${response.statusCode}');
      print('📡 Teams Datasource - Response body: ${response.body.substring(0, 100)}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns array directly, not wrapped in 'teams' field
        final List<dynamic> teamsData = data is List ? data : [];
        return teamsData
            .map((team) => TeamModel.fromJson(team as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(message: 'Failed to load team: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<TeamModel> getTeamById(int teamId) async {
    try {
            final response = await client.get(
              Uri.parse('$baseUrl/teams/$teamId'),
              headers: await _getHeaders(),
            );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TeamModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException(message: 'Failed to load team: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<List<TeamModel>> getAllTeams() async {
    try {
            final response = await client.get(
              Uri.parse('$baseUrl/teams'),
              headers: await _getHeaders(),
            );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns array directly, not wrapped in 'teams' field
        final List<dynamic> teamsData = data is List ? data : [];
        return teamsData
            .map((team) => TeamModel.fromJson(team as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(message: 'Failed to load teams: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<TeamModel> createTeam({
    required String name,
    int? crewCommanderId,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/teams'),
        headers: await _getHeaders(),
        body: json.encode({
          'name': name,
          'crew_commander_id': crewCommanderId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TeamModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException(message: 'Failed to create team: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<TeamModel> updateTeam({
    required int teamId,
    String? name,
    int? crewCommanderId,
  }) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/teams/$teamId'),
        headers: await _getHeaders(),
        body: json.encode({
          if (name != null) 'name': name,
          if (crewCommanderId != null) 'crew_commander_id': crewCommanderId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TeamModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException(message: 'Failed to update team: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTeam(int teamId) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/teams/$teamId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(message: 'Failed to delete team: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<TeamModel> addMemberToTeam({
    required int teamId,
    required int userId,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/teams/$teamId/members'),
        headers: await _getHeaders(),
        body: json.encode({
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TeamModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException(message: 'Failed to add member: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<TeamModel> removeMemberFromTeam({
    required int teamId,
    required int userId,
  }) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/teams/$teamId/members/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TeamModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw ServerException(message: 'Failed to remove member: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  @override
  Future<List<UserModel>> getTeamMembers(int teamId) async {
    try {
      print('🌐 Teams Datasource - Calling: $baseUrl/teams/members/$teamId');
      final response = await client.get(
        Uri.parse('$baseUrl/teams/members/$teamId'),
        headers: await _getHeaders(),
      );

      print('📡 Teams Datasource - Response status: ${response.statusCode}');
      print('📡 Teams Datasource - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> membersData = data is List ? data : [];
        print('✅ Teams Datasource - Parsed ${membersData.length} team members');
        return membersData
            .map((member) => UserModel.fromJson(member as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(message: 'Failed to load team members: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Network error: ${e.toString()}');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    // Get token from secure storage instead of static AppConstants
    final token = await _getTokenFromStorage();
    return {
      AppConstants.contentTypeHeader: AppConstants.applicationJson,
      AppConstants.authorizationHeader: AppConstants.getBearerToken(token),
    };
  }

  Future<String> _getTokenFromStorage() async {
    try {
      final token = await _authService.accessToken;
      print('🔑 Teams Datasource - Token from auth service: ${token?.substring(0, 20)}...');
      if (token != null && token.isNotEmpty) {
        return token;
      }
      print('⚠️ Teams Datasource - No token found in auth service');
      throw Exception('No authentication token available');
    } catch (e) {
      print('❌ Teams Datasource - Token error: $e');
      throw Exception('Authentication token retrieval failed: $e');
    }
  }
}
