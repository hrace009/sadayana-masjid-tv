import 'package:equatable/equatable.dart';
import 'package:miqotul_khoir_tv/domain/entities/settings.dart';

/// Konfigurasi durasi transisi antar status tampilan.
class TransitionConfig extends Equatable {
  final int preAdzanMinutes;
  final int adzanDurationSeconds;
  final int sholatDurationMinutes;

  /// Durasi layar mati khusus hari Jum'at (menit). Mencakup khutbah + sholat.
  final int sholatJumatDurationMinutes;
  final Map<String, int> iqomahMinutes;

  const TransitionConfig({
    required this.preAdzanMinutes,
    required this.adzanDurationSeconds,
    required this.sholatDurationMinutes,
    this.sholatJumatDurationMinutes = 45,
    required this.iqomahMinutes,
  });

  /// Factory method untuk membuat [TransitionConfig] dari [Settings].
  factory TransitionConfig.fromSettings(Settings settings) {
    return TransitionConfig(
      preAdzanMinutes: settings.preAdzanMinutes,
      adzanDurationSeconds: settings.adzanDurationSeconds,
      sholatDurationMinutes: settings.sholatDurationMinutes,
      sholatJumatDurationMinutes: settings.sholatJumatDurationMinutes,
      iqomahMinutes: {
        'Subuh': settings.iqomahSubuh,
        'Dzuhur': settings.iqomahDzuhur,
        "Jum'at": settings.iqomahJumat,
        'Ashar': settings.iqomahAshar,
        'Maghrib': settings.iqomahMaghrib,
        'Isya': settings.iqomahIsya,
      },
    );
  }

  /// Helper untuk mendapatkan durasi iqomah berdasarkan nama sholat.
  /// Default ke 10 menit jika key tidak ditemukan (fallback safety).
  int getIqomahFor(String prayerName) {
    return iqomahMinutes[prayerName] ?? 10;
  }

  /// Helper untuk mendapatkan durasi sholat berdasarkan nama sholat.
  /// Mengembalikan [sholatJumatDurationMinutes] jika [prayerName] adalah "Jum'at",
  /// selain itu mengembalikan [sholatDurationMinutes].
  int getSholatDurationFor(String prayerName) {
    if (prayerName == "Jum'at") return sholatJumatDurationMinutes;
    return sholatDurationMinutes;
  }

  @override
  List<Object?> get props => [
    preAdzanMinutes,
    adzanDurationSeconds,
    sholatDurationMinutes,
    sholatJumatDurationMinutes,
    iqomahMinutes,
  ];
}
