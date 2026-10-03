import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/errors/error_parser.dart';
import '../../../core/theme/app_theme.dart';

/// Modal dialog and bottom sheet handlers for blocking operational states.
class AppErrorDialog {
  /// Shows a modal dialog for critical or actionable errors.
  static Future<bool?> show(
    BuildContext context, {
    required dynamic error,
    VoidCallback? onAction,
    String? customTitle,
    String? customActionLabel,
    bool barrierDismissible = true,
  }) {
    final appError = ErrorParser.parse(error);

    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getAccentColor(appError.category).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(appError.category),
                color: _getAccentColor(appError.category),
                size: 22,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Text(
                customTitle ?? _getDefaultTitle(appError.category),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appError.message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (appError is ValidationAppError && appError.fieldErrors.isNotEmpty) ...[
              const Gap(12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: appError.fieldErrors.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• ${e.key}: ${e.value}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              onAction?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getAccentColor(appError.category),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              customActionLabel ?? appError.actionLabel ?? 'Continue',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a modal bottom sheet for blocker errors with recovery actions.
  static Future<bool?> showSheet(
    BuildContext context, {
    required dynamic error,
    VoidCallback? onAction,
    String? customTitle,
    String? customActionLabel,
  }) {
    final appError = ErrorParser.parse(error);

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getAccentColor(appError.category).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(appError.category),
                      color: _getAccentColor(appError.category),
                      size: 26,
                    ),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customTitle ?? _getDefaultTitle(appError.category),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Code: ${appError.code}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Text(
                appError.message,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const Gap(24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop(true);
                        onAction?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getAccentColor(appError.category),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        customActionLabel ?? appError.actionLabel ?? 'Confirm',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _getAccentColor(ErrorCategory cat) {
    switch (cat) {
      case ErrorCategory.network:
        return const Color(0xFF38BDF8);
      case ErrorCategory.auth:
      case ErrorCategory.security:
        return const Color(0xFFF43F5E);
      case ErrorCategory.authorization:
      case ErrorCategory.permission:
        return const Color(0xFFF59E0B);
      case ErrorCategory.validation:
        return const Color(0xFFFB923C);
      case ErrorCategory.business:
        return const Color(0xFFEAB308);
      case ErrorCategory.ai:
        return const Color(0xFFA855F7);
      case ErrorCategory.storage:
      case ErrorCategory.device:
        return const Color(0xFF94A3B8);
      case ErrorCategory.api:
      case ErrorCategory.database:
      case ErrorCategory.concurrency:
      case ErrorCategory.cache:
      case ErrorCategory.backgroundTask:
      case ErrorCategory.configuration:
      case ErrorCategory.payment:
      case ErrorCategory.uiState:
      case ErrorCategory.unknown:
        return AppTheme.error;
    }
  }

  static IconData _getCategoryIcon(ErrorCategory cat) {
    switch (cat) {
      case ErrorCategory.network:
        return Icons.wifi_off_rounded;
      case ErrorCategory.auth:
      case ErrorCategory.security:
        return Icons.lock_outline_rounded;
      case ErrorCategory.authorization:
      case ErrorCategory.permission:
        return Icons.shield_outlined;
      case ErrorCategory.validation:
        return Icons.edit_note_rounded;
      case ErrorCategory.business:
        return Icons.bolt_rounded;
      case ErrorCategory.ai:
        return Icons.auto_awesome_rounded;
      case ErrorCategory.storage:
      case ErrorCategory.device:
        return Icons.folder_open_rounded;
      case ErrorCategory.api:
      case ErrorCategory.database:
      case ErrorCategory.concurrency:
      case ErrorCategory.cache:
      case ErrorCategory.backgroundTask:
      case ErrorCategory.configuration:
      case ErrorCategory.payment:
      case ErrorCategory.uiState:
      case ErrorCategory.unknown:
        return Icons.warning_amber_rounded;
    }
  }

  static String _getDefaultTitle(ErrorCategory cat) {
    switch (cat) {
      case ErrorCategory.network:
        return 'Network Connection';
      case ErrorCategory.auth:
        return 'Session Required';
      case ErrorCategory.authorization:
        return 'Access Restricted';
      case ErrorCategory.validation:
        return 'Input Required';
      case ErrorCategory.business:
        return 'Credit & Limit Notice';
      case ErrorCategory.ai:
        return 'AI Assistant';
      case ErrorCategory.permission:
        return 'Permission Required';
      case ErrorCategory.storage:
        return 'Storage Notice';
      default:
        return 'Notice';
    }
  }
}
