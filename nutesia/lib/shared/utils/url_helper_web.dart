import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web-specific implementation of URL launcher.
void launchUrlString(String url) {
  try {
    web.window.open(url, '_blank');
  } catch (e) {
    web.console.error('Failed to launch URL: $url. Error: $e'.toJS);
  }
}
