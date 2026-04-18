import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/shared/models/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    // ── fromRaw ───────────────────────────────────────────────────────────────

    group('AppEnvironmentX.fromRaw', () {
      group('dev environment', () {
        test('returns dev for "dev"', () {
          expect(AppEnvironmentX.fromRaw('dev'), equals(AppEnvironment.dev));
        });

        test('returns dev for "DEV" uppercased', () {
          expect(AppEnvironmentX.fromRaw('DEV'), equals(AppEnvironment.dev));
        });

        test('returns dev for "Dev" title-case', () {
          expect(AppEnvironmentX.fromRaw('Dev'), equals(AppEnvironment.dev));
        });
      });

      group('staging environment', () {
        test('returns staging for "staging"', () {
          expect(
            AppEnvironmentX.fromRaw('staging'),
            equals(AppEnvironment.staging),
          );
        });

        test('returns staging for "stage"', () {
          expect(
            AppEnvironmentX.fromRaw('stage'),
            equals(AppEnvironment.staging),
          );
        });

        test('returns staging for "STAGING" uppercased', () {
          expect(
            AppEnvironmentX.fromRaw('STAGING'),
            equals(AppEnvironment.staging),
          );
        });

        test('returns staging for "STAGE" uppercased', () {
          expect(
            AppEnvironmentX.fromRaw('STAGE'),
            equals(AppEnvironment.staging),
          );
        });

        test('returns staging for "Staging" title-case', () {
          expect(
            AppEnvironmentX.fromRaw('Staging'),
            equals(AppEnvironment.staging),
          );
        });
      });

      group('prod environment', () {
        test('returns prod for "prod"', () {
          expect(
            AppEnvironmentX.fromRaw('prod'),
            equals(AppEnvironment.prod),
          );
        });

        test('returns prod for "production"', () {
          expect(
            AppEnvironmentX.fromRaw('production'),
            equals(AppEnvironment.prod),
          );
        });

        test('returns prod for "PROD" uppercased', () {
          expect(
            AppEnvironmentX.fromRaw('PROD'),
            equals(AppEnvironment.prod),
          );
        });

        test('returns prod for "PRODUCTION" uppercased', () {
          expect(
            AppEnvironmentX.fromRaw('PRODUCTION'),
            equals(AppEnvironment.prod),
          );
        });

        test('returns prod for "Production" title-case', () {
          expect(
            AppEnvironmentX.fromRaw('Production'),
            equals(AppEnvironment.prod),
          );
        });
      });

      group('default fallback', () {
        test('defaults to dev for an empty string', () {
          expect(AppEnvironmentX.fromRaw(''), equals(AppEnvironment.dev));
        });

        test('defaults to dev for a completely unknown string', () {
          expect(
            AppEnvironmentX.fromRaw('unknown'),
            equals(AppEnvironment.dev),
          );
        });

        test('defaults to dev for a numeric string', () {
          expect(AppEnvironmentX.fromRaw('1'), equals(AppEnvironment.dev));
        });

        test('defaults to dev for a whitespace string', () {
          expect(AppEnvironmentX.fromRaw('   '), equals(AppEnvironment.dev));
        });

        test('defaults to dev for a partial match like "pro"', () {
          // "pro" is not "prod" or "production" — should fall through to dev.
          expect(AppEnvironmentX.fromRaw('pro'), equals(AppEnvironment.dev));
        });

        test('defaults to dev for a partial match like "stag"', () {
          expect(AppEnvironmentX.fromRaw('stag'), equals(AppEnvironment.dev));
        });
      });
    });

    // ── value serialisation ───────────────────────────────────────────────────

    group('AppEnvironmentX.value', () {
      test('dev serialises to "dev"', () {
        expect(AppEnvironment.dev.value, equals('dev'));
      });

      test('staging serialises to "staging"', () {
        expect(AppEnvironment.staging.value, equals('staging'));
      });

      test('prod serialises to "prod"', () {
        expect(AppEnvironment.prod.value, equals('prod'));
      });

      test('no environment serialises to an empty string', () {
        for (final env in AppEnvironment.values) {
          expect(env.value, isNotEmpty);
        }
      });
    });

    // ── round-trip ────────────────────────────────────────────────────────────

    group('round-trip: fromRaw(env.value) == env', () {
      test('dev round-trip', () {
        expect(
          AppEnvironmentX.fromRaw(AppEnvironment.dev.value),
          equals(AppEnvironment.dev),
        );
      });

      test('staging round-trip', () {
        expect(
          AppEnvironmentX.fromRaw(AppEnvironment.staging.value),
          equals(AppEnvironment.staging),
        );
      });

      test('prod round-trip', () {
        expect(
          AppEnvironmentX.fromRaw(AppEnvironment.prod.value),
          equals(AppEnvironment.prod),
        );
      });

      test('all enum values survive a round-trip', () {
        for (final env in AppEnvironment.values) {
          expect(
            AppEnvironmentX.fromRaw(env.value),
            equals(env),
            reason: 'Round-trip failed for environment: $env',
          );
        }
      });
    });

    // ── enum coverage ─────────────────────────────────────────────────────────

    group('AppEnvironment enum coverage', () {
      test('has exactly three values', () {
        expect(AppEnvironment.values.length, equals(3));
      });

      test('contains dev', () {
        expect(AppEnvironment.values, contains(AppEnvironment.dev));
      });

      test('contains staging', () {
        expect(AppEnvironment.values, contains(AppEnvironment.staging));
      });

      test('contains prod', () {
        expect(AppEnvironment.values, contains(AppEnvironment.prod));
      });

      test('all three environments are distinct', () {
        expect(AppEnvironment.dev, isNot(equals(AppEnvironment.staging)));
        expect(AppEnvironment.dev, isNot(equals(AppEnvironment.prod)));
        expect(AppEnvironment.staging, isNot(equals(AppEnvironment.prod)));
      });
    });
  });
}