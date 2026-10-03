/// The 18 standard error categories in production application architecture.
enum ErrorCategory {
  network,
  api,
  auth,
  authorization,
  validation,
  database,
  business,
  storage,
  cache,
  device,
  permission,
  uiState,
  ai,
  payment,
  backgroundTask,
  concurrency,
  security,
  configuration,
  unknown,
}

/// Visual and operational severity level of an error.
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Recommended action type to guide user recovery or automated UI flows.
enum ErrorActionType {
  retry,
  login,
  watchAd,
  openSettings,
  upgrade,
  dismiss,
  contactSupport,
  none,
}

/// Base abstract class for all domain, system, and operational errors in Nutesia.
abstract class AppError implements Exception {
  final String code;
  final String message;
  final String? technicalDetails;
  final Map<String, dynamic>? details;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final bool retryable;
  final ErrorActionType actionType;
  final String? actionLabel;

  const AppError({
    required this.code,
    required this.message,
    this.technicalDetails,
    this.details,
    required this.category,
    this.severity = ErrorSeverity.error,
    this.retryable = false,
    this.actionType = ErrorActionType.dismiss,
    this.actionLabel,
  });

  @override
  String toString() => 'AppError[$category:$code] $message';
}

// ─── 1. Network / Connectivity Errors ──────────────────────────────────────

class NetworkAppError extends AppError {
  const NetworkAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.warning,
    super.retryable = true,
    super.actionType = ErrorActionType.retry,
    super.actionLabel = 'Retry',
  }) : super(category: ErrorCategory.network);

  const NetworkAppError.noInternet({
    String message = "You're offline. Please check your internet connection.",
    String? technicalDetails,
  }) : this(
          code: 'NO_INTERNET',
          message: message,
          technicalDetails: technicalDetails,
        );

  const NetworkAppError.timeout({
    String message = 'Connection timed out. Please check your network and try again.',
    String? technicalDetails,
  }) : this(
          code: 'NETWORK_TIMEOUT',
          message: message,
          technicalDetails: technicalDetails,
        );

  const NetworkAppError.dnsFailure({
    String message = 'Unable to resolve server address. Please verify your connection.',
    String? technicalDetails,
  }) : this(
          code: 'DNS_FAILURE',
          message: message,
          technicalDetails: technicalDetails,
        );

  const NetworkAppError.connectionRefused({
    String message = 'Unable to reach Nutesia servers. Please try again shortly.',
    String? technicalDetails,
  }) : this(
          code: 'CONNECTION_REFUSED',
          message: message,
          technicalDetails: technicalDetails,
        );

  const NetworkAppError.serverUnreachable({
    String message = 'The server is currently unreachable. Please try again in a few moments.',
    String? technicalDetails,
  }) : this(
          code: 'SERVER_UNREACHABLE',
          message: message,
          technicalDetails: technicalDetails,
        );

  const NetworkAppError.captivePortal({
    String message = 'Wi-Fi login or captive portal authorization is required.',
    String? technicalDetails,
  }) : this(
          code: 'CAPTIVE_PORTAL',
          message: message,
          technicalDetails: technicalDetails,
          actionType: ErrorActionType.openSettings,
          actionLabel: 'Open Settings',
        );

  const NetworkAppError.requestCancelled({
    String message = 'Network request was cancelled.',
    String? technicalDetails,
  }) : this(
          code: 'REQUEST_CANCELLED',
          message: message,
          technicalDetails: technicalDetails,
          retryable: false,
          actionType: ErrorActionType.dismiss,
        );
}

// ─── 2. API / HTTP States ──────────────────────────────────────────────────

class ApiAppError extends AppError {
  final int? statusCode;

  const ApiAppError({
    required super.code,
    required super.message,
    this.statusCode,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.error,
    super.retryable = false,
    super.actionType = ErrorActionType.dismiss,
    super.actionLabel,
  }) : super(category: ErrorCategory.api);

  const ApiAppError.badRequest({
    String message = 'Invalid request parameters. Please verify your data.',
    int? statusCode = 400,
    Map<String, dynamic>? details,
    String? technicalDetails,
  }) : this(
          code: 'BAD_REQUEST',
          message: message,
          statusCode: statusCode,
          details: details,
          technicalDetails: technicalDetails,
        );

  const ApiAppError.notFound({
    String message = 'The requested resource was not found.',
    int? statusCode = 404,
    String? technicalDetails,
  }) : this(
          code: 'NOT_FOUND',
          message: message,
          statusCode: statusCode,
          technicalDetails: technicalDetails,
        );

