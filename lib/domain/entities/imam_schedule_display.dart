import 'package:equatable/equatable.dart';

/// DTO normalized dan resolved untuk satu slot jadwal imam.
///
/// Dihasilkan oleh [ImamScheduleLocalDataSource.getScheduleForDay()] melalui
/// LEFT JOIN ke tabel `imams`. Membawa dua kelompok data sekaligus:
/// - ID stabil untuk binding dropdown UI ([imamId], [khatibId]).
/// - Nama resolved untuk tampilan layar utama ([imamName], [khatibName]).
///
/// Berbeda dari [ImamSchedule] (raw entity), class ini sudah dinormalisasi:
/// - Selalu 5 slot per hari (urutan Subuh-Dzuhur/Jumat-Ashar-Maghrib-Isya).
/// - [prayerLabel] siap ditampilkan dalam bahasa Indonesia.
/// - Slot kosong memiliki [imamId] == null dan [imamName] == null.
///
/// [props] menggunakan kombinasi [dayOfWeek] + [prayerName] yang
/// bersifat unik per baris, memungkinkan perbandingan state yang tepat
/// di [BlocBuilder.buildWhen].
class ImamScheduleDisplay extends Equatable {
  /// Hari dalam seminggu (ISO 8601): 1=Senin … 7=Minggu.
  final int dayOfWeek;

  /// Kunci waktu sholat: 'subuh', 'dzuhur', 'ashar', 'maghrib', 'isya',
  /// atau 'jumat' (hari Jumat, menggantikan 'dzuhur').
  final String prayerName;

  /// Label siap tampil dalam bahasa Indonesia, misal: "Subuh", "Jumat",
  /// "Dzuhur", "Ashar", "Maghrib", "Isya".
  final String prayerLabel;

  /// ID imam yang bertugas; null jika slot belum diisi.
  final int? imamId;

  /// Nama imam yang bertugas (resolved dari JOIN); null jika slot kosong.
  final String? imamName;

  /// ID khatib (khusus slot Jumat); null jika belum diisi.
  final int? khatibId;

  /// Nama khatib (resolved dari JOIN, khusus slot Jumat); null jika kosong.
  final String? khatibName;

  const ImamScheduleDisplay({
    required this.dayOfWeek,
    required this.prayerName,
    required this.prayerLabel,
    this.imamId,
    this.imamName,
    this.khatibId,
    this.khatibName,
  });

  @override
  List<Object?> get props => [dayOfWeek, prayerName];
}
