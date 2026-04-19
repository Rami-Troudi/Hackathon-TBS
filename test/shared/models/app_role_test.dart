import 'package:flutter_test/flutter_test.dart';
import 'package:senior_companion/shared/models/app_role.dart';

void main() {
  group('AppRole', () {
    group('AppRoleX.fromRaw', () {
      test('returns senior for "senior"', () {
        expect(AppRoleX.fromRaw('senior'), equals(AppRole.senior));
      });

      test('returns guardian for "guardian"', () {
        expect(AppRoleX.fromRaw('guardian'), equals(AppRole.guardian));
      });

      test('is case-insensitive — GUARDIAN uppercased', () {
        expect(AppRoleX.fromRaw('GUARDIAN'), equals(AppRole.guardian));
      });

      test('is case-insensitive — Guardian title-case', () {
        expect(AppRoleX.fromRaw('Guardian'), equals(AppRole.guardian));
      });

      test('is case-insensitive — SENIOR uppercased', () {
        expect(AppRoleX.fromRaw('SENIOR'), equals(AppRole.senior));
      });

      test('defaults to senior for an unknown string', () {
        expect(AppRoleX.fromRaw('admin'), equals(AppRole.senior));
      });

      test('defaults to senior for an empty string', () {
        expect(AppRoleX.fromRaw(''), equals(AppRole.senior));
      });

      test('defaults to senior for a whitespace string', () {
        expect(AppRoleX.fromRaw('   '), equals(AppRole.senior));
      });

      test('defaults to senior for a numeric string', () {
        expect(AppRoleX.fromRaw('1'), equals(AppRole.senior));
      });
    });

    group('AppRoleX.value', () {
      test('senior serialises to "senior"', () {
        expect(AppRole.senior.value, equals('senior'));
      });

      test('guardian serialises to "guardian"', () {
        expect(AppRole.guardian.value, equals('guardian'));
      });

      test('round-trip: fromRaw(role.value) returns the original role — senior',
          () {
        expect(AppRoleX.fromRaw(AppRole.senior.value), equals(AppRole.senior));
      });

      test(
          'round-trip: fromRaw(role.value) returns the original role — guardian',
          () {
        expect(
          AppRoleX.fromRaw(AppRole.guardian.value),
          equals(AppRole.guardian),
        );
      });
    });

    group('AppRoleX.label', () {
      test('senior label is "Senior"', () {
        expect(AppRole.senior.label, equals('Senior'));
      });

      test('guardian label is "Guardian"', () {
        expect(AppRole.guardian.label, equals('Guardian'));
      });

      test('label is not empty for any role', () {
        for (final role in AppRole.values) {
          expect(role.label, isNotEmpty);
        }
      });
    });

    group('AppRole enum coverage', () {
      test('has exactly two values', () {
        expect(AppRole.values.length, equals(2));
      });

      test('contains senior', () {
        expect(AppRole.values, contains(AppRole.senior));
      });

      test('contains guardian', () {
        expect(AppRole.values, contains(AppRole.guardian));
      });

      test('senior and guardian are distinct', () {
        expect(AppRole.senior, isNot(equals(AppRole.guardian)));
      });
    });
  });
}
