import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../errors/app_error.dart';
import '../../shared/models/food_entry_model.dart';
import '../../shared/models/member_model.dart';
import '../../shared/models/nutrition_model.dart';
import '../../shared/models/nutrition_space_model.dart';
import '../../shared/models/credit_wallet_model.dart';
import '../../shared/models/user_model.dart';
import 'config_service.dart';


/// Remote persistence boundary for Nutesia's Go API.
/// Local storage remains the offline cache; no Firebase database calls belong in
/// feature providers.
class ApiDataService {
  ApiDataService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    final value = AppConfig.get('API_BASE_URL', 'https://apidot.nutesia.in');
    return value.replaceFirst(RegExp(r'/+$'), '');
  }

  Future<UserModel> saveUser(UserModel user) async {
    final response = await _put(
      '/api/v1/users/${Uri.encodeComponent(user.deviceId)}',
      user.toJson(),
    );
    return UserModel.fromJson(_decodeObject(response));
  }

  Future<UserModel?> getUser(String deviceId) async {
    try {
      final response = await _get(
        '/api/v1/users/${Uri.encodeComponent(deviceId)}',
      );
      return UserModel.fromJson(_decodeObject(response));
    } on NetworkException catch (e) {
      if (e.statusCode == 404 || e.type == NetworkErrorType.notFound) return null;
      rethrow;
    }
  }

  Future<NutritionSpaceModel> getSpace(String deviceId) async {
    final response = await _get(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}',
    );
    return NutritionSpaceModel.fromJson(_decodeObject(response));
  }

  Future<NutritionSpaceModel> saveSpace(String deviceId, Map<String, dynamic> payload) async {
    final response = await _put(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}',
      payload,
    );
    return NutritionSpaceModel.fromJson(_decodeObject(response));
  }

  Future<NutritionSpaceModel> updateSpaceMode(String deviceId, String mode) async {
    final response = await _patch(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/mode',
      {'mode': mode},
    );
    return NutritionSpaceModel.fromJson(_decodeObject(response));
  }

  Future<NutritionSpaceModel> addMember(String deviceId, MemberModel member) async {
    final response = await _post(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/members',
      member.toJson(),
    );
    return NutritionSpaceModel.fromJson(_decodeObject(response));
  }

  Future<NutritionSpaceModel> updateMember(String deviceId, MemberModel member) async {
    final response = await _put(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/members/${Uri.encodeComponent(member.id)}',
      member.toJson(),
    );
    return NutritionSpaceModel.fromJson(_decodeObject(response));
  }

  Future<NutritionSpaceModel> deleteMember(String deviceId, String memberId) async {
    final response = await _delete(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/members/${Uri.encodeComponent(memberId)}',
    );
    return NutritionSpaceModel.fromJson(_decodeObject(response));
  }

  Future<CreditWalletModel> getCreditWallet(String deviceId) async {
    final response = await _get(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/wallet',
    );
    return CreditWalletModel.fromJson(_decodeObject(response));
  }

  Future<CreditWalletModel> rewardAdCredit(String deviceId) async {
    final response = await _post(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/wallet/rewarded-ad',
      const {},
    );
    return CreditWalletModel.fromJson(_decodeObject(response));
  }

  Future<void> saveDailyLog({
    required String deviceId,
    required String dateKey,
    required List<FoodEntry> entries,
    required NutritionData dailyTotal,
    String? memberId,
    int? waterIntakeMl,
  }) {
    final body = <String, dynamic>{
      'date': dateKey,
      'totalNutrition': dailyTotal.toJson(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
    if (memberId != null && memberId.isNotEmpty) {
      body['memberId'] = memberId;
    }
    if (waterIntakeMl != null) {
      body['waterIntakeMl'] = waterIntakeMl;
    }
    final query = memberId != null && memberId.isNotEmpty ? '?memberId=${Uri.encodeComponent(memberId)}' : '';
    return _put(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/days/$dateKey$query',
      body,
    );
  }

  Future<Map<String, dynamic>?> getDailyLogRaw(
    String deviceId,
    String dateKey, {
    String? memberId,
  }) async {
    final query = memberId != null && memberId.isNotEmpty ? '?memberId=${Uri.encodeComponent(memberId)}' : '';
    try {
      final response = await _get(
        '/api/v1/users/${Uri.encodeComponent(deviceId)}/days/$dateKey$query',
      );
      return _decodeObject(response);
    } on NetworkException catch (e) {
      if (e.statusCode == 404 || e.type == NetworkErrorType.notFound) return null;
      rethrow;
    }
  }

  Future<List<FoodEntry>> getEntriesForDate(
    String deviceId,
    String dateKey, {
    String? memberId,
  }) async {
    final raw = await getDailyLogRaw(deviceId, dateKey, memberId: memberId);
    if (raw == null) return const [];
    final entries = raw['entries'] as List<dynamic>? ?? const [];
    return entries
        .map((entry) => FoodEntry.fromJson(entry as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  Future<List<Map<String, dynamic>>> getDailyLogsForRange({
    required String deviceId,
    required String startDateKey,
    required String endDateKey,
    String? memberId,
  }) async {
    final mQuery = memberId != null && memberId.isNotEmpty ? '&memberId=${Uri.encodeComponent(memberId)}' : '';
    try {
      final response = await _get(
        '/api/v1/users/${Uri.encodeComponent(deviceId)}/days?start=$startDateKey&end=$endDateKey$mQuery',
      );
      final decoded = _decodeList(response);
      return decoded.map((item) => item as Map<String, dynamic>).toList();
    } on NetworkException catch (e) {
      if (e.statusCode == 404 || e.type == NetworkErrorType.notFound) return const [];
      rethrow;
    }
  }

  Future<String> parseFood({
    required String deviceId,
    required String input,
  }) async {
    final response = await _post(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/ai/food-parse',
      {'input': input},
    );
    return (_decodeObject(response)['content'] as String?) ?? '';
  }

  Future<String> analyzeDeficiencies({
    required String deviceId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _post(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/ai/deficiency-analysis',
      {'startDate': startDate, 'endDate': endDate},
    );
    return (_decodeObject(response)['content'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> getWallet(String deviceId) async {
    final response = await _get(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/wallet',
    );
    _requireSuccess(response);
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> rewardAd(String deviceId) async {
    final response = await _post(
      '/api/v1/users/${Uri.encodeComponent(deviceId)}/wallet/rewarded-ad',
      const {},
    );
    return _decodeObject(response);
  }


  Future<http.Response> _executeRequest(Future<http.Response> Function() requestFn) async {
    int attempts = 0;
    const maxAttempts = 2;

    while (true) {
      attempts++;
      try {
        final response = await requestFn().timeout(const Duration(seconds: 12));
        _requireSuccess(response);
        return response;
      } catch (e) {
        NetworkErrorType errorType = NetworkErrorType.unknown;
        String message = 'Unable to connect to service. Please check your connection.';
        int? statusCode;
        String? body;

        final rawString = e.toString();

        if (e is TimeoutException) {
          errorType = NetworkErrorType.timeout;
          message = 'Request timed out. Please check your internet connection.';
        } else if (e is SocketException ||
            rawString.contains('SocketException') ||
            rawString.contains('ClientException') ||
            rawString.contains('connection abort') ||
            rawString.contains('Connection refused') ||
            rawString.contains('Connection failed') ||
            rawString.contains('Failed host lookup')) {
          errorType = NetworkErrorType.noInternet;
          message = 'Unable to connect to Nutesia servers. Please check your network connection.';
        } else if (e is ApiException) {
          statusCode = e.statusCode;
          body = e.body;
          message = _extractSafeErrorMessage(e.body, e.statusCode);
          if (e.statusCode == 401) {
            errorType = NetworkErrorType.unauthorized;
          } else if (e.statusCode == 403) {
            errorType = NetworkErrorType.forbidden;
          } else if (e.statusCode == 404) {
            errorType = NetworkErrorType.notFound;
          } else if (e.statusCode == 429) {
            errorType = NetworkErrorType.rateLimited;
            message = 'Too many requests. Please try again in a moment.';
          } else if (e.statusCode >= 500) {
            errorType = NetworkErrorType.serverError;
            message = 'Server error occurred. Please try again later.';
          }
        } else if (e is NetworkException) {
          rethrow;
        } else {
          message = _sanitizeMessage(rawString);
        }

        // Auto retry for transient errors (Timeout and ServerError)
        if (attempts < maxAttempts && (errorType == NetworkErrorType.timeout || errorType == NetworkErrorType.serverError)) {
          await Future.delayed(Duration(seconds: 1 * attempts));
          continue;
        }

        throw NetworkException(type: errorType, message: message, statusCode: statusCode, body: body);
      }
    }
  }

  /// Every API route requires a Firebase ID token. Fail here instead of
  /// sending a request the server will reject with 401.
  Future<Map<String, String>> _buildHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const AuthAppError.notLoggedIn();
    }

    String? token;
    try {
      token = await user.getIdToken();
    } catch (e) {
      throw AuthAppError.sessionExpired(technicalDetails: 'getIdToken failed: $e');
    }
    if (token == null || token.isEmpty) {
      throw const AuthAppError.sessionExpired(technicalDetails: 'getIdToken returned no token');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _get(String path) async {
    final headers = await _buildHeaders();
    debugPrint('🌐 [API GET] $_baseUrl$path');
    return _executeRequest(() => _client.get(Uri.parse('$_baseUrl$path'), headers: headers));
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    final headers = await _buildHeaders();
    debugPrint('🌐 [API PUT] $_baseUrl$path');
    return _executeRequest(() => _client.put(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final headers = await _buildHeaders();
    debugPrint('🌐 [API POST] $_baseUrl$path');
    return _executeRequest(() => _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  Future<http.Response> _patch(String path, Map<String, dynamic> body) async {
    final headers = await _buildHeaders();
    debugPrint('🌐 [API PATCH] $_baseUrl$path');
    return _executeRequest(() => _client.patch(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  Future<http.Response> _delete(String path) async {
    final headers = await _buildHeaders();
    debugPrint('🌐 [API DELETE] $_baseUrl$path');
    return _executeRequest(() => _client.delete(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    ));
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>;
        }
        return decoded;
      }
    } catch (e) {
      debugPrint('ApiDataService._decodeObject error: $e');
    }
    return <String, dynamic>{};
  }

  List<dynamic> _decodeList(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      if (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>) {
        return decoded['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint('ApiDataService._decodeList error: $e');
    }
    return const [];
  }

  void _requireSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(response.statusCode, response.body);
  }

  static String _sanitizeMessage(String rawMessage) {
    if (rawMessage.trim().isEmpty) return 'Unable to connect to the server.';

    var sanitized = rawMessage
        .replaceAll(RegExp(r'(?:https?|wss?|ftp)://[^\s,">)\]]+', caseSensitive: false), 'server')
        .replaceAll(RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?\b'), 'server')
        .replaceAll(RegExp(r'\b(?:[0-9a-fA-F]{1,4}:){2,7}[0-9a-fA-F]{1,4}(?::\d+)?\b'), 'server')
        .replaceAll(RegExp(r'\blocalhost(?::\d+)?\b', caseSensitive: false), 'server')
        .replaceAll(RegExp(r'address\s*=\s*[^\s,)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'host\s*=\s*[^\s,)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'port\s*=\s*\d+', caseSensitive: false), '')
        .replaceAll(RegExp(r'uri\s*=\s*[^\s,)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'url\s*=\s*[^\s,)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'endpoint\s*=\s*[^\s,)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = sanitized.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('connection abort') ||
        lower.contains('connection refused') ||
        lower.contains('connection failed') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable')) {
      return 'Unable to connect to Nutesia servers. Please check your network connection.';
    }
    return sanitized;
  }

  static String _extractSafeErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded.containsKey('error') && decoded['error'] is String) {
        return _sanitizeMessage(decoded['error'] as String);
      } else if (decoded is Map && decoded['error'] is Map && decoded['error']['message'] is String) {
        return _sanitizeMessage(decoded['error']['message'] as String);
      } else if (decoded is Map && decoded.containsKey('message') && decoded['message'] is String) {
        return _sanitizeMessage(decoded['message'] as String);
      }
    } catch (_) {}
    return 'Server returned status code $statusCode.';
  }
}

enum NetworkErrorType {
  noInternet,
  timeout,
  serverError,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  unknown,
}

class NetworkException implements Exception {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;

  /// The server's response body, when the server answered with an error.
  final String? body;

  const NetworkException({required this.type, required this.message, this.statusCode, this.body});

  @override
  String toString() => message;
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'Nutesia API request failed ($statusCode)';
}

