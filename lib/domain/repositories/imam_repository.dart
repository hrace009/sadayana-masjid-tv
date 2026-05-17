import 'package:miqotul_khoir_tv/domain/entities/imam.dart';

/// Port: Abstract interface untuk operasi CRUD pada data imam.
///
/// Didefinisikan di domain layer agar Use Case dan Cubit tidak
/// bergantung pada detail implementasi (SQLite, dll).
///
/// Implementasi konkret: `ImamRepositoryImpl` di `data/repositories/`.
abstract class ImamRepository {
  /// Mengambil semua imam, diurutkan berdasarkan nama secara ascending.
  Future<List<Imam>> getAll();

  /// Mengambil satu imam berdasarkan [id].
  ///
  /// Mengembalikan `null` jika tidak ditemukan.
  Future<Imam?> getById(int id);

  /// Menyimpan imam baru dengan [name] yang diberikan.
  ///
  /// Mengembalikan [id] dari baris yang baru dibuat.
  /// [isActive] diset ke `true` secara default.
  Future<int> insert(String name);

  /// Memperbarui data imam (name dan/atau isActive) berdasarkan [imam.id].
  Future<void> update(Imam imam);

  /// Menghapus imam berdasarkan [id].
  ///
  /// Karena `imam_schedules.imam_id` dan `khatib_id` menggunakan
  /// `ON DELETE SET NULL`, slot jadwal yang mengacu imam ini akan
  /// secara otomatis diset ke NULL oleh database.
  Future<void> delete(int id);

  /// Mengembalikan jumlah total imam yang tersimpan.
  Future<int> count();
}
