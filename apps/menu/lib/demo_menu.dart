import 'package:animation_spec/animation_spec.dart';

/// A menu item as the diner app sees it. In production this comes from the
/// published menu snapshot; here it is hard-coded demo data.
class MenuItem {
  const MenuItem({
    required this.name,
    required this.description,
    required this.priceMinor,
    required this.category,
    required this.modelUrl,
    required this.rawSpec,
  });

  final String name;
  final String description;

  /// Price in minor units (cents). Money is never a float.
  final int priceMinor;

  final ProductCategory category;
  final String modelUrl;

  /// The animation spec as stored, before validation. For [cheesyToast] this
  /// is deliberately messy, the way an LLM might return it.
  final Object? rawSpec;

  String get price => '\$${(priceMinor ~/ 100)}.${(priceMinor % 100).toString().padLeft(2, '0')}';
}

// CC0 sample models from the Khronos glTF sample assets. Both are about 8 MB,
// over the plan's 6 MB hard limit: exactly what the optimisation worker is
// for. They are streamed rather than bundled to keep the repo small.
const _khronos =
    'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models';
const _avocado = '$_khronos/Avocado/glTF-Binary/Avocado.glb';
const _bottle = '$_khronos/WaterBottle/glTF-Binary/WaterBottle.glb';

final demoMenu = <MenuItem>[
  MenuItem(
    name: 'Hass Avocado Half',
    description: 'Ripe avocado, sea salt, a drizzle of lime.',
    priceMinor: 450,
    category: ProductCategory.food,
    modelUrl: _avocado,
    rawSpec: AnimationPresets.drizzle.spec.toJson(),
  ),
  MenuItem(
    name: 'Sparkling Spring Water',
    description: 'Ice-cold, 500 ml.',
    priceMinor: 300,
    category: ProductCategory.drink,
    modelUrl: _bottle,
    rawSpec: AnimationPresets.freshSplash.spec.toJson(),
  ),
  MenuItem(
    name: 'Cheesy Avocado Toast',
    description: 'Sourdough, smashed avocado, melted mozzarella.',
    priceMinor: 1150,
    category: ProductCategory.food,
    modelUrl: _avocado,
    // What an LLM might return for "cheese pull, steam, spin really fast".
    rawSpec: {
      'motion': {'type': 'cheese_pull', 'speed': 12},
      'effects': ['steam', 'steam', 'sparkle'],
      'lighting': 'warm_studio',
    },
  ),
];
