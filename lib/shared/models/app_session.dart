import 'package:senior_companion/shared/models/app_role.dart';

class AppSession {
  const AppSession({
    required this.activeRole,
    required this.activeProfileId,
    required this.startedAt,
  });

  final AppRole activeRole;
  final String activeProfileId;
  final DateTime startedAt;

  Map<String, dynamic> toJson() => {
        'activeRole': activeRole.value,
        'activeProfileId': activeProfileId,
        'startedAt': startedAt.toIso8601String(),
      };

  factory AppSession.fromJson(Map<String, dynamic> json) {
    final legacyUser = json['user'];
    final legacyUserId =
        legacyUser is Map<String, dynamic> ? legacyUser['id'] as String? : null;
    final activeProfileId =
        json['activeProfileId'] as String? ?? legacyUserId ?? '';
    if (activeProfileId.isEmpty) {
      throw const FormatException('Missing activeProfileId in stored session');
    }

    return AppSession(
      activeRole: AppRoleX.fromRaw(json['activeRole'] as String),
      activeProfileId: activeProfileId,
      startedAt: DateTime.parse(json['startedAt'] as String),
    );
  }
}
