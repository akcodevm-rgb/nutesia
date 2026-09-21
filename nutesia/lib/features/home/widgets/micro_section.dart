import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../../shared/widgets/glass_card.dart';

class MicroSection extends StatefulWidget {
  final NutritionData consumed;
  final NutritionData targets;

  const MicroSection({
    super.key,
    required this.consumed,
    required this.targets,
  });

  @override
  State<MicroSection> createState() => _MicroSectionState();
}

class _MicroSectionState extends State<MicroSection> {
  bool _vitaminsExpanded = false;
  bool _mineralsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ExpandableGroup(
          title: 'Vitamins',
          icon: Icons.sunny,
          iconColor: const Color(0xFFFFD93D),
          expanded: _vitaminsExpanded,
          onToggle: () => setState(() => _vitaminsExpanded = !_vitaminsExpanded),
          children: [
            _MicroRow('Vitamin A', widget.consumed.vitamins.vitaminA,
                widget.targets.vitamins.vitaminA, 'mcg'),
            _MicroRow('Vitamin B1', widget.consumed.vitamins.vitaminB1,
                widget.targets.vitamins.vitaminB1, 'mg'),
            _MicroRow('Vitamin B6', widget.consumed.vitamins.vitaminB6,
                widget.targets.vitamins.vitaminB6, 'mg'),
            _MicroRow('Vitamin B12', widget.consumed.vitamins.vitaminB12,
                widget.targets.vitamins.vitaminB12, 'mcg'),
            _MicroRow('Vitamin C', widget.consumed.vitamins.vitaminC,
                widget.targets.vitamins.vitaminC, 'mg'),
            _MicroRow('Vitamin D', widget.consumed.vitamins.vitaminD,
                widget.targets.vitamins.vitaminD, 'mcg'),
            _MicroRow('Vitamin E', widget.consumed.vitamins.vitaminE,
                widget.targets.vitamins.vitaminE, 'mg'),
            _MicroRow('Vitamin K', widget.consumed.vitamins.vitaminK,
                widget.targets.vitamins.vitaminK, 'mcg'),
            _MicroRow('Folate', widget.consumed.vitamins.folate,
                widget.targets.vitamins.folate, 'mcg'),
          ],
        ),
        const Gap(12),
        _ExpandableGroup(
          title: 'Minerals',
          icon: Icons.diamond_outlined,
          iconColor: AppTheme.info,
          expanded: _mineralsExpanded,
          onToggle: () =>
              setState(() => _mineralsExpanded = !_mineralsExpanded),
          children: [
            _MicroRow('Calcium', widget.consumed.minerals.calcium,
                widget.targets.minerals.calcium, 'mg'),
            _MicroRow('Iron', widget.consumed.minerals.iron,
                widget.targets.minerals.iron, 'mg'),
            _MicroRow('Zinc', widget.consumed.minerals.zinc,
                widget.targets.minerals.zinc, 'mg'),
            _MicroRow('Magnesium', widget.consumed.minerals.magnesium,
                widget.targets.minerals.magnesium, 'mg'),
            _MicroRow('Potassium', widget.consumed.minerals.potassium,
                widget.targets.minerals.potassium, 'mg'),
            _MicroRow('Sodium', widget.consumed.minerals.sodium,
                widget.targets.minerals.sodium, 'mg'),
            _MicroRow('Phosphorus', widget.consumed.minerals.phosphorus,
                widget.targets.minerals.phosphorus, 'mg'),
          ],
        ),
      ],
    );
  }
}

class _ExpandableGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  const _ExpandableGroup({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const Gap(12),
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const Spacer(),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: children),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _MicroRow extends StatelessWidget {
  final String name;
  final double consumed;
  final double target;
  final String unit;

  const _MicroRow(this.name, this.consumed, this.target, this.unit);

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;
    final isMet = pct >= 1.0;
    final valueStr =
        consumed < 1 ? consumed.toStringAsFixed(2) : consumed.round().toString();
    final targetStr =
        target < 1 ? target.toStringAsFixed(1) : target.round().toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(name,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: AppTheme.cardBorder,
                valueColor: AlwaysStoppedAnimation(
                    isMet ? AppTheme.primary : AppTheme.info),
              ),
            ),
          ),
          const Gap(10),
          SizedBox(
            width: 80,
            child: Text(
              '$valueStr / $targetStr $unit',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isMet ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
