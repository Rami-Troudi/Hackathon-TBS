import 'package:senior_companion/shared/models/app_role.dart';
import 'package:senior_companion/shared/models/app_session.dart';

abstract class AppSessionRepository {
  Future<AppSession?> getSession();
  Future<void> saveSession(AppSession session);
  Future<void> createSession({
    required AppRole activeRole,
    required String activeProfileId,
  });
  Future<void> switchSessionRole({
    required AppRole activeRole,
    required String activeProfileId,
  });
  Future<void> clearSession();
}
