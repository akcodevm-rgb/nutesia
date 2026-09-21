/// The built-in animation presets offered as chips in the studio.
///
/// These mirror the `animation_presets` table: at runtime the platform may
/// serve extra presets from the database without a deploy, but these defaults
/// ship in the package so the studio, the preview and the offline tests all
/// have a working catalogue with no backend.
///
/// Every preset spec here is written to already satisfy [SpecLimits]; the
/// `presets are self-consistent` test enforces that, so a careless edit cannot
/// ship a preset the validator would have to repair.
library;

import 'limits.dart';
import 'spec.dart';
import 'vocabulary.dart';

class AnimationPreset {
  const AnimationPreset({
    required this.key,
    required this.title,
    required this.description,
    required this.spec,
    required this.appliesTo,
  });

  /// Stable identifier stored on `product_model_configs.animation_preset_key`.
  final String key;

  /// Chip label in the studio.
  final String title;

  /// One line explaining what the diner will see.
  final String description;

  final AnimationSpec spec;

  /// Categories this preset is offered for. Empty means "all".
  final Set<ProductCategory> appliesTo;

  bool appliesToCategory(ProductCategory category) =>
      appliesTo.isEmpty || appliesTo.contains(category);
}

abstract final class AnimationPresets {
  static const AnimationPreset slowSpin = AnimationPreset(
    key: 'slow_spin',
    title: 'Slow spin',
    description: 'A gentle turntable rotation. Works with any dish.',
    appliesTo: {},
    spec: AnimationSpec(
      version: currentSpecVersion,
      motion: Motion(
        type: MotionType.turntable,
        axis: SpinAxis.y,
        speed: 0.35,
        duration: 1.2,
        easing: Easing.linear,
      ),
      secondary: [],
      effects: [],
      camera: CameraSpec.standard(),
      lighting: LightingPreset.warmStudio,
      loop: true,
      autoplay: true,
      delay: 0.0,
    ),
  );

  static const AnimationPreset hotAndSteaming = AnimationPreset(
    key: 'hot_steaming',
    title: 'Hot & steaming',
    description: 'Steam rises off the top while the dish turns slowly.',
    appliesTo: {ProductCategory.food, ProductCategory.side},
    spec: AnimationSpec(
      version: currentSpecVersion,
      motion: Motion(
        type: MotionType.turntable,
        axis: SpinAxis.y,
        speed: 0.28,
        duration: 1.2,
        easing: Easing.linear,
      ),
      secondary: [],
      effects: [
        Effect(
            type: EffectType.steam,
            anchor: EffectAnchor.top,
            intensity: 0.65),
      ],
      camera: CameraSpec(fov: 35, distance: 1.4, orbitControls: true),
      lighting: LightingPreset.warmStudio,
      loop: true,
      autoplay: true,
      delay: 0.0,
    ),
  );

  static const AnimationPreset sizzle = AnimationPreset(
    key: 'sizzle',
    title: 'Sizzle',
    description: 'Sparks and heat haze at the base, for grilled dishes.',
    appliesTo: {ProductCategory.food},
    spec: AnimationSpec(
      version: currentSpecVersion,
      motion: Motion(
        type: MotionType.turntable,
        axis: SpinAxis.y,
        speed: 0.3,
        duration: 1.2,
        easing: Easing.linear,
      ),
      secondary: [],
      effects: [
        Effect(
            type: EffectType.sizzle,
            anchor: EffectAnchor.bottom,
            intensity: 0.7),
        Effect(
            type: EffectType.steam, anchor: EffectAnchor.top, intensity: 0.35),
      ],
      camera: CameraSpec(fov: 35, distance: 1.35, orbitControls: true),
      lighting: LightingPreset.darkMoody,
      loop: true,
      autoplay: true,
      delay: 0.0,
    ),
  );

  static const AnimationPreset freshSplash = AnimationPreset(
    key: 'fresh_splash',
    title: 'Fresh splash',
    description: 'Cool droplets and condensation. Best on cold drinks.',
    appliesTo: {ProductCategory.drink},
    spec: AnimationSpec(
      version: currentSpecVersion,
      motion: Motion(
        type: MotionType.turntable,
        axis: SpinAxis.y,
        speed: 0.32,
        duration: 1.2,
        easing: Easing.linear,
      ),
      secondary: [
        SecondaryMotion(
            type: SecondaryMotionType.float, amplitude: 0.015, period: 3.5),
      ],
      effects: [
        Effect(
            type: EffectType.droplets,
            anchor: EffectAnchor.rim,
            intensity: 0.6),
        Effect(
            type: EffectType.condensation,
            anchor: EffectAnchor.rim,
            intensity: 0.5),
      ],
      camera: CameraSpec(fov: 32, distance: 1.5, orbitControls: true),
      lighting: LightingPreset.brightDaylight,
      loop: true,
      autoplay: true,
      delay: 0.0,
    ),
  );

