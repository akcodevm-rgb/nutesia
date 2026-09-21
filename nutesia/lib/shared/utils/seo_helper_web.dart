import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Web-specific implementation of the SEO landing page cleanup helper.
/// Locates the static HTML `#seo-landing` container and removes it from DOM
/// to allow Flutter CanvasKit / HTML renderer elements to take over.
void cleanSeoLandingPage() {
  try {
    final doc = globalContext['document'] as JSObject?;
    if (doc != null && !doc.isUndefinedOrNull) {
      final el = doc.callMethod('getElementById'.toJS, 'seo-landing'.toJS) as JSObject?;
      if (el != null && !el.isUndefinedOrNull) {
        el.callMethod('remove'.toJS);
      }
    }
  } catch (_) {}
}
