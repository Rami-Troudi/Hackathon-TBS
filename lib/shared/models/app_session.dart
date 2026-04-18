import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/app_user.dart';

class AppSession {
  const AppSession({
    required this.user,
    required this.activeRole,
    required this.startedAt,
  });

  final AppUser user;
  final AppRole activeRole;
  final DateTime startedAt;

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'activeRole': activeRole.value,
        'startedAt': startedAt.toIso8601String(),
      };

  factory AppSession.fromJson(Map<String, dynamic> json) => AppSession(
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
        activeRole: AppRoleX.fromRaw(json['activeRole'] as String),
        startedAt: DateTime.parse(json['startedAt'] as String),
      );
}
