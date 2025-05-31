import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:bm_security/models/visitor_model.dart';
import 'package:bm_security/utils/auth_config.dart';

class VisitorService {
  static const String baseUrl = '${ApiConfig.baseUrl}/api';
  
  static String? _getAuthToken() {
    final box = GetStorage();
    final token = box.read('token');
    if (token == null) {
      print('No authentication token found');
    }
    return token;
  }
  
  static int? _getCurrentUserId() {
    final box = GetStorage();
    final userData = box.read('user');
    if (userData != null && userData is Map<String, dynamic>) {
      // Ensure we're getting an integer value
      final id = userData['id'];
      print('User ID from storage: $id (type: ${id.runtimeType})');
      if (id is int) {
        return id;
      } else if (id is String) {
        // Try to parse as int if it's a string
        return int.tryParse(id);
      } else if (id is double) {
        // Convert double to int if needed
        return id.toInt();
      }
    }
    return null;
  }
  
  static Map<String, String> _headers([String? additionalContentType]) {
    final token = _getAuthToken();
    return {
      'Content-Type': additionalContentType ?? 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  static Future<Visitor> createVisitorRequest(Visitor visitor) async {
    try {
      final token = _getAuthToken();
      if (token == null) {
        throw Exception('User is not authenticated');
      }
      
      print('Creating visitor request to ${ApiConfig.baseUrl}/api/visitors');
      print('Request body: ${jsonEncode(visitor.toJson())}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/visitors'),
        headers: _headers(),
        body: jsonEncode(visitor.toJson()),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Visitor.fromJson(responseData['data']);
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        final errorBody = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'error': 'Unknown error'};
        throw Exception(
            'Failed to create visitor request: ${response.statusCode} - ${errorBody['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Error creating visitor request: $e');
      throw Exception('Failed to create visitor request: $e');
    }
  }
  
  static Future<List<Visitor>> getVisitorRequests({bool onlyCurrentUser = true}) async {
    try {
      final token = _getAuthToken();
      if (token == null) {
        throw Exception('User is not authenticated');
      }
      
      final userId = onlyCurrentUser ? _getCurrentUserId() : null;
      if (onlyCurrentUser && userId == null) {
        print('Warning: User ID not found, but onlyCurrentUser is true');
        return []; // Return empty list if we can't find the user ID
      }
      
      // Use the correct endpoint based on the routes defined in the backend
      // For regular users, use /api/visitors/user
      // For admins who want to see all visitors, use /api/visitors/all
      final Uri uri = onlyCurrentUser 
          ? Uri.parse('${ApiConfig.baseUrl}/api/visitors/user')
          : Uri.parse('${ApiConfig.baseUrl}/api/visitors/all');
          
      print('Fetching visitor requests from: $uri');
      print('Current user ID: $userId');
      
      final response = await http.get(
        uri,
        headers: _headers(),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body.substring(0, min(200, response.body.length))}...');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle both response formats
        List<dynamic> data;
        if (responseData is List) {
          // Direct array response
          data = responseData;
        } else if (responseData['success'] == true && responseData['data'] != null) {
          // Success wrapper response
          data = responseData['data'];
        } else if (responseData['data'] != null) {
          // Data wrapper without success flag
          data = responseData['data'];
        } else {
          // Unknown format
          print('Unknown response format: $responseData');
          return [];
        }
        
        print('Found ${data.length} visitor requests in response');
        
        final visitors = data.map((json) => Visitor.fromJson(json)).toList();
        print('Parsed ${visitors.length} visitor objects');
        
        return visitors;
      } else if (response.statusCode == 404) {
        // Return empty list for 404 (not found) instead of throwing
        print('404 Not Found response from server');
        return [];
      } else {
        throw Exception(
            'Failed to load visitor requests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching visitor requests: $e');
      // For network errors or other issues, return empty list instead of throwing
      return [];
    }
  }
  
  static Future<Visitor> updateVisitorStatus(
      int visitorId, VisitorStatus status) async {
    try {
      final token = _getAuthToken();
      if (token == null) {
        throw Exception('User is not authenticated');
      }
      
      if (visitorId <= 0) {
        throw Exception('Invalid visitor ID');
      }
      
      print('Updating visitor status: ID=$visitorId, Status=$status');
      
      // Create the request URL
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/visitors/$visitorId/status');
      print('Request URL: $uri');
      print('Request method: PUT');
      
      // Create the request body
      final body = jsonEncode({'status': status.toString().split('.').last});
      print('Request body: $body');

      // Use PUT instead of PATCH as per the backend route definition
      final response = await http.put(
        uri,
        headers: _headers(),
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle different response formats
        final Map<String, dynamic> visitorData;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            // Response with data wrapper
            visitorData = responseData['data'];
          } else if (responseData.containsKey('id')) {
            // Direct visitor object
            visitorData = responseData;
          } else {
            throw Exception('Invalid response format: $responseData');
          }
        } else {
          throw Exception('Unexpected response type: ${responseData.runtimeType}');
        }
        
        print('Successfully updated visitor status');
        return Visitor.fromJson(visitorData);
      } else {
        final errorBody = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {'error': 'Unknown error'};
            
        final errorMessage = errorBody is Map 
            ? (errorBody['error'] is Map 
                ? errorBody['error']['message'] 
                : errorBody['error']) 
            : 'Unknown error';
            
        throw Exception(
            'Failed to update visitor status: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('Error updating visitor status: $e');
      throw Exception('Failed to update visitor status: $e');
    }
  }
  
  static Future<Visitor> getVisitorById(int visitorId) async {
    try {
      final token = _getAuthToken();
      if (token == null) {
        throw Exception('User is not authenticated');
      }
      
      print('Fetching visitor with ID: $visitorId');
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/visitors/$visitorId');
      print('Request URL: $uri');
      
      final response = await http.get(
        uri,
        headers: _headers(),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle different response formats
        final Map<String, dynamic> visitorData;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            // Response with data wrapper
            visitorData = responseData['data'];
          } else if (responseData.containsKey('id')) {
            // Direct visitor object
            visitorData = responseData;
          } else {
            throw Exception('Invalid response format: $responseData');
          }
        } else {
          throw Exception('Unexpected response type: ${responseData.runtimeType}');
        }
        
        print('Parsed visitor data: $visitorData');
        return Visitor.fromJson(visitorData);
      } else {
        throw Exception(
            'Failed to load visitor details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching visitor details: $e');
      throw Exception('Failed to load visitor details: $e');
    }
  }

  // Upload visitor photo
  static Future<String> uploadVisitorPhoto(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/visitor-photo'),
      );

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
        ),
      );

      // Add headers
      final token = _getAuthToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return jsonResponse['data']['filePath'];
      } else {
        throw Exception(jsonResponse['error'] ?? 'Failed to upload image');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}
