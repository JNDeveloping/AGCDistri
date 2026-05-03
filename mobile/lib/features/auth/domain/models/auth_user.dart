import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.role,
    required this.permissions,
  });

  final String id;
  final String fullName;
  final String email;
  final String username;
  final String role;
  final List<String> permissions;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      username: (json['username'] as String?) ?? '',
      role: json['role'] as String,
      permissions: (json['permissions'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'username': username,
        'role': role,
        'permissions': permissions,
      };

  @override
  List<Object?> get props => [id, fullName, email, username, role, permissions];
}
