import 'dart:ui' show Color;

import 'package:animation_spec/animation_spec.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'viewer_config.dart';

/// Asset path of the effects runtime, as seen from any app that depends on
/// this package.
const effectsRuntimeAsset = 'packages/viewer_3d/assets/menu3d_effects.js';

/// Shows one menu item's 3D model, animated according to [spec].
///
/// **Web setup.** Flutter web inserts this view with `innerHTML`, which never
/// runs `<script>` tags, so the host page must load both scripts itself. Add
/// to `web/index.html`:
///
/// ```html
/// <script type="module" src="assets/packages/model_viewer_plus/assets/model-viewer.min.js" defer></script>
/// <script src="assets/packages/viewer_3d/assets/menu3d_effects.js" defer></script>
/// ```
///
/// On iOS and Android each viewer is its own WebView and the runtime is
/// injected automatically. WebViews are heavy, so show one viewer at a time
/// (a detail sheet) rather than one per list card.
class MenuItemViewer extends StatelessWidget {
  const MenuItemViewer({
    super.key,
    required this.src,
    required this.spec,
    this.iosSrc,
    this.poster,
    this.alt,
    this.ar = false,
  });

  /// GLB URL or `assets/...` path.
  final String src;

  /// Validated spec. Construct it through `AnimationSpecValidator`; this
  /// widget trusts every value in it.
  final AnimationSpec spec;

  /// USDZ for iOS AR Quick Look.
  final String? iosSrc;

  /// Shown until the model loads. The plan requires a poster first, always.
  final String? poster;

  /// Accessible description of the dish.
  final String? alt;

  final bool ar;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _build(null);
    return FutureBuilder<String>(
      future: _runtimeSource(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.expand();
        return _build(snap.data);
      },
    );
  }

  Widget _build(String? runtimeJs) {
    final c = ViewerConfig.fromSpec(spec);
    return ModelViewer(
      // model_viewer_plus builds its HTML once per State, so a changed spec
      // (e.g. live preview in the studio) needs a fresh element.
      key: ValueKey(Object.hash(src, spec)),
      src: src,
      iosSrc: iosSrc,
      poster: poster,
      alt: alt,
      loading: Loading.eager,
      reveal: Reveal.auto,
      ar: ar,
      cameraControls: c.cameraControls,
      disablePan: true,
      // Vertical swipes scroll the menu instead of being eaten by the model.
      touchAction: TouchAction.panY,
      interactionPrompt: InteractionPrompt.none,
      autoRotate: c.autoRotate,
      rotationPerSecond: c.rotationPerSecond,
      autoRotateDelay: c.autoRotateDelayMs,
      cameraOrbit: c.cameraOrbit,
      fieldOfView: c.fieldOfView,
      exposure: c.look.exposure,
      shadowIntensity: c.look.shadowIntensity,
      backgroundColor: Color(c.look.background),
      innerModelViewerHtml: c.specHtml,
      relatedJs: runtimeJs,
      debugLogging: false,
    );
  }

  static Future<String>? _runtimeCache;

  static Future<String> _runtimeSource() =>
      _runtimeCache ??= rootBundle.loadString(effectsRuntimeAsset);
}
