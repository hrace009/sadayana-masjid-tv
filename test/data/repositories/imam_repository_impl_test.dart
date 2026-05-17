import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';
import 'package:miqotul_khoir_tv/data/datasources/imam_local_data_source.dart';
import 'package:miqotul_khoir_tv/data/repositories/imam_repository_impl.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam.dart';
import 'package:miqotul_khoir_tv/data/models/imam_model.dart';

/// Unit tests untuk [ImamRepositoryImpl] dengan in-memory SQLite.
///
/// Memvalidasi CRUD: getAll, getById, insert, update, delete, count.
/// Termasuk validasi batas maksimal 10 imam (REQ-001).
///
/// Ref: Phase 9 TASK-044 TEST-003
void main() {
  late DatabaseHelper helper;
  late ImanLocalDataSource dataSource;
  late ImamRepositoryImpl repository;

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

    dataSource = ImanLocalDataSource(helper);
    repository = ImamRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await helper.close();
    helper.resetForTesting();
  });

  // ---------------------------------------------------------------------------
  // TEST: getAll
  // ---------------------------------------------------------------------------

  group('getAll()', () {
    test('mengembalikan list kosong saat tidak ada imam', () async {
      final imams = await repository.getAll();
      expect(imams, isEmpty);
    });

    test('mengembalikan list imam setelah insert, diurutkan by name ASC',
        () async {
      await repository.insert('Ust. Zain');
      await repository.insert('Ust. Ahmad');
      await repository.insert('Ust. Budi');

      final imams = await repository.getAll();

      expect(imams.length, equals(3));
      expect(imams[0].name, equals('Ust. Ahmad'));
      expect(imams[1].name, equals('Ust. Budi'));
      expect(imams[2].name, equals('Ust. Zain'));
    });

    test('mengembalikan Imam entities (bukan raw map)', () async {
      await repository.insert('Ust. Ahmad');
      final imams = await repository.getAll();
      expect(imams.first, isA<Imam>());
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: getById
  // ---------------------------------------------------------------------------

  group('getById()', () {
    test('mengembalikan null jika id tidak ditemukan', () async {
      final imam = await repository.getById(999);
      expect(imam, isNull);
    });

    test('mengembalikan imam yang benar berdasarkan id', () async {
      final newId = await repository.insert('Ust. Dani');
      final imam = await repository.getById(newId);

      expect(imam, isNotNull);
      expect(imam!.id, equals(newId));
      expect(imam.name, equals('Ust. Dani'));
      expect(imam.isActive, isTrue); // default isActive=true
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: insert
  // ---------------------------------------------------------------------------

  group('insert()', () {
    test('menyimpan imam baru dan mengembalikan id yang valid (> 0)', () async {
      final id = await repository.insert('Ust. Ahmad');
      expect(id, greaterThan(0));
    });

    test('imam baru memiliki isActive=true secara default', () async {
      final id = await repository.insert('Ust. Ahmad');
      final imam = await repository.getById(id);
      expect(imam!.isActive, isTrue);
    });

    test('menambah count setiap insert', () async {
      expect(await repository.count(), equals(0));
      await repository.insert('Ust. Ahmad');
      expect(await repository.count(), equals(1));
      await repository.insert('Ust. Budi');
      expect(await repository.count(), equals(2));
    });

    test('throws Exception saat mencapai batas 10 imam (REQ-001)', () async {
      // Insert 10 imam
      for (int i = 1; i <= 10; i++) {
        await repository.insert('Imam $i');
      }

      // Insert ke-11 harus throw
      expect(
        () => repository.insert('Imam 11'),
        throwsException,
      );
    });

    test(
        'throws jika nama imam sudah ada (UNIQUE constraint)', () async {
      await repository.insert('Ust. Ahmad');
      expect(
        () => repository.insert('Ust. Ahmad'),
        throwsException,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: update
  // ---------------------------------------------------------------------------

  group('update()', () {
    test('memperbarui nama imam', () async {
      final id = await repository.insert('Ust. Ahmad');
      final original = await repository.getById(id);

      final updated = ImanModel(
        id: original!.id,
        name: 'Ust. Ahmad Fauzi',
        isActive: original.isActive,
      );
      await repository.update(updated);

      final result = await repository.getById(id);
      expect(result!.name, equals('Ust. Ahmad Fauzi'));
    });

    test('dapat menonaktifkan imam (isActive=false)', () async {
      final id = await repository.insert('Ust. Ahmad');
      final original = await repository.getById(id);

      final deactivated = ImanModel(
        id: original!.id,
        name: original.name,
        isActive: false,
      );
      await repository.update(deactivated);

      final result = await repository.getById(id);
      expect(result!.isActive, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: delete
  // ---------------------------------------------------------------------------

  group('delete()', () {
    test('menghapus imam berdasarkan id', () async {
      final id = await repository.insert('Ust. Ahmad');
      expect(await repository.count(), equals(1));

      await repository.delete(id);

      expect(await repository.count(), equals(0));
      expect(await repository.getById(id), isNull);
    });

    test('no-op jika id tidak ditemukan (tidak throws)', () async {
      await expectLater(repository.delete(999), completes);
    });

    test('hanya menghapus imam yang ditentukan, imam lain tidak terpengaruh',
        () async {
      final id1 = await repository.insert('Ust. Ahmad');
      await repository.insert('Ust. Budi');

      await repository.delete(id1);

      final remaining = await repository.getAll();
      expect(remaining.length, equals(1));
      expect(remaining.first.name, equals('Ust. Budi'));
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: count
  // ---------------------------------------------------------------------------

  group('count()', () {
    test('mengembalikan 0 saat tidak ada imam', () async {
      expect(await repository.count(), equals(0));
    });

    test('mengembalikan jumlah total imam yang benar', () async {
      await repository.insert('Ust. Ahmad');
      await repository.insert('Ust. Budi');
      await repository.insert('Ust. Dani');

      expect(await repository.count(), equals(3));
    });

    test('berkurang setelah delete', () async {
      final id = await repository.insert('Ust. Ahmad');
      await repository.insert('Ust. Budi');
      expect(await repository.count(), equals(2));

      await repository.delete(id);
      expect(await repository.count(), equals(1));
    });
  });
}
