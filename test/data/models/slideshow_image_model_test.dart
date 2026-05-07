import 'package:flutter_test/flutter_test.dart';
import 'package:miqotul_khoir_tv/data/models/slideshow_image_model.dart';
import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';

/// Unit tests untuk [SlideshowImageModel] — fromMap, toMap, dan round-trip.
///
/// Ref: TASK-046 (Phase 8 — Slideshow Pengumuman), TEST-002
void main() {
  // ---------------------------------------------------------------------------
  // Test Data
  // ---------------------------------------------------------------------------

  final Map<String, dynamic> sampleMap = {
    'slot_index': 2,
    'file_name': 'slide_slot_2_1714987654321.jpg',
    'stored_path':
        '/data/user/0/com.example/files/slideshow/slide_slot_2_1714987654321.jpg',
    'mime_type': 'image/jpeg',
    'width': 1920,
    'height': 1080,
    'file_size_bytes': 245760,
    // created_at dan updated_at tidak di-map ke entity (lihat model)
    'created_at': '2026-05-06 10:00:00',
    'updated_at': '2026-05-06 10:00:00',
  };

  // ---------------------------------------------------------------------------
  // TEST: fromMap
  // ---------------------------------------------------------------------------

  group('SlideshowImageModel.fromMap()', () {
    test('memetakan semua field wajib dengan benar dari SQLite map', () {
      final model = SlideshowImageModel.fromMap(sampleMap);

      expect(model.slotIndex, equals(2));
      expect(model.fileName, equals('slide_slot_2_1714987654321.jpg'));
      expect(
        model.storedPath,
        equals(
          '/data/user/0/com.example/files/slideshow/slide_slot_2_1714987654321.jpg',
        ),
      );
      expect(model.mimeType, equals('image/jpeg'));
      expect(model.width, equals(1920));
      expect(model.height, equals(1080));
      expect(model.fileSizeBytes, equals(245760));
    });

    test(
      'mengabaikan kolom created_at dan updated_at (tidak ada di entity)',
      () {
        final model = SlideshowImageModel.fromMap(sampleMap);
        // Jika tidak melempar error berarti kolom timestamp aman diabaikan.
        // Entity tidak memiliki field created_at / updated_at.
        expect(model, isA<SlideshowImage>());
      },
    );

    test('slot_index 1 di-parse dengan benar', () {
      final map = Map<String, dynamic>.from(sampleMap);
      map['slot_index'] = 1;
      final model = SlideshowImageModel.fromMap(map);
      expect(model.slotIndex, equals(1));
    });

    test('slot_index 3 (batas atas) di-parse dengan benar', () {
      final map = Map<String, dynamic>.from(sampleMap);
      map['slot_index'] = 3;
      final model = SlideshowImageModel.fromMap(map);
      expect(model.slotIndex, equals(3));
    });
  });

  // ---------------------------------------------------------------------------
  // TEST: toMap
  // ---------------------------------------------------------------------------

  group('SlideshowImageModel.toMap()', () {
    test('menghasilkan snake_case map yang cocok untuk SQLite insert', () {
      final model = SlideshowImageModel.fromMap(sampleMap);
      final map = model.toMap();

      expect(map['slot_index'], equals(2));
      expect(map['file_name'], equals('slide_slot_2_1714987654321.jpg'));
      expect(
        map['stored_path'],
        equals(
          '/data/user/0/com.example/files/slideshow/slide_slot_2_1714987654321.jpg',
        ),
      );
      expect(map['mime_type'], equals('image/jpeg'));
      expect(map['width'], equals(1920));
      expect(map['height'], equals(1080));
      expect(map['file_size_bytes'], equals(245760));
    });

    test('toMap tidak menyertakan created_at (dikelola oleh DB default)', () {
      final model = SlideshowImageModel.fromMap(sampleMap);
      final map = model.toMap();
      expect(map.containsKey('created_at'), isFalse);
    });

    test(
      'toMap tidak menyertakan updated_at (diset eksplisit oleh data source)',
      () {
        final model = SlideshowImageModel.fromMap(sampleMap);
        final map = model.toMap();
        expect(map.containsKey('updated_at'), isFalse);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // TEST: Round-trip
  // ---------------------------------------------------------------------------

  group('Round-trip fromMap → toMap', () {
    test('tidak kehilangan metadata setelah round-trip', () {
      final model = SlideshowImageModel.fromMap(sampleMap);
      final map = model.toMap();
      final restored = SlideshowImageModel.fromMap(map);

      expect(restored.slotIndex, equals(model.slotIndex));
      expect(restored.fileName, equals(model.fileName));
      expect(restored.storedPath, equals(model.storedPath));
      expect(restored.mimeType, equals(model.mimeType));
      expect(restored.width, equals(model.width));
      expect(restored.height, equals(model.height));
      expect(restored.fileSizeBytes, equals(model.fileSizeBytes));
    });

    test('toEntity() menghasilkan SlideshowImage yang equal ke model', () {
      final model = SlideshowImageModel.fromMap(sampleMap);
      final entity = model.toEntity();

      // toEntity() mengembalikan SlideshowImage dengan field yang identik
      expect(entity.slotIndex, equals(model.slotIndex));
      expect(entity.fileName, equals(model.fileName));
      expect(entity.storedPath, equals(model.storedPath));
      expect(entity.mimeType, equals(model.mimeType));
      expect(entity.width, equals(model.width));
      expect(entity.height, equals(model.height));
      expect(entity.fileSizeBytes, equals(model.fileSizeBytes));
      expect(entity.runtimeType, equals(SlideshowImage));
    });

    test('Equatable: dua model dengan data sama dianggap equal', () {
      final a = SlideshowImageModel.fromMap(sampleMap);
      final b = SlideshowImageModel.fromMap(sampleMap);
      expect(a, equals(b));
    });

    test('Equatable: model dengan slotIndex berbeda tidak equal', () {
      final map2 = Map<String, dynamic>.from(sampleMap);
      map2['slot_index'] = 1;
      final a = SlideshowImageModel.fromMap(sampleMap); // slot 2
      final b = SlideshowImageModel.fromMap(map2); // slot 1
      expect(a, isNot(equals(b)));
    });
  });
}
