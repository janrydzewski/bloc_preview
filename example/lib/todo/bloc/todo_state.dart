part of 'todo_bloc.dart';

enum TodoStatus { initial, loading, loaded, error }

class Todo extends Equatable implements JsonEncodable {
  const Todo({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String description;
  final bool isCompleted;

  @override
  List<Object> get props => [id, title, description, isCompleted];

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
      };
}

class TodoState extends Equatable implements JsonEncodable {
  const TodoState({
    this.status = TodoStatus.initial,
    this.todos = const [],
  });

  final TodoStatus status;
  final List<Todo> todos;

  int get completedCount => todos.where((t) => t.isCompleted).length;
  int get pendingCount => todos.where((t) => !t.isCompleted).length;

  TodoState copyWith({TodoStatus? status, List<Todo>? todos}) {
    return TodoState(
      status: status ?? this.status,
      todos: todos ?? this.todos,
    );
  }

  @override
  List<Object> get props => [status, todos];

  @override
  Map<String, dynamic> toJson() => {
        'status': status.name,
        'totalCount': todos.length,
        'completedCount': completedCount,
        'pendingCount': pendingCount,
        'todos': todos.map((t) => t.toJson()).toList(),
      };
}
