import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/member_model.dart';
import '../../../shared/models/nutrition_model.dart';
import '../../../shared/models/nutrition_space_model.dart';
import '../../../shared/providers/tab_toggle_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/providers/rewarded_ad_provider.dart';
import '../../../shared/widgets/credit_chip.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/manage_members_sheet.dart';
import '../providers/nutrition_space_provider.dart';
import '../providers/profile_provider.dart';
import '../../onboarding/screens/profile_setup_screen.dart';
import '../../../shared/utils/url_helper.dart';
import '../../../shared/widgets/error_views/error_views.dart';
import '../../legal/screens/disclaimer_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionSpaceProvider>(
      builder: (context, spaceProvider, _) {
        final space = spaceProvider.space;
        final activeMember = spaceProvider.activeMember;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Nutrition Profile & Space'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editProfile(context, activeMember),
                tooltip: 'Edit active profile',
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              if (spaceProvider.isLoading && space == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                );
              }

              if (spaceProvider.error != null && space == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: AppErrorCard(
                      error: ErrorParser.parse(spaceProvider.error),
                      onAction: () => spaceProvider.refresh(),
                    ),
                  ),
                );
              }

              if (space == null) return const SizedBox.shrink();

              return _ProfileContent(
                space: space,
                activeMember: activeMember ?? (space.profiles.isNotEmpty ? space.profiles.first : null),
                spaceProvider: spaceProvider,
              );
            },
          ),
        );
      },
    );
  }

  void _editProfile(BuildContext context, MemberModel? activeMember) {
    if (activeMember != null &&
        (activeMember.isChild ||
            activeMember.relationship == 'child' ||
            (activeMember.relationship != 'owner' && activeMember.relationship != 'self'))) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => ManageMembersSheet(memberToEdit: activeMember),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(),
          fullscreenDialog: true,
        ),
      );
    }
  }
}

class _ProfileContent extends StatelessWidget {
  final NutritionSpaceModel space;
  final MemberModel? activeMember;
  final NutritionSpaceProvider spaceProvider;

