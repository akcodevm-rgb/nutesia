import 'dart:convert';

import 'package:animation_spec/animation_spec.dart';
import 'package:test/test.dart';
import 'package:viewer_3d/viewer_config.dart';

AnimationSpec spec(Map<String, Object?> raw) =>
    AnimationSpecValidator.validate(raw).spec;

/// Pulls the embedded spec back out of the HTML, the way the JS runtime does.
Map<String, Object?> embeddedSpec(String html) {
  final m = RegExp(r'<script[^>]*>(.*)</script>', dotAll: true).firstMatch(html)!;
  return (jsonDecode(m.group(1)!) as Map).cast<String, Object?>();
}

void main() {
  group('turntable', () {
    test('a y-axis spin uses model-viewer auto-rotate', () {
      final c = ViewerConfig.fromSpec(spec({
        'motion': {'type': 'turntable', 'axis': 'y', 'speed': 0.5},
      }));
      expect(c.autoRotate, isTrue);
      expect(c.rotationPerSecond, '180deg');
    });

    test('an x-axis spin is left to the runtime', () {
      final c = ViewerConfig.fromSpec(spec({
        'motion': {'type': 'turntable', 'axis': 'x', 'speed': 0.5},
      }));
      expect(c.autoRotate, isFalse);
    });

    test('autoplay off waits for a tap before spinning', () {
      final c = ViewerConfig.fromSpec(spec({
        'motion': {'type': 'turntable', 'speed': 0.5},
        'autoplay': false,
      }));
      expect(c.autoRotate, isFalse);
    });

    test('non-turntable motions never enable auto-rotate', () {
      for (final t in ['none', 'float', 'zoom_in', 'tilt_reveal', 'bounce_in']) {
        final c = ViewerConfig.fromSpec(spec({'motion': t}));
        expect(c.autoRotate, isFalse, reason: t);
      }
    });
  });

  group('camera', () {
    test('the reference distance frames the model at 100%', () {
      final c = ViewerConfig.fromSpec(spec({
        'camera': {'distance': 1.4},
      }));
      expect(c.cameraOrbit, '0deg 72deg 100%');
    });

    test('distance scales the orbit radius', () {
      final c = ViewerConfig.fromSpec(spec({
        'camera': {'distance': 2.8},
      }));
      expect(c.cameraOrbit, endsWith('200%'));
    });

    test('fov and orbit controls pass straight through', () {
      final c = ViewerConfig.fromSpec(spec({
        'camera': {'fov': 42.5, 'orbitControls': false},
      }));
      expect(c.fieldOfView, '42.5deg');
      expect(c.cameraControls, isFalse);
    });

    test('delay becomes the auto-rotate delay in milliseconds', () {
      final c = ViewerConfig.fromSpec(spec({'delay': 1.5}));
      expect(c.autoRotateDelayMs, 1500);
    });
  });

  group('lighting', () {
    test('every preset has a look', () {
      for (final l in LightingPreset.values) {
        expect(lightingLooks[l], isNotNull, reason: l.wire);
      }
    });

    test('dark presets mark the spec tag dark so effects tone down', () {
      final moody = ViewerConfig.fromSpec(spec({'lighting': 'dark_moody'}));
      final warm = ViewerConfig.fromSpec(spec({'lighting': 'warm_studio'}));
      expect(moody.specHtml, contains('data-theme="dark"'));
      expect(warm.specHtml, contains('data-theme="light"'));
    });
  });

  group('luminance', () {
    test('matches the WCAG endpoints', () {
      expect(relativeLuminance(0xFF000000), 0);
      expect(relativeLuminance(0xFFFFFFFF), closeTo(1, 1e-9));
    });
  });

  group('embedded spec', () {
    test('is inert JSON, not an executable script', () {
      final html = ViewerConfig.fromSpec(AnimationSpec.fallback).specHtml;
      expect(html, contains('type="application/json"'));
      expect(html, contains('class="menu3d-spec"'));
    });

    test('round-trips through the validator unchanged', () {
      for (final preset in AnimationPresets.all) {
        final html = ViewerConfig.fromSpec(preset.spec).specHtml;
        final back = AnimationSpecValidator.validate(embeddedSpec(html));
        expect(back.isClean, isTrue, reason: preset.key);
        expect(back.spec, preset.spec, reason: preset.key);
      }
    });

    test('cannot close its own tag early', () {
      final html = specScriptTag(AnimationSpec.fallback);
      final body = html.substring(html.indexOf('>') + 1, html.lastIndexOf('<'));
      expect(body, isNot(contains('</')));
    });
  });
}
