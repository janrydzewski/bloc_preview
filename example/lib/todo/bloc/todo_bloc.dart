// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:bloc_preview/bloc_preview.dart';
import 'package:equatable/equatable.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  TodoBloc() : super(const TodoState()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<ToggleTodo>(_onToggleTodo);
    on<DeleteTodo>(_onDeleteTodo);
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(state.copyWith(status: TodoStatus.loading));

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final todos = [
      const Todo(id: '1', title: 'Buy groceries', description: 'Milk, eggs, bread'),
      const Todo(id: '2', title: 'Clean the house', description: 'Vacuum and mop'),
      const Todo(id: '3', title: 'Read Flutter docs', description: 'State management section'),
      const Todo(id: '4', title: 'Write unit tests', description: 'Cover edge cases', isCompleted: true),
      const Todo(id: '5', title: 'Deploy to production', description: 'Version 2.0 release'),
    ];

    emit(state.copyWith(status: TodoStatus.loaded, todos: todos));
  }

  void _onAddTodo(AddTodo event, Emitter<TodoState> emit) {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: event.title,
      description: event.description,
    );
    emit(state.copyWith(todos: [...state.todos, newTodo]));
  }

  void _onToggleTodo(ToggleTodo event, Emitter<TodoState> emit) {
    final updatedTodos = state.todos.map((todo) {
      if (todo.id == event.id) {
        return Todo(
          id: todo.id,
          title: todo.title,
          description: todo.description,
          isCompleted: !todo.isCompleted,
        );
      }
      return todo;
    }).toList();
    emit(state.copyWith(todos: updatedTodos));
  }

  void _onDeleteTodo(DeleteTodo event, Emitter<TodoState> emit) {
    final updatedTodos = state.todos.where((t) => t.id != event.id).toList();
    emit(state.copyWith(todos: updatedTodos));
  }
}
