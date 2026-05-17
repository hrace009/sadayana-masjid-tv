import 'package:miqotul_khoir_tv/domain/entities/imam_schedule.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule_display.dart';

/// Port: Abstract interface untuk operasi read/write pada jadwal imam.
///
/// Didefinisikan di domain layer agar Cubit tidak bergantung pada
/// detail implementasi (SQLite JOIN, dll).
///
/// Implementasi konkret: `ImamScheduleRepositoryImpl` di `data/repositories/`.
abstract class ImamScheduleRepository {
  /// Mengambil 5 slot jadwal untuk [dayOfWeek] dalam bentuk resolved DTO,
  /// siap digunakan untuk binding UI dan tampilan layar utama.
  ///
  /// Selalu mengembalikan tepat 5 item (urutan: subuh, dzuhur/jumat,
  /// ashar, maghrib, isya). Slot yang belum diisi memiliki `imamId == null`.
  /// Pada hari Jumat, slot kedua menggunakan `prayerName = 'jumat'`.
  ///
  /// [dayOfWeek] mengikuti ISO 8601: 1=Senin … 7=Minggu.
  Future<List<ImamScheduleDisplay>> getScheduleForDay(int dayOfWeek);

  /// Mengambil raw entity jadwal untuk [dayOfWeek] tanpa JOIN ke tabel imam.
  ///
  /// Hanya mengembalikan baris yang benar-benar tersimpan di database
  /// (tidak di-pad menjadi 5 slot).
  Future<List<ImamSchedule>> getRawScheduleForDay(int dayOfWeek);

  /// Menyimpan atau memperbarui satu slot jadwal.
  ///
  /// Operasi ini bersifat upsert: jika baris dengan kombinasi
  /// ([dayOfWeek], [prayerName]) sudah ada, baris tersebut diperbarui;
  /// jika belum ada, baris baru dibuat.
  ///
  /// [imamId] null berarti slot imam dikosongkan.
  /// [khatibId] null berarti slot khatib dikosongkan (hanya relevan untuk Jumat).
  Future<void> setSchedule({
    required int dayOfWeek,
    required String prayerName,
    int? imamId,
    int? khatibId,
  });

  /// Menghapus semua entri jadwal untuk [dayOfWeek] tertentu.
  ///
  /// Digunakan saat user ingin mengosongkan seluruh jadwal satu hari.
  Future<void> clearScheduleForDay(int dayOfWeek);
}
