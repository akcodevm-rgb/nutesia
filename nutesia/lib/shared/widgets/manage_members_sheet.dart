import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../features/profile/providers/nutrition_space_provider.dart';
import '../models/member_model.dart';
import '../providers/manage_members_provider.dart';

class ManageMembersSheet extends StatelessWidget {
  final MemberModel? memberToEdit;

  const ManageMembersSheet({super.key, this.memberToEdit});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManageMembersProvider(initialMember: memberToEdit),
      child: _ManageMembersSheetContent(memberToEdit: memberToEdit),
    );
  }
}

class _ManageMembersSheetContent extends StatefulWidget {
  final MemberModel? memberToEdit;

  const _ManageMembersSheetContent({this.memberToEdit});

  @override
  State<_ManageMembersSheetContent> createState() => _ManageMembersSheetContentState();
}

class _ManageMembersSheetContentState extends State<_ManageMembersSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final initial = widget.memberToEdit;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _ageController = TextEditingController(
        text: initial != null && initial.age > 0 ? initial.age.toString() : '10');
    _heightController = TextEditingController(
        text: initial != null && initial.heightCm > 0
            ? initial.heightCm.round().toString()
            : '145');
    _weightController = TextEditingController(
        text: initial != null && initial.weightKg > 0
            ? initial.weightKg.round().toString()
            : '40');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit(
    BuildContext context,
    ManageMembersProvider formProvider,
    NutritionSpaceProvider spaceProvider,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    formProvider.setName(_nameController.text);
    formProvider.setAge(int.tryParse(_ageController.text) ?? 10);
    formProvider.setHeight(_heightController.text);
    formProvider.setWeight(_weightController.text);

    final isEdit = formProvider.isEditMode;
    final success = await formProvider.submit(spaceProvider);

    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit
              ? 'Updated profile "${formProvider.name.trim()}"'
              : 'Added member profile "${formProvider.name.trim()}"'),
        ),
      );
    } else if (formProvider.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formProvider.errorMessage!)),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    ManageMembersProvider formProvider,
    NutritionSpaceProvider spaceProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
            'Are you sure you want to remove "${widget.memberToEdit?.name}" from your family space?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await formProvider.delete(spaceProvider);
    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed profile "${widget.memberToEdit?.name}"')),
      );
    } else if (formProvider.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formProvider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ManageMembersProvider, NutritionSpaceProvider>(
      builder: (context, formProvider, spaceProvider, _) {
        final space = spaceProvider.space;
        final isEdit = formProvider.isEditMode;
        final isLimitReached = !isEdit && space != null && space.profiles.length >= 3;
        final isSubmitting = formProvider.isSubmitting;

        final isChildRole = formProvider.relationship == 'child';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                        isEdit
                            ? (isChildRole ? 'Edit Child Profile' : 'Edit Member Profile')
                            : 'Add Family Member Profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (isEdit && widget.memberToEdit?.relationship != 'owner')
                        IconButton(
                          onPressed: isSubmitting ? null : () => _delete(context, formProvider, spaceProvider),
                          icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                          tooltip: 'Delete Profile',
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEdit
                        ? 'Update pediatric or family member metrics and nutrition goals.'
                        : 'Add up to 3 family members per household device account.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Member Name',
                      hintText: 'e.g. Aarav, Ananya',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age (years)',
                      hintText: 'e.g. 10',
                      prefixIcon: Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      final numVal = int.tryParse(val ?? '');
                      if (numVal == null || numVal < 2 || numVal > 120) {
                        return 'Please enter a valid age (2-120 years). Age < 2 requires clinical care.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // `value` keeps the field in sync with provider state; `initialValue` is read once.
                          // ignore: deprecated_member_use
                          value: formProvider.gender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'female', child: Text('Female')),
                            DropdownMenuItem(value: 'male', child: Text('Male')),
                          ],
                          onChanged: (val) {
                            if (val != null) formProvider.setGender(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // `value` keeps the field in sync with provider state; `initialValue` is read once.
                          // ignore: deprecated_member_use
                          value: formProvider.relationship,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'child', child: Text('Child')),
                            DropdownMenuItem(value: 'spouse', child: Text('Spouse')),
                            DropdownMenuItem(value: 'parent', child: Text('Parent')),
                            DropdownMenuItem(value: 'other', child: Text('Other')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              formProvider.setRelationship(val);
                              if (val == 'child' && formProvider.goal == 'lose_weight') {
                                formProvider.setGoal('maintain_weight');
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || double.tryParse(val) == null
                              ? 'Enter valid height'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || double.tryParse(val) == null
                              ? 'Enter valid weight'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // `value` keeps the field in sync with provider state; `initialValue` is read once.
                    // ignore: deprecated_member_use
                    value: (formProvider.relationship == 'child' && formProvider.goal == 'lose_weight')
                        ? 'maintain_weight'
                        : formProvider.goal,
                    decoration: const InputDecoration(
                      labelText: 'Nutrition Goal',
                      border: OutlineInputBorder(),
                    ),
                    items: formProvider.relationship == 'child'
                        ? const [
                            DropdownMenuItem(
                                value: 'maintain_weight',
                                child: Text('Healthy Pediatric Growth')),
                            DropdownMenuItem(
                                value: 'gain_weight',
                                child: Text('Growth & Active Surplus')),
                          ]
                        : const [
                            DropdownMenuItem(
                                value: 'maintain_weight',
                                child: Text('Maintenance / Stay Healthy')),
                            DropdownMenuItem(
                                value: 'lose_weight',
                                child: Text('Weight Loss (-500 kcal)')),
                            DropdownMenuItem(
                                value: 'gain_weight',
                                child: Text('Weight Gain / Muscle Support')),
                          ],
                    onChanged: (val) {
                      if (val != null) formProvider.setGoal(val);
                    },
                  ),
                  if (formProvider.relationship == 'child')
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        'Caloric deficits are prohibited for growing children under 18.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (isLimitReached)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Maximum limit of 3 member profiles reached.',
                              style:
                                  TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () => _submit(context, formProvider, spaceProvider),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(isEdit ? 'Save Changes' : 'Add Profile',
                                style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
