import 'package:bloc_preview/src/json_encodable.dart';
import 'package:bloc_preview/src/object_parser.dart';

/// Converts arbitrary Dart objects into JSON-compatible values suitable for
/// transmission over WebSocket to the preview dashboard.
///
/// The conversion follows a three-step strategy:
///
/// 1. **[JsonEncodable]** — if the object implements the interface, its
///    `toJson()` method is called directly.
/// 2. **Duck-typed `toJson()`** — if the object exposes a `toJson()` method
///    (common with code-gen packages like `json_serializable`), it is invoked
///    via dynamic dispatch.
/// 3. **`toString()` parsing** — as a last resort the object's string
///    representation is fed into [parseObjectNotation], which attempts to
///    recover a structured map from Dart's default `toString()` format.
class StateConverter {
  /// Creates a [StateConverter].
  const StateConverter();

  /// Converts [value] into a JSON-compatible structure.
  ///
  /// Returns `null` when [value] is `null`.  Primitive types (`int`, `double`,
  /// `bool`, `String`) pass through unchanged.  Complex objects are serialized
  /// using the strategy described in the class documentation.
  dynamic convert(Object? value) {
    if (value == null) return null;
    if (value is num || value is bool || value is String) return value;

    // 1. Explicit interface.
    if (value is JsonEncodable) return value.toJson();

    // 2. Duck-typed toJson().
    try {
      // ignore: avoid_dynamic_calls
      return (value as dynamic).toJson();
    } catch (_) {
      // Not available — fall through.
    }

    // 3. Parse toString() output.
    return parseObjectNotation(value.toString());
  }
}