  const ApiAppError.conflict({
    String message = 'A conflicting record already exists.',
    int? statusCode = 409,
    String? technicalDetails,
  }) : this(
          code: 'CONFLICT',
          message: message,
          statusCode: statusCode,
          technicalDetails: technicalDetails,
        );

  const ApiAppError.rateLimited({
    String message = 'Too many requests. Please wait a moment before trying again.',
    int? statusCode = 429,
    String? technicalDetails,
  }) : this(
          code: 'RATE_LIMITED',
          message: message,
          statusCode: statusCode,
          technicalDetails: technicalDetails,
          retryable: true,
          actionType: ErrorActionType.retry,
          actionLabel: 'Try Again',
        );

  const ApiAppError.serverError({
    String message = 'Server error occurred. Our engineers have been notified.',
    int? statusCode = 500,
    String? technicalDetails,
  }) : this(
          code: 'SERVER_ERROR',
          message: message,
          statusCode: statusCode,
          technicalDetails: technicalDetails,
          severity: ErrorSeverity.error,
          retryable: true,
          actionType: ErrorActionType.retry,
          actionLabel: 'Retry',
        );

  const ApiAppError.badGateway({
    String message = 'Server gateway is temporarily unavailable. Please retry shortly.',
    int? statusCode = 502,
    String? technicalDetails,
  }) : this(
          code: 'BAD_GATEWAY',
          message: message,
          statusCode: statusCode,
          technicalDetails: technicalDetails,
          retryable: true,
          actionType: ErrorActionType.retry,
          actionLabel: 'Retry',
        );

  const ApiAppError.serviceUnavailable({
    String message = 'Nutesia service is temporarily undergoing maintenance.',
    int? statusCode = 503,
    String? technicalDetails,
  }) : this(
          code: 'SERVICE_UNAVAILABLE',
          message: message,
          statusCode: statusCode,
          technicalDetails: technicalDetails,
          retryable: true,
          actionType: ErrorActionType.retry,
          actionLabel: 'Retry',
        );

  const ApiAppError.gatewayTimeout({
    String message = 'Server response took too long. Please try again.',
    int? statusCode = 504,
    String? technicalDetails,
  }) : this(
          code: 'GATEWAY_TIMEOUT',
          message: message,
          statusCode: statusCode,
          technicalDetails: technicalDetails,
          retryable: true,
          actionType: ErrorActionType.retry,
          actionLabel: 'Retry',
        );
}

// ─── 3. Authentication States ──────────────────────────────────────────────

class AuthAppError extends AppError {
  const AuthAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.warning,
    super.retryable = false,
    super.actionType = ErrorActionType.login,
    super.actionLabel = 'Log In',
  }) : super(category: ErrorCategory.auth);

  const AuthAppError.sessionExpired({
    String message = 'Your session has expired. Please sign in again to continue.',
    String? technicalDetails,
  }) : this(
          code: 'SESSION_EXPIRED',
          message: message,
          technicalDetails: technicalDetails,
        );

  const AuthAppError.notLoggedIn({
    String message = 'Please sign in to access this feature.',
    String? technicalDetails,
  }) : this(
          code: 'NOT_LOGGED_IN',
          message: message,
          technicalDetails: technicalDetails,
        );

  const AuthAppError.invalidCredentials({
    String message = 'Invalid email or password. Please verify and try again.',
    String? technicalDetails,
  }) : this(
          code: 'INVALID_CREDENTIALS',
          message: message,
          technicalDetails: technicalDetails,
          actionType: ErrorActionType.dismiss,
          actionLabel: 'OK',
        );

  const AuthAppError.accountDisabled({
    String message = 'This account has been disabled. Please contact support.',
    String? technicalDetails,
  }) : this(
          code: 'ACCOUNT_DISABLED',
          message: message,
          technicalDetails: technicalDetails,
          severity: ErrorSeverity.critical,
          actionType: ErrorActionType.contactSupport,
          actionLabel: 'Contact Support',
        );

  const AuthAppError.tooManyAttempts({
    String message = 'Too many failed login attempts. Please try again later.',
    String? technicalDetails,
  }) : this(
          code: 'TOO_MANY_ATTEMPTS',
          message: message,
          technicalDetails: technicalDetails,
          actionType: ErrorActionType.dismiss,
        );
}

// ─── 4. Authorization States ───────────────────────────────────────────────

