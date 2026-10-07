import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutesia/core/services/api_data_service.dart';
import 'package:nutesia/core/services/credit_service.dart';
import 'package:nutesia/shared/widgets/error_views/error_views.dart';

void main() {
  group('18 AppError Categories and Subclasses Test', () {
    test('1. NetworkAppError initializes properly with retryable flag', () {
      const err = NetworkAppError.noInternet();
      expect(err.category, ErrorCategory.network);
      expect(err.code, 'NO_INTERNET');
      expect(err.retryable, isTrue);
      expect(err.actionType, ErrorActionType.retry);
    });

    test('2. ApiAppError handles HTTP status and retry logic', () {
      const err = ApiAppError.rateLimited(statusCode: 429);
      expect(err.category, ErrorCategory.api);
      expect(err.code, 'RATE_LIMITED');
      expect(err.retryable, isTrue);
      expect(err.actionType, ErrorActionType.retry);
    });

    test('3. AuthAppError handles session expiration with login action', () {
      const err = AuthAppError.sessionExpired();
      expect(err.category, ErrorCategory.auth);
      expect(err.code, 'SESSION_EXPIRED');
      expect(err.actionType, ErrorActionType.login);
    });

    test('4. AuthorizationAppError handles subscription gating with upgrade action', () {
      const err = AuthorizationAppError.subscriptionRequired();
      expect(err.category, ErrorCategory.authorization);
      expect(err.code, 'SUBSCRIPTION_REQUIRED');
      expect(err.actionType, ErrorActionType.upgrade);
    });

    test('5. ValidationAppError formats field error mappings', () {
      final err = ValidationAppError.fromFieldErrors(
        fieldErrors: {'email': 'Invalid email format', 'password': 'Too short'},
      );
      expect(err.category, ErrorCategory.validation);
      expect(err.code, 'VALIDATION_ERROR');
      expect(err.fieldErrors['email'], 'Invalid email format');
      expect(err.fieldErrors.containsKey('password'), isTrue);
    });

    test('6. DatabaseAppError handles query failures', () {
      const err = DatabaseAppError.queryFailed();
      expect(err.category, ErrorCategory.database);
      expect(err.code, 'DB_QUERY_FAILED');
    });

    test('7. BusinessAppError handles insufficient credits with watchAd action', () {
      const err = BusinessAppError.insufficientCredits();
      expect(err.category, ErrorCategory.business);
      expect(err.code, 'INSUFFICIENT_CREDITS');
      expect(err.actionType, ErrorActionType.watchAd);
    });

    test('8. StorageAppError handles storage issues', () {
      const err = StorageAppError.insufficientStorage();
      expect(err.category, ErrorCategory.storage);
      expect(err.code, 'INSUFFICIENT_STORAGE');
      expect(err.actionType, ErrorActionType.openSettings);
    });

    test('9. CacheAppError handles cache misses and corruption', () {
      const err = CacheAppError.corrupted(message: 'Corrupted food log cache');
      expect(err.category, ErrorCategory.cache);
      expect(err.code, 'CACHE_CORRUPTED');
    });

    test('10. DeviceAppError handles hardware unavailability', () {
      const err = DeviceAppError.cameraUnavailable();
      expect(err.category, ErrorCategory.device);
      expect(err.code, 'CAMERA_UNAVAILABLE');
    });

    test('11. PermissionAppError routes to settings action', () {
      const err = PermissionAppError.denied(permission: 'Camera');
      expect(err.category, ErrorCategory.permission);
      expect(err.code, 'PERMISSION_DENIED');
      expect(err.actionType, ErrorActionType.openSettings);
    });

    test('12. UnknownAppError handles fallback state', () {
      const err = UnknownAppError();
      expect(err.category, ErrorCategory.unknown);
      expect(err.code, 'UNKNOWN_ERROR');
    });

    test('13. AIAppError handles AI timeouts and parsing failures', () {
      const err = AIAppError.timeout();
      expect(err.category, ErrorCategory.ai);
      expect(err.code, 'AI_TIMEOUT');
      expect(err.retryable, isTrue);
    });

    test('14. PaymentAppError handles failed payments', () {
      const err = PaymentAppError.failed();
      expect(err.category, ErrorCategory.payment);
      expect(err.code, 'PAYMENT_FAILED');
      expect(err.actionType, ErrorActionType.retry);
    });

    test('15. BackgroundTaskAppError handles sync failures', () {
      const err = BackgroundTaskAppError(
        code: 'BACKGROUND_SYNC_FAILED',
        message: 'Sync failed for health data',
      );
      expect(err.category, ErrorCategory.backgroundTask);
      expect(err.code, 'BACKGROUND_SYNC_FAILED');
    });

    test('16. ConcurrencyAppError handles conflict and stale versions', () {
      const err = ConcurrencyAppError.conflict();
      expect(err.category, ErrorCategory.concurrency);
      expect(err.code, 'CONCURRENCY_CONFLICT');
      expect(err.retryable, isTrue);
    });

    test('17. SecurityAppError handles verification and tampering', () {
      const err = SecurityAppError.tampering();
      expect(err.category, ErrorCategory.security);
      expect(err.code, 'SECURITY_VERIFICATION_FAILED');
      expect(err.actionType, ErrorActionType.login);
    });

    test('18. ConfigurationAppError handles missing configuration', () {
      const err = ConfigurationAppError.missing(configKey: 'GEMINI_API_KEY');
      expect(err.category, ErrorCategory.configuration);
      expect(err.code, 'MISSING_CONFIGURATION');
      expect(err.actionType, ErrorActionType.dismiss);
    });
  });

  group('ErrorParser Universal Parsing and Sanitization Test', () {
    test('Parses structured JSON ApiException with VALIDATION_ERROR', () {
      const rawJson = '{"success": false, "error": {"code": "VALIDATION_ERROR", "message": "Invalid input provided", "details": {"name": "Name is required"}}}';
      const exception = ApiException(422, rawJson);
      final appErr = ErrorParser.parse(exception);

      expect(appErr, isA<ValidationAppError>());
      final valErr = appErr as ValidationAppError;
      expect(valErr.fieldErrors['name'], 'Name is required');
      expect(valErr.category, ErrorCategory.validation);
    });

    test('Parses ApiException 401 as AuthAppError', () {
      const exception = ApiException(401, '{"message": "Unauthorized token"}');
      final appErr = ErrorParser.parse(exception);

      expect(appErr, isA<AuthAppError>());
      expect(appErr.actionType, ErrorActionType.login);
    });

    test('Parses ApiException 403 as AuthorizationAppError', () {
      const exception = ApiException(403, '{"message": "Forbidden resource"}');
      final appErr = ErrorParser.parse(exception);

      expect(appErr, isA<AuthorizationAppError>());
      expect(appErr.code, 'FORBIDDEN');
    });

    test('Parses ApiException 429 as ApiAppError rate limited', () {
      const exception = ApiException(429, '{"message": "Too many requests"}');
      final appErr = ErrorParser.parse(exception);

      expect(appErr, isA<ApiAppError>());
      expect(appErr.code, 'RATE_LIMITED');
      expect(appErr.retryable, isTrue);
    });

    test('Parses ApiException 500 as ApiAppError server error with retryable', () {
      const exception = ApiException(500, '{"message": "Internal server crash"}');
      final appErr = ErrorParser.parse(exception);

      expect(appErr, isA<ApiAppError>());
      expect(appErr.code, 'SERVER_ERROR');
      expect(appErr.retryable, isTrue);
    });

    test('Parses NetworkException types accurately', () {
      const noInternet = NetworkException(
        type: NetworkErrorType.noInternet,
        message: 'No connection available',
      );
      expect(ErrorParser.parse(noInternet), isA<NetworkAppError>());

      const timeout = NetworkException(
        type: NetworkErrorType.timeout,
        message: 'Request timed out',
      );
      expect(ErrorParser.parse(timeout), isA<NetworkAppError>());

      const unauth = NetworkException(
        type: NetworkErrorType.unauthorized,
        message: 'Token expired',
      );
      expect(ErrorParser.parse(unauth), isA<AuthAppError>());
    });

    test('Reads the server error envelope carried by a NetworkException', () {
      const noCredits = NetworkException(
        type: NetworkErrorType.unknown,
        message: 'Server returned status code 402.',
        statusCode: 402,
        body: '{"success":false,"statusCode":402,"error":{"code":"INSUFFICIENT_CREDITS",'
            '"message":"Not enough credits for AI analysis. Watch an ad to earn free credits.","retryable":false}}',
      );
      final appErr = ErrorParser.parse(noCredits);
      expect(appErr, isA<BusinessAppError>());
      expect(appErr.code, 'INSUFFICIENT_CREDITS');
      expect(appErr.message.contains('402'), isFalse);

      const badFood = NetworkException(
        type: NetworkErrorType.unknown,
        message: 'Invalid food input.',
        statusCode: 400,
        body: '{"error":"Invalid food input. Please describe a food item."}',
      );
      expect(ErrorParser.parse(badFood).message, 'Invalid food input. Please describe a food item.');
    });

    test('Parses CreditException and RewardLimitException', () {
      const credErr = CreditException(currentCredits: 0);
      final appErr1 = ErrorParser.parse(credErr);
      expect(appErr1, isA<BusinessAppError>());
      expect(appErr1.code, 'INSUFFICIENT_CREDITS');
      expect(appErr1.actionType, ErrorActionType.watchAd);

      const limitErr = RewardLimitException('Daily ad reward limit reached');
      final appErr2 = ErrorParser.parse(limitErr);
      expect(appErr2, isA<BusinessAppError>());
      expect(appErr2.code, 'DAILY_LIMIT_REACHED');
    });

    test('Parses Dart I/O exceptions: TimeoutException and SocketException', () {
      final timeout = TimeoutException('Operation timed out after 10s');
      expect(ErrorParser.parse(timeout), isA<NetworkAppError>());

      const socket = SocketException('Failed host lookup');
      expect(ErrorParser.parse(socket), isA<NetworkAppError>());
    });

    test('Sanitizes sensitive leaks from raw messages (IPs, URLs, Stack traces)', () {
      const rawLeak1 = 'Error connecting to http://192.168.1.100:8080/api/v1/user at #0 Object.noSuchMethod';
      final sanitized1 = ErrorParser.sanitize(rawLeak1);

      expect(sanitized1.contains('192.168.1.100'), isFalse);
      expect(sanitized1.contains('8080'), isFalse);
      expect(sanitized1.contains('http://'), isFalse);
      expect(sanitized1.contains('noSuchMethod'), isFalse);

      const rawLeak2 = 'SocketException: OS Error: Connection refused, errno = 111, address = 10.0.0.5, port = 5432, uri = https://api.nuto.app/v1/auth';
      final sanitized2 = ErrorParser.sanitize(rawLeak2);
      expect(sanitized2.contains('10.0.0.5'), isFalse);
      expect(sanitized2.contains('5432'), isFalse);
      expect(sanitized2.contains('https://api.nuto.app'), isFalse);
      expect(sanitized2.contains('errno'), isFalse);

      // Verify ErrorParser.parse output also shields URLs and IPs
      final parsedErr = ErrorParser.parse(const SocketException('Failed host lookup: api.internal.nuto.app at 172.16.0.1:443'));
      expect(parsedErr.message.contains('api.internal.nuto.app'), isFalse);
      expect(parsedErr.message.contains('172.16.0.1'), isFalse);
      expect(parsedErr.message.contains('443'), isFalse);
    });
  });

  group('UiState and StateView Widget Rendering Test', () {
    testWidgets('StateView renders initial widget or shrink for UiStatus.initial', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateView<String>(
              status: UiStatus.initial,
              initialWidget: const Text('Initial View'),
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Initial View'), findsOneWidget);
    });

    testWidgets('StateView renders loading state for UiStatus.loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateView<String>(
              status: UiStatus.loading,
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('StateView renders empty state for UiStatus.empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateView<String>(
              status: UiStatus.empty,
              emptyTitle: 'No Food Logs',
              emptyMessage: 'Start tracking your meals today.',
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Food Logs'), findsOneWidget);
      expect(find.text('Start tracking your meals today.'), findsOneWidget);
    });

    testWidgets('StateView renders error state with AppErrorCard for UiStatus.error and triggers retry', (tester) async {
      bool retried = false;
      const testError = NetworkAppError.noInternet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateView<String>(
              status: UiStatus.error,
              error: testError,
              onRetry: () => retried = true,
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("You're offline. Please check your internet connection."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(retried, isTrue);
    });

    testWidgets('StateView renders content when UiStatus.success', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StateView<String>(
              status: UiStatus.success,
              data: 'Nutrition Dashboard Content',
              builder: (context, data) => Text(data),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nutrition Dashboard Content'), findsOneWidget);
    });

    testWidgets('InlineFieldError renders message only when errorText is non-null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                InlineFieldError(errorText: null),
                InlineFieldError(errorText: 'Email is required'),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('OfflineBanner renders when isOffline is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OfflineBanner(isOffline: true),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No internet connection. Changes will sync when reconnected.'), findsOneWidget);
    });
  });

  group('Error Dialogs and Toasts Test', () {
    testWidgets('AppToast.showInfo and showWarning render floating snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppToast.showInfo(context, 'Sync scheduled for background execution'),
                child: const Text('Show Info'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Sync scheduled for background execution'), findsOneWidget);
    });
  });
}

