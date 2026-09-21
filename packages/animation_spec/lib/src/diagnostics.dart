/// User-facing explanations of what the validator changed.
///
/// Every repair is reported. A spec that silently loses half the user's request
/// is worse than one that fails loudly, because the user re-runs an expensive
/// generation trying to work out why nothing happened.
library;

enum DiagnosticKind {
  /// A field or list entry was removed; it named something we cannot render.
  dropped,

  /// A number was outside its allowed range and was pulled to the nearest edge.
  clamped,

  /// A malformed or missing value was replaced with the default.
  repaired,

  /// Recognised as a real request, but needs capability we do not have yet.
  /// Distinct from [dropped] so the UI can say "not yet" rather than "invalid".
  unsupported,

  /// The spec is renderable as-is, but is probably not what the user wanted.
  advice,
}

/// One thing the validator changed or wants to flag.
class SpecDiagnostic {
  const SpecDiagnostic({
    required this.kind,
    required this.path,
    required this.message,
  });

  final DiagnosticKind kind;

  /// JSON pointer-ish location, e.g. `effects[1].intensity`.
  final String path;

  /// Written for a restaurant owner, not an engineer. This string is shown
  /// verbatim in the studio UI.
  final String message;

  /// True when the user asked for something real that we cannot do yet, as
  /// opposed to input that was simply malformed.
  bool get isNotYetSupported => kind == DiagnosticKind.unsupported;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'path': path,
        'message': message,
      };

  @override
  String toString() => '[${kind.name}] $path: $message';
}

/// Collects diagnostics while walking untrusted JSON.
class DiagnosticSink {
  final List<SpecDiagnostic> _items = [];

  List<SpecDiagnostic> get items => List.unmodifiable(_items);

  void add(DiagnosticKind kind, String path, String message) {
    _items.add(SpecDiagnostic(kind: kind, path: path, message: message));
  }

  void dropped(String path, String message) =>
      add(DiagnosticKind.dropped, path, message);

  void clamped(String path, String message) =>
      add(DiagnosticKind.clamped, path, message);

  void repaired(String path, String message) =>
      add(DiagnosticKind.repaired, path, message);

  void unsupported(String path, String message) =>
      add(DiagnosticKind.unsupported, path, message);

  void advice(String path, String message) =>
      add(DiagnosticKind.advice, path, message);
}
