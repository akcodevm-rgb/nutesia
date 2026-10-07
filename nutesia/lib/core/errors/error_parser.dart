import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../services/api_data_service.dart';
import '../services/credit_service.dart';
import 'app_error.dart';

/// Universal Error Classifier and Mapper for Nutesia.
/// Transforms raw exceptions, HTTP responses, Firebase codes, and network errors
/// into strongly-typed [AppError] domain objects.
class ErrorParser {
  /// Parses any error into a standardized [AppError] instance.
  static AppError parse(dynamic error, [StackTrace? stackTrace]) {
    if (error == null) {
      return const UnknownAppError();
    }

    if (error is AppError) {
      return error;
    }

    // 1. Backend NetworkException from ApiDataService
    if (error is NetworkException) {
      return _parseNetworkException(error);
    }

    // 2. Backend ApiException with raw HTTP body
    if (error is ApiException) {
      return _parseApiException(error);
    }

    // 3. Firebase Auth Exceptions
    if (error is FirebaseAuthException) {
      return _parseFirebaseAuthException(error);
    }

    // 4. Domain Credit Exceptions
    if (error is CreditException) {
      return BusinessAppError.insufficientCredits(
        message: 'Not enough credits. Watch a short video to earn credits.',
        technicalDetails: 'currentCredits: ${error.currentCredits}',
      );
    }

    if (error is RewardLimitException) {
      return BusinessAppError.dailyLimitReached(
        message: sanitize(error.message),
      );
    }

    // 5. Dart / Core I/O Network Exceptions
    if (error is TimeoutException) {
      return NetworkAppError.timeout(technicalDetails: error.message);
    }

    if (error is SocketException) {
      return NetworkAppError.noInternet(technicalDetails: error.message);
    }

    if (error is HandshakeException || error is CertificateException) {
      return const NetworkAppError(
        code: 'SSL_TLS_ERROR',
        message: 'Secure connection could not be established. Please verify date & network.',
        severity: ErrorSeverity.error,
        retryable: true,
        actionType: ErrorActionType.retry,
      );
    }

    if (error is HttpException) {
      return NetworkAppError.serverUnreachable(technicalDetails: error.message);
    }

    // 6. Platform / Permission Exceptions
    if (error is PlatformException) {
      return _parsePlatformException(error);
    }

    // 7. Format / JSON parsing exceptions
    if (error is FormatException) {
      return AIAppError.invalidResponse(
        technicalDetails: error.message,
      );
    }

    // 8. Raw string analysis & technical sanitization
    final raw = error.toString();
    return _parseFromString(raw);
  }

  static AppError _parseNetworkException(NetworkException e) {
    switch (e.type) {
      case NetworkErrorType.noInternet:
        return NetworkAppError.noInternet(message: sanitize(e.message));
      case NetworkErrorType.timeout:
        return NetworkAppError.timeout(message: sanitize(e.message));
      case NetworkErrorType.unauthorized:
        return AuthAppError.sessionExpired(message: sanitize(e.message));
      case NetworkErrorType.forbidden:
        return AuthorizationAppError.forbidden(message: sanitize(e.message));
      case NetworkErrorType.notFound:
        return ApiAppError.notFound(message: sanitize(e.message));
      case NetworkErrorType.rateLimited:
        return ApiAppError.rateLimited(message: sanitize(e.message));
      case NetworkErrorType.serverError:
        return ApiAppError.serverError(message: sanitize(e.message), statusCode: e.statusCode);
      case NetworkErrorType.unknown:
        // The server answered (e.g. 400, 402, 409): read its error envelope.
        if (e.statusCode != null && e.body != null) {
          return _parseApiException(ApiException(e.statusCode!, e.body!));
        }
        return _parseFromString(e.message, e.statusCode);
    }
  }

