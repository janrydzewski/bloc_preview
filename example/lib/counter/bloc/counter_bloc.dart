// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:bloc_preview/bloc_preview.dart';
import 'package:equatable/equatable.dart';

part 'counter_event.dart';
part 'counter_state.dart';

/// A simple counter bloc for demonstration purposes.
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState(counter: 0)) {
    on<IncrementCounterEvent>(
      (event, emit) => emit(state.copyWith(counter: state.counter + 1)),
    );
    on<DecrementCounterEvent>(
      (event, emit) => emit(state.copyWith(counter: state.counter - 1)),
    );
  }
}
