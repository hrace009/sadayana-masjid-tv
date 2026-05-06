import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';

/// Data model yang mengkonversi antara [SlideshowImage] entity dan SQLite map.
///
/// Mapping conventions:
/// - SQLite column names: `snake_case`
/// - Dart field names: `camelCase`
///
/// Ref: TASK-013 (Phase 2 — Slideshow Pengumuman)
class SlideshowImageModel extends SlideshowImage {
  const SlideshowImageModel({
    required super.slotIndex,
    required super.fileName,
    required super.storedPath,
    required super.mimeType,
    required super.width,
    required super.height,
    required super.fileSizeBytes,
  });

  /// Membuat [SlideshowImageModel] dari raw SQLite `Map<String, dynamic>`.
  ///
  /// Seluruh kolom wajib ada karena schema mendefinisikan semua kolom sebagai
  /// `NOT NULL`. `created_at` dan `updated_at` tidak dipetakan ke entity
  /// karena domain tidak membutuhkannya.
  factory SlideshowImageModel.fromMap(Map<String, dynamic> map) {
    return SlideshowImageModel(
      slotIndex: map['slot_index'] as int,
      fileName: map['file_name'] as String,
      storedPath: map['stored_path'] as String,
      mimeType: map['mime_type'] as String,
      width: map['width'] as int,
      height: map['height'] as int,
      fileSizeBytes: map['file_size_bytes'] as int,
    );
  }

  /// Mengkonversi ke SQLite-compatible map untuk operasi insert/update.
  ///
  /// Output menggunakan snake_case keys sesuai column names di tabel
  /// `slideshow_images`. Tidak menyertakan `created_at` karena dikelola
  /// oleh database default. `updated_at` diset eksplisit oleh data source
  /// saat operasi save/upsert (TS-P2-005).
  Map<String, dynamic> toMap() {
    return {
      'slot_index': slotIndex,
      'file_name': fileName,
      'stored_path': storedPath,
      'mime_type': mimeType,
      'width': width,
      'height': height,
      'file_size_bytes': fileSizeBytes,
    };
  }

  /// Mengkonversi model ke domain entity [SlideshowImage].
  SlideshowImage toEntity() {
    return SlideshowImage(
      slotIndex: slotIndex,
      fileName: fileName,
      storedPath: storedPath,
      mimeType: mimeType,
      width: width,
      height: height,
      fileSizeBytes: fileSizeBytes,
    );
  }
}