  static const AnimationPreset fizz = AnimationPreset(
    key: 'fizz',
    title: 'Fizz',
    description: 'Rising bubbles for sparkling and poured drinks.',
    appliesTo: {ProductCategory.drink},
    spec: AnimationSpec(
      version: currentSpecVersion,
      motion: Motion(
        type: MotionType.turntable,
        axis: SpinAxis.y,
        speed: 0.25,
        duration: 1.2,
        easing: Easing.linear,
      ),
      secondary: [],
      effects: [
        Effect(
            type: EffectType.bubbles,
            anchor: EffectAnchor.base,
            intensity: 0.7),
        Effect(
            type: EffectType.condensation,
            anchor: EffectAnchor.rim,
            intensity: 0.4),
      ],
      camera: CameraSpec(fov: 32, distance: 1.5, orbitControls: true),
      lighting: LightingPreset.brightDaylight,
      loop: true,
      autoplay: true,
      delay: 0.0,
    ),
  );

  static const AnimationPreset drizzle = AnimationPreset(
    key: 'drizzle',
    title: 'Drizzle',
    description: 'A glossy sauce or syrup highlight running down the dish.',
    appliesTo: {ProductCategory.dessert, ProductCategory.food},
    spec: AnimationSpec(
      version: currentSpecVersion,
      motion: Motion(
        type: MotionType.turntable,
        axis: SpinAxis.y,
        speed: 0.3,
        duration: 1.2,
        easing: Easing.linear,
      ),
      secondary: [],
      effects: [
        Effect(type: EffectType.drip, anchor: EffectAnchor.top, intensity: 0.6),
      ],
      camera: CameraSpec(fov: 35, distance: 1.4, orbitControls: true),
      lighting: LightingPreset.warmStudio,
      loop: true,
      autoplay: true,
      delay: 0.0,
    ),
  );

  static const AnimationPreset sparkle = AnimationPreset(
    key: 'sparkle',
    title: 'Sparkle',
    description: 'A soft glint that catches the eye as the dish turns.',
    appliesTo: {},
    spec: AnimationSpec(
      version: currentSpecVersion,
      motion: Motion(
        type: MotionType.turntable,
        axis: SpinAxis.y,
        speed: 0.35,
        duration: 1.2,
        easing: Easing.linear,
      ),
      secondary: [],
      effects: [
        Effect(
            type: EffectType.sparkle,
            anchor: EffectAnchor.center,
            intensity: 0.3),
      ],
      camera: CameraSpec.standard(),
      lighting: LightingPreset.neon,
      loop: true,
      autoplay: true,
      delay: 0.0,
    ),
  );

  static const AnimationPreset gentleFloat = AnimationPreset(
    key: 'gentle_float',
    title: 'Gentle float',
    description: 'The dish hovers and bobs softly, with no spin.',
    appliesTo: {},
    spec: AnimationSpec(
      version: currentSpecVersion,
      motion: Motion(
        type: MotionType.float,
        axis: SpinAxis.y,
        speed: 0.0,
        duration: 1.2,
        easing: Easing.easeInOut,
      ),
      secondary: [
        SecondaryMotion(
            type: SecondaryMotionType.sway, amplitude: 0.02, period: 5.0),
      ],
      effects: [],
      camera: CameraSpec.standard(),
      lighting: LightingPreset.warmStudio,
      loop: true,
      autoplay: true,
      delay: 0.0,
    ),
  );

  /// Every built-in preset, in the order the studio shows them.
  static const List<AnimationPreset> all = [
    slowSpin,
    hotAndSteaming,
    sizzle,
    freshSplash,
    fizz,
    drizzle,
    sparkle,
    gentleFloat,
  ];

  static AnimationPreset? byKey(String key) {
    for (final p in all) {
      if (p.key == key) return p;
    }
    return null;
  }

  /// Presets worth offering for [category], most relevant first.
  ///
  /// Category-specific presets come before the universal ones so a drink shows
  /// "Fizz" above "Slow spin".
  static List<AnimationPreset> forCategory(ProductCategory category) {
    final specific = <AnimationPreset>[];
    final universal = <AnimationPreset>[];
    for (final p in all) {
      if (!p.appliesToCategory(category)) continue;
      (p.appliesTo.isEmpty ? universal : specific).add(p);
    }
    return [...specific, ...universal];
  }
}
