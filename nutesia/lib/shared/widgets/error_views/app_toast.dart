import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_parser.dart';
import '../../../core/theme/app_theme.dart';

/// Modern floating frosted toast notification with interactive recovery action chip.
class AppToast {
  /// Displays a floating actionable error banner.
  static void showError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onAction,
    String? customActionLabel,
    Duration duration = const Duration(seconds: 4),
  }) {
    final appError = ErrorParser.parse(error);
    final theme = _resolveToastTheme(appError.category, appError.severity);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: theme.accentColor.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(theme.icon, size: 18, color: theme.accentColor),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appError.message,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onAction != null || appError.actionLabel != null || customActionLabel != null) ...[
                const Gap(8),
                InkWell(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction?.call();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customActionLabel ?? appError.actionLabel ?? 'Retry',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Displays a floating success banner.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF10241A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF22543D), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppTheme.primary),
              ),
              const Gap(10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays a floating warning banner.
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF241C10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5A3E14), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.warning),
              ),
              const Gap(10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays a floating info banner.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF101B2B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E3A5F), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF38BDF8)),
              ),
              const Gap(10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _ToastTheme _resolveToastTheme(ErrorCategory cat, ErrorSeverity severity) {
    if (severity == ErrorSeverity.critical) {
      return const _ToastTheme(
        accentColor: AppTheme.error,
        backgroundColor: Color(0xFF261215),
        borderColor: Color(0xFF6B2129),
        icon: Icons.error_rounded,
      );
    }

    switch (cat) {
      case ErrorCategory.network:
        return const _ToastTheme(
          accentColor: Color(0xFF38BDF8),
          backgroundColor: Color(0xFF101C2B),
          borderColor: Color(0xFF1E3A5F),
          icon: Icons.wifi_off_rounded,
        );
      case ErrorCategory.auth:
      case ErrorCategory.security:
        return const _ToastTheme(
          accentColor: Color(0xFFF43F5E),
          backgroundColor: Color(0xFF24141A),
          borderColor: Color(0xFF5C1D2A),
          icon: Icons.lock_outline_rounded,
        );
      case ErrorCategory.authorization:
      case ErrorCategory.permission:
        return const _ToastTheme(
          accentColor: Color(0xFFF59E0B),
          backgroundColor: Color(0xFF241C10),
          borderColor: Color(0xFF5A3E14),
          icon: Icons.shield_outlined,
        );
      case ErrorCategory.validation:
        return const _ToastTheme(
          accentColor: Color(0xFFFB923C),
          backgroundColor: Color(0xFF221710),
          borderColor: Color(0xFF542C12),
          icon: Icons.edit_note_rounded,
        );
      case ErrorCategory.business:
        return const _ToastTheme(
          accentColor: Color(0xFFEAB308),
          backgroundColor: Color(0xFF221F10),
          borderColor: Color(0xFF544912),
          icon: Icons.bolt_rounded,
        );
      case ErrorCategory.ai:
        return const _ToastTheme(
          accentColor: Color(0xFFA855F7),
          backgroundColor: Color(0xFF1C1329),
          borderColor: Color(0xFF45226E),
          icon: Icons.auto_awesome_rounded,
        );
      case ErrorCategory.storage:
      case ErrorCategory.device:
        return const _ToastTheme(
          accentColor: Color(0xFF94A3B8),
          backgroundColor: Color(0xFF181C24),
          borderColor: Color(0xFF2D3748),
          icon: Icons.folder_open_rounded,
        );
      case ErrorCategory.api:
      case ErrorCategory.database:
      case ErrorCategory.concurrency:
      case ErrorCategory.cache:
      case ErrorCategory.backgroundTask:
      case ErrorCategory.configuration:
      case ErrorCategory.payment:
      case ErrorCategory.uiState:
      case ErrorCategory.unknown:
        return const _ToastTheme(
          accentColor: AppTheme.error,
          backgroundColor: Color(0xFF241416),
          borderColor: Color(0xFF571F25),
          icon: Icons.error_outline_rounded,
        );
    }
  }
}

class _ToastTheme {
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  const _ToastTheme({
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}
