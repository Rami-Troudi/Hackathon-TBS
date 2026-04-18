enum AppEnvironment { dev, staging, prod }

extension AppEnvironmentX on AppEnvironment {
  String get value => switch (this) {
        AppEnvironment.dev => 'dev',
        AppEnvironment.staging => 'staging',
        AppEnvironment.prod => 'prod',
      };

  static AppEnvironment fromRaw(String raw) {
    return switch (raw.toLowerCase()) {
      'prod' || 'production' => AppEnvironment.prod,
      'stage' || 'staging' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
  }
}
