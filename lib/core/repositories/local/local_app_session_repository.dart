import 'dart:convert';

import 'package:senior_companion/core/logging/app_logger.dart';
import 'package:senior_companion/core/repositories/app_session_repository.dart';
import 'package:senior_companion/core/storage/storage_keys.dart';
import 'package:senior_companion/core/storage/storage_service.dart';
import 'package:senior_companion/shared/models/app_session.dart';

class LocalAppSessionRepository implements AppSessionRepository {
  const LocalAppSessionRepository({
    required this.storage,
    required this.logger,
  });

  final StorageService storage;
  final AppLogger logger;

  @override
  Future<AppSession?> getSession() async {
    final raw = storage.getString(StorageKeys.appSession);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppSession.fromJson(decoded);
    } catch (error, stack) {
      // Stored session data is corrupt — this can happen after an app update
      // that changes the session schema, or due to rare storage corruption.
      // Clear the bad data and return null so the app starts cleanly.
      logger.warn(
        'Corrupt session data detected in storage — clearing session. '
        'Error: $error',
      );
      logger.error('Session parse failure', error, stack);
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> saveSession(AppSession session) async {
    try {
      final saved = await storage.setString(
        StorageKeys.appSession,
        jsonEncode(session.toJson()),
      );
      if (!saved) {
        logger.warn('LocalAppSessionRepository: storage returned false when saving session');
      }
    } catch (error, stack) {
      logger.error('Failed to save session', error, stack);
    }
  }

  @override
  Future<void> clearSession() async {
    await storage.remove(StorageKeys.appSession);
    logger.info('LocalAppSessionRepository: session cleared');
  }
}