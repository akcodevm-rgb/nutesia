import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bmi_utils.dart';
import '../../../core/services/analytics_service.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/onboarding_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/providers/nutrition_space_provider.dart';
import '../../../shared/widgets/error_views/error_views.dart';
import '../../legal/screens/disclaimer_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final initialName = context.read<OnboardingProvider>().name.isNotEmpty
        ? context.read<OnboardingProvider>().name
        : (context.read<UserProfileProvider>().user?.name ?? '');
    _nameController = TextEditingController(text: initialName);
    if (initialName.isNotEmpty && context.read<OnboardingProvider>().name.isEmpty) {
      context.read<OnboardingProvider>().setName(initialName);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage(
    OnboardingProvider onboarding,
    UserProfileProvider profileProvider,
    NutritionSpaceProvider spaceProvider,
  ) {
    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : onboarding.name.trim();

    debugPrint('[ProfileSetup] _nextPage invoked - currentStep: ${onboarding.currentStep}, resolvedName: "$name"');

    if (onboarding.currentStep == 0 && name.isEmpty) {
      debugPrint('[ProfileSetup] Validation error: Name is empty');
      _showError('Please enter your name');
      return;
    }
    if (name.isNotEmpty) {
      onboarding.setName(name);
    }

    if (onboarding.currentStep < 2) {
      final next = onboarding.currentStep + 1;
      onboarding.setStep(next);
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (!onboarding.disclaimerAccepted) {
        _showError('Please confirm the Health & Medical Disclaimer to complete profile setup.');
        return;
      }
      _save(onboarding, profileProvider, spaceProvider);
    }
  }

  void _prevPage(OnboardingProvider onboarding) {
    if (onboarding.currentStep > 0) {
      final prev = onboarding.currentStep - 1;
      onboarding.setStep(prev);
      _pageController.animateToPage(
        prev,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _save(
    OnboardingProvider onboarding,
    UserProfileProvider profileProvider,
    NutritionSpaceProvider spaceProvider,
  ) async {
    final success = await onboarding.saveProfile(profileProvider, spaceProvider);
    if (!success && mounted) {
      AppToast.showError(
        context,
        onboarding.appError ?? onboarding.errorMessage ?? 'Failed to save profile',
        onAction: () => _save(onboarding, profileProvider, spaceProvider),
      );
    } else if (success && mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showError(dynamic error) {
    AppToast.showError(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.read<UserProfileProvider>();
    final spaceProvider = context.read<NutritionSpaceProvider>();

    return Consumer<OnboardingProvider>(
      builder: (context, onboarding, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AnalyticsService.instance.logScreenView('profile_setup_step_${onboarding.currentStep}');
        });

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(onboarding.currentStep),
                _buildProgressBar(onboarding.currentStep),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StepBasicInfo(
                        nameController: _nameController,
                        age: onboarding.age,
                        gender: onboarding.gender,
                        onNameChanged: (v) => onboarding.setName(v),
                        onAgeChanged: (v) => onboarding.setAge(v),
                        onGenderChanged: (v) => onboarding.setGender(v),
                      ),
                      _StepBodyMetrics(
                        heightCm: onboarding.heightCm,
                        weightKg: onboarding.weightKg,
                        onHeightChanged: (v) => onboarding.setHeight(v),
                        onWeightChanged: (v) => onboarding.setWeight(v),
                        bmiResult: onboarding.bmi,
                      ),
                      _StepGoal(
                        age: onboarding.age,
                        goal: onboarding.goal,
                        disclaimerAccepted: onboarding.disclaimerAccepted,
                        onGoalChanged: (v) => onboarding.setGoal(v),
                        onDisclaimerAcceptedChanged: (v) => onboarding.setDisclaimerAccepted(v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildNavButtons(onboarding, profileProvider, spaceProvider),
        );
      },
    );
  }

  Widget _buildHeader(int currentStep) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
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
                'Step ${currentStep + 1} of 3',
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

  Widget _buildProgressBar(int currentStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= currentStep;
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

  Widget _buildNavButtons(
    OnboardingProvider onboarding,
    UserProfileProvider profileProvider,
    NutritionSpaceProvider spaceProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppTheme.background,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (onboarding.currentStep > 0) ...[
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      _prevPage(onboarding);
                    },
                    child: const Text('Back'),
                  ),
                ),
              ),
              const Gap(12),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    debugPrint(
                        '[ProfileSetup] Continue clicked! nameController: "${_nameController.text}", onboarding.name: "${onboarding.name}", currentStep: ${onboarding.currentStep}');
                    if (!onboarding.isSaving) {
                      _nextPage(onboarding, profileProvider, spaceProvider);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: onboarding.isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          onboarding.currentStep == 2 ? 'Get Started 🚀' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 1: Basic Info ────────────────────────────────────────────────────

class _StepBasicInfo extends StatelessWidget {
  final TextEditingController nameController;
  final int age;
  final String gender;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<String> onGenderChanged;

  const _StepBasicInfo({
    required this.nameController,
    required this.age,
    required this.gender,
    required this.onNameChanged,
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
            onChanged: onNameChanged,
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
                        if (age > 2) onAgeChanged(age - 1);
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
          if (age < 18) ...[
            const Gap(8),
            Text(
              'Pediatric mode active (Ages 2-17): Goals prioritize healthy developmental growth.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          const Gap(24),

          // Medical Disclaimer Notice
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DisclaimerScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: AppTheme.primary),
                  Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medical Notice: Nutesia provides educational estimates for wellness tracking only. Pregnancy and medical conditions are not supported.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        Gap(4),
                        Text(
                          'Read Health & Regulatory Disclaimer →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
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
                ? AppTheme.primary.withValues(alpha: 0.15)
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
              overlayColor: AppTheme.primary.withValues(alpha: 0.12),
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
                  style: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 11)),
              Text('${max.round()} $unit',
                  style: const TextStyle(
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
      borderColor: _bmiColor.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _bmiColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.monitor_heart_outlined, color: _bmiColor),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your BMI',
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
              color: _bmiColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _bmiColor.withValues(alpha: 0.3)),
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
  final int age;
  final String goal;
  final bool disclaimerAccepted;
  final ValueChanged<String> onGoalChanged;
  final ValueChanged<bool> onDisclaimerAcceptedChanged;

  const _StepGoal({
    required this.age,
    required this.goal,
    required this.disclaimerAccepted,
    required this.onGoalChanged,
    required this.onDisclaimerAcceptedChanged,
  });

  List<Map<String, dynamic>> get _availableGoals {
    if (age < 18) {
      return const [
        {
          'id': 'maintain',
          'label': 'Healthy Growth',
          'sub': 'Developmental nutrition · Balanced macros',
          'icon': Icons.spa_rounded,
          'color': AppTheme.primary,
        },
        {
          'id': 'gain',
          'label': 'Active / Growth Surplus',
          'sub': 'Extra energy for sports & growth spurts',
          'icon': Icons.bolt_rounded,
          'color': AppTheme.info,
        },
      ];
    }
    return const [
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
  }

  @override
  Widget build(BuildContext context) {
    final goals = _availableGoals;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(8),
          Text(age < 18 ? 'Choose growth\ngoal' : 'What\'s your\ngoal?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  )).animate().fadeIn(delay: 100.ms).slideX(begin: 0.3),
          const Gap(8),
          Text(
            age < 18
                ? 'Pediatric safety policy: Caloric deficit dieting is prohibited for children under 18.'
                : 'This determines your daily calorie and nutrient targets.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary),
          ).animate().fadeIn(delay: 200.ms),
          const Gap(28),
          ...List.generate(goals.length, (i) {
            final g = goals[i];
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
                        ? color.withValues(alpha: 0.1)
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
                                style: const TextStyle(
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
          const Gap(10),

          // Mandatory Health & Medical Disclaimer Acknowledgment Card
          GlassCard(
            borderColor: disclaimerAccepted ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.cardBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: disclaimerAccepted,
                      activeColor: AppTheme.primary,
                      checkColor: Colors.black,
                      onChanged: (val) => onDisclaimerAcceptedChanged(val ?? false),
                    ),
                    const Gap(6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onDisclaimerAcceptedChanged(!disclaimerAccepted),
                        child: const Text(
                          'I confirm that I am not pregnant, have no diagnosed medical conditions requiring clinical supervision, and agree to the Health & Medical Disclaimer.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Padding(
                  padding: const EdgeInsets.only(left: 46),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DisclaimerScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: const Text(
                      'Read Full Health & Regulatory Disclaimer →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
          const Gap(20),
        ],
      ),
    );
  }
}
