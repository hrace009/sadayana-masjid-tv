import 'package:equatable/equatable.dart';

/// Domain entity yang merepresentasikan metadata satu gambar slideshow.
///
/// Setiap instance merepresentasikan satu slot gambar yang sudah diimpor
/// ke internal storage aplikasi. [slotIndex] adalah identitas permanen slot
/// pada rentang `1..3`, bukan ID database dinamis.
///
/// Ref: TASK-003 (Phase 1 — Slideshow Pengumuman)
class SlideshowImage extends Equatable {
  /// Indeks slot permanen gambar ini (`1..3`).
  final int slotIndex;

  /// Nama file hasil impor yang di-generate oleh aplikasi.
  final String fileName;

  /// Path absolut file gambar di internal storage aplikasi.
  final String storedPath;

  /// MIME type gambar, contoh: `image/jpeg`, `image/png`, `image/webp`.
  final String mimeType;

  /// Lebar gambar dalam piksel.
  final int width;

  /// Tinggi gambar dalam piksel.
  final int height;

  /// Ukuran file gambar dalam bytes.
  final int fileSizeBytes;

  const SlideshowImage({
    required this.slotIndex,
    required this.fileName,
    required this.storedPath,
    required this.mimeType,
    required this.width,
    required this.height,
    required this.fileSizeBytes,
  });

  @override
  List<Object?> get props => [
    slotIndex,
    fileName,
    storedPath,
    mimeType,
    width,
    height,
    fileSizeBytes,
  ];
}
