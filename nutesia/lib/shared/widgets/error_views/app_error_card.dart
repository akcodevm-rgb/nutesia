import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme.dart';

/// Rich visual error card with category styling, badges, validation breakdown,
/// and interactive action buttons.
class AppErrorCard extends StatelessWidget {
  final AppError error;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final String? customActionLabel;
  final bool compact;

  const AppErrorCard({
    super.key,
    required this.error,
    this.onAction,
    this.onDismiss,
    this.customActionLabel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = _getCategoryTheme(error.category, error.severity);

    return Container(
      padding: EdgeInsets.all(compact ? 14.0 : 20.0),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 34 : 40,
                height: compact ? 34 : 40,
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  theme.icon,
                  color: theme.accentColor,
                  size: compact ? 18 : 22,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _getDisplayTitle(error),
                            style: TextStyle(
                              fontSize: compact ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(8),
                        _CategoryBadge(
                          label: _getCategoryLabel(error.category),
                          color: theme.accentColor,
                        ),
                      ],
                    ),
                    if (!compact) ...[
                      const Gap(2),
                      Text(
                        'Code: ${error.code}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.textMuted),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Dismiss',
                ),
            ],
          ),
          const Gap(12),
          Text(
            error.message,
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          if (error is ValidationAppError && (error as ValidationAppError).fieldErrors.isNotEmpty) ...[
            const Gap(12),
            _ValidationFieldList(fieldErrors: (error as ValidationAppError).fieldErrors),
          ],
          if (onAction != null || (error.actionType != ErrorActionType.dismiss && error.actionType != ErrorActionType.none)) ...[
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onDismiss != null) ...[
                  TextButton(
                    onPressed: onDismiss,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontSize: 13)),
                  ),
                  const Gap(8),
                ],
                if (onAction != null || error.actionLabel != null || customActionLabel != null)
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: Icon(theme.actionIcon, size: 16),
                    label: Text(
                      customActionLabel ?? error.actionLabel ?? 'Retry',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, curve: Curves.easeOut);
  }

  String _getDisplayTitle(AppError error) {
    if (error is NetworkAppError) return 'Network Connection';
    if (error is AuthAppError) return 'Authentication';
    if (error is AuthorizationAppError) return 'Access Restricted';
    if (error is ValidationAppError) return 'Validation Error';
    if (error is BusinessAppError) return 'Limit or Balance';
    if (error is AIAppError) return 'AI Nutrition Assistant';
    if (error is PermissionAppError) return 'Permission Required';
    if (error is StorageAppError) return 'Storage';
    if (error is ApiAppError) return 'Server Communication';
    return 'Action Needed';
  }

  String _getCategoryLabel(ErrorCategory cat) {
    switch (cat) {
      case ErrorCategory.network:
        return 'Network';
      case ErrorCategory.api:
        return 'API';
      case ErrorCategory.auth:
        return 'Auth';
      case ErrorCategory.authorization:
        return 'Access';
      case ErrorCategory.validation:
        return 'Input';
      case ErrorCategory.database:
        return 'Database';
      case ErrorCategory.business:
        return 'Account';
      case ErrorCategory.storage:
        return 'Storage';
      case ErrorCategory.cache:
        return 'Cache';
      case ErrorCategory.device:
        return 'Device';
      case ErrorCategory.permission:
        return 'Permission';
      case ErrorCategory.uiState:
        return 'UI';
      case ErrorCategory.ai:
        return 'AI Service';
      case ErrorCategory.payment:
        return 'Payment';
      case ErrorCategory.backgroundTask:
        return 'Background';
      case ErrorCategory.concurrency:
        return 'Sync';
      case ErrorCategory.security:
        return 'Security';
      case ErrorCategory.configuration:
        return 'Config';
      case ErrorCategory.unknown:
        return 'Notice';
    }
  }

  _ErrorCategoryTheme _getCategoryTheme(ErrorCategory cat, ErrorSeverity severity) {
    if (severity == ErrorSeverity.critical) {
      return const _ErrorCategoryTheme(
        accentColor: AppTheme.error,
        backgroundColor: Color(0xFF241416),
        borderColor: Color(0xFF68262C),
        icon: Icons.error_rounded,
        actionIcon: Icons.refresh_rounded,
      );
    }

    switch (cat) {
      case ErrorCategory.network:
        return const _ErrorCategoryTheme(
          accentColor: Color(0xFF38BDF8), // Cyan blue
          backgroundColor: Color(0xFF101B2B),
          borderColor: Color(0xFF1E3A5F),
          icon: Icons.wifi_off_rounded,
          actionIcon: Icons.refresh_rounded,
        );
      case ErrorCategory.auth:
      case ErrorCategory.security:
        return const _ErrorCategoryTheme(
          accentColor: Color(0xFFF43F5E), // Rose red
          backgroundColor: Color(0xFF24141A),
          borderColor: Color(0xFF5C1D2A),
          icon: Icons.lock_outline_rounded,
          actionIcon: Icons.login_rounded,
        );
      case ErrorCategory.authorization:
      case ErrorCategory.permission:
        return const _ErrorCategoryTheme(
          accentColor: Color(0xFFF59E0B), // Amber
          backgroundColor: Color(0xFF241C10),
          borderColor: Color(0xFF5A3E14),
          icon: Icons.shield_outlined,
          actionIcon: Icons.settings_rounded,
        );
      case ErrorCategory.validation:
        return const _ErrorCategoryTheme(
          accentColor: Color(0xFFFB923C), // Orange
          backgroundColor: Color(0xFF221710),
          borderColor: Color(0xFF542C12),
          icon: Icons.edit_note_rounded,
          actionIcon: Icons.check_circle_outline_rounded,
        );
      case ErrorCategory.business:
        return const _ErrorCategoryTheme(
          accentColor: Color(0xFFEAB308), // Yellow gold
          backgroundColor: Color(0xFF221F10),
          borderColor: Color(0xFF544912),
          icon: Icons.bolt_rounded,
          actionIcon: Icons.play_circle_outline_rounded,
        );
      case ErrorCategory.ai:
        return const _ErrorCategoryTheme(
          accentColor: Color(0xFFA855F7), // Purple / AI
          backgroundColor: Color(0xFF1C1329),
          borderColor: Color(0xFF45226E),
          icon: Icons.auto_awesome_rounded,
          actionIcon: Icons.refresh_rounded,
        );
      case ErrorCategory.storage:
      case ErrorCategory.device:
        return const _ErrorCategoryTheme(
          accentColor: Color(0xFF94A3B8), // Slate
          backgroundColor: Color(0xFF181C24),
          borderColor: Color(0xFF2D3748),
          icon: Icons.folder_open_rounded,
          actionIcon: Icons.refresh_rounded,
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
        return const _ErrorCategoryTheme(
          accentColor: AppTheme.error,
          backgroundColor: Color(0xFF201518),
          borderColor: Color(0xFF4D2128),
          icon: Icons.warning_amber_rounded,
          actionIcon: Icons.refresh_rounded,
        );
    }
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _CategoryBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ValidationFieldList extends StatelessWidget {
  final Map<String, String> fieldErrors;

  const _ValidationFieldList({required this.fieldErrors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fieldErrors.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.circle, size: 5, color: AppTheme.error),
                ),
                const Gap(8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${entry.key}: ',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        TextSpan(
                          text: entry.value,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ErrorCategoryTheme {
  final Color accentColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final IconData actionIcon;

  const _ErrorCategoryTheme({
    required this.accentColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.actionIcon,
  });
}
