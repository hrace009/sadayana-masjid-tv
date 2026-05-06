import 'dart:typed_data';

import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';

/// Kontrak service untuk manajemen file gambar slideshow di internal storage.
///
/// Implementasi konkret menangani akses filesystem dan hanya boleh menulis
/// ke app-specific internal storage. File sumber dari picker tidak pernah
/// dipakai langsung pada runtime.
///
/// Ref: TASK-005 (Phase 1 — Slideshow Pengumuman)
abstract class SlideshowFileStorageService {
  /// Mengimpor gambar ke internal storage aplikasi dan mengembalikan entity
  /// [SlideshowImage] dengan metadata yang sudah diisi.
  ///
  /// Alur impor:
  /// 1. Validasi ekstensi dari [originalFileName] terhadap whitelist
  ///    (`jpg`, `jpeg`, `png`, `webp`).
  /// 2. Decode [bytes] untuk membaca dimensi gambar.
  /// 3. Tolak jika bytes bukan gambar valid atau ekstensi tidak didukung.
  /// 4. Generate nama file terkontrol aplikasi dengan pola
  ///    `slide_slot_{slotIndex}_{millisecondsSinceEpoch}.{ext}`.
  /// 5. Simpan file ke subfolder `slideshow/` di app documents directory.
  /// 6. Return entity dengan semua metadata terisi.
  ///
  /// Throws [Exception] jika validasi gagal atau operasi I/O error.
  Future<SlideshowImage> importImage({
    required int slotIndex,
    required String originalFileName,
    required Uint8List bytes,
  });

  /// Menghapus file gambar dari internal storage berdasarkan path-nya.
  ///
  /// Operasi ini idempotent: jika file sudah tidak ada, tidak akan error.
  Future<void> deleteStoredImage(String storedPath);
}
