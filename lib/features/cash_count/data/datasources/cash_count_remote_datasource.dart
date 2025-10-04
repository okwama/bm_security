import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../services/http/auth_service.dart';
import '../models/cash_count_model.dart';

abstract class CashCountRemoteDataSource {
  Future<CashCountModel> submitCashCount({
    required int requestId,
    required int staffId,
    required int ones,
    required int fives,
    required int tens,
    required int twenties,
    required int forties,
    required int fifties,
    required int hundreds,
    required int twoHundreds,
    required int fiveHundreds,
    required int thousands,
    String? sealNumber,
    String? imageUrl,
    required bool isAtmCashCount,
  });

  Future<List<CashCountModel>> getCashCounts({
    int? requestId,
    int? staffId,
    bool? isAtmCashCount,
  });

  Future<CashCountModel> getCashCountById(int id);
}

class CashCountRemoteDataSourceImpl implements CashCountRemoteDataSource {
  final http.Client client;
  final AuthService _authService = AuthService();

  CashCountRemoteDataSourceImpl({required this.client});

  @override
  Future<CashCountModel> submitCashCount({
    required int requestId,
    required int staffId,
    required int ones,
    required int fives,
    required int tens,
    required int twenties,
    required int forties,
    required int fifties,
    required int hundreds,
    required int twoHundreds,
    required int fiveHundreds,
    required int thousands,
    String? sealNumber,
    String? imageUrl,
    required bool isAtmCashCount,
  }) async {
    try {
      // Calculate total amount
      final totalAmount = (ones * 1) +
          (fives * 5) +
          (tens * 10) +
          (twenties * 20) +
          (forties * 40) +
          (fifties * 50) +
          (hundreds * 100) +
          (twoHundreds * 200) +
          (fiveHundreds * 500) +
          (thousands * 1000);

      final requestBody = {
        'request_id': requestId,
        'staff_id': staffId,
        'ones': ones,
        'fives': fives,
        'tens': tens,
        'twenties': twenties,
        'forties': forties,
        'fifties': fifties,
        'hundreds': hundreds,
        'twoHundreds': twoHundreds,
        'fiveHundreds': fiveHundreds,
        'thousands': thousands,
        'totalAmount': totalAmount,
        if (sealNumber != null) 'sealNumber': sealNumber,
        if (imageUrl != null) 'image_url': imageUrl,
        if (!isAtmCashCount) 'status': 'pending',
      };

      // Choose endpoint based on whether it's ATM cash count
      final endpoint = isAtmCashCount 
          ? '${AppConstants.baseUrl}/atm-cash-counts'
          : '${AppConstants.baseUrl}/cash-counts';

      final response = await client.post(
        Uri.parse(endpoint),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return CashCountModel.fromJson(jsonResponse, isAtmCashCount: isAtmCashCount);
      } else {
        throw ServerException(message: 'Failed to submit cash count: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<List<CashCountModel>> getCashCounts({
    int? requestId,
    int? staffId,
    bool? isAtmCashCount,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (requestId != null) queryParams['request_id'] = requestId.toString();
      if (staffId != null) queryParams['staff_id'] = staffId.toString();

      // Choose endpoint based on whether it's ATM cash count
      final endpoint = (isAtmCashCount == true)
          ? '${AppConstants.baseUrl}/atm-cash-counts'
          : '${AppConstants.baseUrl}/cash-counts';

      final uri = Uri.parse(endpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await client.get(
        uri,
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CashCountModel.fromJson(json, isAtmCashCount: isAtmCashCount ?? false)).toList();
      } else {
        throw ServerException(message: 'Failed to load cash counts: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Network error: $e');
    }
  }

  @override
  Future<CashCountModel> getCashCountById(int id) async {
    try {
      final response = await client.get(
        Uri.parse('${AppConstants.baseUrl}/cash-counts/$id'),
        headers: {
          AppConstants.contentTypeHeader: AppConstants.applicationJson,
          AppConstants.authorizationHeader: AppConstants.getBearerToken(await _getTokenFromStorage()),
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return CashCountModel.fromJson(jsonResponse);
      } else {
        throw ServerException(message: 'Failed to load cash count: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Network error: $e');
    }
  }

  Future<String> _getTokenFromStorage() async {
    try {
      final token = await _authService.accessToken;
      if (token != null && token.isNotEmpty) {
        return token;
      }
      throw Exception('No authentication token available');
    } catch (e) {
      throw Exception('Authentication token retrieval failed: $e');
    }
  }
}

