import 'package:equatable/equatable.dart';

import '../../domain/models/auth_session.dart';

enum AuthStatus { checking, unauthenticated, authenticating, authenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.checking,
    this.session,
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthSession? session;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && session != null;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? errorMessage,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage];
}
