/// Configuration for the [BlocPreviewObserver] web dashboard.
///
/// All parameters are optional and fall back to sensible defaults that work
/// out of the box for most Flutter projects.
///
/// ```dart
/// final config = PreviewConfig(
///   port: 9000,
///   host: '0.0.0.0',
///   maxEvents: 500,
/// );
/// ```
class PreviewConfig {
  /// Creates a new [PreviewConfig].
  ///
  /// * [port] — TCP port for the built-in HTTP / WebSocket server.
  ///   Defaults to `4680`.
  /// * [host] — Network interface to bind to. Use `'localhost'` to restrict
  ///   access to the local machine, or `'0.0.0.0'` to allow connections from
  ///   other devices on the same network. Defaults to `'localhost'`.
  /// * [maxEvents] — Maximum number of events kept in the history ring buffer.
  ///   Oldest events are discarded when this limit is exceeded.
  ///   Defaults to `1000`.
  const PreviewConfig({
    this.port = 4680,
    this.host = 'localhost',
    this.maxEvents = 1000,
  });

  /// TCP port the dashboard server listens on.
  final int port;

  /// Network interface the server binds to.
  final String host;

  /// Maximum number of events retained in the history buffer.
  final int maxEvents;
}
