import 'package:equatable/equatable.dart';

class UserSession extends Equatable {
  const UserSession({
    required this.userId,
    required this.email,
    required this.role,
    required this.token,
  });

  final String userId;
  final String email;
  final String role;
  final String token;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'role': role,
      'token': token,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      token: json['token'] as String,
    );
  }

  @override
  List<Object?> get props => [userId, email, role, token];
}
