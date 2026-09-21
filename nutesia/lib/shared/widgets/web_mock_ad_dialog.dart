import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class WebMockAdDialog extends StatefulWidget {
  const WebMockAdDialog({super.key});

  /// Shows the mock rewarded ad and returns true if the user completed the ad, or false if skipped.
  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // User must watch the ad or explicitly skip
          builder: (context) => const WebMockAdDialog(),
        ) ??
        false;
  }

  @override
  State<WebMockAdDialog> createState() => _WebMockAdDialogState();
}

class _WebMockAdDialogState extends State<WebMockAdDialog> {
  static const int adDurationSeconds = 10;
  int _secondsRemaining = adDurationSeconds;
  Timer? _timer;
  bool _rewardEarned = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          _rewardEarned = true;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleClose() async {
    if (_rewardEarned) {
      Navigator.of(context).pop(true);
      return;
    }

    // Warn the user before skipping the ad
    final skip = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Skip Ad?'),
            content: const Text(
                'If you skip this ad now, you will not receive your free credit.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep Watching'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Skip Ad'),
              ),
            ],
          ),
        ) ??
        false;

    if (skip && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (adDurationSeconds - _secondsRemaining) / adDurationSeconds;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 440,
        height: 520,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.cardBorder, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 5,
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative background glow
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [AppTheme.primary, Colors.transparent],
                      radius: 0.8,
                    ),
                  ),
                ),
              ),
            ),

            // Content Layout
            Column(
              children: [
                // Top header bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14, color: AppTheme.textSecondary),
                            const Gap(6),
                            Text(
                              'Sponsored',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_rewardEarned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Reward in ${_secondsRemaining}s',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 14, color: AppTheme.primary),
                              const Gap(4),
                              Text(
                                'Reward Earned',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Main Ad Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Glowing app/sponsor icon container
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  width: 3,
                                ),
                              ),
                              child: const Center(
                                child: Text('🥗', style: TextStyle(fontSize: 54)),
                              ),
                            ),
                            const Gap(24),
                            Text(
                              'Nutesia Premium',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Gap(10),
                            Text(
                              'Track macros effortlessly, get instant AI food insights, and unlock personalized nutritional feedback.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.normal,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const Gap(20),
                            // Feature badges
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildFeatureBadge('🤖 Unlimited AI'),
                                _buildFeatureBadge('📊 Advanced Analytics'),
                                _buildFeatureBadge('🎯 Custom Goals'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Progress Bar and action buttons
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppTheme.card,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary),
                        ),
                      ),
                    ),
                    const Gap(20),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 24, right: 24, bottom: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: _rewardEarned
                            ? ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                icon: const Icon(Icons.stars_rounded,
                                    color: Colors.black),
                                label: const Text('Collect +1 Credit'),
                              )
                            : OutlinedButton(
                                onPressed: _handleClose,
                                child: Text(
                                  'Skip Ad',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Top close "X" button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: _handleClose,
                icon: const Icon(Icons.close_rounded,
                    color: AppTheme.textSecondary),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.card,
                  hoverColor: AppTheme.cardHover,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
