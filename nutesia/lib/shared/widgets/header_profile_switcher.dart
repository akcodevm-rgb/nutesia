import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/profile/providers/nutrition_space_provider.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/onboarding/screens/profile_setup_screen.dart';
import '../models/member_model.dart';
import 'manage_members_sheet.dart';

class HeaderProfileSwitcher extends StatelessWidget {
  const HeaderProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionSpaceProvider>(
      builder: (context, spaceProvider, _) {
        final space = spaceProvider.space;
        final activeMember = spaceProvider.activeMember;

        if (space == null) return const SizedBox.shrink();
        final isFamily = space.isFamilyMode;
        final memberName = activeMember?.name.isNotEmpty == true
            ? activeMember!.name
            : 'Primary Profile';

        return GestureDetector(
          onTap: () {
            _showProfileSelectionSheet(context, spaceProvider);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isFamily
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    memberName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  memberName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isFamily) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ] else ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileSelectionSheet(BuildContext context, NutritionSpaceProvider spaceProvider) {
    final space = spaceProvider.space;
    if (space == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<NutritionSpaceProvider>(
          builder: (context, currentSpaceProvider, _) {
            final activeId = currentSpaceProvider.activeMemberId;
            final currentSpace = currentSpaceProvider.space ?? space;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentSpace.isFamilyMode
                            ? 'Family Profiles (${currentSpace.profiles.length}/3)'
                            : 'Personal Profile',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (!currentSpace.isFamilyMode)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            currentSpaceProvider.updateSpaceMode('FAMILY');
                            _showAddMemberModal(context);
                          },
                          icon: const Icon(Icons.group_add_outlined, size: 18),
                          label: const Text('Switch to Family Mode'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: currentSpace.profiles.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final profile = currentSpace.profiles[idx];
                        final isActive = profile.id == activeId;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Text(
                              profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'M',
                              style: TextStyle(
                                color: isActive
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                profile.name,
                                style: TextStyle(
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: profile.isChild
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  profile.isChild ? 'Child (${profile.age}y)' : 'Adult',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: profile.isChild ? Colors.orange.shade800 : Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('BMI: ${profile.bmi} (${profile.bmiCategory})'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit profile',
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  if (profile.relationship == 'owner' || profile.relationship == 'self') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ProfileSetupScreen(),
                                        fullscreenDialog: true,
                                      ),
                                    );
                                  } else {
                                    _showEditMemberModal(context, profile);
                                  }
                                },
                              ),
                              if (isActive)
                                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                            ],
                          ),
                          onTap: () {
                            currentSpaceProvider.switchActiveMember(profile.id);
                            context.read<HomeProvider>().updateActiveMember(profile.id);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (currentSpace.canAddMember)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddMemberModal(context);
                        },
                        icon: const Icon(Icons.add),
                        label: Text('Add Family Member (${currentSpace.profiles.length}/3)'),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Maximum 3 member profiles limit reached for this device.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
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

  void _showEditMemberModal(BuildContext context, MemberModel member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ManageMembersSheet(memberToEdit: member),
    );
  }
}
