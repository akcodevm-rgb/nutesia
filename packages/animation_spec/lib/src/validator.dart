/// Turns untrusted JSON into a guaranteed-renderable [AnimationSpec].
///
/// This is the trust boundary between the LLM (which sees user-authored prompt
/// text) and the diner's renderer. Three rules hold throughout:
///
/// 1. **Never throw.** Any input, including deliberate garbage, yields a spec.
/// 2. **Never invent capability.** Unknown names are dropped, not guessed at.
/// 3. **Always explain.** Every change produces a diagnostic the user can read.
///
/// The validator is deliberately lenient about *shape* (a bare string where a
/// map was expected, a number written as `"0.4"`) because those are the ways a
/// language model drifts, and rejecting them wastes a paid generation. It is
/// strict about *vocabulary and range*, because those are what protect the
/// phone at the other end.
library;

import 'diagnostics.dart';
import 'limits.dart';
import 'spec.dart';
import 'vocabulary.dart';

/// The outcome of validating one candidate spec.
class SpecValidation {
  const SpecValidation({required this.spec, required this.diagnostics});

  /// Always renderable, even when [diagnostics] is long.
  final AnimationSpec spec;

  final List<SpecDiagnostic> diagnostics;

  /// True when the input needed no repair at all.
  bool get isClean => diagnostics.isEmpty;

  /// Things the user asked for that are real, but that we cannot do yet.
  /// The studio surfaces these differently from malformed input.
  List<SpecDiagnostic> get notYetSupported =>
      diagnostics.where((d) => d.isNotYetSupported).toList();

  /// Short summary for the studio UI, or null when nothing changed.
  String? get summary {
    if (diagnostics.isEmpty) return null;
    final unsupported = notYetSupported;
    if (unsupported.isNotEmpty) return unsupported.first.message;
    return diagnostics.first.message;
  }
}

abstract final class AnimationSpecValidator {
  /// Validates [raw], repairing whatever it can.
  ///
  /// [category] is optional product context; when given, effects that make no
  /// sense for it (bubbles on a steak) produce advice diagnostics rather than
  /// being removed. The user stays in charge of taste.
  static SpecValidation validate(Object? raw, {ProductCategory? category}) {
    final sink = DiagnosticSink();

    if (raw is! Map) {
      sink.repaired(
        r'$',
        'We could not read that animation, so the default slow spin was used.',
      );
      return SpecValidation(
        spec: AnimationSpec.fallback,
        diagnostics: sink.items,
      );
    }

    final map = _stringKeyed(raw);

    if (map.length > SpecLimits.maxRawKeys) {
      sink.dropped(
        r'$',
        'That animation had far more settings than we support, so the extra '
            'ones were ignored.',
      );
    }

    final version = _readVersion(map['version'], sink);
    final motion = _readMotion(map['motion'], sink);
    final secondary = _readSecondary(map['secondary'], sink);
    final effects = _readEffects(map['effects'], sink, category);
    final camera = _readCamera(map['camera'], sink);

    final lighting = _readEnum(
      map['lighting'],
      LightingPreset.values,
      LightingPreset.warmStudio,
      'lighting',
      'Lighting style',
      sink,
    );

    final loop = _readBool(map['loop'], true, 'loop', 'Looping', sink);
    final autoplay =
        _readBool(map['autoplay'], true, 'autoplay', 'Autoplay', sink);
    final delay =
        _readNum(map['delay'], SpecLimits.delay, 'delay', 'Start delay', sink);

    return SpecValidation(
      spec: AnimationSpec(
        version: version,
        motion: motion,
        secondary: secondary,
        effects: effects,
        camera: camera,
        lighting: lighting,
        loop: loop,
        autoplay: autoplay,
        delay: delay,
      ),
      diagnostics: sink.items,
    );
  }

  /// Convenience for callers that only want the spec.
  static AnimationSpec parseOrFallback(Object? raw,
          {ProductCategory? category}) =>
      validate(raw, category: category).spec;

