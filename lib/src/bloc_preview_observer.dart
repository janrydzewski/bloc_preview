// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_preview/src/preview_config.dart';
import 'package:bloc_preview/src/preview_server.dart';
import 'package:bloc_preview/src/state_converter.dart';

/// A [BlocObserver] that launches a local web dashboard for inspecting BLoC
/// states and events in real time.
///
/// ## Usage
///
/// Create an instance and assign it to `Bloc.observer` **before** calling
/// `runApp`:
///
/// ```dart
/// void main() {
///   Bloc.observer = BlocPreviewObserver();
///   runApp(const MyApp());
/// }
/// ```
///
/// Then open `http://localhost:4680` in your browser to see the dashboard.
///
/// ## Configuration
///
/// Pass a [PreviewConfig] to change the port, host, or event buffer size:
///
/// ```dart
/// Bloc.observer = BlocPreviewObserver(
///   config: PreviewConfig(port: 9000),
/// );
/// ```
///
/// ## Features
///
/// * **State diff** — every transition highlights exactly which fields
///   changed between the previous and the next state.
/// * **Performance timeline** — measures milliseconds between events to
///   help identify slow transitions.
/// * **Snapshot export** — copy any state as JSON to the clipboard.
/// * **Bloc lifecycle map** — visualises creation and disposal of every
///   bloc on a horizontal timeline.
/// * **Event frequency monitor** — detects event storms and shows
///   per-bloc event rates.
/// * **State size tracker** — reports the serialised size of each state
///   so you can spot unbounded growth.
class BlocPreviewObserver extends BlocObserver {
  /// Creates a [BlocPreviewObserver] and immediately starts the dashboard
  /// server.
  ///
  /// The optional [config] parameter allows you to customise the server
  /// binding and event buffer size.
  BlocPreviewObserver({
    PreviewConfig config = const PreviewConfig(),
  })  : _config = config,
        _server = PreviewServer(config),
        _converter = const StateConverter() {
    _server.onClientConnected = _onClientConnected;
    _server.start();
  }

  final PreviewConfig _config;
  final PreviewServer _server;
  final StateConverter _converter;

  /// Tracks all BLoC instances that are currently alive.
  final Set<BlocBase<dynamic>> _activeBlocs = {};

  /// Maps BLoC type names to their latest serialised state.
  final Map<String, dynamic> _latestStates = {};

  /// Maps BLoC type names to their **previous** serialised state (for diff).
  final Map<String, dynamic> _previousStates = {};

  /// Rolling event log.
  final List<Map<String, dynamic>> _eventLog = [];

  /// Bloc lifecycle records: `{ bloc, created, closed? }`.
  final List<Map<String, dynamic>> _lifecycles = [];

  /// Timestamp of the last event per bloc (for performance measurement).
  final Map<String, DateTime> _lastEventTime = {};

  /// Running event count per bloc (for frequency monitoring).
  final Map<String, int> _eventCounts = {};

  /// Timestamp of when each bloc started being tracked for frequency.
  final Map<String, DateTime> _frequencyStart = {};

  // -- BlocObserver overrides -----------------------------------------------

  /// Called whenever a new [BlocBase] (Bloc or Cubit) is created.
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _activeBlocs.add(bloc);

    final name = _nameOf(bloc);
    final now = DateTime.now();
    final converted = _converter.convert(bloc.state);

    _latestStates[name] = converted;
    _previousStates[name] = null;
    _lastEventTime[name] = now;
    _eventCounts[name] = 0;
    _frequencyStart[name] = now;

    _lifecycles.add({
      'bloc': name,
      'created': now.toIso8601String(),
      'closed': null,
    });

