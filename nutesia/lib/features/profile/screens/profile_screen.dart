import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/profile_provider.dart';
import '../../onboarding/screens/profile_setup_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/legal_constants.dart';
import '../../../core/services/account_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editProfile(context),
            tooltip: 'Edit profile',
          ),
        ],
      ),
      body: profileAsync.when(
        data: (user) {
          if (user == null) return const SizedBox.shrink();
          return _ProfileContent(user: user);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _editProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileSetupScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final bmiColor = _bmiColor(user.bmiCategory);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Avatar + Name ─────────────────────────────────
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      '${user.age} years · ${user.gender == 'male' ? 'Male' : 'Female'}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const Gap(4),
                    Text(
                      _goalLabel(user.goal),
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.2),
        const Gap(16),

        // ── Body Stats ────────────────────────────────────
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Body Stats',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const Gap(12),
              Row(
                children: [
                  _StatBox('Height', '${user.heightCm.round()} cm',
                      Icons.height_rounded, AppTheme.info),
                  const Gap(10),
                  _StatBox('Weight', '${user.weightKg.round()} kg',
                      Icons.monitor_weight_outlined, AppTheme.proteinColor),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
        const Gap(16),

        // ── BMI Card ──────────────────────────────────────
        GlassCard(
          borderColor: bmiColor.withValues(alpha: 0.3),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bmiColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.monitor_heart_outlined,
                        color: bmiColor, size: 22),
                  ),
                  const Gap(14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BMI',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                        Text(
                          '${user.bmi}',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: bmiColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: bmiColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(user.bmiCategory,
                        style: TextStyle(
                            color: bmiColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Gap(12),
              _BmiScale(value: user.bmi),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
        const Gap(16),

        // ── Daily Targets ─────────────────────────────────
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Targets',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const Gap(12),
              _TargetRow('Calories', '${user.dailyTargets.calories.round()} kcal',
                  AppTheme.calColor),
              _TargetRow('Protein', '${user.dailyTargets.protein.round()} g',
                  AppTheme.proteinColor),
              _TargetRow('Carbohydrates', '${user.dailyTargets.carbs.round()} g',
                  AppTheme.carbsColor),
              _TargetRow('Fat', '${user.dailyTargets.fat.round()} g',
                  AppTheme.fatColor, isLast: true),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const Gap(16),

        // ── Micronutrient Targets ─────────────────────────
        _MicroTargetsCard(targets: user.dailyTargets)
            .animate()
            .fadeIn(delay: 250.ms)
            .slideY(begin: 0.2),
        const Gap(16),

        // ── Settings & Legal ─────────────────────────────
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Settings & Legal',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const Gap(12),
              _MenuRow(
                'Privacy Policy',
                Icons.privacy_tip_outlined,
                onTap: () => _open(context, LegalConstants.privacyUrl),
              ),
              _MenuRow(
                'Terms of Service',
                Icons.description_outlined,
                onTap: () => _open(context, LegalConstants.termsUrl),
              ),
              if (LegalConstants.supportEmail.isNotEmpty)
                _MenuRow(
                  'Contact Support',
                  Icons.mail_outline_rounded,
                  onTap: () => _open(context, 'mailto:${LegalConstants.supportEmail}'),
                ),
              _MenuRow(
                'Delete account',
                Icons.delete_forever_outlined,
                color: AppTheme.error,
                onTap: () => _confirmDeleteAccount(context),
                isLast: true,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        const Gap(80),
      ],
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't open $url")),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (deleted == true && context.mounted) {
      // Signing out happened with the deletion; the auth listener in main.dart
      // shows the login screen. Close anything stacked above it.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Color _bmiColor(String cat) {
    switch (cat) {
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

  String _goalLabel(String goal) {
    switch (goal) {
      case 'lose':
        return 'Goal: Lose Weight';
      case 'gain':
        return 'Goal: Gain Muscle';
      default:
        return 'Goal: Maintain Weight';
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(8),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _TargetRow(this.label, this.value, this.color,
      {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const Gap(12),
              Text(label,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppTheme.divider),
      ],
    );
  }
}

class _BmiScale extends StatelessWidget {
  final double value;

  const _BmiScale({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(flex: 18, child: Container(color: AppTheme.info)),
                Expanded(flex: 7, child: Container(color: AppTheme.primary)),
                Expanded(flex: 5, child: Container(color: AppTheme.warning)),
                Expanded(flex: 10, child: Container(color: AppTheme.error)),
              ],
            ),
          ),
        ),
        const Gap(4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('10',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            Text('18.5',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            Text('25',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            Text('30',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            Text('40',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _MicroTargetsCard extends StatefulWidget {
  final NutritionData targets;

  const _MicroTargetsCard({required this.targets});

  @override
  State<_MicroTargetsCard> createState() => _MicroTargetsCardState();
}

class _MicroTargetsCardState extends State<_MicroTargetsCard> {
  bool _showMinerals = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.targets.vitamins;
    final m = widget.targets.minerals;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Nutrient Targets',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              _TabBtn('Vitamins', !_showMinerals,
                  () => setState(() => _showMinerals = false)),
              const Gap(8),
              _TabBtn('Minerals', _showMinerals,
                  () => setState(() => _showMinerals = true)),
            ],
          ),
          const Gap(12),
          AnimatedCrossFade(
            crossFadeState: _showMinerals
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            firstChild: Column(
              children: [
                _MicroTargetRow('Vitamin A', v.vitaminA, 'mcg'),
                _MicroTargetRow('Vitamin B12', v.vitaminB12, 'mcg'),
                _MicroTargetRow('Vitamin C', v.vitaminC, 'mg'),
                _MicroTargetRow('Vitamin D', v.vitaminD, 'mcg'),
                _MicroTargetRow('Vitamin E', v.vitaminE, 'mg'),
                _MicroTargetRow('Folate', v.folate, 'mcg', isLast: true),
              ],
            ),
            secondChild: Column(
              children: [
                _MicroTargetRow('Calcium', m.calcium, 'mg'),
                _MicroTargetRow('Iron', m.iron, 'mg'),
                _MicroTargetRow('Zinc', m.zinc, 'mg'),
                _MicroTargetRow('Magnesium', m.magnesium, 'mg'),
                _MicroTargetRow('Potassium', m.potassium, 'mg'),
                _MicroTargetRow('Sodium', m.sodium, 'mg', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppTheme.primary : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12)),
      ),
    );
  }
}

class _MicroTargetRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool isLast;

  const _MicroTargetRow(this.label, this.value, this.unit,
      {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final display =
        value < 1 ? value.toStringAsFixed(1) : value.round().toString();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
              const Spacer(),
              Text('$display $unit',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppTheme.divider),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLast;
  final Color? color; // for destructive actions

  const _MenuRow(this.label, this.icon,
      {required this.onTap, this.isLast = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Icon(icon, color: color ?? AppTheme.primary, size: 20),
                const Gap(12),
                Text(label, style: TextStyle(color: color ?? AppTheme.textPrimary, fontSize: 14)),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppTheme.divider),
      ],
    );
  }
}

/// Confirms account deletion. Email accounts re-enter their password (Firebase
/// requires a recent sign-in to delete an account); guest accounts just confirm.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _service = AccountService();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.deleteAccount(password: _password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on AccountDeletionException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Delete account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes your account, profile, food logs and '
            'credits. It cannot be undone.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          if (_service.needsPassword) ...[
            const Gap(16),
            Text('Enter the password for ${_service.email}',
                style: const TextStyle(fontSize: 13)),
            const Gap(8),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_busy,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _busy ? null : _delete(),
            ),
          ],
          if (_error != null) ...[
            const Gap(12),
            Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy ? null : _delete,
          child: _busy
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Delete permanently',
                  style: TextStyle(color: AppTheme.error)),
        ),
      ],
    );
  }
}