  // ---------------------------------------------------------------- sections

  static int _readVersion(Object? raw, DiagnosticSink sink) {
    final n = _number(raw);
    if (n == null) return currentSpecVersion;
    final v = n.round();

    if (v < minSupportedSpecVersion) {
      sink.repaired(
        'version',
        'That animation was saved in an old format we no longer read, so the '
            'default spin was used.',
      );
      return currentSpecVersion;
    }
    if (v > currentSpecVersion) {
      // Forward compatibility: read what we recognise rather than refusing.
      // A menu published by a newer deploy must not go blank on an older one.
      sink.advice(
        'version',
        'This animation was made with a newer version of the studio. Anything '
            'we did not recognise has been left out.',
      );
      return currentSpecVersion;
    }
    return v;
  }

  static Motion _readMotion(Object? raw, DiagnosticSink sink) {
    const fallback = Motion(
      type: MotionType.turntable,
      axis: SpinAxis.y,
      speed: 0.4,
      duration: 1.2,
      easing: Easing.linear,
    );

    if (raw == null) return fallback;

    // Models often emit `"motion": "turntable"` instead of an object.
    final map = raw is Map
        ? _stringKeyed(raw)
        : (raw is String ? <String, Object?>{'type': raw} : null);

    if (map == null) {
      sink.repaired('motion', 'We could not read the movement, so the model '
          'spins slowly instead.');
      return fallback;
    }

    final type = parseWire(MotionType.values, map['type']);
    if (type == null) {
      _reportUnknownMotion(map['type'], sink);
      return fallback;
    }

    final axis = _readEnum(
      map['axis'],
      SpinAxis.values,
      SpinAxis.y,
      'motion.axis',
      'Spin axis',
      sink,
    );

    return Motion(
      type: type,
      axis: axis,
      speed: _readNum(
          map['speed'], SpecLimits.speed, 'motion.speed', 'Spin speed', sink),
      duration: _readNum(map['duration'], SpecLimits.duration,
          'motion.duration', 'Animation length', sink),
      easing: _readEnum(
        map['easing'],
        Easing.values,
        Easing.linear,
        'motion.easing',
        'Easing',
        sink,
      ),
    );
  }

  /// Distinguishes "we have never heard of this" from "we know exactly what
  /// you mean and cannot do it yet". The second message keeps users from
  /// burning credits re-running a generation that was never going to work.
  static void _reportUnknownMotion(Object? rawType, DiagnosticSink sink) {
    if (rawType is String) {
      final key = rawType.trim().toLowerCase().replaceAll(' ', '_');
      final human = knownUnsupportedMotions[key];
      if (human != null) {
        sink.unsupported(
          'motion.type',
          'Animating $human is not supported yet, so the model spins slowly '
              'instead. Effects like steam and sparkle do work.',
        );
        return;
      }
    }
    sink.dropped(
      'motion.type',
      'We do not recognise that movement, so the model spins slowly instead.',
    );
  }

  static List<SecondaryMotion> _readSecondary(
      Object? raw, DiagnosticSink sink) {
    if (raw == null) return const [];
    if (raw is! List) {
      sink.dropped('secondary',
          'We could not read the extra movement, so it was left out.');
      return const [];
    }

    final out = <SecondaryMotion>[];
    final seen = <SecondaryMotionType>{};

    for (var i = 0; i < raw.length; i++) {
      final path = 'secondary[$i]';
      if (out.length >= SpecLimits.maxSecondaryMotions) {
        sink.dropped(
          path,
          'Only ${SpecLimits.maxSecondaryMotions} extra movements can run at '
              'once, so the rest were left out.',
        );
        break;
      }

      final entry = raw[i];
      final map = entry is Map
          ? _stringKeyed(entry)
          : (entry is String ? <String, Object?>{'type': entry} : null);
      if (map == null) {
        sink.dropped(path, 'One extra movement could not be read and was '
            'left out.');
        continue;
      }

      final type = parseWire(SecondaryMotionType.values, map['type']);
      if (type == null) {
        _reportUnknownSecondary(map['type'], path, sink);
        continue;
      }
      if (!seen.add(type)) {
        sink.dropped(path,
            'The "${type.wire}" movement was listed twice, so one was removed.');
        continue;
      }

      out.add(SecondaryMotion(
        type: type,
        amplitude: _readNum(map['amplitude'], SpecLimits.amplitude,
            '$path.amplitude', 'Movement size', sink),
        period: _readNum(
            map['period'], SpecLimits.period, '$path.period', 'Cycle time',
            sink),
      ));
    }
    return List.unmodifiable(out);
  }

