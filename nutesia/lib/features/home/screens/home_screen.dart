import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/food_entry_model.dart';
import '../../../shared/widgets/credit_chip.dart';
import '../providers/home_provider.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/micro_section.dart';
import '../widgets/food_timeline_item.dart';
import '../../profile/providers/profile_provider.dart';
import '../../food_log/screens/add_food_screen.dart';
import '../../food_log/screens/food_detail_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../analytics/screens/analytics_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _tabIndex,
        children: [
          const _DashboardTab(),
          const AnalyticsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        index: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
      ),
      floatingActionButton: _tabIndex == 0 ? _AddFoodFab() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      selected: index == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      selected: index == 1,
                      onTap: () => onTap(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 80), // Center FAB space
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Icons.person_outlined,
                      label: 'Profile',
                      selected: index == 2,
                      onTap: () => onTap(2),
                    ),
                  ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textMuted,
                size: 24),
            const Gap(3),
            Text(label,
                style: TextStyle(
                  color: selected ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Tab ─────────────────────────────────────────────────────────

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final entriesAsync = ref.watch(foodEntriesProvider);
    final consumed = ref.watch(dailySummaryProvider);
    final targets = ref.watch(dailyTargetsProvider);
    final date = ref.watch(selectedDateProvider);

    return RefreshIndicator(
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      onRefresh: () async => ref.read(foodEntriesProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppTheme.background,
            floating: true,
            expandedHeight: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey ${profile?.name.split(' ').first ?? 'there'} 👋',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  AppDateUtils.toRelative(date),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textSecondary),
                ),
              ],
            ),
            actions: [
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Center(child: CreditChip()),
              ),
              IconButton(
                onPressed: () => _showDatePicker(context, ref, date),
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
                    entriesAsync
                            .whenData((e) => Text(
                                  '${e.length} entries',
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 12),
                                ))
                            .valueOrNull ??
                        const SizedBox.shrink(),
                  ],
                ).animate().fadeIn(delay: 300.ms),
                const Gap(8),

                entriesAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return _EmptyState().animate().fadeIn(delay: 350.ms);
                    }
                    return _buildTimeline(context, ref, entries);
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  ),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: AppTheme.error)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
      BuildContext context, WidgetRef ref, List<FoodEntry> entries) {
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
          onEntryDelete: (id) => _confirmDelete(context, ref, id),
        );
      }).toList(),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String entryId) async {
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
      await ref.read(foodEntriesProvider.notifier).deleteEntry(entryId);
    }
  }

  Future<void> _showDatePicker(
      BuildContext context, WidgetRef ref, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
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
      ref.read(selectedDateProvider.notifier).state = picked;
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
          Icon(Icons.restaurant_menu, size: 48, color: AppTheme.primary),
          const Gap(12),
          Text('No meals logged yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  )),
          const Gap(6),
          Text('Tap "Log Food" to add your first meal',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
