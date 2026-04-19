enum AppRole { senior, guardian }

extension AppRoleX on AppRole {
  String get value => switch (this) {
        AppRole.senior => 'senior',
        AppRole.guardian => 'guardian',
      };

  String get label => switch (this) {
        AppRole.senior => 'Senior',
        AppRole.guardian => 'Guardian',
      };

  static AppRole fromRaw(String raw) {
    return switch (raw.toLowerCase()) {
      'guardian' => AppRole.guardian,
      _ => AppRole.senior,
    };
  }
}
