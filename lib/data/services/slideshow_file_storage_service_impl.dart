import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';
import 'package:miqotul_khoir_tv/domain/services/slideshow_file_storage_service.dart';

/// Implementasi konkret [SlideshowFileStorageService] yang menyimpan gambar
/// slideshow ke direktori internal aplikasi (`<appDocDir>/slideshow/`).
///
/// **Keamanan (SEC-004)**: Hanya ekstensi dalam `_allowedExtensions` yang
/// diterima. File di luar whitelist ini dilempar sebagai [Exception].
///
/// **Dimensi gambar (TS-P3-004)**: Dibaca langsung dari bytes menggunakan
/// `dart:ui` sehingga tidak memerlukan package tambahan.
///
/// **Idempoten (TS-P3-008)**: [deleteStoredImage] melakukan cek `exists()`
/// sebelum delete — tidak akan error bila file sudah terhapus lebih dulu.
///
/// Ref: TASK-017, TASK-018 (Phase 3 — Slideshow Pengumuman)
class SlideshowFileStorageServiceImpl implements SlideshowFileStorageService {
  /// Whitelist ekstensi yang diizinkan. Dibandingkan setelah `toLowerCase()`.
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Peta ekstensi → MIME type.
  static const _mimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  @override
  Future<SlideshowImage> importImage({
    required int slotIndex,
    required String originalFileName,
    required Uint8List bytes,
  }) async {
    // 1. Validasi ekstensi
    final ext = p
        .extension(originalFileName)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw Exception(
        'Format file tidak didukung: .$ext. '
        'Hanya jpg, jpeg, png, webp yang diizinkan.',
      );
    }

    // 2. Decode gambar untuk mendapatkan dimensi (TS-P3-004)
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width;
    final height = frame.image.height;
    frame.image.dispose();
    codec.dispose();

    // 3. Generate nama file unik berdasarkan slot dan timestamp (TS-P3-002)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'slide_slot_${slotIndex}_$timestamp.$ext';

    // 4. Resolusi direktori penyimpanan (TS-P3-001)
    final appDocDir = await getApplicationDocumentsDirectory();
    final slideshowDir = Directory(p.join(appDocDir.path, 'slideshow'));
    if (!slideshowDir.existsSync()) {
      await slideshowDir.create(recursive: true);
    }

    // 5. Tulis bytes ke file
    final storedPath = p.join(slideshowDir.path, fileName);
    await File(storedPath).writeAsBytes(bytes);

    // 6. Kembalikan entity domain
    return SlideshowImage(
      slotIndex: slotIndex,
      fileName: fileName,
      storedPath: storedPath,
      mimeType: _mimeTypes[ext]!,
      width: width,
      height: height,
      fileSizeBytes: bytes.length,
    );
  }

  @override
  Future<void> deleteStoredImage(String storedPath) async {
    final file = File(storedPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
