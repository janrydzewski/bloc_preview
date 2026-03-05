/// A zero-configuration BLoC state inspector with a built-in web dashboard.
///
/// Attach [BlocPreviewObserver] as your `Bloc.observer` to visualize state
/// changes, events, and errors in real time — directly in your browser.
///
/// ## Quick start
///
/// ```dart
/// import 'package:bloc_preview/bloc_preview.dart';
///
/// void main() {
///   Bloc.observer = BlocPreviewObserver();
///   // The dashboard is now available at http://localhost:4680
///   runApp(const MyApp());
/// }
/// ```
///
/// ## Configuration
///
/// Use [PreviewConfig] to customise the server port, host binding, or the
/// maximum number of events kept in the history buffer:
///
/// ```dart
/// Bloc.observer = BlocPreviewObserver(
///   config: PreviewConfig(
///     port: 9000,
///     host: '0.0.0.0',
///     maxEvents: 500,
///   ),
/// );
/// ```
///
/// ## State serialization
///
/// States and events are serialized automatically in three ways (tried in
/// order):
///
/// 1. If the object implements [JsonEncodable], its `toJson()` is called.
/// 2. If the object has a `toJson()` method (duck-typed), it is called.
/// 3. Otherwise the `toString()` output is parsed into a structured map.
library;

export 'src/bloc_preview_observer.dart';
export 'src/json_encodable.dart';
export 'src/preview_config.dart';
