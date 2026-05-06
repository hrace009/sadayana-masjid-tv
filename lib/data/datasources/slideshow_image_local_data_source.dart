import 'package:sqflite/sqflite.dart';

import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';

/// Data source yang berinteraksi langsung dengan SQLite untuk tabel
/// `slideshow_images`.
///
/// Berisi raw SQL operations. Tidak memiliki business logic —
/// itu tanggung jawab repository layer.
///
/// `save()` menggunakan upsert berbasis `slot_index` sehingga operasi
/// insert dan replace slot dapat dilakukan lewat satu method yang sama.
///
/// Ref: TASK-014 (Phase 3 — Slideshow Pengumuman), TS-P2-005, TS-P3-005
class SlideshowImageLocalDataSource {
  final DatabaseHelper _databaseHelper;

  SlideshowImageLocalDataSource(this._databaseHelper);

  /// Mengambil semua row dari `slideshow_images`, diurutkan ascending
  /// berdasarkan `slot_index`.
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _databaseHelper.database;
    return db.query('slideshow_images', orderBy: 'slot_index ASC');
  }

  /// Mengambil row pada slot tertentu, atau `null` jika slot kosong.
  Future<Map<String, dynamic>?> getBySlot(int slotIndex) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'slideshow_images',
      where: 'slot_index = ?',
      whereArgs: [slotIndex],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  /// Menyimpan atau mengganti metadata gambar pada slot tertentu.
  ///
  /// Upsert dilakukan dengan [ConflictAlgorithm.replace] yang memanfaatkan
  /// `slot_index` sebagai PRIMARY KEY — jika row sudah ada maka diganti,
  /// jika belum maka di-insert. `updated_at` diset eksplisit pada tiap
  /// operasi save sesuai TS-P2-005.
  Future<void> save(Map<String, dynamic> data) async {
    final db = await _databaseHelper.database;
    final payload = Map<String, dynamic>.from(data);
    payload['updated_at'] = DateTime.now()
        .toLocal()
        .toString()
        .split('.')
        .first;
    await db.insert(
      'slideshow_images',
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Menghapus row pada slot tertentu. No-op jika slot sudah kosong.
  Future<void> deleteBySlot(int slotIndex) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'slideshow_images',
      where: 'slot_index = ?',
      whereArgs: [slotIndex],
    );
  }

  /// Mengembalikan jumlah slot yang terisi (0..3).
  Future<int> count() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM slideshow_images',
    );
    return (result.first['cnt'] as int?) ?? 0;
  }
}