class AuthorizationAppError extends AppError {
  const AuthorizationAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.warning,
    super.retryable = false,
    super.actionType = ErrorActionType.upgrade,
    super.actionLabel = 'Upgrade',
  }) : super(category: ErrorCategory.authorization);

  const AuthorizationAppError.forbidden({
    String message = 'You do not have permission to access this resource.',
    String? technicalDetails,
  }) : this(
          code: 'FORBIDDEN',
          message: message,
          technicalDetails: technicalDetails,
          actionType: ErrorActionType.dismiss,
          actionLabel: 'OK',
        );

  const AuthorizationAppError.subscriptionRequired({
    String message = 'This feature requires an active premium subscription.',
    String? technicalDetails,
  }) : this(
          code: 'SUBSCRIPTION_REQUIRED',
          message: message,
          technicalDetails: technicalDetails,
        );
}

// ─── 5. Input & Validation States ──────────────────────────────────────────

class ValidationAppError extends AppError {
  final Map<String, String> fieldErrors;

  ValidationAppError({
    required super.code,
    required super.message,
    this.fieldErrors = const {},
    super.technicalDetails,
    Map<String, dynamic>? details,
    super.severity = ErrorSeverity.warning,
  }) : super(
          category: ErrorCategory.validation,
          details: details ?? fieldErrors,
          retryable: false,
          actionType: ErrorActionType.dismiss,
          actionLabel: 'Fix Input',
        );

  factory ValidationAppError.fromFieldErrors({
    required Map<String, String> fieldErrors,
    String message = 'Please review and correct the marked fields.',
    String? technicalDetails,
  }) {
    return ValidationAppError(
      code: 'VALIDATION_ERROR',
      message: message,
      fieldErrors: fieldErrors,
      technicalDetails: technicalDetails,
    );
  }

  factory ValidationAppError.singleField({
    required String field,
    required String error,
    String? technicalDetails,
  }) {
    return ValidationAppError(
      code: 'FIELD_INVALID',
      message: error,
      fieldErrors: {field: error},
      technicalDetails: technicalDetails,
    );
  }
}

// ─── 6. Business Logic States ──────────────────────────────────────────────

class BusinessAppError extends AppError {
  const BusinessAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.warning,
    super.retryable = false,
    super.actionType = ErrorActionType.dismiss,
    super.actionLabel,
  }) : super(category: ErrorCategory.business);

  const BusinessAppError.insufficientCredits({
    String message = 'Not enough credits. Watch a short video to earn free credits.',
    String? technicalDetails,
  }) : this(
          code: 'INSUFFICIENT_CREDITS',
          message: message,
          technicalDetails: technicalDetails,
          actionType: ErrorActionType.watchAd,
          actionLabel: 'Watch Ad (+1 Credit)',
        );

  const BusinessAppError.dailyLimitReached({
    String message = 'Daily ad reward limit reached. Your free credits reset at midnight.',
    String? technicalDetails,
  }) : this(
          code: 'DAILY_LIMIT_REACHED',
          message: message,
          technicalDetails: technicalDetails,
          actionType: ErrorActionType.dismiss,
        );

  const BusinessAppError.profileLimitReached({
    String message = 'Maximum 3 member profiles allowed per family space.',
    String? technicalDetails,
  }) : this(
          code: 'PROFILE_LIMIT_REACHED',
          message: message,
          technicalDetails: technicalDetails,
        );

  const BusinessAppError.alreadyExists({
    String message = 'This item already exists in your log.',
    String? technicalDetails,
  }) : this(
          code: 'ALREADY_EXISTS',
          message: message,
          technicalDetails: technicalDetails,
        );
}

// ─── 7. AI-Specific States ─────────────────────────────────────────────────

class AIAppError extends AppError {
  const AIAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.error,
    super.retryable = true,
    super.actionType = ErrorActionType.retry,
    super.actionLabel = 'Try Again',
  }) : super(category: ErrorCategory.ai);

  const AIAppError.modelUnavailable({
    String message = 'AI nutrition assistant is temporarily busy. Please try again shortly.',
    String? technicalDetails,
  }) : this(
          code: 'AI_MODEL_UNAVAILABLE',
          message: message,
          technicalDetails: technicalDetails,
        );

  const AIAppError.timeout({
    String message = 'AI analysis timed out. Please simplify your description or try again.',
    String? technicalDetails,
  }) : this(
          code: 'AI_TIMEOUT',
          message: message,
          technicalDetails: technicalDetails,
        );

  const AIAppError.rateLimited({
    String message = 'AI analysis rate limit reached. Please wait a moment.',
    String? technicalDetails,
  }) : this(
          code: 'AI_RATE_LIMITED',
          message: message,
          technicalDetails: technicalDetails,
        );

  const AIAppError.invalidResponse({
    String message = 'Could not parse nutritional details from this input. Please specify quantities and food names.',
    String? technicalDetails,
  }) : this(
          code: 'AI_INVALID_RESPONSE',
          message: message,
          technicalDetails: technicalDetails,
          retryable: false,
          actionType: ErrorActionType.dismiss,
          actionLabel: 'Edit Input',
        );

  const AIAppError.contentRejected({
    String message = 'The provided input could not be processed as a food item.',
    String? technicalDetails,
  }) : this(
          code: 'AI_CONTENT_REJECTED',
          message: message,
          technicalDetails: technicalDetails,
          retryable: false,
        );
}

