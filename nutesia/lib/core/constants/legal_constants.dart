/// Where the legal pages live and how users reach support.
///
/// The pages are in `web/` (privacy.html, terms.html, delete-account.html) and
/// are published with the web build on Firebase Hosting. Override the base URL
/// at build time if they're hosted elsewhere:
///   flutter build appbundle --dart-define=LEGAL_BASE_URL=https://example.com
class LegalConstants {
  static const String baseUrl =
      String.fromEnvironment('LEGAL_BASE_URL', defaultValue: 'https://nutesia.web.app');

  static const String privacyUrl = '$baseUrl/privacy.html';
  static const String termsUrl = '$baseUrl/terms.html';

  /// Google Play's "delete your account" link for the store listing.
  static const String deleteAccountUrl = '$baseUrl/delete-account.html';

  /// Support address. Empty until a working mailbox exists: the app hides
  /// "Contact Support" while it's empty. Also fill in the matching
  /// placeholder in web/privacy.html, terms.html and delete-account.html.
  static const String supportEmail = '';
}
