import 'package:miqotul_khoir_tv/data/datasources/slideshow_image_local_data_source.dart';
import 'package:miqotul_khoir_tv/data/models/slideshow_image_model.dart';
import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';
import 'package:miqotul_khoir_tv/domain/repositories/slideshow_image_repository.dart';

/// Implementasi konkret [SlideshowImageRepository].
///
/// Mendelegasikan semua CRUD ke [SlideshowImageLocalDataSource] dan
/// melakukan konversi antara raw map SQLite dan domain entity melalui
/// [SlideshowImageModel].
///
/// Ref: TASK-015 (Phase 3 — Slideshow Pengumuman), GUD-003
class SlideshowImageRepositoryImpl implements SlideshowImageRepository {
  final SlideshowImageLocalDataSource _dataSource;

  SlideshowImageRepositoryImpl(this._dataSource);

  @override
  Future<List<SlideshowImage>> getAll() async {
    final rows = await _dataSource.getAll();
    return rows.map(SlideshowImageModel.fromMap).toList();
  }

  @override
  Future<SlideshowImage?> getBySlot(int slotIndex) async {
    final row = await _dataSource.getBySlot(slotIndex);
    if (row == null) return null;
    return SlideshowImageModel.fromMap(row);
  }

  @override
  Future<void> save(SlideshowImage image) async {
    final model = SlideshowImageModel(
      slotIndex: image.slotIndex,
      fileName: image.fileName,
      storedPath: image.storedPath,
      mimeType: image.mimeType,
      width: image.width,
      height: image.height,
      fileSizeBytes: image.fileSizeBytes,
    );
    await _dataSource.save(model.toMap());
  }

  @override
  Future<void> deleteBySlot(int slotIndex) =>
      _dataSource.deleteBySlot(slotIndex);

  @override
  Future<int> count() => _dataSource.count();
}
