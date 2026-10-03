import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// A premium, tactile skeuomorphic container.
/// It features realistic beveled edges, outer depth shadows, and an inner glossy gradient.
class SkeuoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? baseColor;
  final bool depressed;
  final double elevation;
  final VoidCallback? onTap;

  const SkeuoCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.baseColor,
    this.depressed = false,
    this.elevation = 4,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = baseColor ?? AppTheme.surface;

    // Highlights and shadows for the skeuomorphic 3D depth
    final Color shadowColor = Colors.black.withValues(alpha: 0.6);
    final Color highlightColor = const Color(0xFF1E2D4A).withValues(alpha: 0.4);

    final Widget cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: depressed
            ? LinearGradient(
                colors: [
                  themeColor.withValues(alpha: 0.8),
                  themeColor.withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  themeColor.withValues(alpha: 1.0),
                  themeColor.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: depressed
            ? [
                // Inset-like effect
                BoxShadow(
                  color: shadowColor,
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
                BoxShadow(
                  color: highlightColor,
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
              ]
            : [
                // Pop-out 3D effect
                BoxShadow(
                  color: shadowColor,
                  offset: Offset(elevation, elevation),
                  blurRadius: elevation * 2,
                ),
                BoxShadow(
                  color: highlightColor,
                  offset: Offset(-elevation, -elevation),
                  blurRadius: elevation * 2,
                ),
              ],
        border: Border.all(
          color: depressed
              ? Colors.black.withValues(alpha: 0.5)
              : const Color(0xFF2E3E5C).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardContent,
      );
    }
    return cardContent;
  }
}

/// A tactile toggle switch styled like a physical debossed slider track.
class SkeuoToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SkeuoToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF070B14),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF1B2436),
          width: 2,
        ),
        boxShadow: [
          // Inner shadow effect
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            offset: const Offset(1, 1),
            blurRadius: 3,
          )
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF223652),
                            Color(0xFF131F32),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            offset: const Offset(0, 3),
                            blurRadius: 4,
                          ),
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                  border: isSelected
                      ? Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.5),
                          width: 1,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected) ...[
                      // Glowing LED dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary,
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      options[index],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// An analogue circular gauge featuring dial markings and a realistic pointer needle.
class SkeuoDial extends StatelessWidget {
  final double percent;
  final String title;
  final String valueText;
  final Color activeColor;

  const SkeuoDial({
    super.key,
    required this.percent,
    required this.title,
    required this.valueText,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: CustomPaint(
            painter: _SkeuoDialPainter(
              percent: percent,
              activeColor: activeColor,
            ),
            child: Center(
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E283C), Color(0xFF0C1019)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border:
                      Border.all(color: const Color(0xFF2E3E5C), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: activeColor,
                    shadows: [
                      Shadow(
                          color: activeColor.withValues(alpha: 0.6), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SkeuoDialPainter extends CustomPainter {
  final double percent;
  final Color activeColor;

  _SkeuoDialPainter({required this.percent, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer metal rim
    final rimPaint = Paint()
      ..color = const Color(0xFF151C2C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 1.5, rimPaint);

    // Draw dial markings/ticks
    final tickPaint = Paint()
      ..color = const Color(0xFF2A364F)
      ..strokeWidth = 1.5;

    const tickCount = 24;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i * (2 * math.pi / tickCount)) - math.pi / 2;
      final isAccent = i % 4 == 0;
      final double innerR = radius - (isAccent ? 8 : 5);
      final double outerR = radius - 3;

      final start = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final end = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );

      tickPaint.color =
          isAccent ? const Color(0xFF4A5C7F) : const Color(0xFF1E283C);
      canvas.drawLine(start, end, tickPaint);
    }

    // Active arc track (starts from bottom-left -135deg to bottom-right 135deg)
    const double startAngle = 135 * math.pi / 180;
    const double sweepAngle = 270 * math.pi / 180;

    final trackPaint = Paint()
      ..color = const Color(0xFF0F1622)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active glow track
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      startAngle,
      sweepAngle * percent.clamp(0.0, 1.0),
      false,
      activePaint,
    );

    // Needle indicator
    final needlePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final needleAngle = startAngle + (sweepAngle * percent.clamp(0.0, 1.0));
    final needleTip = Offset(
      center.dx + (radius - 12) * math.cos(needleAngle),
      center.dy + (radius - 12) * math.sin(needleAngle),
    );

    canvas.drawLine(center, needleTip, needlePaint);
  }

  @override
  bool shouldRepaint(covariant _SkeuoDialPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.activeColor != activeColor;
  }
}

/// A progress bar styled like a glass tube filled with glowing fluorescent liquid.
class SkeuoProgress extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const SkeuoProgress({
    super.key,
    required this.value,
    required this.color,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF060B12),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(
          color: const Color(0xFF1E283B),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Filled Portion
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height / 2),
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.8),
                    color,
                    color.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
          ),
          // Gloss Highlight Layer (The reflection on the glass tube)
          Positioned(
            top: 1.5,
            left: 5,
            right: 5,
            child: Container(
              height: height * 0.25,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(height * 0.125),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A futuristic radar oscilloscope panel for visual scans and diagnostics.
class SkeuoRadar extends StatefulWidget {
  const SkeuoRadar({super.key});

  @override
  State<SkeuoRadar> createState() => _SkeuoRadarState();
}

class _SkeuoRadarState extends State<SkeuoRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SkeuoRadarPainter(angle: _controller.value * 2 * math.pi),
          child: const SizedBox(
            height: 120,
            width: double.infinity,
          ),
        );
      },
    );
  }
}

class _SkeuoRadarPainter extends CustomPainter {
  final double angle;

  _SkeuoRadarPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 10;

    final gridPaint = Paint()
      ..color = const Color(0xFF0F321C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw grid rings
    canvas.drawCircle(center, maxRadius * 0.33, gridPaint);
    canvas.drawCircle(center, maxRadius * 0.66, gridPaint);
    canvas.drawCircle(center, maxRadius, gridPaint);

    // Draw grid crosshairs
    canvas.drawLine(Offset(center.dx - maxRadius, center.dy),
        Offset(center.dx + maxRadius, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxRadius),
        Offset(center.dx, center.dy + maxRadius), gridPaint);

    // Draw scanning sweep
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00FF66).withValues(alpha: 0.15),
          const Color(0xFF00FF66).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        angle - 0.5,
        0.5,
        false,
      )
      ..close();

    canvas.drawPath(sweepPath, sweepPaint);

    // Blinking dots / targets
    final targetPaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..style = PaintingStyle.fill;

    // Fixed dummy targets
    final targetPositions = [
      Offset(center.dx - maxRadius * 0.4, center.dy - maxRadius * 0.3),
      Offset(center.dx + maxRadius * 0.6, center.dy + maxRadius * 0.2),
    ];

    for (final pos in targetPositions) {
      // Calculate angle from center to pos
      final diff = pos - center;
      final posAngle = math.atan2(diff.dy, diff.dx);
      // Normalized to [0, 2PI]
      final normPosAngle = posAngle < 0 ? posAngle + 2 * math.pi : posAngle;
      final diffAngle = (angle - normPosAngle).abs();

      if (diffAngle < 0.8 || (2 * math.pi - diffAngle) < 0.8) {
        final opacity = (1.0 - (diffAngle / 0.8)).clamp(0.0, 1.0);
        targetPaint.color = const Color(0xFF00FF66).withValues(alpha: opacity);
        canvas.drawCircle(pos, 4, targetPaint);
        // Outer rings of targets
        final pulsePaint = Paint()
          ..color = const Color(0xFF00FF66).withValues(alpha: opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(pos, 8 * (1.0 - opacity + 0.3), pulsePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkeuoRadarPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}

/// A smooth, glowing Neumorphic line chart for displaying trends.
class SkeuoLineChart extends StatefulWidget {
  final List<double> values1;
  final List<double> values2;
  final double targetValue;
  final List<String> labels;
  final String tooltipLabel;

  const SkeuoLineChart({
    super.key,
    required this.values1,
    required this.values2,
    required this.targetValue,
    required this.labels,
    this.tooltipLabel = 'kcal',
  });

  @override
  State<SkeuoLineChart> createState() => _SkeuoLineChartState();
}

class _SkeuoLineChartState extends State<SkeuoLineChart> {
  final ValueNotifier<int?> _hoveredIndexNotifier = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _hoveredIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate simplified/spaced labels to prevent overlapping
    final displayLabels = <String>[];
    final step = widget.values1.length > 7 ? (widget.values1.length / 5).round() : 1;
    for (int i = 0; i < widget.values1.length; i++) {
      if (i % step == 0 || i == widget.values1.length - 1) {
        displayLabels.add(widget.labels[i]);
      } else {
        displayLabels.add('');
      }
    }

    return ValueListenableBuilder<int?>(
      valueListenable: _hoveredIndexNotifier,
      builder: (context, hoveredIndex, _) {
        // Default legend values (either current hovered values or targets/averages)
        final val1 = hoveredIndex != null && hoveredIndex < widget.values1.length
            ? widget.values1[hoveredIndex].round()
            : (widget.values1.isNotEmpty ? (widget.values1.reduce((a, b) => a + b) / widget.values1.length).round() : 0);
        final val2 = hoveredIndex != null && hoveredIndex < widget.values2.length
            ? widget.values2[hoveredIndex].round()
            : widget.targetValue.round();

        return Column(
          children: [
            // Legend exactly matching the HTML Waves graph
            Column(
              children: [
                const Text(
                  'Variable Difference',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF33D0F7),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$val1',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6A67F1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$val2',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanUpdate: (details) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final localPos = box.globalToLocal(details.globalPosition);
                      final double sectionWidth = constraints.maxWidth / (widget.values1.length - 1);
                      final int index = (localPos.dx / sectionWidth).round().clamp(0, widget.values1.length - 1);
                      if (_hoveredIndexNotifier.value != index) {
                        _hoveredIndexNotifier.value = index;
                      }
                    },
                    onTapDown: (details) {
                      final RenderBox box = context.findRenderObject() as RenderBox;
                      final localPos = box.globalToLocal(details.globalPosition);
                      final double sectionWidth = constraints.maxWidth / (widget.values1.length - 1);
                      final int index = (localPos.dx / sectionWidth).round().clamp(0, widget.values1.length - 1);
                      _hoveredIndexNotifier.value = index;
                    },
                    onPanEnd: (_) => _hoveredIndexNotifier.value = null,
                    onTapCancel: () => _hoveredIndexNotifier.value = null,
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        values1: widget.values1,
                        values2: widget.values2,
                        targetValue: widget.targetValue,
                        hoveredIndex: hoveredIndex,
                        tooltipLabel: widget.tooltipLabel,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Draw labels below chart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.values1.length, (index) {
                final isHovered = index == hoveredIndex;
                final label = displayLabels[index];
                if (label.isEmpty) return const SizedBox(width: 4);
                return Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isHovered ? AppTheme.primary : AppTheme.textSecondary,
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values1;
  final List<double> values2;
  final double targetValue;
  final int? hoveredIndex;
  final String tooltipLabel;

  _LineChartPainter({
    required this.values1,
    required this.values2,
    required this.targetValue,
    required this.tooltipLabel,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values1.isEmpty) return;

    final double maxVal = math.max(
      targetValue * 1.3,
      math.max(
        values1.reduce(math.max),
        values2.isNotEmpty ? values2.reduce(math.max) : 0.0,
      ) * 1.15,
    );

    final double widthStep = size.width / (values1.length - 1);
    final List<Offset> points1 = [];
    final List<Offset> points2 = [];

    for (int i = 0; i < values1.length; i++) {
      final double x = i * widthStep;
      final double y1 = size.height - (values1[i] / maxVal) * (size.height - 20) - 10;
      points1.add(Offset(x, y1));

      if (i < values2.length) {
        final double y2 = size.height - (values2[i] / maxVal) * (size.height - 20) - 10;
        points2.add(Offset(x, y2));
      }
    }

    // 1. Draw horizontal background grid lines (dotted)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E2D4A).withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double levels = 3;
    for (int i = 1; i <= levels; i++) {
      final y = size.height * (i / (levels + 1));
      double curX = 0;
      while (curX < size.width) {
        canvas.drawLine(Offset(curX, y), Offset(curX + 4, y), gridPaint);
        curX += 8;
      }
    }

    // Helper to build smooth wave spline path
    Path buildSmoothPath(List<Offset> points) {
      final path = Path();
      if (points.isEmpty) return path;
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final cp1 = Offset(p0.dx + widthStep * 0.35, p0.dy);
        final cp2 = Offset(p1.dx - widthStep * 0.35, p1.dy);
        path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      }
      return path;
    }

    // Helper to draw gradient area under path
    void drawGradientFill(Path path, Color startColor) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0.0, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            startColor.withValues(alpha: 0.22),
            startColor.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // 2. Draw Layer 2 (Purple - values2) first so it sits behind
    if (points2.isNotEmpty) {
      final path2 = buildSmoothPath(points2);
      drawGradientFill(path2, const Color(0xFF6A67F1));

      final linePaint2 = Paint()
        ..color = const Color(0xFF6A67F1)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path2, linePaint2);
    }

    // 3. Draw Layer 1 (Cyan - values1) on top
    final path1 = buildSmoothPath(points1);
    drawGradientFill(path1, const Color(0xFF33D0F7));

    final linePaint1 = Paint()
      ..color = const Color(0xFF33D0F7)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path1, linePaint1);

    // 4. Draw interactive selected indicators (exactly matching the user image)
    if (hoveredIndex != null && hoveredIndex! < points1.length) {
      final point = points1[hoveredIndex!];

      // Vertical helper line
      final vLinePaint = Paint()
        ..color = const Color(0xFF3864F2).withValues(alpha: 0.6)
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(point.dx, 0), Offset(point.dx, size.height), vLinePaint);

      // Bottom handle dot
      final handlePaint = Paint()
        ..color = const Color(0xFF3864F2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(point.dx, size.height), 4, handlePaint);

      // Glow circle at intersection point of values1
      final pointGlowPaint = Paint()
        ..color = const Color(0xFF33D0F7).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 12, pointGlowPaint);

      // White outline circle on intersection point
      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(point, 6, outlinePaint);

      final innerPointPaint = Paint()
        ..color = const Color(0xFF33D0F7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4, innerPointPaint);

      // Floating Tooltip Pill (e.g. "1850 kcal")
      final String text = '${values1[hoveredIndex!].round()} $tooltipLabel';
      final textSpan = TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        text: text,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final double pillWidth = textPainter.width + 16;
      final double pillHeight = textPainter.height + 8;
      final double pillX = (point.dx - pillWidth / 2).clamp(0.0, size.width - pillWidth);
      final double pillY = (point.dy - pillHeight - 12).clamp(0.0, size.height);

      final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(pillX, pillY, pillWidth, pillHeight),
        const Radius.circular(8),
      );

      final pillPaint = Paint()
        ..color = const Color(0xFF3864F2)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(pillRect, pillPaint);

      textPainter.paint(
        canvas,
        Offset(pillX + 8, pillY + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values1 != values1 ||
        oldDelegate.values2 != values2 ||
        oldDelegate.targetValue != targetValue ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

