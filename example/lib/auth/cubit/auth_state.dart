part of 'auth_cubit.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

class User extends Equatable implements JsonEncodable {
  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final String role;

  @override
  List<Object> get props => [id, email, name, avatarUrl, role];

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatarUrl': avatarUrl,
        'role': role,
      };
}

class AuthState extends Equatable implements JsonEncodable {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];

  @override
  Map<String, dynamic> toJson() => {
        'status': status.name,
        'user': user?.toJson(),
        'errorMessage': errorMessage,
      };
}
