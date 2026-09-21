import 'package:animation_spec/animation_spec.dart';
import 'package:flutter/material.dart';
import 'package:viewer_3d/viewer_3d.dart';

import 'demo_menu.dart';

void main() => runApp(const MenuApp());

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB5562B),
        useMaterial3: true,
      ),
      home: const MenuPage(),
    );
  }
}

/// The list diners land on after scanning the table QR code.
///
/// Cards are plain Flutter with no 3D. The model loads only when a diner taps
/// an item, following the plan's "posters first, one active viewer" rule.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Menu')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demoMenu.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = demoMenu[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(child: Icon(Icons.view_in_ar)),
              title: Text(item.name),
              subtitle: Text(item.description),
              trailing: Text(item.price,
                  style: Theme.of(context).textTheme.titleMedium),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ItemPage(item: item),
              )),
            ),
          );
        },
      ),
    );
  }
}

/// One item in 3D, with preset chips so the animation can be switched live.
///
/// The chips stand in for the restaurant studio's preset picker (plan 8.1
/// step 3). Switching one only swaps the spec, never the mesh.
class ItemPage extends StatefulWidget {
  const ItemPage({super.key, required this.item});

  final MenuItem item;

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  late SpecValidation _validation;
  String? _presetKey;

  @override
  void initState() {
    super.initState();
    _validation = AnimationSpecValidator.validate(
      widget.item.rawSpec,
      category: widget.item.category,
    );
  }

  void _choose(AnimationPreset preset) {
    setState(() {
      _presetKey = preset.key;
      _validation = AnimationSpecValidator.validate(
        preset.spec.toJson(),
        category: widget.item.category,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context);
    final presets = AnimationPresets.forCategory(item.category);

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MenuItemViewer(
              src: item.modelUrl,
              spec: _validation.spec,
              alt: item.name,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                    child: Text(item.name, style: theme.textTheme.titleLarge)),
                Text(item.price, style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(item.description, style: theme.textTheme.bodyMedium),
          ),
          if (_validation.diagnostics.isNotEmpty)
            _DiagnosticsCard(diagnostics: _validation.diagnostics),
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                for (final p in presets)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.title),
                      tooltip: p.description,
                      selected: _presetKey == p.key,
                      onSelected: (_) => _choose(p),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows what the validator changed, in the words it wrote for the user.
class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({required this.diagnostics});

  final List<SpecDiagnostic> diagnostics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final d in diagnostics)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      d.isNotYetSupported
                          ? Icons.hourglass_empty
                          : Icons.info_outline,
                      size: 16,
                      color: scheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(d.message,
                          style: TextStyle(color: scheme.onTertiaryContainer)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