  const _ProfileContent({
    required this.space,
    required this.activeMember,
    required this.spaceProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isFamily = space.isFamilyMode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Shared Credit Wallet Card ─────────────────────────
        _CreditWalletCard(spaceProvider: spaceProvider)
            .animate()
            .fadeIn()
            .slideY(begin: 0.15),
        const Gap(16),

        // ── Space Mode & Member Switcher ───────────────────────
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isFamily ? AppTheme.proteinColor.withValues(alpha: 0.15) : AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isFamily ? 'FAMILY SPACE (${space.profiles.length}/3)' : 'PERSONAL SPACE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isFamily ? AppTheme.proteinColor : AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isFamily)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        _showAddMemberModal(context);
                      },
                      icon: const Icon(Icons.group_add_outlined, size: 16),
                      label: const Text('Add Member', style: TextStyle(fontSize: 12)),
                    )
                  else if (space.canAddMember)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _showAddMemberModal(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text('+ Add (${space.profiles.length}/3)', style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const Gap(12),

              // Profiles Carousel / Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...space.profiles.map((p) {
                      final isSelected = activeMember?.id == p.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: isSelected ? Colors.black : AppTheme.primary.withValues(alpha: 0.2),
                                child: Text(
                                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppTheme.primary,
                                  ),
                                ),
                              ),
                              const Gap(6),
                              Text(p.name),
                              if (p.isChild) ...[
                                const Gap(4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.black.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${p.age}y',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.black : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.primary,
                          onSelected: (_) {
                            spaceProvider.switchActiveMember(p.id);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.15),
        const Gap(16),

        if (activeMember != null) ...[
          // ── Active Member Details & Avatar ──────────────────
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
                      activeMember!.name.isNotEmpty
                          ? activeMember!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              activeMember!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Gap(8),
                          if (activeMember!.relationship == 'owner')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Gap(2),
                      Text(
                        '${activeMember!.age} yrs old · ${activeMember!.gender == 'male' ? 'Male' : 'Female'}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        _goalLabel(activeMember!.goal),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                  tooltip: 'Edit Profile Details',
                  onPressed: () {
                    if (activeMember!.isChild ||
                        activeMember!.relationship == 'child' ||
                        (activeMember!.relationship != 'owner' && activeMember!.relationship != 'self')) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (ctx) => ManageMembersSheet(memberToEdit: activeMember),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProfileSetupScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
          const Gap(16),

          // ── Body Stats ────────────────────────────────────
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Body Stats',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const Gap(12),
                Row(
                  children: [
                    _StatBox(
                      'Height',
                      '${activeMember!.heightCm.round()} cm',
                      Icons.height_rounded,
                      AppTheme.info,
                    ),
                    const Gap(10),
                    _StatBox(
                      'Weight',
                      '${activeMember!.weightKg.round()} kg',
                      Icons.monitor_weight_outlined,
                      AppTheme.proteinColor,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
          const Gap(16),

          // ── Clinical Assessment (Pediatric Percentile vs Adult) ──
          _AssessmentCard(member: activeMember!)
              .animate()
              .fadeIn(delay: 200.ms)
              .slideY(begin: 0.2),
          const Gap(16),

          // ── Daily Targets ─────────────────────────────────
          if (activeMember!.dailyTargets.calories > 0) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Calculated Daily Targets',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          activeMember!.isChild ? 'Schofield (1985)' : 'Mifflin-St Jeor (1990)',
                          style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  _TargetRow(
                    'Calories',
                    '${activeMember!.dailyTargets.calories.round()} kcal',
                    AppTheme.calColor,
                  ),
                  _TargetRow(
                    'Protein',
                    '${activeMember!.dailyTargets.protein.round()} g',
                    AppTheme.proteinColor,
                  ),
                  _TargetRow(
                    'Carbohydrates',
                    '${activeMember!.dailyTargets.carbs.round()} g',
                    AppTheme.carbsColor,
                  ),
                  _TargetRow(
                    'Fat',
                    '${activeMember!.dailyTargets.fat.round()} g',
                    AppTheme.fatColor,
                    isLast: true,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
            const Gap(16),

            // ── Micronutrient Targets ─────────────────────────
            _MicroTargetsCard(targets: activeMember!.dailyTargets)
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.2),
            const Gap(16),
          ] else ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.orange.shade400, size: 20),
                      const Gap(8),
                      const Text(
                        'Clinical Safety Notice',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                      ),
                    ],
                  ),
                  const Gap(10),
                  const Text(
                    'Automated targets are paused for this profile state. If this profile is for pregnancy, lactation, or specialized infant care, please consult a registered dietitian or physician for individualized clinical dietary planning.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
            const Gap(16),
          ],
        ],

        // ── Scientific References & Medical Disclaimer ───────
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 18, color: AppTheme.primary),
                  const Gap(8),
                  const Text(
                    'Engine Standards & Medical Notice',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
                      );
                    },
                    child: const Text(
                      'View All →',
                      style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Gap(10),
              const Text(
                '• Adult Energy: Mifflin-St Jeor (1990) Predictive Equation\n'
                '• Pediatric Energy: Schofield (1985) + DRI Growth Allowance\n'
                '• Nutrients: National Academies Dietary Reference Intakes (DRI)\n'
                '• Dietary Fiber: WHO (2023) Healthy Diet & DRI Guidelines\n'
                '• Hydration: Holliday-Segar & 35ml/kg Fluid Standards',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.45),
              ),
              const Gap(10),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppTheme.primary),
                      Gap(8),
                      Expanded(
                        child: Text(
                          'Notice: Nutesia is a non-medical wellness tool. Pregnancy & medical conditions are not supported. Tap to view full regulatory & clinical disclaimer.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5, height: 1.35),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.2),
        const Gap(16),

        // ── Settings & Legal ─────────────────────────────
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings & Legal',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              _MenuRow(
                'Health & Regulatory Disclaimer',
                Icons.shield_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
                ),
              ),
              _MenuRow(
                'Privacy Policy',
                Icons.privacy_tip_outlined,
                onTap: () => launchUrlString('privacy.html'),
              ),
              _MenuRow(
                'Terms of Service',
                Icons.description_outlined,
                onTap: () => launchUrlString('terms.html'),
              ),
              _MenuRow(
                'Contact Support',
                Icons.mail_outline_rounded,
                onTap: () => launchUrlString('mailto:akhilcode74@gmail.com'),
              ),
              _MenuRow(
                'Log Out',
                Icons.logout_rounded,
                color: AppTheme.error,
                onTap: () => _confirmLogout(context),
                isLast: true,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
        const Gap(80),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again. Data saved on this device will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final profile = context.read<UserProfileProvider>();
    // Wipe locally cached profile, food and water data, then sign out of
    // Firebase (which removes the auth tokens). AuthWrapper then shows login.
    await profile.clearProfile();
    await auth.signOut();
  }

  void _showAddMemberModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const ManageMembersSheet(),
    );
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'lose':
      case 'lose_weight':
        return 'Goal: Weight Loss';
      case 'gain':
      case 'gain_weight':
        return 'Goal: Weight Gain / Muscle';
      case 'healthy_growth':
        return 'Goal: Healthy Pediatric Growth';
      default:
        return 'Goal: Maintenance';
    }
  }
}

