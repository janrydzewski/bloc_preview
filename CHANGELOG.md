## 1.0.0

- Initial release.
- `BlocPreviewObserver` — drop-in `BlocObserver` that launches a local web
  dashboard for inspecting BLoC states and events.
- Built-in web UI served on `localhost` with real-time WebSocket updates.
- Automatic state serialization via `toJson()`, `JsonEncodable`, or
  intelligent `toString()` parsing.
- **State diff** — highlights exactly which fields changed between the
  previous and current state in every transition and change event.
- **Performance timeline** — measures milliseconds between events per bloc
  and flags slow transitions (>100ms) in the UI.
- **Snapshot export** — one-click "Copy JSON" button to export any state to
  the clipboard for bug reports or test fixtures.
- **Bloc lifecycle map** — horizontal bar chart visualising when each bloc
  was created and closed, helping detect memory leaks and unnecessary
  rebuilds.
- **Event frequency monitor** — tracks events per second for each bloc and
  warns when the rate exceeds 10 ev/s (event storm detection).
- **State size tracker** — reports the serialised size of each state and
  warns when it exceeds 5 KB, helping spot unbounded state growth.
- Configurable server port, host, and event history limit via
  `PreviewConfig`.