  static void _reportUnknownSecondary(
      Object? rawType, String path, DiagnosticSink sink) {
    if (rawType is String) {
      final key = rawType.trim().toLowerCase().replaceAll(' ', '_');
      final human = knownUnsupportedMotions[key];
      if (human != null) {
        sink.unsupported(
            '$path.type', 'Animating $human is not supported yet, so it was '
                'left out.');
        return;
      }
    }
    sink.dropped('$path.type',
        'We do not recognise that extra movement, so it was left out.');
  }

  static List<Effect> _readEffects(
      Object? raw, DiagnosticSink sink, ProductCategory? category) {
    if (raw == null) return const [];
    if (raw is! List) {
      sink.dropped(
          'effects', 'We could not read the effects, so none were applied.');
      return const [];
    }

    final out = <Effect>[];
    final seen = <EffectType>{};

    for (var i = 0; i < raw.length; i++) {
      final path = 'effects[$i]';
      if (out.length >= SpecLimits.maxEffects) {
        sink.dropped(
          path,
          'Only ${SpecLimits.maxEffects} effects can run at once, so the rest '
              'were left out to keep the menu smooth on phones.',
        );
        break;
      }

      final entry = raw[i];
      final map = entry is Map
          ? _stringKeyed(entry)
          : (entry is String ? <String, Object?>{'type': entry} : null);
      if (map == null) {
        sink.dropped(path, 'One effect could not be read and was left out.');
        continue;
      }

      final type = parseWire(EffectType.values, map['type']);
      if (type == null) {
        _reportUnknownEffect(map['type'], path, sink);
        continue;
      }
      if (!seen.add(type)) {
        sink.dropped(path,
            'The "${type.wire}" effect was listed twice, so one was removed.');
        continue;
      }

      if (category != null) {
        final fits = effectAffinity[type];
        if (fits != null && !fits.contains(category)) {
          sink.advice(
            '$path.type',
            'The "${type.wire}" effect is unusual on a ${category.wire} item. '
                'It will still play if you want it.',
          );
        }
      }

      out.add(Effect(
        type: type,
        anchor: _readEnum(
          map['anchor'],
          EffectAnchor.values,
          _defaultAnchor(type),
          '$path.anchor',
          'Effect position',
          sink,
        ),
        intensity: _readNum(map['intensity'], SpecLimits.intensity,
            '$path.intensity', 'Effect strength', sink),
      ));
    }
    return List.unmodifiable(out);
  }

  static void _reportUnknownEffect(
      Object? rawType, String path, DiagnosticSink sink) {
    if (rawType is String) {
      final key = rawType.trim().toLowerCase().replaceAll(' ', '_');
      final human = knownUnsupportedMotions[key];
      if (human != null) {
        sink.unsupported(
          '$path.type',
          'Showing $human is not supported yet, so that effect was left out.',
        );
        return;
      }
    }
    sink.dropped(
        '$path.type', 'We do not have that effect yet, so it was left out.');
  }

