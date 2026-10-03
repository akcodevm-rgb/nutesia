import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/ui_state.dart';
import '../../../core/theme/app_theme.dart';
import 'app_error_card.dart';

/// Comprehensive multi-state widget container for screens and modular views.
/// Renders distinct UI states seamlessly: Initial, Loading, Empty, Error, Offline, Retrying, and Content.
class StateView<T> extends StatelessWidget {
  final UiStatus status;
  final T? data;
  final AppError? error;
  final String? emptyMessage;
  final String? emptyTitle;
  final IconData? emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final VoidCallback? onRetry;
  final VoidCallback? onDismissError;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget? initialWidget;
  final bool isSliver;

  const StateView({
    super.key,
    required this.status,
    this.data,
    this.error,
    this.emptyMessage,
    this.emptyTitle,
    this.emptyIcon,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.onRetry,
    this.onDismissError,
    required this.builder,
    this.loadingWidget,
    this.initialWidget,
    this.isSliver = false,
  });

  /// Factory from a [UiState] object.
  factory StateView.fromState({
    Key? key,
    required UiState<T> state,
    required Widget Function(BuildContext context, T data) builder,
    VoidCallback? onRetry,
    VoidCallback? onEmptyAction,
    VoidCallback? onDismissError,
    String? emptyTitle,
    IconData? emptyIcon,
    String? emptyActionLabel,
    Widget? loadingWidget,
    Widget? initialWidget,
    bool isSliver = false,
  }) {
    return StateView<T>(
      key: key,
      status: state.status,
      data: state.data,
      error: state.error,
      emptyMessage: state.emptyMessage,
      emptyTitle: emptyTitle,
      emptyIcon: emptyIcon,
      emptyActionLabel: emptyActionLabel,
      onRetry: onRetry,
      onEmptyAction: onEmptyAction,
      onDismissError: onDismissError,
      loadingWidget: loadingWidget,
      initialWidget: initialWidget,
      isSliver: isSliver,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildContent(context);
    if (isSliver) {
      return SliverToBoxAdapter(child: body);
    }
    return body;
  }

  Widget _buildContent(BuildContext context) {
    switch (status) {
      case UiStatus.initial:
        return initialWidget ?? const SizedBox.shrink();

      case UiStatus.loading:
        return loadingWidget ?? _defaultLoadingWidget();

      case UiStatus.empty:
        return _EmptyStateView(
          title: emptyTitle ?? 'Nothing Here Yet',
          message: emptyMessage ?? 'No data found for this section.',
          icon: emptyIcon ?? Icons.inbox_rounded,
          actionLabel: emptyActionLabel,
          onAction: onEmptyAction,
        );

      case UiStatus.error:
        final currentError = error ?? const UnknownAppError();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: AppErrorCard(
            error: currentError,
            onAction: onRetry,
            onDismiss: onDismissError,
          ),
        );

      case UiStatus.offline:
        return _OfflineStateView(
          cachedData: data,
          onRetry: onRetry,
          builder: builder,
        );

      case UiStatus.retrying:
        if (data != null) {
          return Stack(
            children: [
              builder(context, data as T),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return loadingWidget ?? _defaultLoadingWidget();

      case UiStatus.success:
        if (data != null) {
          return builder(context, data as T);
        }
        return const SizedBox.shrink();
    }
  }

  Widget _defaultLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: AppTheme.primary,
              ),
            ),
            Gap(16),
            Text(
              'Loading...',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyStateView({
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppTheme.primary),
          ),
          const Gap(16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const Gap(6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const Gap(20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08);
  }
}

class _OfflineStateView<T> extends StatelessWidget {
  final T? cachedData;
  final VoidCallback? onRetry;
  final Widget Function(BuildContext context, T data) builder;

  const _OfflineStateView({
    required this.cachedData,
    required this.onRetry,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (cachedData != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, size: 16, color: Color(0xFF38BDF8)),
                const Gap(8),
                const Expanded(
                  child: Text(
                    'Offline Mode — showing cached data',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFF38BDF8),
                    ),
                    child: const Text('Retry Sync', style: TextStyle(fontSize: 11.5)),
                  ),
              ],
            ),
          ),
          builder(context, cachedData as T),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppErrorCard(
        error: const NetworkAppError.noInternet(),
        onAction: onRetry,
      ),
    );
  }
}
