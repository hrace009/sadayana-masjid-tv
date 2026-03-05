import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';
import 'package:miqotul_khoir_tv/data/datasources/settings_local_data_source.dart';
import 'package:miqotul_khoir_tv/data/repositories/settings_repository_impl.dart';

/// Unit tests untuk [SettingsRepositoryImpl].
///
/// Menggunakan in-memory SQLite database via `sqflite_common_ffi`.
/// Setiap test mendapat fresh database (isolated).
///
/// Ref: Plan 02 TASK-020 s.d. TASK-025
void main() {
  late DatabaseHelper helper;
  late SettingsLocalDataSource dataSource;
  late SettingsRepositoryImpl repository;

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    helper = DatabaseHelper();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await helper.createTablesForTesting(db);
    await helper.insertDefaultSettingsForTesting(db);
    helper.initForTesting(db);

    dataSource = SettingsLocalDataSource(helper);
    repository = SettingsRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await helper.close();
    helper.resetForTesting();
  });

  // ---------------------------------------------------------------------------
  // TEST: getSettings() returns default values on fresh database
  // ---------------------------------------------------------------------------

  test(
    'getSettings() returns default settings on fresh database '
    '(is_first_run = true, mosqueName = empty, latitude = -6.9175)',
    () async {
      final settings = await repository.getSettings();

      expect(settings.isFirstRun, isTrue);
      expect(settings.mosqueName, equals(''));
      expect(settings.mosqueAddress, equals(''));
      expect(settings.cityName, equals(''));
      expect(settings.latitude, closeTo(-6.9175, 0.0001));
      expect(settings.longitude, closeTo(107.6191, 0.0001));
      expect(settings.timezone, equals('Asia/Jakarta'));
      expect(settings.calculationMethod, equals('kemenag'));
      expect(settings.offsetSubuh, equals(0));
      expect(settings.dhuhaOffsetMinutes, equals(20));
      expect(settings.hijriAdjustment, equals(0));
      expect(settings.iqomahSubuh, equals(10));
      expect(settings.iqomahMaghrib, equals(7));
      expect(settings.preAdzanMinutes, equals(10));
      expect(settings.sholatDurationMinutes, equals(15));
      expect(settings.adzanDurationSeconds, equals(180));
      expect(settings.runningText, equals('Selamat datang di masjid kami'));
      expect(settings.settingsPinHash, equals(''));
      expect(settings.elevation, equals(0));
    },
  );

  // ---------------------------------------------------------------------------
  // TEST: updateSettings() updates only specified fields
  // ---------------------------------------------------------------------------

  test(
    'updateSettings() updates only mosque_name, other fields retain defaults',
    () async {
      await repository.updateSettings({'mosque_name': 'Masjid Al-Ikhlas'});

      final settings = await repository.getSettings();

      // Updated field
      expect(settings.mosqueName, equals('Masjid Al-Ikhlas'));

      // Retained defaults
      expect(settings.isFirstRun, isTrue);
      expect(settings.mosqueAddress, equals(''));
      expect(settings.latitude, closeTo(-6.9175, 0.0001));
      expect(settings.calculationMethod, equals('kemenag'));
    },
  );

  // ---------------------------------------------------------------------------
  // TEST: completeFirstRun() sets is_first_run to false
  // ---------------------------------------------------------------------------

  test('completeFirstRun() sets is_first_run to false', () async {
    // Verify initial state
    var settings = await repository.getSettings();
    expect(settings.isFirstRun, isTrue);

    // Complete first run
    await repository.completeFirstRun();

    // Verify updated state
    settings = await repository.getSettings();
    expect(settings.isFirstRun, isFalse);
  });

  // ---------------------------------------------------------------------------
  // TEST: verifyPin() returns true when PIN is disabled (hash empty)
  // ---------------------------------------------------------------------------

  test(
    'verifyPin() returns true when PIN is disabled (pin_hash empty)',
    () async {
      final result = await repository.verifyPin('');
      expect(result, isTrue);

      final resultWithAnyPin = await repository.verifyPin('123456');
      expect(resultWithAnyPin, isTrue);
    },
  );

  // ---------------------------------------------------------------------------
  // TEST: setPin() and verifyPin() — full PIN lifecycle
  // ---------------------------------------------------------------------------

  test(
    'setPin() hashes and saves PIN, verifyPin() validates correctly',
    () async {
      const pin = '123456';

      // Set PIN
      await repository.setPin(pin);

      // Verify correct PIN
      final correctResult = await repository.verifyPin(pin);
      expect(correctResult, isTrue);

      // Verify wrong PIN
      final wrongResult = await repository.verifyPin('000000');
      expect(wrongResult, isFalse);

      // Verify stored hash is SHA-256
      final settings = await repository.getSettings();
      final expectedHash = sha256.convert(utf8.encode(pin)).toString();
      expect(settings.settingsPinHash, equals(expectedHash));

      // Disable PIN (empty string)
      await repository.setPin('');
      final afterDisable = await repository.getSettings();
      expect(afterDisable.settingsPinHash, equals(''));

      // Verify returns true after disable
      final disabledResult = await repository.verifyPin('anything');
      expect(disabledResult, isTrue);
    },
  );
}
