import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/food_entry_model.dart';
import '../../../shared/models/member_model.dart';
import '../../../shared/widgets/credit_chip.dart';
import '../../../shared/widgets/header_profile_switcher.dart';
import '../providers/home_provider.dart';
import '../providers/water_provider.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/water_intake_card.dart';
import '../widgets/micro_section.dart';
import '../widgets/food_timeline_item.dart';
import '../widgets/child_nutrition_card.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/providers/nutrition_space_provider.dart';
import '../../food_log/screens/add_food_screen.dart';
import '../../food_log/screens/food_detail_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../../shared/widgets/error_views/error_views.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, home, _) {
        final tabIndex = home.tabIndex;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: IndexedStack(
            index: tabIndex,
            children: const [
              _DashboardTab(),
              AnalyticsScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            index: tabIndex,
            onTap: (i) => home.setTabIndex(i),
          ),
          floatingActionButton: tabIndex == 0 ? _AddFoodFab() : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }
}

class _AddFoodFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (ctx, anim, _) => const AddFoodScreen(),
              transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 1), end: Offset.zero)
                    .animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 350),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Log Food',
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: index == 0,
                  onTap: () => onTap(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  selected: index == 1,
                  onTap: () => onTap(1),
                ),
              ),
              const SizedBox(width: 80), // Center FAB space
              Expanded(
                child: _NavItem(
                  icon: Icons.person_outlined,
                  label: 'Profile',
                  selected: index == 2,
                  onTap: () => onTap(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primary : AppTheme.textMuted,
              size: 24,
            ),
            const Gap(3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppTheme.primary : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ─────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncChildSummaries();
    });
  }

  void _syncChildSummaries() {
    final spaceProvider = context.read<NutritionSpaceProvider>();
    final activeMember = spaceProvider.activeMember;

    final isChildProfile = activeMember != null &&
        (activeMember.isChild || activeMember.relationship == 'child');

    if (isChildProfile) return;

    final space = spaceProvider.space;
    if (space != null && space.profiles.isNotEmpty) {
      final childIds = space.profiles
          .where((p) => (p.isChild || p.relationship == 'child') && p.id != activeMember?.id)
          .map((p) => p.id)
          .toList();
      if (childIds.isNotEmpty) {
        context.read<HomeProvider>().loadMemberSummaries(childIds);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<HomeProvider, UserProfileProvider, NutritionSpaceProvider>(
      builder: (context, home, profileProvider, spaceProvider, _) {
        final consumed = home.dailySummary;
        final activeMember = spaceProvider.activeMember;
        final targets = (activeMember != null && activeMember.dailyTargets.calories > 0)
            ? activeMember.dailyTargets
            : profileProvider.user?.dailyTargets;

        final space = spaceProvider.space;

        final isChildProfile = activeMember != null &&
            (activeMember.isChild || activeMember.relationship == 'child');

        final isMasterOrParent = !isChildProfile &&
            (activeMember == null ||
                activeMember.relationship == 'owner' ||
                activeMember.relationship == 'self' ||
                activeMember.relationship == 'parent' ||
                activeMember.id == space?.ownerUserId ||
                activeMember.id == space?.profiles.firstOrNull?.id);

        final allChildren = isMasterOrParent
            ? (space?.profiles
                    .where((p) =>
                        (p.isChild || p.relationship == 'child') &&
                        p.id != activeMember?.id)
                    .toList() ??
                <MemberModel>[])
            : <MemberModel>[];

        return RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          onRefresh: () async {
            await home.refresh();
            _syncChildSummaries();
          },
          child: CustomScrollView(
            slivers: [
              // ── App Bar ─────────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppTheme.background,
                floating: true,
                expandedHeight: 0,
                title: const HeaderProfileSwitcher(),
                actions: [
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Center(child: CreditChip()),
                  ),
                  IconButton(
                    onPressed: () => _showDatePicker(context, home),
                    icon: const Icon(Icons.calendar_today_outlined, size: 20),
                    tooltip: 'Select date',
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Daily Summary ────────────────────────────
                    if (targets != null)
                      DailySummaryCard(consumed: consumed, targets: targets)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2),
                    const Gap(16),

                    // ── Child Nutrition Overview (Only shown for Master/Parent) ───
                    if (isMasterOrParent && allChildren.isNotEmpty) ...[
                      ChildNutritionSection(children: allChildren)
                          .animate()
                          .fadeIn(duration: 420.ms)
                          .slideY(begin: 0.18),
                      const Gap(16),
                    ],

                    // ── Water Intake ─────────────────────────────
                    const WaterIntakeCard()
                        .animate()
                        .fadeIn(duration: 450.ms)
                        .slideY(begin: 0.15),
                    const Gap(16),

                    // ── Micronutrients ──────────────────────────
                    Text('Micronutrients',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: AppTheme.textSecondary))
                        .animate()
                        .fadeIn(delay: 200.ms),
                    const Gap(8),
                    if (targets != null)
                      MicroSection(consumed: consumed, targets: targets)
                          .animate()
                          .fadeIn(delay: 250.ms),
                    const Gap(24),

                    // ── Timeline ─────────────────────────────────
                    Row(
                      children: [
                        Text('Today\'s Log',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: AppTheme.textSecondary)),
                        const Spacer(),
                        Text(
                          '${home.entries.length} entries',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                    const Gap(8),

                    if (home.isLoading && home.entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ),
                      )
                    else if (home.error != null && home.entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: AppErrorCard(
                          error: ErrorParser.parse(home.error),
                          onAction: () => home.refresh(),
                        ),
                      )
                    else if (home.entries.isEmpty)
                      _EmptyState().animate().fadeIn(delay: 350.ms)
                    else
                      _buildTimeline(context, home, home.entries),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeline(
      BuildContext context, HomeProvider home, List<FoodEntry> entries) {
    const mealOrder = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mealOrder.map((meal) {
        final group = entries.where((e) => e.mealType == meal).toList();
        return MealGroup(
          mealType: meal,
          entries: group,
          onEntryTap: (entry) => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FoodDetailScreen(entry: entry),
            ),
          ),
          onEntryDelete: (id) => _confirmDelete(context, home, id),
        );
      }).toList(),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, HomeProvider home, String entryId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This food entry will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await home.deleteEntry(entryId);
    }
  }

  Future<void> _showDatePicker(BuildContext context, HomeProvider home) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: home.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: AppTheme.primary,
                onPrimary: Colors.black,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      home.setSelectedDate(picked);
      if (context.mounted) {
        context.read<WaterProvider>().updateDate(picked);
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.restaurant_menu, size: 48, color: AppTheme.primary),
          const Gap(12),
          Text('No meals logged yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  )),
          const Gap(6),
          const Text('Tap "Log Food" to add your first meal',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
