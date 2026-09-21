import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bmi_utils.dart';
import '../../../core/services/device_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/services/analytics_service.dart';


class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Form values
  final _nameController = TextEditingController();
  int _age = 25;
  String _gender = 'male';
  double _heightCm = 170;
  double _weightKg = 70;
  String _goal = 'maintain';

  // Derived
  BMIResult? _bmiResult;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _recomputeBmi() {
    if (_weightKg > 0 && _heightCm > 0) {
      setState(() {
        _bmiResult = BMIUtils.calculate(
          weightKg: _weightKg,
          heightCm: _heightCm,
        );
      });
    }
  }

  Future<void> _nextPage() async {
    // Step-level validation
    if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _save();
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final deviceId = await DeviceService.getDeviceId();
      final bmi = BMIUtils.calculate(weightKg: _weightKg, heightCm: _heightCm);
      final targets = BMIUtils.generateTargets(
        weightKg: _weightKg,
        heightCm: _heightCm,
        age: _age,
        gender: _gender,
        goal: _goal,
      );

      final user = UserModel(
        deviceId: deviceId,
        name: _nameController.text.trim(),
        age: _age,
        gender: _gender,
        heightCm: _heightCm,
        weightKg: _weightKg,
        goal: _goal,
        bmi: bmi.bmi,
        bmiCategory: bmi.category,
        dailyTargets: targets,
        createdAt: DateTime.now(),
      );

      await ref.read(userProfileProvider.notifier).saveProfile(user);

      // Log onboarding completion
      await AnalyticsService.instance.logOnboardingComplete(goal: _goal);
      await AnalyticsService.instance.setUserProperties(goal: _goal);

    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Log screen view for each step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView('profile_setup_step_$_currentStep');
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _StepBasicInfo(
                    nameController: _nameController,
                    age: _age,
                    gender: _gender,
                    onAgeChanged: (v) => setState(() => _age = v),
                    onGenderChanged: (v) => setState(() => _gender = v),
                  ),
                  _StepBodyMetrics(
                    heightCm: _heightCm,
                    weightKg: _weightKg,
                    onHeightChanged: (v) {
                      setState(() => _heightCm = v);
                      _recomputeBmi();
                    },
                    onWeightChanged: (v) {
                      setState(() => _weightKg = v);
                      _recomputeBmi();
                    },
                    bmiResult: _bmiResult,
                  ),
                  _StepGoal(
                    goal: _goal,
                    onGoalChanged: (v) => setState(() => _goal = v),
                  ),
                ],
              ),
            ),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.restaurant_menu_rounded,
                color: AppTheme.primary, size: 24),
          ),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nutesia',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary)),
              Text(
                'Step ${_currentStep + 1} of 3',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3);
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevPage,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const Gap(12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _nextPage,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text(_currentStep == 2 ? 'Get Started 🚀' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Basic Info ────────────────────────────────────────────────────

class _StepBasicInfo extends StatelessWidget {
  final TextEditingController nameController;
  final int age;
  final String gender;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<String> onGenderChanged;

  const _StepBasicInfo({
    required this.nameController,
    required this.age,
    required this.gender,
    required this.onAgeChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(8),
          Text('Tell us about\nyourself',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  )).animate().fadeIn(delay: 100.ms).slideX(begin: 0.3),
          const Gap(8),
          Text('This helps us personalize your nutrition targets.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary))
              .animate()
              .fadeIn(delay: 200.ms),
          const Gap(28),

          // Name field
          TextField(
            controller: nameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Your Name',
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.3),
          const Gap(20),

          // Age selector
          Text('Age',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.textSecondary))
              .animate()
              .fadeIn(delay: 300.ms),
          const Gap(10),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined,
                    color: AppTheme.textSecondary, size: 20),
                const Gap(12),
                Text('$age years',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (age > 10) onAgeChanged(age - 1);
                      },
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppTheme.textSecondary),
                    ),
                    IconButton(
                      onPressed: () {
                        if (age < 100) onAgeChanged(age + 1);
                      },
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 320.ms),
          const Gap(20),

          // Gender selector
          Text('Gender',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppTheme.textSecondary))
              .animate()
              .fadeIn(delay: 350.ms),
          const Gap(10),
          Row(
            children: [
              _GenderChip(
                label: 'Male',
                icon: Icons.male_rounded,
                selected: gender == 'male',
                onTap: () => onGenderChanged('male'),
              ),
              const Gap(12),
              _GenderChip(
                label: 'Female',
                icon: Icons.female_rounded,
                selected: gender == 'female',
                onTap: () => onGenderChanged('female'),
              ),
            ],
          ).animate().fadeIn(delay: 380.ms),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                  size: 32),
              const Gap(6),
              Text(label,
                  style: TextStyle(
                    color: selected ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 2: Body Metrics ──────────────────────────────────────────────────

class _StepBodyMetrics extends StatelessWidget {
  final double heightCm;
  final double weightKg;
  final ValueChanged<double> onHeightChanged;
  final ValueChanged<double> onWeightChanged;
  final BMIResult? bmiResult;

  const _StepBodyMetrics({
    required this.heightCm,
    required this.weightKg,
    required this.onHeightChanged,
    required this.onWeightChanged,
    this.bmiResult,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(8),
          Text('Your body\nmetrics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  )).animate().fadeIn(delay: 100.ms).slideX(begin: 0.3),
          const Gap(8),
          Text('We use these to calculate your BMI and daily targets.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary))
              .animate()
              .fadeIn(delay: 200.ms),
          const Gap(28),

          // Height
          _MetricSlider(
            label: 'Height',
            value: heightCm,
            unit: 'cm',
            min: 100,
            max: 220,
            divisions: 120,
            onChanged: onHeightChanged,
            icon: Icons.height_rounded,
          ).animate().fadeIn(delay: 250.ms),
          const Gap(20),

          // Weight
          _MetricSlider(
            label: 'Weight',
            value: weightKg,
            unit: 'kg',
            min: 30,
            max: 200,
            divisions: 170,
            onChanged: onWeightChanged,
            icon: Icons.monitor_weight_outlined,
          ).animate().fadeIn(delay: 300.ms),
          const Gap(24),

          // BMI Preview
          if (bmiResult != null)
            _BmiPreviewCard(bmi: bmiResult!)
                .animate(key: ValueKey(bmiResult!.bmi))
                .fadeIn()
                .scale(begin: const Offset(0.95, 0.95)),
        ],
      ),
    );
  }
}

class _MetricSlider extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final IconData icon;

  const _MetricSlider({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.textSecondary, size: 20),
              const Gap(8),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: AppTheme.textSecondary)),
              const Spacer(),
              Text(
                '${value.round()} $unit',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.cardBorder,
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.round()} $unit',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 11)),
              Text('${max.round()} $unit',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BmiPreviewCard extends StatelessWidget {
  final BMIResult bmi;

  const _BmiPreviewCard({required this.bmi});

  Color get _bmiColor {
    switch (bmi.category) {
      case 'Underweight':
        return AppTheme.info;
      case 'Normal':
        return AppTheme.primary;
      case 'Overweight':
        return AppTheme.warning;
      default:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: _bmiColor.withOpacity(0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bmiColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.monitor_heart_outlined, color: _bmiColor),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your BMI',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              Text(
                '${bmi.bmi}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _bmiColor,
                    ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _bmiColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _bmiColor.withOpacity(0.3)),
            ),
            child: Text(
              bmi.category,
              style: TextStyle(
                  color: _bmiColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Goal ──────────────────────────────────────────────────────────

class _StepGoal extends StatelessWidget {
  final String goal;
  final ValueChanged<String> onGoalChanged;

  const _StepGoal({required this.goal, required this.onGoalChanged});

  static const _goals = [
    {
      'id': 'lose',
      'label': 'Lose Weight',
      'sub': 'Caloric deficit · Fat loss focus',
      'icon': Icons.local_fire_department_rounded,
      'color': AppTheme.warning,
    },
    {
      'id': 'maintain',
      'label': 'Stay Healthy',
      'sub': 'Balanced nutrition · Maintenance',
      'icon': Icons.balance_rounded,
      'color': AppTheme.primary,
    },
    {
      'id': 'gain',
      'label': 'Gain Muscle',
      'sub': 'Caloric surplus · High protein',
      'icon': Icons.fitness_center_rounded,
      'color': AppTheme.info,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(8),
          Text('What\'s your\ngoal?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  )).animate().fadeIn(delay: 100.ms).slideX(begin: 0.3),
          const Gap(8),
          Text('This determines your daily calorie and nutrient targets.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary))
              .animate()
              .fadeIn(delay: 200.ms),
          const Gap(28),
          ...List.generate(_goals.length, (i) {
            final g = _goals[i];
            final selected = goal == g['id'];
            final color = g['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => onGoalChanged(g['id'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.1)
                        : AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? color : AppTheme.cardBorder,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(g['icon'] as IconData, size: 32, color: color),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: selected ? color : AppTheme.textPrimary,
                                )),
                            const Gap(2),
                            Text(g['sub'] as String,
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? color : AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ).animate(delay: (200 + i * 80).ms).fadeIn().slideX(begin: 0.2),
            );
          }),
        ],
      ),
    );
  }
}
