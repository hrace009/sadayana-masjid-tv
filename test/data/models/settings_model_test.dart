import 'package:flutter_test/flutter_test.dart';

import 'package:miqotul_khoir_tv/data/models/settings_model.dart';

/// Unit tests untuk [SettingsModel] — konversi fromMap/toMap.
///
/// Memvalidasi bahwa semua 27+ fields di-mapping dengan benar
/// antara SQLite map (snake_case) dan Dart entity (camelCase),
/// termasuk konversi `int → bool` untuk `is_first_run`.
///
/// Ref: Plan 02 TASK-014 s.d. TASK-017
void main() {
  // ---------------------------------------------------------------------------
  // Test Data: Raw SQLite map yang merepresentasikan default settings
  // ---------------------------------------------------------------------------

  final Map<String, dynamic> defaultSettingsMap = {
    'id': 1,
    'is_first_run': 1,
    'mosque_name': '',
    'mosque_address': '',
    'city_name': '',
    'latitude': -6.9175,
    'longitude': 107.6191,
    'timezone': 'Asia/Jakarta',
    'calculation_method': 'kemenag',
    'offset_subuh': 0,
    'offset_syuruq': 0,
    'offset_dhuha': 0,
    'offset_dzuhur': 0,
    'offset_ashar': 0,
    'offset_maghrib': 0,
    'offset_isya': 0,
    'dhuha_offset_minutes': 20,
    'hijri_adjustment': 0,
    'iqomah_subuh': 10,
    'iqomah_dzuhur': 10,
    'iqomah_ashar': 10,
    'iqomah_maghrib': 7,
    'iqomah_isya': 10,
    'iqomah_jumat': 10,
    'pre_adzan_minutes': 10,
    'sholat_duration_minutes': 15,
    'sholat_jumat_duration_minutes': 45,
    'adzan_duration_seconds': 180,
    'running_text': 'Selamat datang di masjid kami',
    'settings_pin_hash': '',
    'elevation': 0,
    'is_treasury_enabled': 0,
    'treasury_balance': 0,
    'treasury_income': 0,
    'treasury_expense': 0,
    'created_at': '2026-01-01T00:00:00',
    'updated_at': '2026-01-01T00:00:00',
  };

  final Map<String, dynamic> customSettingsMap = {
    'id': 1,
    'is_first_run': 0,
    'mosque_name': 'Masjid Al-Ikhlas',
    'mosque_address': 'Jl. Merdeka No. 1',
    'city_name': 'Kota Bandung',
    'latitude': -6.9034,
    'longitude': 107.5731,
    'timezone': 'Asia/Jakarta',
    'calculation_method': 'muslim_world_league',
    'offset_subuh': 2,
    'offset_syuruq': -1,
    'offset_dhuha': 0,
    'offset_dzuhur': 3,
    'offset_ashar': 1,
    'offset_maghrib': 2,
    'offset_isya': -2,
    'dhuha_offset_minutes': 15,
    'hijri_adjustment': -1,
    'iqomah_subuh': 12,
    'iqomah_dzuhur': 8,
    'iqomah_ashar': 10,
    'iqomah_maghrib': 5,
    'iqomah_isya': 10,
    'iqomah_jumat': 12,
    'pre_adzan_minutes': 5,
    'sholat_duration_minutes': 20,
    'sholat_jumat_duration_minutes': 50,
    'adzan_duration_seconds': 240,
    'running_text': 'Selamat datang di Masjid Al-Ikhlas',
    'settings_pin_hash': 'abc123hash',
    'elevation': 698,
    'is_treasury_enabled': 1,
    'treasury_balance': 5000000,
    'treasury_income': 2500000,
    'treasury_expense': 750000,
    'created_at': '2026-02-18T10:00:00',
    'updated_at': '2026-02-18T14:00:00',
  };

  // ---------------------------------------------------------------------------
  // TEST: SettingsModel.fromMap() maps all fields correctly
  // ---------------------------------------------------------------------------

  group('SettingsModel.fromMap()', () {
    test('maps default settings fields correctly (int → bool conversion)', () {
      final model = SettingsModel.fromMap(defaultSettingsMap);

      expect(model.isFirstRun, isTrue);
      expect(model.mosqueName, equals(''));
      expect(model.mosqueAddress, equals(''));
      expect(model.cityName, equals(''));
      expect(model.latitude, closeTo(-6.9175, 0.0001));
      expect(model.longitude, closeTo(107.6191, 0.0001));
      expect(model.timezone, equals('Asia/Jakarta'));
      expect(model.calculationMethod, equals('kemenag'));
      expect(model.offsetSubuh, equals(0));
      expect(model.offsetSyuruq, equals(0));
      expect(model.offsetDhuha, equals(0));
      expect(model.offsetDzuhur, equals(0));
      expect(model.offsetAshar, equals(0));
      expect(model.offsetMaghrib, equals(0));
      expect(model.offsetIsya, equals(0));
      expect(model.dhuhaOffsetMinutes, equals(20));
      expect(model.hijriAdjustment, equals(0));
      expect(model.iqomahSubuh, equals(10));
      expect(model.iqomahDzuhur, equals(10));
      expect(model.iqomahAshar, equals(10));
      expect(model.iqomahMaghrib, equals(7));
      expect(model.iqomahIsya, equals(10));
      expect(model.preAdzanMinutes, equals(10));
      expect(model.sholatDurationMinutes, equals(15));
      expect(model.adzanDurationSeconds, equals(180));
      expect(model.runningText, equals('Selamat datang di masjid kami'));
      expect(model.settingsPinHash, equals(''));
      expect(model.elevation, equals(0));
      expect(model.iqomahJumat, equals(10));
      expect(model.sholatJumatDurationMinutes, equals(45));
      // Treasury fields — semua default OFF / 0
      expect(model.isTreasuryEnabled, isFalse);
      expect(model.treasuryBalance, equals(0));
      expect(model.treasuryIncome, equals(0));
      expect(model.treasuryExpense, equals(0));
    });

    test(
      'maps custom settings fields correctly (is_first_run = 0 → false)',
      () {
        final model = SettingsModel.fromMap(customSettingsMap);

        expect(model.isFirstRun, isFalse);
        expect(model.mosqueName, equals('Masjid Al-Ikhlas'));
        expect(model.mosqueAddress, equals('Jl. Merdeka No. 1'));
        expect(model.cityName, equals('Kota Bandung'));
        expect(model.latitude, closeTo(-6.9034, 0.0001));
        expect(model.longitude, closeTo(107.5731, 0.0001));
        expect(model.calculationMethod, equals('muslim_world_league'));
        expect(model.offsetSubuh, equals(2));
        expect(model.offsetSyuruq, equals(-1));
        expect(model.offsetDzuhur, equals(3));
        expect(model.offsetAshar, equals(1));
        expect(model.offsetMaghrib, equals(2));
        expect(model.offsetIsya, equals(-2));
        expect(model.dhuhaOffsetMinutes, equals(15));
        expect(model.hijriAdjustment, equals(-1));
        expect(model.iqomahSubuh, equals(12));
        expect(model.iqomahDzuhur, equals(8));
        expect(model.iqomahMaghrib, equals(5));
        expect(model.preAdzanMinutes, equals(5));
        expect(model.sholatDurationMinutes, equals(20));
        expect(model.adzanDurationSeconds, equals(240));
        expect(model.runningText, equals('Selamat datang di Masjid Al-Ikhlas'));
        expect(model.settingsPinHash, equals('abc123hash'));
        expect(model.elevation, equals(698));
        expect(model.iqomahJumat, equals(12));
        expect(model.sholatJumatDurationMinutes, equals(50));
        // Treasury fields — custom values
        expect(model.isTreasuryEnabled, isTrue);
        expect(model.treasuryBalance, equals(5000000));
        expect(model.treasuryIncome, equals(2500000));
        expect(model.treasuryExpense, equals(750000));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // TEST: SettingsModel.toMap() converts back to SQLite-compatible map
  // ---------------------------------------------------------------------------

  group('SettingsModel.toMap()', () {
    test('converts entity to snake_case map with bool → int conversion', () {
      final model = SettingsModel.fromMap(customSettingsMap);
      final map = model.toMap();

      expect(map['is_first_run'], equals(0));
      expect(map['mosque_name'], equals('Masjid Al-Ikhlas'));
      expect(map['mosque_address'], equals('Jl. Merdeka No. 1'));
      expect(map['city_name'], equals('Kota Bandung'));
      expect(map['latitude'], closeTo(-6.9034, 0.0001));
      expect(map['longitude'], closeTo(107.5731, 0.0001));
      expect(map['timezone'], equals('Asia/Jakarta'));
      expect(map['calculation_method'], equals('muslim_world_league'));
      expect(map['offset_subuh'], equals(2));
      expect(map['offset_syuruq'], equals(-1));
      expect(map['dhuha_offset_minutes'], equals(15));
      expect(map['hijri_adjustment'], equals(-1));
      expect(map['iqomah_subuh'], equals(12));
      expect(map['pre_adzan_minutes'], equals(5));
      expect(map['sholat_duration_minutes'], equals(20));
      expect(map['adzan_duration_seconds'], equals(240));
      expect(map['running_text'], equals('Selamat datang di Masjid Al-Ikhlas'));
      expect(map['settings_pin_hash'], equals('abc123hash'));
      expect(map['elevation'], equals(698));
      expect(map['iqomah_jumat'], equals(12));
      expect(map['sholat_jumat_duration_minutes'], equals(50));
      // Treasury fields
      expect(map['is_treasury_enabled'], equals(1));
      expect(map['treasury_balance'], equals(5000000));
      expect(map['treasury_income'], equals(2500000));
      expect(map['treasury_expense'], equals(750000));

      // toMap() should NOT include id, created_at, updated_at
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map.containsKey('updated_at'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: Round-trip (fromMap → toMap → fromMap) produces identical data
  // ---------------------------------------------------------------------------

  group('SettingsModel round-trip', () {
    test('fromMap → toMap → fromMap produces identical entity', () {
      final original = SettingsModel.fromMap(customSettingsMap);
      final map = original.toMap();

      // Re-add fields that toMap() excludes (managed by DB)
      map['id'] = 1;
      map['created_at'] = '2026-02-18T10:00:00';
      map['updated_at'] = '2026-02-18T14:00:00';

      final reconstructed = SettingsModel.fromMap(map);

      // Equatable ensures value equality
      expect(reconstructed, equals(original));
    });
  });
}
