# bloc_preview

A zero-configuration BLoC state inspector with a built-in web dashboard.

Attach it as a `BlocObserver` and open your browser - no external servers,
no extra packages, no setup.

![bloc_preview demo](https://raw.githubusercontent.com/janrydzewski/bloc_preview/main/assets/preview.gif)

## Features

- **Zero configuration** - one line of code to get started.
- **Built-in web dashboard** - served locally, no external dependencies.
- **Real-time updates** - state changes, events, and errors streamed via WebSocket.
- **State diff** - highlights exactly which fields changed between transitions, like a git diff.
- **Performance timeline** - measures milliseconds between events to spot slow transitions.
- **Snapshot export** - copy any state as JSON to clipboard for bug reports or tests.
- **Bloc lifecycle map** - visualises when each bloc was created and closed on a timeline, helping detect memory leaks.
- **Event frequency monitor** - detects event storms and shows per-bloc event rates with warnings.
- **State size tracker** - reports serialised state size so you can spot unbounded growth.
- **Automatic serialization** - works with `toJson()`, `JsonEncodable`, or plain `toString()`.
- **Filterable timeline** - search by bloc name or event type.
- **Collapsible state tree** - inspect deeply nested states with ease.

## Getting started

Add `bloc_preview` to your `dev_dependencies`:

```yaml
dev_dependencies:
  bloc_preview: ^1.0.0
```

## Usage

### Basic setup

```dart
import 'package:bloc_preview/bloc_preview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  Bloc.observer = BlocPreviewObserver();
  // Dashboard is now live at http://localhost:4680
  runApp(const MyApp());
}
```

### Custom configuration

```dart
Bloc.observer = BlocPreviewObserver(
  config: PreviewConfig(
    port: 9000,            // custom port
    host: '0.0.0.0',       // allow LAN access
    maxEvents: 500,        // event buffer size
  ),
);
```

### Better state serialization

For the best experience implement `JsonEncodable` on your states:

```dart
class CounterState implements JsonEncodable {
  const CounterState({required this.count});
  final int count;

  @override
  Map<String, dynamic> toJson() => {'count': count};
}
```

If your state already has a `toJson()` method (e.g. from `json_serializable`
or `freezed`), it will be picked up automatically - no extra interface needed.

States without `toJson()` are serialized by parsing their `toString()` output
into a structured tree.

### Cleanup

```dart
final observer = BlocPreviewObserver();
Bloc.observer = observer;

// Later, when no longer needed (e.g. in tests):
await observer.dispose();
```

## Dashboard tabs

### Timeline

Live event feed showing every create, transition, change, close, and error.
Each row displays the **duration in milliseconds** since the last event for
that bloc - slow transitions (>100ms) are highlighted in red.

Click any event to open the detail panel with:
- **State diff** - red/green comparison of previous vs current state
- **Current state** - collapsible tree view
- **Event data** - the triggering event
- **Copy JSON** - export the state to clipboard

### Lifecycle

Horizontal bar chart showing when each bloc was created and closed. Helps you
detect:
- Blocs that are **never closed** (potential memory leaks)
- Blocs that are **created too often** (unnecessary rebuilds)
- Overlapping instances of the same bloc type

### Analytics

Two data tables:
- **Event frequency** - events per second for each bloc, with visual bars and
  red warnings when the rate exceeds 10 ev/s (event storm detection)
- **State size** - serialised size of each bloc's current state, with warnings
  for states exceeding 5 KB

## How it works

`BlocPreviewObserver` extends `BlocObserver` and listens to every BLoC
lifecycle event. On creation it starts a lightweight HTTP server that serves a
single-page web dashboard. Every event is serialized (with previous state for
diff computation) and pushed to all connected browsers over WebSocket.

## Additional information

- **Issues**: https://github.com/janrydzewski/bloc_preview/issues
- **Contributing**: Pull requests are welcome.
- **License**: MIT
