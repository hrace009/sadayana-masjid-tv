import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Domain entity yang merepresentasikan satu waktu sholat.
///
/// Immutable class dengan value equality via [Equatable].
/// Menyimpan waktu sholat setelah Ihtiyat diterapkan ([time]),
/// waktu asli dari library ([originalTime]), dan offset yang dipakai ([ihtiyatMinutes]).
///
/// Ref: Plan 05 — Phase 2, SPEC-03
class PrayerTime extends Equatable {
  /// Nama waktu sholat, salah satu dari:
  /// "Subuh", "Syuruq", "Dhuha", "Dzuhur", "Ashar", "Maghrib", "Isya"
  final String name;

  /// Waktu sholat setelah Ihtiyat (offset koreksi) diterapkan.
  /// Ini adalah waktu yang ditampilkan ke pengguna.
  final DateTime time;

  /// Waktu sholat asli dari library `adhan` sebelum Ihtiyat diterapkan.
  /// Disimpan untuk keperluan audit atau perbandingan.
  final DateTime originalTime;

  /// Offset Ihtiyat dalam menit yang diterapkan ke [originalTime].
  /// Nilai positif = ditambahkan, nilai negatif = dikurangi.
  final int ihtiyatMinutes;

  const PrayerTime({
    required this.name,
    required this.time,
    required this.originalTime,
    required this.ihtiyatMinutes,
  });

  /// Mengembalikan waktu sholat [time] dalam format "HH:mm" (24-jam).
  ///
  /// Contoh: "05:13", "12:30", "18:45"
  String get formattedTime => DateFormat('HH:mm').format(time);

  @override
  List<Object?> get props => [name, time, originalTime, ihtiyatMinutes];
}
