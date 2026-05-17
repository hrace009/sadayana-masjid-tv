import 'package:flutter_test/flutter_test.dart';

import 'package:miqotul_khoir_tv/data/models/imam_model.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam.dart';

/// Unit tests untuk [ImanModel] — konversi fromMap/toMap.
///
/// Memvalidasi mapping antara SQLite map (snake_case) dan Dart entity (camelCase),
/// termasuk konversi `INTEGER` (0/1) → `bool` untuk `is_active`.
///
/// Ref: Phase 9 TASK-044 TEST-001
void main() {
  // ---------------------------------------------------------------------------
  // Test Data
  // ---------------------------------------------------------------------------

  final Map<String, dynamic> activeImamMap = {
    'id': 1,
    'name': 'Ust. Ahmad Fauzi',
    'is_active': 1,
  };

  final Map<String, dynamic> inactiveImamMap = {
    'id': 2,
    'name': 'Ust. Budi Santoso',
    'is_active': 0,
  };

  // ---------------------------------------------------------------------------
  // TEST: ImanModel.fromMap()
  // ---------------------------------------------------------------------------

  group('ImanModel.fromMap()', () {
    test('memetakan imam aktif dengan benar (is_active=1 → true)', () {
      final model = ImanModel.fromMap(activeImamMap);

      expect(model.id, equals(1));
      expect(model.name, equals('Ust. Ahmad Fauzi'));
      expect(model.isActive, isTrue);
    });

    test('memetakan imam nonaktif dengan benar (is_active=0 → false)', () {
      final model = ImanModel.fromMap(inactiveImamMap);

      expect(model.id, equals(2));
      expect(model.name, equals('Ust. Budi Santoso'));
      expect(model.isActive, isFalse);
    });

    test('mengembalikan ImanModel yang merupakan subtype Imam (LSP)', () {
      final model = ImanModel.fromMap(activeImamMap);
      expect(model, isA<Imam>());
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: ImanModel.toMap()
  // ---------------------------------------------------------------------------

  group('ImanModel.toMap()', () {
    test(
      'mengkonversi ke snake_case map tanpa id saat includeId=false (default)',
      () {
        final model = ImanModel.fromMap(activeImamMap);
        final map = model.toMap();

        expect(map['name'], equals('Ust. Ahmad Fauzi'));
        expect(map['is_active'], equals(1)); // bool → int
        expect(map.containsKey('id'), isFalse); // id tidak disertakan
      },
    );

    test(
      'menyertakan id dalam map saat includeId=true',
      () {
        final model = ImanModel.fromMap(activeImamMap);
        final map = model.toMap(includeId: true);

        expect(map['id'], equals(1));
        expect(map['name'], equals('Ust. Ahmad Fauzi'));
        expect(map['is_active'], equals(1));
      },
    );

    test('mengkonversi isActive=false ke is_active=0', () {
      final model = ImanModel.fromMap(inactiveImamMap);
      final map = model.toMap();

      expect(map['is_active'], equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: toEntity()
  // ---------------------------------------------------------------------------

  group('toEntity()', () {
    test('mengembalikan Imam entity yang identik dengan model', () {
      final model = ImanModel.fromMap(activeImamMap);
      final entity = model.toEntity();

      expect(entity.id, equals(model.id));
      expect(entity.name, equals(model.name));
      expect(entity.isActive, equals(model.isActive));
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: Round-trip (fromMap → toMap → fromMap)
  // ---------------------------------------------------------------------------

  group('ImanModel round-trip', () {
    test('fromMap → toMap(includeId:true) → fromMap menghasilkan entity identik',
        () {
      final original = ImanModel.fromMap(activeImamMap);
      final map = original.toMap(includeId: true);
      final reconstructed = ImanModel.fromMap(map);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.name, equals(original.name));
      expect(reconstructed.isActive, equals(original.isActive));
    });
  });
}
