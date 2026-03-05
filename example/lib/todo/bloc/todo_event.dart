part of 'todo_bloc.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object> get props => [];
}

class LoadTodos extends TodoEvent {}

class AddTodo extends TodoEvent {
  const AddTodo({required this.title, required this.description});

  final String title;
  final String description;

  @override
  List<Object> get props => [title, description];
}

class ToggleTodo extends TodoEvent {
  const ToggleTodo({required this.id});

  final String id;

  @override
  List<Object> get props => [id];
}

class DeleteTodo extends TodoEvent {
  const DeleteTodo({required this.id});

  final String id;

  @override
  List<Object> get props => [id];
}