// ─── 8. Storage & File States ──────────────────────────────────────────────

class StorageAppError extends AppError {
  const StorageAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.error,
    super.retryable = false,
    super.actionType = ErrorActionType.dismiss,
    super.actionLabel,
  }) : super(category: ErrorCategory.storage);

  const StorageAppError.fileNotFound({
    String message = 'Selected file was not found.',
    String? technicalDetails,
  }) : this(
          code: 'FILE_NOT_FOUND',
          message: message,
          technicalDetails: technicalDetails,
        );

  const StorageAppError.uploadFailed({
    String message = 'File upload failed. Please try again.',
    String? technicalDetails,
  }) : this(
          code: 'UPLOAD_FAILED',
          message: message,
          technicalDetails: technicalDetails,
          retryable: true,
          actionType: ErrorActionType.retry,
          actionLabel: 'Retry Upload',
        );

  const StorageAppError.insufficientStorage({
    String message = 'Device storage is nearly full. Please free up space.',
    String? technicalDetails,
  }) : this(
          code: 'INSUFFICIENT_STORAGE',
          message: message,
          technicalDetails: technicalDetails,
          severity: ErrorSeverity.critical,
          actionType: ErrorActionType.openSettings,
          actionLabel: 'Storage Settings',
        );
}

// ─── 9. Cache States ───────────────────────────────────────────────────────

class CacheAppError extends AppError {
  const CacheAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.info,
    super.retryable = true,
    super.actionType = ErrorActionType.retry,
    super.actionLabel = 'Refresh',
  }) : super(category: ErrorCategory.cache);

  const CacheAppError.miss({
    String message = 'Cached data unavailable. Fetching latest data.',
    String? technicalDetails,
  }) : this(
          code: 'CACHE_MISS',
          message: message,
          technicalDetails: technicalDetails,
        );

  const CacheAppError.corrupted({
    String message = 'Local cache was corrupted and has been reset.',
    String? technicalDetails,
  }) : this(
          code: 'CACHE_CORRUPTED',
          message: message,
          technicalDetails: technicalDetails,
        );
}

// ─── 10. Device States ─────────────────────────────────────────────────────

class DeviceAppError extends AppError {
  const DeviceAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.warning,
    super.retryable = false,
    super.actionType = ErrorActionType.openSettings,
    super.actionLabel = 'Open Settings',
  }) : super(category: ErrorCategory.device);

  const DeviceAppError.cameraUnavailable({
    String message = 'Camera is currently unavailable on this device.',
    String? technicalDetails,
  }) : this(
          code: 'CAMERA_UNAVAILABLE',
          message: message,
          technicalDetails: technicalDetails,
        );

  const DeviceAppError.lowBattery({
    String message = 'Battery saver mode is active. High performance operations may be throttled.',
    String? technicalDetails,
  }) : this(
          code: 'BATTERY_SAVER_ACTIVE',
          message: message,
          technicalDetails: technicalDetails,
          severity: ErrorSeverity.info,
          actionType: ErrorActionType.dismiss,
        );
}

// ─── 11. Permission States ─────────────────────────────────────────────────

class PermissionAppError extends AppError {
  final String permission;

  const PermissionAppError({
    required super.code,
    required super.message,
    required this.permission,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.warning,
    super.retryable = false,
    super.actionType = ErrorActionType.openSettings,
    super.actionLabel = 'Grant Permission',
  }) : super(category: ErrorCategory.permission);

  const PermissionAppError.denied({
    required String permission,
    String? message,
    String? technicalDetails,
  }) : this(
          code: 'PERMISSION_DENIED',
          permission: permission,
          message: message ?? 'Permission to access $permission was denied.',
          technicalDetails: technicalDetails,
        );

  const PermissionAppError.permanentlyDenied({
    required String permission,
    String? message,
    String? technicalDetails,
  }) : this(
          code: 'PERMISSION_PERMANENTLY_DENIED',
          permission: permission,
          message: message ?? 'Permission to access $permission is permanently denied. Please enable it in Settings.',
          technicalDetails: technicalDetails,
        );
}

