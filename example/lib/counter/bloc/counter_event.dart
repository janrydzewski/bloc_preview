part of 'counter_bloc.dart';

/// Base event for [CounterBloc].
abstract class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object> get props => [];
}

/// Increments the counter by one.
class IncrementCounterEvent extends CounterEvent {}

/// Decrements the counter by one.
class DecrementCounterEvent extends CounterEvent {}
