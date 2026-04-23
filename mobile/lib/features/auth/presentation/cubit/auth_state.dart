import 'package:equatable/equatable.dart';

import '../../../../models/user_session.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserSession? session;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated && session != null;

  AuthState copyWith({
    AuthStatus? status,
    UserSession? session,
    String? errorMessage,
    bool clearSession = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: clearSession ? null : session ?? this.session,
      errorMessage: errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'session': session?.toJson(),
      'errorMessage': errorMessage,
    };
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    final status = AuthStatus.values.firstWhere(
      (element) => element.name == statusName,
      orElse: () => AuthStatus.initial,
    );

    final sessionJson = json['session'] as Map<String, dynamic>?;

    return AuthState(
      status: status,
      session: sessionJson != null ? UserSession.fromJson(sessionJson) : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  List<Object?> get props => [status, session, errorMessage];
}
