/// Schema, validator and presets for the 3D menu animation spec.
///
/// The animation a diner sees is *not* baked into the 3D mesh. It is this
/// small JSON document, interpreted by the viewer at render time. That split is
/// what makes animation edits instant and free while mesh generation stays
/// expensive and rare.
///
/// Typical use:
///
/// ```dart
/// final result = AnimationSpecValidator.validate(
///   jsonDecode(llmOutput),
///   category: ProductCategory.drink,
/// );
/// for (final d in result.diagnostics) showToUser(d.message);
/// render(result.spec); // always safe
/// ```
library animation_spec;

export 'src/diagnostics.dart';
export 'src/limits.dart' show Range, SpecLimits, currentSpecVersion, minSupportedSpecVersion;
export 'src/presets.dart';
export 'src/spec.dart';
export 'src/validator.dart';
export 'src/vocabulary.dart';
