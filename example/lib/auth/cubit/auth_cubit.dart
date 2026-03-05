// ignore_for_file: depend_on_referenced_packages

import 'package:bloc/bloc.dart';
import 'package:bloc_preview/bloc_preview.dart';
import 'package:equatable/equatable.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));

    await Future.delayed(const Duration(seconds: 2));

    if (email == 'test@test.com' && password == 'password') {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: User(
          id: 'usr_12345',
          email: email,
          name: 'John Doe',
          avatarUrl: 'https://i.pravatar.cc/150?img=3',
          role: 'admin',
        ),
      ));
    } else if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Email and password are required',
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid credentials. Try test@test.com / password',
      ));
    }
  }

  void logout() {
    emit(const AuthState());
  }
}
