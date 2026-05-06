import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';

/// Kontrak repository untuk CRUD metadata gambar slideshow.
///
/// Semua operasi berinteraksi dengan tabel `slideshow_images` di SQLite.
/// Implementasi konkret berada di data layer.
///
/// Ref: TASK-004 (Phase 1 — Slideshow Pengumuman)
abstract class SlideshowImageRepository {
  /// Mengambil semua gambar slideshow yang tersimpan, diurutkan berdasarkan
  /// [SlideshowImage.slotIndex] secara ascending.
  Future<List<SlideshowImage>> getAll();

  /// Mengambil gambar pada slot tertentu, atau `null` jika slot kosong.
  Future<SlideshowImage?> getBySlot(int slotIndex);

  /// Menyimpan atau mengganti metadata gambar pada slot yang sesuai.
  /// Operasi ini bersifat upsert berdasarkan [SlideshowImage.slotIndex].
  Future<void> save(SlideshowImage image);

  /// Menghapus metadata gambar pada slot tertentu.
  Future<void> deleteBySlot(int slotIndex);

  /// Mengembalikan jumlah slot yang terisi (0..3).
  Future<int> count();
}
