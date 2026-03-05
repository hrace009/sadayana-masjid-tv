import 'package:flutter_test/flutter_test.dart';
import 'package:miqotul_khoir_tv/domain/entities/setup_wizard_data.dart';

void main() {
  group('SetupWizardData', () {
    const defaultData = SetupWizardData();

    test('supports value comparisons', () {
      expect(const SetupWizardData(), const SetupWizardData());
    });

    group('isIdentityValid', () {
      test('returns false when mosqueName is empty', () {
        expect(defaultData.isIdentityValid, isFalse);
      });

      test('returns false when mosqueName is too short (< 3 chars)', () {
        final data = defaultData.copyWith(mosqueName: 'AB');
        expect(data.isIdentityValid, isFalse);
      });

      test('returns true when mosqueName is valid (>= 3 chars)', () {
        final data = defaultData.copyWith(mosqueName: 'Masjid Raya');
        expect(data.isIdentityValid, isTrue);
      });
    });

    group('isLocationValid', () {
      test('returns false when cityName is empty', () {
        // default data has empty cityName
        expect(defaultData.isLocationValid, isFalse);
      });

      test('returns false when coordinates are 0', () {
        final data = defaultData.copyWith(cityName: 'Bandung');
        // default lat/long is 0.0
        expect(data.isLocationValid, isFalse);
      });

      test('returns true when city and coordinates are populated', () {
        final data = defaultData.copyWith(
          cityName: 'Bandung',
          latitude: -6.9175,
          longitude: 107.6191,
        );
        expect(data.isLocationValid, isTrue);
      });
    });

    group('isComplete', () {
      test('returns false when identity is invalid', () {
        final data = defaultData.copyWith(
          // invalid identity
          mosqueName: '',
          // valid location
          cityName: 'Bandung',
          latitude: -6.9175,
          longitude: 107.6191,
        );
        expect(data.isComplete, isFalse);
      });

      test('returns false when location is invalid', () {
        final data = defaultData.copyWith(
          // valid identity
          mosqueName: 'Masjid Raya',
          // invalid location
          cityName: '',
        );
        expect(data.isComplete, isFalse);
      });

      test('returns true when both are valid', () {
        final data = defaultData.copyWith(
          mosqueName: 'Masjid Raya',
          cityName: 'Bandung',
          latitude: -6.9175,
          longitude: 107.6191,
        );
        expect(data.isComplete, isTrue);
      });
    });

    test('copyWith creates new instance with updated values', () {
      final updated = defaultData.copyWith(mosqueName: 'New Name');
      expect(updated.mosqueName, 'New Name');
      expect(updated.mosqueAddress, defaultData.mosqueAddress);
    });
  });
}
