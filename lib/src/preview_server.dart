import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:bloc_preview/src/dashboard.dart';
import 'package:bloc_preview/src/preview_config.dart';

/// Lightweight HTTP + WebSocket server that serves the preview dashboard and
/// broadcasts BLoC events to all connected browser clients.
///
/// This class is an implementation detail of [BlocPreviewObserver] and is not
/// intended to be used directly.
class PreviewServer {
  /// Creates a [PreviewServer] bound to the given [config].
  PreviewServer(this.config);

  /// The configuration for this server instance.
  final PreviewConfig config;

  HttpServer? _server;
  final Set<WebSocket> _sockets = {};

  /// Whether the server is currently listening for connections.
  bool get isRunning => _server != null;

  /// Starts the HTTP server and begins accepting connections.
  ///
  /// If the server is already running this method does nothing.
  Future<void> start() async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(config.host, config.port);
      dev.log(
        'bloc_preview dashboard: http://${config.host}:${config.port}',
        name: 'bloc_preview',
      );

      _server!.listen(_handleRequest);
    } catch (error) {
      dev.log(
        'bloc_preview failed to start server: $error',
        name: 'bloc_preview',
        level: 900,
      );
    }
  }

  /// Sends [payload] as a JSON-encoded string to every connected client.
  ///
  /// Clients that fail to receive the message are silently removed.
  void broadcast(Map<String, dynamic> payload) {
    final encoded = jsonEncode(payload);
    for (final socket in _sockets.toList()) {
      try {
        socket.add(encoded);
      } catch (_) {
        _sockets.remove(socket);
      }
    }
  }

  /// Sends a snapshot of the current state to a single newly-connected
  /// [socket].
  void sendSnapshot(
    WebSocket socket, {
    required Map<String, dynamic> states,
    required List<Map<String, dynamic>> log,
    required List<Map<String, dynamic>> lifecycles,
    required Map<String, double> frequencies,
    required Map<String, int> stateSizes,
  }) {
    try {
      socket.add(jsonEncode({
        'type': 'snapshot',
        'states': states,
        'log': log,
        'lifecycles': lifecycles,
        'frequencies': frequencies,
        'stateSizes': stateSizes,
      }));
    } catch (_) {
      _sockets.remove(socket);
    }
  }

  /// A callback invoked whenever a new WebSocket client connects.
  ///
  /// Set this from [BlocPreviewObserver] so the server can send the initial
  /// state snapshot on connect.
  void Function(WebSocket socket)? onClientConnected;

  /// Stops the server and closes all active WebSocket connections.
  Future<void> stop() async {
    for (final socket in _sockets) {
      await socket.close();
    }
    _sockets.clear();
    await _server?.close();
    _server = null;
  }

  // -- Private ---------------------------------------------------------------

  void _handleRequest(HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      _upgradeToWebSocket(request);
    } else {
      _serveDashboard(request);
    }
  }

  void _serveDashboard(HttpRequest request) {
    request.response
      ..headers.contentType = ContentType.html
      ..write(dashboardHtml)
      ..close();
  }

  Future<void> _upgradeToWebSocket(HttpRequest request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    _sockets.add(socket);
    onClientConnected?.call(socket);

    socket.listen(
      (_) {}, // We do not process incoming messages from the dashboard.
      onDone: () => _sockets.remove(socket),
      onError: (_) => _sockets.remove(socket),
    );
  }
}
