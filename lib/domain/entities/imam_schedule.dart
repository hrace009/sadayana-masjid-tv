import 'package:equatable/equatable.dart';

/// Domain entity yang merepresentasikan satu entri jadwal imam
/// untuk hari tertentu dan waktu sholat tertentu.
///
/// Immutable class dengan value equality via [Equatable].
/// Data bersumber dari tabel `imam_schedules` di SQLite.
///
/// [dayOfWeek] mengikuti ISO 8601: 1=Senin, 2=Selasa, ..., 7=Minggu,
/// konsisten dengan [DateTime.weekday].
///
/// [imamId] dan [khatibId] bersifat nullable karena slot bisa
/// belum diisi (imam_id NULL di database).
/// [khatibId] hanya relevan untuk slot Jumat ([prayerName] == 'jumat').
///
/// [props] hanya menggunakan [id] karena id sudah unik per baris.
class ImamSchedule extends Equatable {
  final int id;

  /// Hari dalam seminggu (ISO 8601): 1=Senin … 7=Minggu.
  final int dayOfWeek;

  /// Kunci waktu sholat: 'subuh', 'dzuhur', 'ashar', 'maghrib', 'isya',
  /// atau 'jumat' (khusus hari Jumat menggantikan 'dzuhur').
  final String prayerName;

  /// ID imam untuk slot ini; null jika belum ditentukan.
  final int? imamId;

  /// ID khatib untuk slot Jumat; null jika belum ditentukan
  /// atau bukan slot Jumat.
  final int? khatibId;

  const ImamSchedule({
    required this.id,
    required this.dayOfWeek,
    required this.prayerName,
    this.imamId,
    this.khatibId,
  });

  @override
  List<Object?> get props => [id];
}