  /// Where each effect naturally belongs, so a spec that omits `anchor` still
  /// looks right: steam rises off the top, bubbles start at the base.
  static EffectAnchor _defaultAnchor(EffectType type) => switch (type) {
        EffectType.steam => EffectAnchor.top,
        EffectType.sparkle => EffectAnchor.center,
        EffectType.sizzle => EffectAnchor.bottom,
        EffectType.bubbles => EffectAnchor.base,
        EffectType.condensation => EffectAnchor.rim,
        EffectType.droplets => EffectAnchor.rim,
        EffectType.drip => EffectAnchor.top,
      };

  static CameraSpec _readCamera(Object? raw, DiagnosticSink sink) {
    if (raw == null) return const CameraSpec.standard();
    if (raw is! Map) {
      sink.repaired('camera',
          'We could not read the camera settings, so the standard view '
              'was used.');
      return const CameraSpec.standard();
    }
    final map = _stringKeyed(raw);
    return CameraSpec(
      fov: _readNum(map['fov'], SpecLimits.fov, 'camera.fov', 'Zoom', sink),
      distance: _readNum(map['distance'], SpecLimits.distance,
          'camera.distance', 'Camera distance', sink),
      // Accept both spellings: the wire format is camelCase, but models
      // frequently snake_case every key for consistency.
      orbitControls: _readBool(
        map['orbitControls'] ?? map['orbit_controls'],
        true,
        'camera.orbitControls',
        'Drag to rotate',
        sink,
      ),
    );
  }

  // ----------------------------------------------------------------- scalars

  /// Reads a number, clamping into [range] and reporting what it did.
  ///
  /// An absent value is normal and silent; a *present but unreadable* one is
  /// worth telling the user about, because they asked for something.
  static double _readNum(Object? raw, Range range, String path, String label,
      DiagnosticSink sink) {
    if (raw == null) return range.defaultValue;

    final n = _number(raw);
    if (n == null) {
      sink.repaired(
          path, '$label was not a number, so the usual value was used.');
      return range.defaultValue;
    }
    if (!range.contains(n)) {
      final clamped = range.clamp(n);
      sink.clamped(
        path,
        '$label was adjusted to ${_fmt(clamped)} '
            '(it must be between ${_fmt(range.min)} and ${_fmt(range.max)}).',
      );
      return clamped;
    }
    return n;
  }

  static T _readEnum<T extends WireValue>(Object? raw, List<T> values,
      T fallback, String path, String label, DiagnosticSink sink) {
    if (raw == null) return fallback;
    final parsed = parseWire(values, raw);
    if (parsed == null) {
      sink.dropped(
        path,
        'We do not recognise that $label, so "${fallback.wire}" was used.',
      );
      return fallback;
    }
    return parsed;
  }

  static bool _readBool(Object? raw, bool fallback, String path, String label,
      DiagnosticSink sink) {
    if (raw == null) return fallback;
    if (raw is bool) return raw;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      if (s == 'true' || s == 'yes' || s == '1') return true;
      if (s == 'false' || s == 'no' || s == '0') return false;
    }
    if (raw is num) return raw != 0;
    sink.repaired(path, '$label was not a yes/no value, so the usual setting '
        'was used.');
    return fallback;
  }

  // ------------------------------------------------------------------ helpers

  /// Rejects NaN and infinity, which survive a `num` cast but would poison
  /// every transform they touch downstream.
  static double? _number(Object? v) {
    if (v is num) {
      final d = v.toDouble();
      return d.isFinite ? d : null;
    }
    if (v is String) {
      final parsed = num.tryParse(v.trim());
      if (parsed == null) return null;
      final d = parsed.toDouble();
      return d.isFinite ? d : null;
    }
    return null;
  }

  static Map<String, Object?> _stringKeyed(Map raw) {
    final out = <String, Object?>{};
    for (final entry in raw.entries) {
      final k = entry.key;
      if (k is String) out[k] = entry.value;
    }
    return out;
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? v.toStringAsFixed(0) : s;
  }
}
