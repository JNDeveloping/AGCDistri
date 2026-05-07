import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.username,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String fullName;
  final String email;
  final String username;
  final String role;
  final bool isActive;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      username: (json['username'] as String?) ?? '',
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, username, role, isActive];
}