  static AppError _parseApiException(ApiException e) {
    final body = e.body;
    final statusCode = e.statusCode;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        // Parse standard API error envelope:
        // { "success": false, "error": { "code": "...", "message": "...", "details": {...} } }
        if (decoded['error'] is Map<String, dynamic>) {
          final errMap = decoded['error'] as Map<String, dynamic>;
          final code = (errMap['code'] as String?)?.toUpperCase() ?? 'API_ERROR';
          final message = sanitize((errMap['message'] as String?) ?? 'Server error occurred.');
          final details = errMap['details'] as Map<String, dynamic>?;
          final retryable = (errMap['retryable'] as bool?) ?? (statusCode >= 500 || statusCode == 429);

          if (code == 'VALIDATION_ERROR' && details != null) {
            final fieldMap = details.map((k, v) => MapEntry(k, v.toString()));
            return ValidationAppError.fromFieldErrors(
              fieldErrors: fieldMap,
              message: message,
            );
          }

          if (code == 'INSUFFICIENT_CREDITS') {
            return BusinessAppError.insufficientCredits(message: message);
          }

          if (code == 'RATE_LIMITED' || statusCode == 429) {
            return ApiAppError.rateLimited(message: message, statusCode: statusCode);
          }

          if (statusCode == 401) {
            return AuthAppError.sessionExpired(message: message);
          }

          if (statusCode == 403) {
            return AuthorizationAppError.forbidden(message: message);
          }

          return ApiAppError(
            code: code,
            message: message,
            statusCode: statusCode,
            details: details,
            retryable: retryable,
            actionType: retryable ? ErrorActionType.retry : ErrorActionType.dismiss,
            actionLabel: retryable ? 'Retry' : null,
          );
        }

        // Direct string error or message key
        if (decoded.containsKey('error') && decoded['error'] is String) {
          final rawMsg = decoded['error'] as String;
          return _mapStatusCode(statusCode, sanitize(rawMsg));
        }
        if (decoded.containsKey('message') && decoded['message'] is String) {
          final rawMsg = decoded['message'] as String;
          return _mapStatusCode(statusCode, sanitize(rawMsg));
        }
      }
    } catch (_) {}

    return _mapStatusCode(statusCode, null);
  }

  static AppError _mapStatusCode(int statusCode, String? customMessage) {
    switch (statusCode) {
      case 400:
        return ApiAppError.badRequest(message: customMessage ?? 'Invalid request data.');
      case 401:
        return AuthAppError.sessionExpired(message: customMessage ?? 'Session expired. Please sign in again.');
      case 403:
        return AuthorizationAppError.forbidden(message: customMessage ?? 'Access forbidden.');
      case 404:
        return ApiAppError.notFound(message: customMessage ?? 'The requested item was not found.');
      case 409:
        return ApiAppError.conflict(message: customMessage ?? 'Resource conflict occurred.');
      case 422:
        return ValidationAppError(
          code: 'UNPROCESSABLE_ENTITY',
          message: customMessage ?? 'Please verify submitted data.',
        );
      case 429:
        return ApiAppError.rateLimited(message: customMessage ?? 'Too many requests. Please wait a moment.', statusCode: statusCode);
      case 500:
        return ApiAppError.serverError(message: customMessage ?? 'Internal server error. Please retry shortly.', statusCode: statusCode);
      case 502:
        return ApiAppError.badGateway(message: customMessage ?? 'Bad gateway. Please retry.', statusCode: statusCode);
      case 503:
        return ApiAppError.serviceUnavailable(message: customMessage ?? 'Service is temporarily unavailable.', statusCode: statusCode);
      case 504:
        return ApiAppError.gatewayTimeout(message: customMessage ?? 'Gateway timed out. Please retry.', statusCode: statusCode);
      default:
        return ApiAppError(
          code: 'HTTP_$statusCode',
          message: customMessage ?? 'Server returned status code $statusCode.',
          statusCode: statusCode,
          retryable: statusCode >= 500,
          actionType: statusCode >= 500 ? ErrorActionType.retry : ErrorActionType.dismiss,
          actionLabel: statusCode >= 500 ? 'Retry' : null,
        );
    }
  }

  static AppError _parseFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthAppError.invalidCredentials();
      case 'user-disabled':
        return const AuthAppError.accountDisabled();
      case 'too-many-requests':
        return const AuthAppError.tooManyAttempts();
      case 'email-already-in-use':
        return const BusinessAppError.alreadyExists(
          message: 'An account already exists with this email address.',
        );
      case 'invalid-email':
        return ValidationAppError.singleField(
          field: 'email',
          error: 'Please enter a valid email address.',
        );
      case 'weak-password':
        return ValidationAppError.singleField(
          field: 'password',
          error: 'Password is too weak. Please use at least 6 characters.',
        );
      case 'network-request-failed':
        return const NetworkAppError.noInternet();
      default:
        return AuthAppError(
          code: e.code.toUpperCase(),
          message: sanitize(e.message ?? 'Authentication error occurred.'),
          actionType: ErrorActionType.dismiss,
        );
    }
  }

  static AppError _parsePlatformException(PlatformException e) {
    final codeLower = e.code.toLowerCase();
    if (codeLower.contains('permission') || codeLower.contains('denied')) {
      return PermissionAppError.denied(
        permission: e.code,
        message: sanitize(e.message ?? 'Required permission was denied.'),
      );
    }
    if (codeLower.contains('camera')) {
      return DeviceAppError.cameraUnavailable(
        message: sanitize(e.message ?? 'Camera is currently unavailable.'),
      );
    }
    return UnknownAppError(
      code: e.code.toUpperCase(),
      message: sanitize(e.message ?? 'Platform operation failed.'),
      technicalDetails: e.details?.toString(),
    );
  }

  static AppError _parseFromString(String raw, [int? statusCode]) {
    final lower = raw.toLowerCase();

    // Network / Connectivity cues
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('clientexception') ||
        lower.contains('connection abort') ||
        lower.contains('connection closed')) {
      return NetworkAppError.noInternet(technicalDetails: raw);
    }

    if (lower.contains('connection refused') || lower.contains('connection reset')) {
      return NetworkAppError.connectionRefused(technicalDetails: raw);
    }

    if (lower.contains('timeoutexception') ||
        lower.contains('timed out') ||
        lower.contains('deadline exceeded') ||
        lower.contains('request timeout')) {
      return NetworkAppError.timeout(technicalDetails: raw);
    }

    // AI Cues
    if (lower.contains('food-parse') ||
        lower.contains('ai quota') ||
        lower.contains('gemini') ||
        lower.contains('deficiency-analysis')) {
      if (lower.contains('quota') || lower.contains('rate limit')) {
        return AIAppError.rateLimited(technicalDetails: raw);
      }
      return AIAppError.modelUnavailable(technicalDetails: raw);
    }

    // Credits / Limits
    if (lower.contains('insufficient credit') || lower.contains('not enough credit')) {
      return BusinessAppError.insufficientCredits(technicalDetails: raw);
    }

    if (lower.contains('daily limit') || lower.contains('reward limit')) {
      return BusinessAppError.dailyLimitReached(technicalDetails: raw);
    }

    // Clean generic message
    final cleaned = sanitize(raw);
    if (statusCode != null) {
      return _mapStatusCode(statusCode, cleaned);
    }

    return UnknownAppError(
      message: cleaned.isNotEmpty ? cleaned : 'An unexpected error occurred. Please try again.',
      technicalDetails: raw,
    );
  }

  /// Sanitizes raw error strings by strictly stripping IP addresses, ports, internal URIs, and stack traces.
  static String sanitize(String raw) {
    if (raw.trim().isEmpty) return 'An unexpected error occurred. Please try again.';

    // If the raw error message contains lower-level system/socket leaks, return a friendly fallback
    if (_isTechnicalLeak(raw)) {
      return _getTechnicalFallback(raw);
    }

    var s = raw
        .replaceAll(RegExp(r'Exception:\s*'), '')
        .replaceAll(RegExp(r'FormatException:\s*'), '')
        .replaceAll(RegExp(r'StateError:\s*'), '')
        .replaceAll(RegExp(r'PlatformException\([^)]*\)'), '')
        // Strip URLs entirely (http, https, ws, wss, ftp)
        .replaceAll(RegExp(r'(?:https?|wss?|ftp)://[^\s,">)\]]+', caseSensitive: false), 'server')
        // Strip IPv4 addresses with optional ports
        .replaceAll(RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?\b'), 'server')
        // Strip IPv6 addresses
        .replaceAll(RegExp(r'\b(?:[0-9a-fA-F]{1,4}:){2,7}[0-9a-fA-F]{1,4}(?::\d+)?\b'), 'server')
        // Strip localhost with optional ports
        .replaceAll(RegExp(r'\blocalhost(?::\d+)?\b', caseSensitive: false), 'server')
        // Strip explicit address/host/port/uri/endpoint parameters
        .replaceAll(RegExp(r'address\s*=\s*[^\s,)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'host\s*=\s*[^\s,)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'port\s*=\s*\d+', caseSensitive: false), '')
        .replaceAll(RegExp(r'uri\s*=\s*[^\s,)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'url\s*=\s*[^\s,)]+', caseSensitive: false), '')
        .replaceAll(RegExp(r'endpoint\s*=\s*[^\s,)]+', caseSensitive: false), '')
        // Strip file paths
        .replaceAll(RegExp(r'\b[A-Za-z]:\\[^\s,">)\]]+'), '')
        .replaceAll(RegExp(r'/(?:usr|var|etc|home|data|storage|app|lib|bin)/[^\s,">)\]]+'), '')
        // Clean double spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (s.isEmpty || _isTechnicalLeak(s)) {
      return _getTechnicalFallback(raw);
    }

    return s;
  }

  static bool _isTechnicalLeak(String s) {
    final lower = s.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('connection abort') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('connection failed') ||
        lower.contains('failed host lookup') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('network is unreachable') ||
        lower.contains('xmlhttprequest') ||
        lower.contains('typeerror') ||
        lower.contains('nosuchmethod') ||
        lower.contains('nullthrownerror') ||
        lower.contains('stack trace') ||
        lower.contains('handshakeexception') ||
        lower.contains('certificateexception') ||
        lower.contains('os error') ||
        lower.contains('errno =') ||
        lower.contains('dial tcp') ||
        lower.contains('getsockopt') ||
        lower.contains('pq: ') ||
        lower.contains('sql:') ||
        lower.contains('gorm:') ||
        lower.contains('#0') ||
        lower.contains('#1') ||
        RegExp(r'#\d+\s+').hasMatch(s) ||
        RegExp(r'(?:https?|wss?|ftp)://', caseSensitive: false).hasMatch(s) ||
        RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b').hasMatch(s);
  }

  static String _getTechnicalFallback(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('socket') ||
        lower.contains('host lookup') ||
        lower.contains('connection') ||
        lower.contains('network') ||
        lower.contains('clientexception')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }
    if (lower.contains('timeout') || lower.contains('deadline')) {
      return 'Request timed out. Please check your network and try again.';
    }
    if (lower.contains('ssl') || lower.contains('certificate') || lower.contains('handshake')) {
      return 'Secure connection could not be established. Please verify your network and device date.';
    }
    return 'Unable to process request. Please try again.';
  }
}
