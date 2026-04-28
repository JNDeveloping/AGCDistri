import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState());

  final AuthRepository _authRepository;

  Future<void> initialize() async {
    emit(state.copyWith(status: AuthStatus.checking, errorMessage: null));
    final session = await _authRepository.restoreSession();

    if (session == null) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearSession: true));
      return;
    }

    emit(state.copyWith(status: AuthStatus.authenticated, session: session));
  }

  Future<void> login({required String identifier, required String password}) async {
    emit(state.copyWith(status: AuthStatus.authenticating, errorMessage: null));
    try {
      final session = await _authRepository.login(identifier: identifier, password: password);
      emit(state.copyWith(status: AuthStatus.authenticated, session: session));
    } on AuthException catch (error) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: error.message, clearSession: true));
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearSession: true));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'No se pudo iniciar sesión. Verificá conexión y credenciales.',
        clearSession: true,
      ));
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearSession: true));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(state.copyWith(status: AuthStatus.unauthenticated, clearSession: true, errorMessage: null));
  }
}
