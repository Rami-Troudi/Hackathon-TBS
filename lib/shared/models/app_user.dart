import 'package:senior_companion/shared/models/app_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final AppRole role;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.value,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        role: AppRoleX.fromRaw(json['role'] as String),
      );
}