    _record('create', bloc, stateOverride: converted);
  }

  /// Called whenever a [Bloc] processes a [Transition] (event -> state).
  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);

    final name = _nameOf(bloc);
    final prevState = _latestStates[name];
    final nextState = _converter.convert(transition.nextState);

    _previousStates[name] = prevState;
    _latestStates[name] = nextState;

    _record(
      'transition',
      bloc,
      event: transition.event,
      stateOverride: nextState,
      previousState: prevState,
    );
  }

  /// Called whenever a [BlocBase] emits a new state via [Change].
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);

    final name = _nameOf(bloc);
    final prevState = _latestStates[name];
    final nextState = _converter.convert(change.nextState);

    _previousStates[name] = prevState;
    _latestStates[name] = nextState;

    _record(
      'change',
      bloc,
      stateOverride: nextState,
      previousState: prevState,
    );
  }

  /// Called whenever a [BlocBase] is closed.
  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    _activeBlocs.remove(bloc);

    final name = _nameOf(bloc);
    _latestStates.remove(name);
    _previousStates.remove(name);

    // Mark lifecycle as closed.
    for (final lc in _lifecycles.reversed) {
      if (lc['bloc'] == name && lc['closed'] == null) {
        lc['closed'] = DateTime.now().toIso8601String();
        break;
      }
    }

    _record('close', bloc);
  }

  /// Called whenever a [BlocBase] encounters an [error].
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);

    final name = _nameOf(bloc);
    final now = DateTime.now();
    final durationMs = _measureDuration(name, now);

    _bumpFrequency(name);

    final entry = <String, dynamic>{
      'timestamp': now.toIso8601String(),
      'type': 'error',
      'bloc': name,
      'error': error.toString(),
      'stackTrace': stackTrace.toString().split('\n').take(10).join('\n'),
      'durationMs': durationMs,
      'frequency': _currentFrequency(name),
    };
    _appendEvent(entry);
    _server.broadcast({'type': 'event', 'data': entry});
  }

  /// Stops the dashboard server and releases all resources.
  ///
  /// Call this when you no longer need the observer (e.g. in integration
  /// tests).
  Future<void> dispose() async {
    await _server.stop();
  }

  // -- Private helpers ------------------------------------------------------

  /// Returns a human-readable name for the given [bloc].
  String _nameOf(BlocBase<dynamic> bloc) => bloc.runtimeType.toString();

  /// Measures the number of milliseconds since the last event for [blocName].
  int _measureDuration(String blocName, DateTime now) {
    final last = _lastEventTime[blocName];
    _lastEventTime[blocName] = now;
    if (last == null) return 0;
    return now.difference(last).inMilliseconds;
  }

  /// Increments the event counter for [blocName].
  void _bumpFrequency(String blocName) {
    _eventCounts[blocName] = (_eventCounts[blocName] ?? 0) + 1;
  }

  /// Returns the average events-per-second for [blocName].
  double _currentFrequency(String blocName) {
    final count = _eventCounts[blocName] ?? 0;
    final start = _frequencyStart[blocName];
    if (start == null || count == 0) return 0;
    final seconds = DateTime.now().difference(start).inMilliseconds / 1000.0;
    if (seconds < 0.001) return 0;
    return count / seconds;
  }

  /// Computes the approximate serialised size of [state] in bytes.
  int _stateSize(dynamic state) {
    if (state == null) return 0;
    try {
      return jsonEncode(state).length;
    } catch (_) {
      return state.toString().length;
    }
  }

  /// Records a lifecycle event, broadcasts it, and trims the log if needed.
  void _record(
    String type,
    BlocBase<dynamic> bloc, {
    dynamic event,
    dynamic stateOverride,
    dynamic previousState,
  }) {
    final name = _nameOf(bloc);
    final now = DateTime.now();
    final durationMs = _measureDuration(name, now);
    final currentState = stateOverride ?? _converter.convert(bloc.state);

    _bumpFrequency(name);

    final entry = <String, dynamic>{
      'timestamp': now.toIso8601String(),
      'type': type,
      'bloc': name,
      'state': currentState,
      // ignore: use_null_aware_elements
      if (previousState != null) 'prevState': previousState,
      if (event != null) 'event': _converter.convert(event),
      'durationMs': durationMs,
      'stateSize': _stateSize(currentState),
      'frequency': _currentFrequency(name),
    };
    _appendEvent(entry);
    _server.broadcast({'type': 'event', 'data': entry});
  }

  /// Appends [entry] to the log and discards the oldest entries when the
  /// buffer exceeds [PreviewConfig.maxEvents].
  void _appendEvent(Map<String, dynamic> entry) {
    _eventLog.add(entry);
    if (_eventLog.length > _config.maxEvents) {
      _eventLog.removeRange(0, _eventLog.length - _config.maxEvents);
    }
  }

  /// Sends the full current state snapshot to a newly connected dashboard
  /// client.
  void _onClientConnected(dynamic socket) {
    _server.sendSnapshot(
      socket,
      states: _latestStates,
      log: _eventLog,
      lifecycles: _lifecycles,
      frequencies: _buildFrequencySnapshot(),
      stateSizes: _buildSizeSnapshot(),
    );
  }

  /// Builds a snapshot of event frequencies for all tracked blocs.
  Map<String, double> _buildFrequencySnapshot() {
    final result = <String, double>{};
    for (final name in _eventCounts.keys) {
      result[name] = _currentFrequency(name);
    }
    return result;
  }

  /// Builds a snapshot of current state sizes for all active blocs.
  Map<String, int> _buildSizeSnapshot() {
    final result = <String, int>{};
    for (final entry in _latestStates.entries) {
      result[entry.key] = _stateSize(entry.value);
    }
    return result;
  }
}