// ─── 12. Database States ───────────────────────────────────────────────────

class DatabaseAppError extends AppError {
  const DatabaseAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.error,
    super.retryable = true,
    super.actionType = ErrorActionType.retry,
    super.actionLabel = 'Retry',
  }) : super(category: ErrorCategory.database);

  const DatabaseAppError.queryFailed({
    String message = 'Database query failed. Please retry.',
    String? technicalDetails,
  }) : this(
          code: 'DB_QUERY_FAILED',
          message: message,
          technicalDetails: technicalDetails,
        );

  const DatabaseAppError.constraintViolation({
    String message = 'Record constraint violation encountered.',
    String? technicalDetails,
  }) : this(
          code: 'DB_CONSTRAINT_VIOLATION',
          message: message,
          technicalDetails: technicalDetails,
          retryable: false,
          actionType: ErrorActionType.dismiss,
        );
}

// ─── 13. Concurrency States ────────────────────────────────────────────────

class ConcurrencyAppError extends AppError {
  const ConcurrencyAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.warning,
    super.retryable = true,
    super.actionType = ErrorActionType.retry,
    super.actionLabel = 'Refresh',
  }) : super(category: ErrorCategory.concurrency);

  const ConcurrencyAppError.conflict({
    String message = 'The record was modified by another session. Please refresh.',
    String? technicalDetails,
  }) : this(
          code: 'CONCURRENCY_CONFLICT',
          message: message,
          technicalDetails: technicalDetails,
        );
}

// ─── 14. Security States ───────────────────────────────────────────────────

class SecurityAppError extends AppError {
  const SecurityAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.critical,
    super.retryable = false,
    super.actionType = ErrorActionType.login,
    super.actionLabel = 'Authenticate',
  }) : super(category: ErrorCategory.security);

  const SecurityAppError.tampering({
    String message = 'Security verification failed. Please re-authenticate.',
    String? technicalDetails,
  }) : this(
          code: 'SECURITY_VERIFICATION_FAILED',
          message: message,
          technicalDetails: technicalDetails,
        );
}

// ─── 15. Payment States ────────────────────────────────────────────────────

class PaymentAppError extends AppError {
  const PaymentAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.error,
    super.retryable = true,
    super.actionType = ErrorActionType.retry,
    super.actionLabel = 'Retry Payment',
  }) : super(category: ErrorCategory.payment);

  const PaymentAppError.failed({
    String message = 'Payment could not be processed. Please check payment details.',
    String? technicalDetails,
  }) : this(
          code: 'PAYMENT_FAILED',
          message: message,
          technicalDetails: technicalDetails,
        );

  const PaymentAppError.cancelled({
    String message = 'Payment transaction was cancelled.',
    String? technicalDetails,
  }) : this(
          code: 'PAYMENT_CANCELLED',
          message: message,
          technicalDetails: technicalDetails,
          retryable: false,
          actionType: ErrorActionType.dismiss,
        );
}

// ─── 16. Background Task States ────────────────────────────────────────────

class BackgroundTaskAppError extends AppError {
  const BackgroundTaskAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.warning,
    super.retryable = true,
    super.actionType = ErrorActionType.retry,
    super.actionLabel = 'Retry Task',
  }) : super(category: ErrorCategory.backgroundTask);
}

// ─── 17. Configuration States ──────────────────────────────────────────────

class ConfigurationAppError extends AppError {
  const ConfigurationAppError({
    required super.code,
    required super.message,
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.critical,
    super.retryable = false,
    super.actionType = ErrorActionType.dismiss,
    super.actionLabel = 'Dismiss',
  }) : super(category: ErrorCategory.configuration);

  const ConfigurationAppError.missing({
    required String configKey,
    String? technicalDetails,
  }) : this(
          code: 'MISSING_CONFIGURATION',
          message: 'Application configuration error. Please ensure environment is set up.',
          technicalDetails: technicalDetails ?? 'Missing config: $configKey',
        );
}

// ─── 18. Unknown / Fallback States ─────────────────────────────────────────

class UnknownAppError extends AppError {
  const UnknownAppError({
    super.code = 'UNKNOWN_ERROR',
    super.message = 'An unexpected error occurred. Please try again.',
    super.technicalDetails,
    super.details,
    super.severity = ErrorSeverity.error,
    super.retryable = true,
    super.actionType = ErrorActionType.retry,
    super.actionLabel = 'Retry',
  }) : super(
          category: ErrorCategory.unknown,
        );
}
