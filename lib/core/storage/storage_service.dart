import 'package:shared_preferences/shared_preferences.dart';

/// Abstract interface for lightweight local key-value storage.
///
/// This abstraction exists so that:
/// 1. The implementation can be swapped without touching call sites.
/// 2. Tests can inject a fake implementation without touching the real storage.
///
/// This service is intended for simple flags and preferences only:
/// - app flags (first launch, onboarding done)
/// - user preferences (role, notification settings)
/// - lightweight string lists (e.g. dismissed banner IDs)
///
/// It is NOT a replacement for a structured local database.
/// For entity lists (medications, events, incidents), use a dedicated
/// local repository backed by Hive or a similar store.
abstract class StorageService {
  /// Initialises the underlying storage backend.
  /// Must be called once during app bootstrap before any read/write.
  Future<void> initialize();

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Returns the stored [String] for [key], or null if not found.
  String? getString(String key);

  /// Returns the stored [bool] for [key], or null if not found.
  bool? getBool(String key);

  /// Returns the stored [int] for [key], or null if not found.
  int? getInt(String key);

  /// Returns the stored [double] for [key], or null if not found.
  double? getDouble(String key);

  /// Returns the stored [List<String>] for [key], or null if not found.
  List<String>? getStringList(String key);

  // ── Write ───────────────────────────────────────────────────────────────────

  /// Persists [value] under [key]. Returns true if the write succeeded.
  Future<bool> setString(String key, String value);

  /// Persists [value] under [key]. Returns true if the write succeeded.
  Future<bool> setBool(String key, bool value);

  /// Persists [value] under [key]. Returns true if the write succeeded.
  Future<bool> setInt(String key, int value);

  /// Persists [value] under [key]. Returns true if the write succeeded.
  Future<bool> setDouble(String key, double value);

  /// Persists [value] under [key]. Returns true if the write succeeded.
  Future<bool> setStringList(String key, List<String> value);

  // ── Delete ──────────────────────────────────────────────────────────────────

  /// Removes the value stored under [key].
  /// Returns true if the removal succeeded (including when the key did not exist).
  Future<bool> remove(String key);
}

// ─────────────────────────────────────────────────────────────────────────────

/// [StorageService] implementation backed by [SharedPreferences].
///
/// SharedPreferences is synchronous after initialization — all read methods
/// return immediately without async overhead once [initialize] has been called.
///
/// If any read is called before [initialize], a [StateError] is thrown.
/// This is intentional: silent no-ops on uninitialized storage hide bugs.
class SharedPreferencesStorageService implements StorageService {
  SharedPreferences? _prefs;

  SharedPreferences get _instance {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'StorageService accessed before initialization. '
        'Ensure StorageService.initialize() is awaited during app bootstrap.',
      );
    }
    return prefs;
  }

  @override
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  @override
  String? getString(String key) => _instance.getString(key);

  @override
  bool? getBool(String key) => _instance.getBool(key);

  @override
  int? getInt(String key) => _instance.getInt(key);

  @override
  double? getDouble(String key) => _instance.getDouble(key);

  @override
  List<String>? getStringList(String key) => _instance.getStringList(key);

  // ── Write ───────────────────────────────────────────────────────────────────

  @override
  Future<bool> setString(String key, String value) =>
      _instance.setString(key, value);

  @override
  Future<bool> setBool(String key, bool value) =>
      _instance.setBool(key, value);

  @override
  Future<bool> setInt(String key, int value) =>
      _instance.setInt(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _instance.setDouble(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _instance.setStringList(key, value);

  // ── Delete ──────────────────────────────────────────────────────────────────

  @override
  Future<bool> remove(String key) => _instance.remove(key);
}