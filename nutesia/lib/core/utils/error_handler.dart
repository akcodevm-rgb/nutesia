import '../errors/app_error.dart';
import '../errors/error_parser.dart';

export '../errors/app_error.dart';
export '../errors/error_parser.dart';

/// Legacy-compatible wrapper around [ErrorParser] and [AppError].
/// Translates any error into clean, actionable, and sanitized user messaging.
class AppErrorHandler {
  /// Converts any caught error into a safe, human-friendly message,
  /// strictly stripping out IP addresses, URLs, stack traces, and internal technical names.
  static String toHumanMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';
    final appError = ErrorParser.parse(error);
    return appError.message;
  }

  /// Parses any error directly into a strongly typed [AppError].
  static AppError parse(dynamic error, [StackTrace? stackTrace]) {
    return ErrorParser.parse(error, stackTrace);
  }

  /// Sanitizes raw strings by stripping IPs, URLs, ports, and internal Exception class names.
  static String sanitize(String message) {
    return ErrorParser.sanitize(message);
  }
}
