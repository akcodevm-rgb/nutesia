import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/water_provider.dart';

class WaterIntakeCard extends StatelessWidget {
  const WaterIntakeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WaterProvider>(
      builder: (context, water, _) {
        final intakeMl = water.intakeMl;
        final targetMl = water.targetMl;
        final percentage = (intakeMl / targetMl).clamp(0.0, 1.0);
        final pctDisplay = (percentage * 100).toInt();

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF48DBFB).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF48DBFB).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Color(0xFF48DBFB),
                          size: 20,
                        ),
                      ),
                      const Gap(12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Water Intake',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Goal: $targetMl ml ($pctDisplay%)',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '$intakeMl / $targetMl ml',
                    style: const TextStyle(
                      color: Color(0xFF48DBFB),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Gap(14),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 10,
                  backgroundColor: AppTheme.background,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF48DBFB),
                  ),
                ),
              ),
              const Gap(14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _WaterActionButton(
                      label: '-250 ml',
                      icon: Icons.remove,
                      color: AppTheme.textMuted,
                      bgColor: AppTheme.surface,
                      borderColor: AppTheme.cardBorder,
                      onTap: () => water.subtractWater(250),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _WaterActionButton(
                      label: '+250 ml',
                      icon: Icons.local_drink_outlined,
                      color: const Color(0xFF48DBFB),
                      bgColor: const Color(0xFF48DBFB).withValues(alpha: 0.12),
                      borderColor: const Color(0xFF48DBFB).withValues(alpha: 0.3),
                      onTap: () => water.addWater(250),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: _WaterActionButton(
                      label: '+500 ml',
                      icon: Icons.water_drop_outlined,
                      color: const Color(0xFF00E676),
                      bgColor: const Color(0xFF00E676).withValues(alpha: 0.12),
                      borderColor: const Color(0xFF00E676).withValues(alpha: 0.3),
                      onTap: () => water.addWater(500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaterActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _WaterActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
