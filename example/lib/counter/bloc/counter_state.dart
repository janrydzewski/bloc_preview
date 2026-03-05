part of 'counter_bloc.dart';

/// State for [CounterBloc], implementing [JsonEncodable] for best
/// serialization in the bloc_preview dashboard.
class CounterState extends Equatable implements JsonEncodable {
  const CounterState({required this.counter});

  /// The current counter value.
  final int counter;

  /// Returns a copy with the given fields replaced.
  CounterState copyWith({int? counter}) =>
      CounterState(counter: counter ?? this.counter);

  @override
  List<Object> get props => [counter];

  @override
  Map<String, dynamic> toJson() => {'counter': counter};
}
