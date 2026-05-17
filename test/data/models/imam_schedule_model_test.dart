import 'package:flutter_test/flutter_test.dart';

import 'package:miqotul_khoir_tv/data/models/imam_schedule_model.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule.dart';

/// Unit tests untuk [ImamScheduleModel] — konversi fromMap/toMap.
///
/// Memvalidasi mapping `snake_case` ↔ `camelCase` termasuk nullable fields
/// `imam_id` dan `khatib_id`.
///
/// Ref: Phase 9 TASK-044 TEST-002
void main() {
  // ---------------------------------------------------------------------------
  // Test Data
  // ---------------------------------------------------------------------------

  final Map<String, dynamic> scheduleWithImamMap = {
    'id': 1,
    'day_of_week': 1, // Senin
    'prayer_name': 'subuh',
    'imam_id': 5,
    'khatib_id': null,
  };

  final Map<String, dynamic> fridayScheduleMap = {
    'id': 2,
    'day_of_week': 5, // Jumat
    'prayer_name': 'jumat',
    'imam_id': 3,
    'khatib_id': 7,
  };

  final Map<String, dynamic> emptySlotMap = {
    'id': 3,
    'day_of_week': 2, // Selasa
    'prayer_name': 'dzuhur',
    'imam_id': null,
    'khatib_id': null,
  };

  // ---------------------------------------------------------------------------
  // TEST: ImamScheduleModel.fromMap()
  // ---------------------------------------------------------------------------

  group('ImamScheduleModel.fromMap()', () {
    test('memetakan jadwal dengan imam terdaftar (imam_id tidak null)', () {
      final model = ImamScheduleModel.fromMap(scheduleWithImamMap);

      expect(model.id, equals(1));
      expect(model.dayOfWeek, equals(1));
      expect(model.prayerName, equals('subuh'));
      expect(model.imamId, equals(5));
      expect(model.khatibId, isNull);
    });

    test('memetakan jadwal Jumat dengan imam_id dan khatib_id', () {
      final model = ImamScheduleModel.fromMap(fridayScheduleMap);

      expect(model.id, equals(2));
      expect(model.dayOfWeek, equals(5));
      expect(model.prayerName, equals('jumat'));
      expect(model.imamId, equals(3));
      expect(model.khatibId, equals(7));
    });

    test('memetakan slot kosong (imam_id dan khatib_id null)', () {
      final model = ImamScheduleModel.fromMap(emptySlotMap);

      expect(model.imamId, isNull);
      expect(model.khatibId, isNull);
    });

    test('mengembalikan ImamScheduleModel yang merupakan subtype ImamSchedule',
        () {
      final model = ImamScheduleModel.fromMap(scheduleWithImamMap);
      expect(model, isA<ImamSchedule>());
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: ImamScheduleModel.toMap()
  // ---------------------------------------------------------------------------

  group('ImamScheduleModel.toMap()', () {
    test(
      'mengkonversi ke snake_case map tanpa id saat includeId=false (default)',
      () {
        final model = ImamScheduleModel.fromMap(scheduleWithImamMap);
        final map = model.toMap();

        expect(map['day_of_week'], equals(1));
        expect(map['prayer_name'], equals('subuh'));
        expect(map['imam_id'], equals(5));
        expect(map['khatib_id'], isNull);
        expect(map.containsKey('id'), isFalse);
      },
    );

    test('menyertakan id saat includeId=true', () {
      final model = ImamScheduleModel.fromMap(fridayScheduleMap);
      final map = model.toMap(includeId: true);

      expect(map['id'], equals(2));
      expect(map['day_of_week'], equals(5));
      expect(map['prayer_name'], equals('jumat'));
      expect(map['imam_id'], equals(3));
      expect(map['khatib_id'], equals(7));
    });

    test('slot kosong: imam_id dan khatib_id tetap null di map', () {
      final model = ImamScheduleModel.fromMap(emptySlotMap);
      final map = model.toMap();

      expect(map['imam_id'], isNull);
      expect(map['khatib_id'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: toEntity()
  // ---------------------------------------------------------------------------

  group('toEntity()', () {
    test('mengembalikan ImamSchedule entity yang identik dengan model', () {
      final model = ImamScheduleModel.fromMap(fridayScheduleMap);
      final entity = model.toEntity();

      expect(entity.id, equals(model.id));
      expect(entity.dayOfWeek, equals(model.dayOfWeek));
      expect(entity.prayerName, equals(model.prayerName));
      expect(entity.imamId, equals(model.imamId));
      expect(entity.khatibId, equals(model.khatibId));
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: Round-trip
  // ---------------------------------------------------------------------------

  group('ImamScheduleModel round-trip', () {
    test(
      'fromMap → toMap(includeId:true) → fromMap menghasilkan entity identik',
      () {
        final original = ImamScheduleModel.fromMap(fridayScheduleMap);
        final map = original.toMap(includeId: true);
        final reconstructed = ImamScheduleModel.fromMap(map);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.dayOfWeek, equals(original.dayOfWeek));
        expect(reconstructed.prayerName, equals(original.prayerName));
        expect(reconstructed.imamId, equals(original.imamId));
        expect(reconstructed.khatibId, equals(original.khatibId));
      },
    );
  });
}
