/// The validated animation spec.
///
/// An [AnimationSpec] instance is a *guarantee*: every enum is one the renderer
/// knows, every number sits inside [SpecLimits], and every list is within its
/// cap. Instances are only ever produced by the validator, never by parsing
/// raw JSON directly, so the renderer can skip defensive checks entirely.
library;

import 'limits.dart';
import 'vocabulary.dart';

/// Primary motion of the whole model.
class Motion {
  const Motion({
    required this.type,
    required this.axis,
    required this.speed,
    required this.duration,
    required this.easing,
  });

  const Motion.still()
      : type = MotionType.none,
        axis = SpinAxis.y,
        speed = 0.0,
        duration = 1.2,
        easing = Easing.easeInOut;

  final MotionType type;

  /// Axis of rotation. Only meaningful for [MotionType.turntable] and
  /// [MotionType.tiltReveal]; carried regardless so switching type in the
  /// studio does not lose the user's choice.
  final SpinAxis axis;

  /// Revolutions per second for continuous motion.
  final double speed;

  /// Runtime of one-shot intro motions (zoomIn, tiltReveal, bounceIn).
  final double duration;

  final Easing easing;

  /// Whether this motion plays once and stops, rather than running forever.
  bool get isOneShot => const {
        MotionType.zoomIn,
        MotionType.tiltReveal,
        MotionType.bounceIn,
      }.contains(type);

  Motion copyWith({
    MotionType? type,
    SpinAxis? axis,
    double? speed,
    double? duration,
    Easing? easing,
  }) =>
      Motion(
        type: type ?? this.type,
        axis: axis ?? this.axis,
        speed: speed ?? this.speed,
        duration: duration ?? this.duration,
        easing: easing ?? this.easing,
      );

  Map<String, Object?> toJson() => {
        'type': type.wire,
        'axis': axis.wire,
        'speed': speed,
        'duration': duration,
        'easing': easing.wire,
      };

  @override
  bool operator ==(Object other) =>
      other is Motion &&
      other.type == type &&
      other.axis == axis &&
      other.speed == speed &&
      other.duration == duration &&
      other.easing == easing;

  @override
  int get hashCode => Object.hash(type, axis, speed, duration, easing);
}

/// Motion layered on top of the primary one, e.g. a gentle bob while spinning.
class SecondaryMotion {
  const SecondaryMotion({
    required this.type,
    required this.amplitude,
    required this.period,
  });

  final SecondaryMotionType type;

  /// Travel as a fraction of model height.
  final double amplitude;

  /// Seconds per cycle.
  final double period;

  SecondaryMotion copyWith({
    SecondaryMotionType? type,
    double? amplitude,
    double? period,
  }) =>
      SecondaryMotion(
        type: type ?? this.type,
        amplitude: amplitude ?? this.amplitude,
        period: period ?? this.period,
      );

  Map<String, Object?> toJson() => {
        'type': type.wire,
        'amplitude': amplitude,
        'period': period,
      };

  @override
  bool operator ==(Object other) =>
      other is SecondaryMotion &&
      other.type == type &&
      other.amplitude == amplitude &&
      other.period == period;

  @override
  int get hashCode => Object.hash(type, amplitude, period);
}

/// A particle or shader effect drawn around the model.
class Effect {
  const Effect({
    required this.type,
    required this.anchor,
    required this.intensity,
  });

  final EffectType type;
  final EffectAnchor anchor;

  /// Normalised strength; the renderer scales this by device tier.
  final double intensity;

  Effect copyWith({EffectType? type, EffectAnchor? anchor, double? intensity}) =>
      Effect(
        type: type ?? this.type,
        anchor: anchor ?? this.anchor,
        intensity: intensity ?? this.intensity,
      );

  Map<String, Object?> toJson() => {
        'type': type.wire,
        'anchor': anchor.wire,
        'intensity': intensity,
      };

  @override
  bool operator ==(Object other) =>
      other is Effect &&
      other.type == type &&
      other.anchor == anchor &&
      other.intensity == intensity;

  @override
  int get hashCode => Object.hash(type, anchor, intensity);
}

class CameraSpec {
  const CameraSpec({
    required this.fov,
    required this.distance,
    required this.orbitControls,
  });

