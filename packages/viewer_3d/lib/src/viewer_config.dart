/// Translates a validated [AnimationSpec] into `<model-viewer>` settings.
///
/// Kept free of widgets so the mapping is unit-testable. The split of
/// responsibility is:
///
/// * **model-viewer attributes** handle what model-viewer does natively and
///   well: y-axis turntable, camera framing, drag-to-orbit, exposure, shadows.
/// * **the effects runtime** (`assets/menu3d_effects.js`) handles everything
///   else: particle effects, float/sway/pulse, intro motions, and spinning on
///   axes other than y. It reads the spec from a JSON block embedded in the
///   element.
library;

import 'dart:convert';
import 'dart:ui' show Color;

import 'package:animation_spec/animation_spec.dart';

/// Look and exposure for each lighting preset.
class LightingLook {
  const LightingLook({
    required this.exposure,
    required this.shadowIntensity,
    required this.background,
  });

  final double exposure;
  final double shadowIntensity;

  /// Backdrop behind the model. Most of the preset's mood comes from here,
  /// since model-viewer has no coloured-light API.
  final Color background;
}

const Map<LightingPreset, LightingLook> lightingLooks = {
  LightingPreset.warmStudio: LightingLook(
    exposure: 1.05,
    shadowIntensity: 1.0,
    background: Color(0xFFF6EBDD),
  ),
  LightingPreset.brightDaylight: LightingLook(
    exposure: 1.3,
    shadowIntensity: 0.6,
    background: Color(0xFFEAF4FB),
  ),
  LightingPreset.darkMoody: LightingLook(
    exposure: 0.75,
    shadowIntensity: 1.6,
    background: Color(0xFF1B1714),
  ),
  LightingPreset.neon: LightingLook(
    exposure: 0.95,
    shadowIntensity: 0.8,
    background: Color(0xFF1A1033),
  ),
};

/// Camera elevation for the default framing. Slightly above the table, the
/// angle a diner actually sees a plate from.
const double _cameraPhiDeg = 72;

/// Distance the spec treats as "normal". model-viewer frames the model itself
/// at radius 100%, so spec distance is expressed relative to this.
const double _referenceDistance = 1.4;

class ViewerConfig {
  const ViewerConfig({
    required this.autoRotate,
    required this.rotationPerSecond,
    required this.autoRotateDelayMs,
    required this.cameraOrbit,
    required this.fieldOfView,
    required this.cameraControls,
    required this.look,
    required this.specHtml,
  });

  factory ViewerConfig.fromSpec(AnimationSpec spec) {
    // model-viewer's auto-rotate only spins about y. Other axes and every
    // one-shot intro go to the JS runtime instead, so the two never fight
    // over the model's orientation.
    final nativeSpin = spec.motion.type == MotionType.turntable &&
        spec.motion.axis == SpinAxis.y &&
        spec.motion.speed > 0 &&
        spec.autoplay;

    final radiusPct = (spec.camera.distance / _referenceDistance * 100).round();
    final look = lightingLooks[spec.lighting]!;

    return ViewerConfig(
      autoRotate: nativeSpin,
      rotationPerSecond: '${_trim(spec.motion.speed * 360)}deg',
      autoRotateDelayMs: (spec.delay * 1000).round(),
      cameraOrbit: '0deg ${_trim(_cameraPhiDeg)}deg $radiusPct%',
      fieldOfView: '${_trim(spec.camera.fov)}deg',
      cameraControls: spec.camera.orbitControls,
      look: look,
      specHtml: specScriptTag(
        spec,
        darkBackground: look.background.computeLuminance() < 0.3,
      ),
    );
  }

  final bool autoRotate;
  final String rotationPerSecond;
  final int autoRotateDelayMs;
  final String cameraOrbit;
  final String fieldOfView;
  final bool cameraControls;
  final LightingLook look;

  /// Inert JSON block placed inside `<model-viewer>` for the runtime to read.
  final String specHtml;
}

/// Embeds [spec] as a non-executing JSON script tag.
///
/// `type="application/json"` is data, not code, so it survives being inserted
/// with `innerHTML` on web where executable scripts are silently skipped.
/// The spec only ever holds whitelisted names and numbers, but `</` is escaped
/// anyway so no future field can close the tag early.
///
/// [darkBackground] lets the runtime tone effects down on dark backdrops,
/// where full-strength white steam reads as fog.
String specScriptTag(AnimationSpec spec, {bool darkBackground = false}) {
  final json = jsonEncode(spec.toJson()).replaceAll('</', r'<\/');
  final theme = darkBackground ? 'dark' : 'light';
  return '<script type="application/json" class="menu3d-spec" '
      'data-theme="$theme">$json</script>';
}

String _trim(double v) {
  final s = v.toStringAsFixed(2);
  if (s.endsWith('.00')) return v.toStringAsFixed(0);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}
