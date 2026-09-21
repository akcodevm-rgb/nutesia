/// Numeric bounds and defaults for every tunable field in the spec.
///
/// Kept in one file because these are a *performance and taste contract*, not
/// arbitrary numbers: they cap what an LLM (or a hand-edited spec) can ask the
/// diner's phone to do. The renderer trusts that a validated spec sits inside
/// these bounds and does no clamping of its own.
library;

/// An inclusive numeric range with a default, used to clamp untrusted input.
class Range {
  const Range(this.min, this.max, this.defaultValue)
      : assert(min <= defaultValue && defaultValue <= max,
            'default must sit inside the range');

  final double min;
  final double max;
  final double defaultValue;

  bool contains(double v) => v >= min && v <= max;

  double clamp(double v) => v < min ? min : (v > max ? max : v);
}

/// Current spec schema version emitted by this package.
///
/// Bump on any breaking shape change. Older versions keep rendering: published
/// menus store the spec they were published with, so the viewer must go on
/// understanding every version it has ever emitted.
const int currentSpecVersion = 1;

/// The oldest schema version this package can still read.
const int minSupportedSpecVersion = 1;

class SpecLimits {
  const SpecLimits._();

  /// Turntable revolutions per second. The top end is already brisk; faster
  /// reads as a spinning prop rather than an appetising dish.
  static const speed = Range(0.0, 2.0, 0.4);

  /// Bob/sway travel as a fraction of the model's height.
  static const amplitude = Range(0.0, 0.25, 0.02);

  /// Seconds for one full cycle of a secondary motion.
  static const period = Range(0.2, 20.0, 3.0);

  /// Effect strength, normalised. The renderer maps this onto particle counts
  /// per device tier, so 1.0 does not mean the same absolute count everywhere.
  static const intensity = Range(0.0, 1.0, 0.5);

  /// Camera field of view in degrees. Below ~10 the model reads as flat;
  /// above ~90 the fisheye distortion makes food look wrong.
  static const fov = Range(10.0, 90.0, 35.0);

  /// Camera distance in model-height multiples.
  static const distance = Range(0.5, 10.0, 1.4);

  /// Seconds to wait before the animation starts.
  static const delay = Range(0.0, 10.0, 0.0);

  /// Seconds a one-shot intro motion runs for.
  static const duration = Range(0.1, 10.0, 1.2);

  /// Hard caps on list lengths. These are the diner-side frame budget: each
  /// extra effect is another particle system on a mid-range phone.
  static const int maxEffects = 4;
  static const int maxSecondaryMotions = 3;

  /// Defensive cap on how much raw JSON we will even walk.
  static const int maxRawKeys = 64;
}