  const CameraSpec.standard()
      : fov = 35.0,
        distance = 1.4,
        orbitControls = true;

  /// Field of view in degrees.
  final double fov;

  /// Distance from the model, in model-height multiples.
  final double distance;

  /// Whether the diner can drag to rotate. Turning this off is a deliberate
  /// choice for menus that want a fixed hero shot.
  final bool orbitControls;

  CameraSpec copyWith({double? fov, double? distance, bool? orbitControls}) =>
      CameraSpec(
        fov: fov ?? this.fov,
        distance: distance ?? this.distance,
        orbitControls: orbitControls ?? this.orbitControls,
      );

  Map<String, Object?> toJson() => {
        'fov': fov,
        'distance': distance,
        // camelCase here matches the wire format in the architecture plan.
        // The validator also accepts `orbit_controls` when reading.
        'orbitControls': orbitControls,
      };

  @override
  bool operator ==(Object other) =>
      other is CameraSpec &&
      other.fov == fov &&
      other.distance == distance &&
      other.orbitControls == orbitControls;

  @override
  int get hashCode => Object.hash(fov, distance, orbitControls);
}

/// A complete, renderable animation.
class AnimationSpec {
  const AnimationSpec({
    required this.version,
    required this.motion,
    required this.secondary,
    required this.effects,
    required this.camera,
    required this.lighting,
    required this.loop,
    required this.autoplay,
    required this.delay,
  });

  /// The spec used when there is nothing else to fall back to.
  ///
  /// A slow turntable in warm studio light flatters almost any dish, so a
  /// totally unusable input still yields a menu item that looks intentional.
  static const AnimationSpec fallback = AnimationSpec(
    version: currentSpecVersion,
    motion: Motion(
      type: MotionType.turntable,
      axis: SpinAxis.y,
      speed: 0.4,
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
  );

  final int version;
  final Motion motion;
  final List<SecondaryMotion> secondary;
  final List<Effect> effects;
  final CameraSpec camera;
  final LightingPreset lighting;
  final bool loop;
  final bool autoplay;

  /// Seconds before the animation begins.
  final double delay;

  /// True when nothing moves and no effect draws, so the viewer can skip the
  /// render loop entirely and leave the poster up.
  bool get isStatic =>
      motion.type == MotionType.none && secondary.isEmpty && effects.isEmpty;

  AnimationSpec copyWith({
    int? version,
    Motion? motion,
    List<SecondaryMotion>? secondary,
    List<Effect>? effects,
    CameraSpec? camera,
    LightingPreset? lighting,
    bool? loop,
    bool? autoplay,
    double? delay,
  }) =>
      AnimationSpec(
        version: version ?? this.version,
        motion: motion ?? this.motion,
        secondary: secondary ?? this.secondary,
        effects: effects ?? this.effects,
        camera: camera ?? this.camera,
        lighting: lighting ?? this.lighting,
        loop: loop ?? this.loop,
        autoplay: autoplay ?? this.autoplay,
        delay: delay ?? this.delay,
      );

  Map<String, Object?> toJson() => {
        'version': version,
        'motion': motion.toJson(),
        'secondary': [for (final s in secondary) s.toJson()],
        'effects': [for (final e in effects) e.toJson()],
        'camera': camera.toJson(),
        'lighting': lighting.wire,
        'loop': loop,
        'autoplay': autoplay,
        'delay': delay,
      };

  @override
  bool operator ==(Object other) {
    if (other is! AnimationSpec) return false;
    if (other.secondary.length != secondary.length) return false;
    if (other.effects.length != effects.length) return false;
    for (var i = 0; i < secondary.length; i++) {
      if (other.secondary[i] != secondary[i]) return false;
    }
    for (var i = 0; i < effects.length; i++) {
      if (other.effects[i] != effects[i]) return false;
    }
    return other.version == version &&
        other.motion == motion &&
        other.camera == camera &&
        other.lighting == lighting &&
        other.loop == loop &&
        other.autoplay == autoplay &&
        other.delay == delay;
  }

  @override
  int get hashCode => Object.hash(
        version,
        motion,
        Object.hashAll(secondary),
        Object.hashAll(effects),
        camera,
        lighting,
        loop,
        autoplay,
        delay,
      );
}
