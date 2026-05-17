import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';
import 'package:miqotul_khoir_tv/data/datasources/imam_local_data_source.dart';
import 'package:miqotul_khoir_tv/data/datasources/imam_schedule_local_data_source.dart';
import 'package:miqotul_khoir_tv/data/repositories/imam_schedule_repository_impl.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule_display.dart';

/// Unit tests untuk [ImamScheduleRepositoryImpl] dengan in-memory SQLite.
///
/// Memvalidasi:
/// - getScheduleForDay: JOIN query resolve nama imam + khatib
/// - getRawScheduleForDay: tanpa JOIN
/// - setSchedule: upsert, normalisasi Jumat
/// - clearScheduleForDay: hapus semua slot hari tertentu
///
/// Ref: Phase 9 TASK-044 TEST-004
void main() {
  late DatabaseHelper helper;
  late ImanLocalDataSource imamDataSource;
  late ImamScheduleLocalDataSource scheduleDataSource;
  late ImamScheduleRepositoryImpl repository;

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

    imamDataSource = ImanLocalDataSource(helper);
    scheduleDataSource = ImamScheduleLocalDataSource(helper);
    repository = ImamScheduleRepositoryImpl(scheduleDataSource);
  });

  tearDown(() async {
    await helper.close();
    helper.resetForTesting();
  });

  // ---------------------------------------------------------------------------
  // Helper: insert imam dan kembalikan id
  // ---------------------------------------------------------------------------

  Future<int> insertImam(String name) => imamDataSource.insert(name);

  // ---------------------------------------------------------------------------
  // TEST: getScheduleForDay
  // ---------------------------------------------------------------------------

  group('getScheduleForDay()', () {
    test('mengembalikan list kosong saat tidak ada jadwal untuk hari itu',
        () async {
      final schedule = await repository.getScheduleForDay(1);
      expect(schedule, isEmpty);
    });

    test('mengembalikan jadwal dengan nama imam yang sudah di-resolve',
        () async {
      final imamId = await insertImam('Ust. Ahmad');
      await repository.setSchedule(
        dayOfWeek: 1,
        prayerName: 'subuh',
        imamId: imamId,
      );

      final schedule = await repository.getScheduleForDay(1);

      expect(schedule.length, equals(1));
      expect(schedule.first.prayerLabel, equals('Subuh'));
      expect(schedule.first.imamName, equals('Ust. Ahmad'));
      expect(schedule.first.khatibName, isNull);
    });

    test('slot kosong (imam_id NULL) memiliki imamName null', () async {
      await repository.setSchedule(
        dayOfWeek: 2,
        prayerName: 'dzuhur',
        imamId: null,
      );

      final schedule = await repository.getScheduleForDay(2);

      expect(schedule.length, equals(1));
      expect(schedule.first.imamName, isNull);
    });

    test('mengembalikan ImamScheduleDisplay entities', () async {
      final imamId = await insertImam('Ust. Budi');
      await repository.setSchedule(
        dayOfWeek: 3,
        prayerName: 'ashar',
        imamId: imamId,
      );

      final schedule = await repository.getScheduleForDay(3);
      expect(schedule.first, isA<ImamScheduleDisplay>());
    });

    test('Jumat: jadwal menggunakan prayerName=jumat dengan khatib dan imam',
        () async {
      final imamId = await insertImam('Ust. Ali');
      final khatibId = await insertImam('Ust. Mahmud');

      await repository.setSchedule(
        dayOfWeek: 5, // Jumat
        prayerName: 'jumat',
        imamId: imamId,
        khatibId: khatibId,
      );

      final schedule = await repository.getScheduleForDay(5);
      final fridaySlot = schedule.firstWhere(
        (s) => s.prayerName == 'jumat',
      );

      expect(fridaySlot.prayerLabel, equals('Jumat'));
      expect(fridaySlot.imamName, equals('Ust. Ali'));
      expect(fridaySlot.khatibName, equals('Ust. Mahmud'));
    });

    test('jadwal diurutkan sesuai urutan waktu sholat', () async {
      final imamId = await insertImam('Ust. Zain');
      // Insert tidak berurutan
      await repository.setSchedule(
          dayOfWeek: 1, prayerName: 'isya', imamId: imamId);
      await repository.setSchedule(
          dayOfWeek: 1, prayerName: 'subuh', imamId: imamId);
      await repository.setSchedule(
          dayOfWeek: 1, prayerName: 'ashar', imamId: imamId);

      final schedule = await repository.getScheduleForDay(1);

      expect(schedule[0].prayerName, equals('subuh'));
      expect(schedule[1].prayerName, equals('ashar'));
      expect(schedule[2].prayerName, equals('isya'));
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: getRawScheduleForDay
  // ---------------------------------------------------------------------------

  group('getRawScheduleForDay()', () {
    test('mengembalikan list kosong saat tidak ada jadwal', () async {
      final raw = await repository.getRawScheduleForDay(1);
      expect(raw, isEmpty);
    });

    test('mengembalikan raw data tanpa resolve nama', () async {
      final imamId = await insertImam('Ust. Ahmad');
      await repository.setSchedule(
        dayOfWeek: 1,
        prayerName: 'maghrib',
        imamId: imamId,
      );

      final raw = await repository.getRawScheduleForDay(1);

      expect(raw.length, equals(1));
      expect(raw.first.imamId, equals(imamId));
      expect(raw.first.prayerName, equals('maghrib'));
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: setSchedule (upsert)
  // ---------------------------------------------------------------------------

  group('setSchedule()', () {
    test('menyimpan jadwal baru', () async {
      final imamId = await insertImam('Ust. Ahmad');
      await repository.setSchedule(
        dayOfWeek: 1,
        prayerName: 'subuh',
        imamId: imamId,
      );

      final schedule = await repository.getScheduleForDay(1);
      expect(schedule.length, equals(1));
      expect(schedule.first.imamId, equals(imamId));
    });

    test('upsert: memperbarui jadwal yang sudah ada di slot yang sama',
        () async {
      final imam1Id = await insertImam('Ust. Ahmad');
      final imam2Id = await insertImam('Ust. Budi');

      await repository.setSchedule(
          dayOfWeek: 1, prayerName: 'subuh', imamId: imam1Id);
      await repository.setSchedule(
          dayOfWeek: 1, prayerName: 'subuh', imamId: imam2Id); // update

      final schedule = await repository.getScheduleForDay(1);
      expect(schedule.length, equals(1)); // tetap 1 row, bukan 2
      expect(schedule.first.imamId, equals(imam2Id));
    });

    test(
        'normalisasi Jumat: prayerName=dzuhur di hari 5 diubah menjadi jumat',
        () async {
      final imamId = await insertImam('Ust. Ali');
      await repository.setSchedule(
        dayOfWeek: 5,
        prayerName: 'dzuhur', // input dzuhur
        imamId: imamId,
      );

      final raw = await repository.getRawScheduleForDay(5);
      // Harus tersimpan sebagai 'jumat'
      expect(raw.any((r) => r.prayerName == 'jumat'), isTrue);
      expect(raw.any((r) => r.prayerName == 'dzuhur'), isFalse);
    });

    test('throws jika prayerName=jumat di hari selain Jumat', () async {
      expect(
        () => repository.setSchedule(
          dayOfWeek: 1, // bukan Jumat
          prayerName: 'jumat',
        ),
        throwsException,
      );
    });

    test('dapat mengosongkan imam (imamId=null)', () async {
      final imamId = await insertImam('Ust. Ahmad');
      await repository.setSchedule(
          dayOfWeek: 1, prayerName: 'subuh', imamId: imamId);
      await repository.setSchedule(
          dayOfWeek: 1, prayerName: 'subuh', imamId: null); // kosongkan

      final schedule = await repository.getScheduleForDay(1);
      expect(schedule.first.imamId, isNull);
      expect(schedule.first.imamName, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: clearScheduleForDay
  // ---------------------------------------------------------------------------

  group('clearScheduleForDay()', () {
    test('menghapus semua jadwal untuk hari yang ditentukan', () async {
      final imamId = await insertImam('Ust. Ahmad');
      await repository.setSchedule(
          dayOfWeek: 2, prayerName: 'subuh', imamId: imamId);
      await repository.setSchedule(
          dayOfWeek: 2, prayerName: 'dzuhur', imamId: imamId);

      await repository.clearScheduleForDay(2);

      final schedule = await repository.getScheduleForDay(2);
      expect(schedule, isEmpty);
    });

    test('hanya menghapus hari yang ditentukan, hari lain tidak terpengaruh',
        () async {
      final imamId = await insertImam('Ust. Ahmad');
      await repository.setSchedule(
          dayOfWeek: 1, prayerName: 'subuh', imamId: imamId);
      await repository.setSchedule(
          dayOfWeek: 2, prayerName: 'subuh', imamId: imamId);

      await repository.clearScheduleForDay(1);

      expect(await repository.getScheduleForDay(1), isEmpty);
      expect(await repository.getScheduleForDay(2), isNotEmpty);
    });

    test(
        'Jumat: clearScheduleForDay(5) menghapus slot jumat (dan dzuhur) saja',
        () async {
      final imamId = await insertImam('Ust. Ahmad');
      // Insert hanya slot jumat (bukan ashar) di hari Jumat
      await repository.setSchedule(
          dayOfWeek: 5, prayerName: 'jumat', imamId: imamId);

      await repository.clearScheduleForDay(5);

      final raw = await repository.getRawScheduleForDay(5);
      // Slot 'jumat' sudah dihapus
      expect(raw.any((r) => r.prayerName == 'jumat'), isFalse);
      expect(raw.any((r) => r.prayerName == 'dzuhur'), isFalse);
    });

    test('no-op jika tidak ada jadwal untuk hari itu (tidak throws)', () async {
      await expectLater(repository.clearScheduleForDay(3), completes);
    });
  });
}
