import 'package:dio/dio.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../../models/user_session.dart';
import '../../../../services/api/api_client.dart';
import '../../../../services/storage/token_storage.dart';
import 'auth_state.dart';

class AuthCubit extends HydratedCubit<AuthState> {
  AuthCubit({required ApiClient apiClient, required TokenStorage tokenStorage})
      : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        super(const AuthState());

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<void> restoreSession() async {
    final session = state.session;
    if (session != null) {
      await _tokenStorage.save(session.token);
      emit(state.copyWith(status: AuthStatus.authenticated));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearSession: true));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final payload = response.data?['data'] as Map<String, dynamic>?;
      if (payload == null) {
        throw const FormatException('La respuesta del servidor no tiene sesión válida.');
      }

      final session = UserSession.fromJson(payload);
      await _tokenStorage.save(session.token);
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
          errorMessage: null,
        ),
      );
    } on DioException catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.response?.data.toString() ?? 'No se pudo iniciar sesión.',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Se produjo un error inesperado en autenticación.',
        ),
      );
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    emit(
      state.copyWith(
        status: AuthStatus.unauthenticated,
        clearSession: true,
        errorMessage: null,
      ),
    );
  }

  @override
  AuthState? fromJson(Map<String, dynamic> json) => AuthState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(AuthState state) => state.toJson();
}
