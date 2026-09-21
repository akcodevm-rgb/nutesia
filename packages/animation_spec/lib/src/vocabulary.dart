/// The closed vocabulary of the animation spec.
///
/// This file *is* the whitelist referenced in the security model: anything the
/// LLM emits that is not named here gets dropped by the validator and reported
/// back to the user. Adding a capability means adding it here first, so the
/// renderer never has to guess what a string means.
library;

/// A value that serialises to a stable snake_case string on the wire.
abstract interface class WireValue {
  String get wire;
}

/// Looks [wire] up in [values], returning null for anything unrecognised.
///
/// Deliberately total: untrusted input must never throw.
T? parseWire<T extends WireValue>(List<T> values, Object? wire) {
  if (wire is! String) return null;
  final needle = wire.trim().toLowerCase();
  for (final v in values) {
    if (v.wire == needle) return v;
  }
  return null;
}

/// Primary motion applied to the whole model.
enum MotionType implements WireValue {
  /// No primary motion; the model sits still and can still be orbited by hand.
  none('none'),
  turntable('turntable'),
  float('float'),
  zoomIn('zoom_in'),
  tiltReveal('tilt_reveal'),
  bounceIn('bounce_in');

  const MotionType(this.wire);
  @override
  final String wire;
}

/// Secondary motion layered on top of the primary one.
enum SecondaryMotionType implements WireValue {
  float('float'),
  sway('sway'),
  pulse('pulse');

  const SecondaryMotionType(this.wire);
  @override
  final String wire;
}

/// Particle and shader effects drawn around the model.
enum EffectType implements WireValue {
  steam('steam'),
  sizzle('sizzle'),
  droplets('droplets'),
  drip('drip'),
  sparkle('sparkle'),
  bubbles('bubbles'),
  condensation('condensation');

  const EffectType(this.wire);
  @override
  final String wire;
}

/// Where on the model's bounding box an effect is emitted from.
enum EffectAnchor implements WireValue {
  top('top'),
  center('center'),
  bottom('bottom'),
  rim('rim'),
  base('base');

  const EffectAnchor(this.wire);
  @override
  final String wire;
}

enum SpinAxis implements WireValue {
  x('x'),
  y('y'),
  z('z');

  const SpinAxis(this.wire);
  @override
  final String wire;
}

enum LightingPreset implements WireValue {
  warmStudio('warm_studio'),
  brightDaylight('bright_daylight'),
  darkMoody('dark_moody'),
  neon('neon');

  const LightingPreset(this.wire);
  @override
  final String wire;
}

enum Easing implements WireValue {
  linear('linear'),
  easeIn('ease_in'),
  easeOut('ease_out'),
  easeInOut('ease_in_out');

  const Easing(this.wire);
  @override
  final String wire;
}

/// Product categories that gate which presets and effects make sense.
enum ProductCategory implements WireValue {
  food('food'),
  drink('drink'),
  dessert('dessert'),
  side('side');

  const ProductCategory(this.wire);
  @override
  final String wire;
}

/// Effects that only make sense on some categories.
///
/// Used for advice, never for hard rejection — a sparkling dessert cocktail is
/// the user's call, not ours.
const Map<EffectType, Set<ProductCategory>> effectAffinity = {
  EffectType.steam: {ProductCategory.food, ProductCategory.side},
  EffectType.sizzle: {ProductCategory.food, ProductCategory.side},
  EffectType.bubbles: {ProductCategory.drink},
  EffectType.condensation: {ProductCategory.drink},
  EffectType.drip: {ProductCategory.dessert, ProductCategory.food},
  EffectType.droplets: {ProductCategory.drink, ProductCategory.food},
  EffectType.sparkle: {
    ProductCategory.food,
    ProductCategory.drink,
    ProductCategory.dessert,
    ProductCategory.side,
  },
};

/// Motions people ask for that need true mesh animation.
///
/// The architecture plan calls these out as not reliably solvable on arbitrary
/// AI-generated meshes. Naming them lets the validator answer "cheese pull
/// isn't supported yet" instead of a blank "unknown motion", which is the
/// difference between a user retrying and a user giving up.
const Map<String, String> knownUnsupportedMotions = {
  'cheese_pull': 'a cheese pull',
  'cheese-pull': 'a cheese pull',
  'cheesepull': 'a cheese pull',
  'melt': 'melting',
  'melting': 'melting',
  'pour': 'pouring liquid',
  'pouring': 'pouring liquid',
  'splash': 'a real liquid splash',
  'stack': 'the dish stacking or assembling itself',
  'unstack': 'the dish coming apart',
  'assemble': 'the dish stacking or assembling itself',
  'explode': 'an exploded view',
  'exploded': 'an exploded view',
  'slice': 'slicing',
  'cut': 'slicing',
  'bite': 'a bite being taken',
  'steam_rise': 'mesh-driven steam',
};
