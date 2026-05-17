import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';
import 'package:miqotul_khoir_tv/data/models/imam_model.dart';

/// Data source yang berinteraksi langsung dengan SQLite untuk imam.
///
/// Berisi raw SQL operations untuk tabel `imams` (master daftar imam).
///
/// REQ-001: Maksimal 10 imam dapat terdaftar, divalidasi saat insert.
class ImanLocalDataSource {
  final DatabaseHelper _databaseHelper;

  ImanLocalDataSource(this._databaseHelper);

  /// Ambil semua imam, diurutkan berdasarkan nama ascending.
  Future<List<ImanModel>> getAll() async {
    final db = await _databaseHelper.database;
    final results = await db.query('imams', orderBy: 'name ASC');
    return results.map(ImanModel.fromMap).toList();
  }

  /// Ambil satu imam berdasarkan [id].
  ///
  /// Mengembalikan `null` jika tidak ditemukan.
  Future<ImanModel?> getById(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'imams',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ImanModel.fromMap(results.first);
  }

  /// Menyimpan imam baru dengan [name] yang diberikan.
  ///
  /// [isActive] diset ke `true` secara default.
  /// Mengembalikan [id] dari baris yang baru dibuat.
  ///
  /// Throws jika sudah ada 10 imam terdaftar (REQ-001).
  /// Throws jika [name] sudah ada (UNIQUE constraint di DB).
  Future<int> insert(String name) async {
    final db = await _databaseHelper.database;

    // Validasi: maksimal 10 imam
    final count = await this.count();
    if (count >= 10) {
      throw Exception(
        'Maksimal 10 imam dapat didaftarkan. Saat ini sudah ada $count imam.',
      );
    }

    final result = await db.insert('imams', {'name': name, 'is_active': 1});
    return result;
  }

  /// Memperbarui data imam (name dan/atau isActive) berdasarkan [imam.id].
  Future<void> update(ImanModel imam) async {
    final db = await _databaseHelper.database;
    await db.update(
      'imams',
      imam.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [imam.id],
    );
  }

  /// Menghapus imam berdasarkan [id].
  ///
  /// Karena `imam_schedules.imam_id` dan `khatib_id` menggunakan
  /// `ON DELETE SET NULL`, slot jadwal yang mengacu imam ini akan
  /// secara otomatis diset ke NULL oleh database (foreign key enforcement).
  Future<void> delete(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('imams', where: 'id = ?', whereArgs: [id]);
  }

  /// Mengembalikan jumlah total imam yang tersimpan.
  Future<int> count() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM imams');
    return (result.first['count'] as int?) ?? 0;
  }
}
