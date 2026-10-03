import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Medical & Regulatory Disclaimer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Top Official Header Card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.18),
                    AppTheme.surface.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AppTheme.primary, size: 24),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NUTESIA HEALTH & REGULATORY NOTICE',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                            ),
                            const Text(
                              'General Wellness & Non-Medical Tool',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  const Text(
                    'Please read this disclaimer carefully before using Nutesia. By using this application, you acknowledge and agree to the scope, clinical boundaries, and regulatory notices outlined below.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const Gap(10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Version: 2026.1 (India & International)',
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1),
            const Gap(20),

            // ── Section 1: Critical Exclusions (Pregnancy & Illness) ──────────
            const _SectionCard(
              title: '1. Strict Clinical Exclusions',
              subtitle: 'Nutesia is NOT designed or intended for the following populations:',
              accentColor: AppTheme.error,
              icon: Icons.block_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BulletAlert(
                    title: 'Pregnancy (Strictly Unsupported)',
                    description:
                        'Nutesia does not calculate personalized nutrition targets for pregnant women. Nutritional demands dynamically change during pregnancy and require specialized obstetric care and clinical dietary counseling by a licensed healthcare practitioner.',
                    color: AppTheme.error,
                  ),
                  Gap(12),
                  _BulletAlert(
                    title: 'Individuals with Medical Conditions',
                    description:
                        'Nutesia is strictly NOT intended for individuals suffering from any acute or chronic medical condition, illness, or clinical disorder, including but not limited to:\n'
                        '• Diabetes Mellitus (Type 1 or Type 2)\n'
                        '• Renal / Kidney Disease or Renal Impairment\n'
                        '• Cardiovascular / Heart Disease & Hypertension\n'
                        '• Liver / Hepatic Disorders\n'
                        '• Gastrointestinal, Celiac, or Malabsorption Disorders\n'
                        '• Active Cancer or Chemotherapy Treatment\n'
                        '• Eating Disorders (Anorexia, Bulimia, Binge Eating Disorder)\n'
                        '• Inborn Errors of Metabolism (e.g., PKU)',
                    color: AppTheme.warning,
                  ),
                  Gap(12),
                  _BulletAlert(
                    title: 'Infants & Toddlers Under 2 Years',
                    description:
                        'Nutesia does not support infants or children under 2 years of age. Infant feeding requires direct pediatric oversight and specialized nutritional care.',
                    color: AppTheme.info,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const Gap(16),

            // ── Section 2: Intended Audience ─────────────────────────────────
            const _SectionCard(
              title: '2. Intended Audience & Purpose',
              subtitle: 'For healthy individuals with non-medical wellness goals',
              accentColor: AppTheme.primary,
              icon: Icons.person_search_rounded,
              child: Text(
                'Nutesia is designed exclusively for generally healthy individuals (aged 2 years and above) who have no active medical complications and seek general lifestyle awareness, food tracking, and educational nutritional estimation.\n\n'
                'All calculations, macronutrient breakdowns, and micronutrient references are automated mathematical estimates based on published scientific population reference standards and are NOT personalized clinical prescriptions.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
              ),
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
            const Gap(16),

            // ── Section 3: Indian Government & Regulatory Compliance ────────
            const _SectionCard(
              title: '3. Indian Regulatory & Digital Health Compliance',
              subtitle: 'CDSCO, MoHFW, and Telemedicine Guidelines alignment',
              accentColor: AppTheme.info,
              icon: Icons.account_balance_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RegulatoryBadge(
                    tag: 'CDSCO Non-Medical Device Scope',
                    text:
                        'Under the Medical Devices Rules (MDR) regulated by the Central Drugs Standard Control Organisation (CDSCO), Government of India, Nutesia is classified as a General Health, Wellness and Lifestyle Application, and is NOT Software as a Medical Device (SaMD). It is not intended to diagnose, cure, mitigate, treat, or prevent any disease or medical condition.',
                  ),
                  Gap(12),
                  _RegulatoryBadge(
                    tag: 'MoHFW & Telemedicine Practice Guidelines',
                    text:
                        'In compliance with guidelines from the Ministry of Health and Family Welfare (MoHFW), Government of India, the information presented in this app does not constitute medical advice or teleconsultation. Users must not use Nutesia to replace the clinical judgment of a Registered Medical Practitioner (RMP) or certified clinical dietitian.',
                  ),
                  Gap(12),
                  _RegulatoryBadge(
                    tag: 'ICMR-NIN Reference Framework',
                    text:
                        'Nutritional benchmarks and daily reference values are aligned with the Indian Council of Medical Research - National Institute of Nutrition (ICMR-NIN) "Dietary Guidelines for Indians" and the National Academies Dietary Reference Intakes (DRI).',
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const Gap(16),

            // ── Section 4: Pediatric Safety Policy ───────────────────────────
            const _SectionCard(
              title: '4. Pediatric Safety Policy (Ages 2–17)',
              subtitle: 'Protection against pediatric calorie restriction',
              accentColor: Colors.orange,
              icon: Icons.child_care_rounded,
              child: Text(
                'In accordance with pediatric clinical consensus (WHO & Indian Academy of Pediatrics principles):\n'
                '• Intentional caloric deficit dieting is strictly prohibited for children and adolescents under 18 years of age.\n'
                '• Pediatric profiles only generate targets supporting healthy developmental growth, maintenance, and sports activity.\n'
                '• All pediatric tracking must be managed and monitored by a parent or legal guardian.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
            const Gap(16),

            // ── Section 5: Medical Emergency Notice ──────────────────────────
            _SectionCard(
              title: '5. Medical Emergency Notice',
              subtitle: 'Do not use this app in medical emergencies',
              accentColor: AppTheme.error,
              icon: Icons.emergency_rounded,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 IF YOU ARE EXPERIENCING A MEDICAL EMERGENCY:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.error,
                        fontSize: 13,
                      ),
                    ),
                    Gap(6),
                    Text(
                      'Immediately contact your local emergency medical services (such as 112 or 108 in India, or 911 / 999 internationally) or proceed to the nearest hospital emergency room. Never delay seeking medical advice because of something you read or calculated in this app.',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
            const Gap(16),

            // ── Section 6: Data Privacy & Processing Notice ──────────────────
            const _SectionCard(
              title: '6. Privacy & Data Protection (DPDP Act 2023)',
              subtitle: 'How your health and nutrition logs are handled',
              accentColor: AppTheme.primary,
              icon: Icons.lock_outline_rounded,
              child: Text(
                'Nutesia processes your anthropometric and dietary log data in accordance with the Digital Personal Data Protection (DPDP) Act, 2023 and the Information Technology Act, 2000 of India. Your entries are used solely to compute your personal wellness estimates and synchronization within your private family nutrition space.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
              ),
            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
            const Gap(24),

            // ── Bottom Acknowledgment Action Button ─────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text(
                  'I Understand & Acknowledge',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(14),
          child,
        ],
      ),
    );
  }
}

class _BulletAlert extends StatelessWidget {
  final String title;
  final String description;
  final Color color;

  const _BulletAlert({
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: color),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Gap(6),
          Text(
            description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegulatoryBadge extends StatelessWidget {
  final String tag;
  final String text;

  const _RegulatoryBadge({
    required this.tag,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.info,
              ),
            ),
          ),
          const Gap(8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
