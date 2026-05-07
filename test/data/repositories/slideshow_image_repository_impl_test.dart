import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';
import 'package:miqotul_khoir_tv/data/datasources/slideshow_image_local_data_source.dart';
import 'package:miqotul_khoir_tv/data/repositories/slideshow_image_repository_impl.dart';
import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';

/// Unit tests untuk [SlideshowImageRepositoryImpl] dengan in-memory SQLite.
///
/// Setiap test mendapat fresh database (isolated). Test memverifikasi
/// CRUD `getAll`, `getBySlot`, `save`, `deleteBySlot`, dan `count()`.
///
/// Ref: TASK-048 (Phase 8 — Slideshow Pengumuman), TEST-003
void main() {
  late DatabaseHelper helper;
  late SlideshowImageLocalDataSource dataSource;
  late SlideshowImageRepositoryImpl repository;

  // Helper: buat SlideshowImage untuk slot tertentu
  SlideshowImage makeImage(int slot) => SlideshowImage(
    slotIndex: slot,
    fileName: 'slide_slot_${slot}_1000.jpg',
    storedPath: '/internal/slideshow/slide_slot_${slot}_1000.jpg',
    mimeType: 'image/jpeg',
    width: 1920,
    height: 1080,
    fileSizeBytes: 200000,
  );

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

    dataSource = SlideshowImageLocalDataSource(helper);
    repository = SlideshowImageRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await helper.close();
    helper.resetForTesting();
  });

  // ---------------------------------------------------------------------------
  // TEST: getAll
  // ---------------------------------------------------------------------------

  group('getAll()', () {
    test('mengembalikan list kosong saat tidak ada gambar', () async {
      final images = await repository.getAll();
      expect(images, isEmpty);
    });

    test(
      'mengembalikan semua gambar setelah save, diurutkan by slot_index',
      () async {
        await repository.save(makeImage(3));
        await repository.save(makeImage(1));

        final images = await repository.getAll();

        expect(images.length, equals(2));
        expect(images[0].slotIndex, equals(1));
        expect(images[1].slotIndex, equals(3));
      },
    );

    test('mengembalikan SlideshowImage entities (bukan raw map)', () async {
      await repository.save(makeImage(1));
      final images = await repository.getAll();
      expect(images.first, isA<SlideshowImage>());
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: getBySlot
  // ---------------------------------------------------------------------------

  group('getBySlot()', () {
    test('mengembalikan null jika slot kosong', () async {
      final image = await repository.getBySlot(1);
      expect(image, isNull);
    });

    test(
      'mengembalikan gambar yang benar untuk slot yang ditentukan',
      () async {
        await repository.save(makeImage(2));

        final image = await repository.getBySlot(2);

        expect(image, isNotNull);
        expect(image!.slotIndex, equals(2));
        expect(image.fileName, equals('slide_slot_2_1000.jpg'));
        expect(image.mimeType, equals('image/jpeg'));
      },
    );

    test('mengembalikan null untuk slot yang tidak diisi (slot 3)', () async {
      await repository.save(makeImage(1));
      final image = await repository.getBySlot(3);
      expect(image, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: save (insert + upsert)
  // ---------------------------------------------------------------------------

  group('save()', () {
    test('menyimpan gambar baru ke slot kosong', () async {
      await repository.save(makeImage(1));

      final image = await repository.getBySlot(1);

      expect(image, isNotNull);
      expect(
        image!.storedPath,
        equals('/internal/slideshow/slide_slot_1_1000.jpg'),
      );
      expect(image.width, equals(1920));
      expect(image.height, equals(1080));
      expect(image.fileSizeBytes, equals(200000));
    });

    test(
      'mengganti gambar lama dengan gambar baru di slot yang sama (upsert)',
      () async {
        await repository.save(makeImage(1)); // insert awal

        // Gambar baru dengan data berbeda di slot yang sama
        const newImage = SlideshowImage(
          slotIndex: 1,
          fileName: 'slide_slot_1_9999.png',
          storedPath: '/internal/slideshow/slide_slot_1_9999.png',
          mimeType: 'image/png',
          width: 1280,
          height: 720,
          fileSizeBytes: 100000,
        );
        await repository.save(newImage);

        final saved = await repository.getBySlot(1);

        expect(saved, isNotNull);
        expect(saved!.fileName, equals('slide_slot_1_9999.png'));
        expect(saved.mimeType, equals('image/png'));
        expect(saved.width, equals(1280));
      },
    );

    test('menyimpan gambar ke 3 slot sekaligus (slot 1, 2, 3)', () async {
      await repository.save(makeImage(1));
      await repository.save(makeImage(2));
      await repository.save(makeImage(3));

      final all = await repository.getAll();
      expect(all.length, equals(3));
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: deleteBySlot
  // ---------------------------------------------------------------------------

  group('deleteBySlot()', () {
    test('menghapus gambar dari slot yang ditentukan', () async {
      await repository.save(makeImage(2));

      await repository.deleteBySlot(2);

      final image = await repository.getBySlot(2);
      expect(image, isNull);
    });

    test('no-op jika slot sudah kosong (tidak throws)', () async {
      // Tidak ada gambar di slot 3
      await expectLater(repository.deleteBySlot(3), completes);
    });

    test(
      'hanya menghapus slot yang ditentukan, slot lain tidak terpengaruh',
      () async {
        await repository.save(makeImage(1));
        await repository.save(makeImage(2));

        await repository.deleteBySlot(1);

        final all = await repository.getAll();
        expect(all.length, equals(1));
        expect(all.first.slotIndex, equals(2));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // TEST: count
  // ---------------------------------------------------------------------------

  group('count()', () {
    test('mengembalikan 0 saat tidak ada gambar', () async {
      final count = await repository.count();
      expect(count, equals(0));
    });

    test('mengembalikan jumlah slot yang terisi dengan benar', () async {
      expect(await repository.count(), equals(0));

      await repository.save(makeImage(1));
      expect(await repository.count(), equals(1));

      await repository.save(makeImage(3));
      expect(await repository.count(), equals(2));

      await repository.save(makeImage(2));
      expect(await repository.count(), equals(3));
    });

    test('berkurang setelah deleteBySlot', () async {
      await repository.save(makeImage(1));
      await repository.save(makeImage(2));

      await repository.deleteBySlot(1);

      expect(await repository.count(), equals(1));
    });
  });
}