// ─── Shared Credit Wallet Card ──────────────────────────────────────────────

class _CreditWalletCard extends StatelessWidget {
  final NutritionSpaceProvider spaceProvider;

  const _CreditWalletCard({required this.spaceProvider});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CreditProvider, RewardedAdProvider>(
      builder: (context, creditProvider, adProvider, _) {
        final totalCredits = creditProvider.creditBalance;
        final dailyAllowance = creditProvider.dailyCredits;
        final adCredits = creditProvider.adCredits;
        final isAdLoading = adProvider.isLoading;

        final isTester = totalCredits >= 9999 || dailyAllowance >= 9999;

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 20),
                  const Gap(8),
                  const Text(
                    'Shared AI Credit Wallet',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isTester ? '⚡ Unlimited (Tester)' : '$totalCredits Credits',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(10),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isTester
                              ? '🧪 QA Test Mode: Unlimited AI Credits granted'
                              : 'Daily Allowance: $dailyAllowance / 5 · Ad Credits: $adCredits',
                          style: TextStyle(
                            color: isTester ? AppTheme.primary : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: isTester ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: isAdLoading
                          ? null
                          : () async {
                              await showRewardedAdForCredit(context);
                              await spaceProvider.loadWallet();
                            },
                      icon: isAdLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                            )
                          : const Icon(Icons.play_circle_outline_rounded, size: 18, color: AppTheme.primary),
                      label: Text(
                        isAdLoading ? 'Loading Ad...' : 'Watch Rewarded Ad (+1 Credit)',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
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

// ─── Assessment Card (Pediatric vs Adult) ───────────────────────────────────

class _AssessmentCard extends StatelessWidget {
  final MemberModel member;

  const _AssessmentCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final isPediatric = member.bmiAssessment.type == 'PEDIATRIC' || member.isChild;
    final bmiColor = _assessmentColor(member.bmiCategory);

    return GlassCard(
      borderColor: bmiColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bmiColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPediatric ? Icons.child_care_rounded : Icons.monitor_heart_outlined,
                  color: bmiColor,
                  size: 22,
                ),
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPediatric ? 'Pediatric Growth Assessment' : 'Adult BMI Assessment',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    Text(
                      '${member.bmi} BMI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: bmiColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bmiColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  member.bmiCategory,
                  style: TextStyle(color: bmiColor, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          if (isPediatric && member.bmiAssessment.percentile != null) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.orange, size: 18),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      'CDC/WHO Growth Percentile: ${member.bmiAssessment.percentile!.round()}th percentile for age & sex.',
                      style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (member.bmiAssessment.assessmentText.isNotEmpty) ...[
            const Gap(8),
            Text(
              member.bmiAssessment.assessmentText,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Color _assessmentColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'underweight':
        return AppTheme.info;
      case 'normal':
      case 'healthy weight':
        return AppTheme.primary;
      case 'overweight':
        return AppTheme.warning;
      default:
        return AppTheme.error;
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
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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

  const _TargetRow(this.label, this.value, this.color, {this.isLast = false});

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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const Gap(12),
              Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
              const Spacer(),
              Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppTheme.divider),
      ],
    );
  }
}

class _MicroTargetsCard extends StatelessWidget {
  final NutritionData targets;

  const _MicroTargetsCard({required this.targets});

  @override
  Widget build(BuildContext context) {
    final v = targets.vitamins;
    final m = targets.minerals;

    return ChangeNotifierProvider(
      create: (_) => TabToggleProvider(),
      child: Consumer<TabToggleProvider>(
        builder: (context, toggleProvider, _) {
          final showMinerals = toggleProvider.isSecondary;

          return GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Nutrient Targets', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const Spacer(),
                    _TabBtn('Vitamins', !showMinerals, () => toggleProvider.selectPrimary()),
                    const Gap(8),
                    _TabBtn('Minerals', showMinerals, () => toggleProvider.selectSecondary()),
                  ],
                ),
                const Gap(12),
                AnimatedCrossFade(
                  crossFadeState: showMinerals ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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
        },
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
          color: selected ? AppTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppTheme.primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _MicroTargetRow extends StatelessWidget {
  final String name;
  final double target;
  final String unit;
  final bool isLast;

  const _MicroTargetRow(this.name, this.target, this.unit, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(name, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const Spacer(),
              Text(
                '${target < 1 ? target.toStringAsFixed(1) : target.round()} $unit',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppTheme.divider),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLast;
  final Color? color;

  const _MenuRow(this.title, this.icon, {required this.onTap, this.isLast = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color ?? AppTheme.textSecondary),
                const Gap(12),
                Text(title, style: TextStyle(fontSize: 14, color: color)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppTheme.divider),
      ],
    );
  }
}
