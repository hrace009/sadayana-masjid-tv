import 'package:equatable/equatable.dart';

import 'prayer_time.dart';

/// Domain entity yang merepresentasikan semua 7 waktu sholat untuk satu hari.
///
/// Immutable class dengan value equality via [Equatable].
/// Menyimpan tanggal Masehi ([date]), tanggal Hijri ([hijriDate]),
/// serta entri [PrayerTime] untuk setiap waktu sholat.
///
/// Ref: Plan 05 — Phase 3, SPEC-03
class DailyPrayerTimes extends Equatable {
  /// Tanggal Masehi untuk data sholat ini.
  final DateTime date;

  /// Tanggal Hijri yang telah diformat, contoh: "12 Rajab 1447 H".
  final String hijriDate;

  /// Waktu Sholat Subuh.
  final PrayerTime subuh;

  /// Waktu Syuruq (terbit matahari). Bukan sholat wajib.
  final PrayerTime syuruq;

  /// Waktu Sholat Dhuha. Dhuha = Syuruq + offset menit.
  final PrayerTime dhuha;

  /// Waktu Sholat Dzuhur.
  final PrayerTime dzuhur;

  /// Waktu Sholat Ashar.
  final PrayerTime ashar;

  /// Waktu Sholat Maghrib.
  final PrayerTime maghrib;

  /// Waktu Sholat Isya.
  final PrayerTime isya;

  const DailyPrayerTimes({
    required this.date,
    required this.hijriDate,
    required this.subuh,
    required this.syuruq,
    required this.dhuha,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  /// Mengembalikan semua 7 waktu sholat dalam urutan kronologis.
  ///
  /// Urutan: [subuh, syuruq, dhuha, dzuhur, ashar, maghrib, isya]
  List<PrayerTime> get allPrayers => [
    subuh,
    syuruq,
    dhuha,
    dzuhur,
    ashar,
    maghrib,
    isya,
  ];

  /// Mengembalikan hanya 5 waktu sholat wajib (fardhu), tanpa Syuruq dan Dhuha.
  ///
  /// Urutan: [subuh, dzuhur, ashar, maghrib, isya]
  List<PrayerTime> get mainPrayers => [subuh, dzuhur, ashar, maghrib, isya];

  /// Mengembalikan waktu sholat yang paling baru sudah masuk berdasarkan [now].
  ///
  /// Iterasi dari waktu terakhir ke pertama. Mengembalikan [PrayerTime] pertama
  /// yang waktunya sudah lewat atau sama dengan [now].
  /// Mengembalikan `null` jika belum ada sholat yang masuk hari ini (sebelum Subuh).
  PrayerTime? currentPrayer(DateTime now) {
    final reversed = allPrayers.reversed;
    for (final prayer in reversed) {
      if (!prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null;
  }

  /// Mengembalikan waktu sholat berikutnya setelah [now].
  ///
  /// Iterasi dari waktu pertama ke terakhir. Mengembalikan [PrayerTime] pertama
  /// yang waktunya lebih besar dari [now].
  /// Mengembalikan `null` jika semua sholat sudah lewat (setelah Isya).
  PrayerTime? nextPrayer(DateTime now) {
    for (final prayer in allPrayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
    date,
    hijriDate,
    subuh,
    syuruq,
    dhuha,
    dzuhur,
    ashar,
    maghrib,
    isya,
  ];
}
