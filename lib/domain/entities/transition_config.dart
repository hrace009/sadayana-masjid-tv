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

  // Kata Mutiara Islam
  final bool isWisdomEnabled;
  final int wisdomIntervalMinutes;
  final int wisdomDurationMinutes;
  final int wisdomStartHour;
  final int wisdomStartMinute;
  final int wisdomEndHour;
  final int wisdomEndMinute;
  final bool wisdomShuffle;

  // Mode Hemat Daya Malam
  final bool isMidnightModeEnabled;
  final int midnightStartHour;
  final int midnightStartMinute;
  final int midnightEndHour;
  final int midnightEndMinute;

  // Alarm Tanda Waktu
  final bool isPreAdzanAlertEnabled;
  final bool isPreIqomahAlertEnabled;
  final int preAdzanAlertSeconds;
  final int preIqomahAlertSeconds;

  const TransitionConfig({
    required this.preAdzanMinutes,
    required this.adzanDurationSeconds,
    required this.sholatDurationMinutes,
    this.sholatJumatDurationMinutes = 45,
    required this.iqomahMinutes,
    this.isWisdomEnabled = false,
    this.wisdomIntervalMinutes = 15,
    this.wisdomDurationMinutes = 3,
    this.wisdomStartHour = 6,
    this.wisdomStartMinute = 0,
    this.wisdomEndHour = 21,
    this.wisdomEndMinute = 0,
    this.wisdomShuffle = false,
    this.isMidnightModeEnabled = false,
    this.midnightStartHour = 23,
    this.midnightStartMinute = 0,
    this.midnightEndHour = 3,
    this.midnightEndMinute = 30,
    this.isPreAdzanAlertEnabled = false,
    this.isPreIqomahAlertEnabled = false,
    this.preAdzanAlertSeconds = 10,
    this.preIqomahAlertSeconds = 10,
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
      isWisdomEnabled: settings.isWisdomEnabled,
      wisdomIntervalMinutes: settings.wisdomIntervalMinutes,
      wisdomDurationMinutes: settings.wisdomDurationMinutes,
      wisdomStartHour: settings.wisdomStartHour,
      wisdomStartMinute: settings.wisdomStartMinute,
      wisdomEndHour: settings.wisdomEndHour,
      wisdomEndMinute: settings.wisdomEndMinute,
      wisdomShuffle: settings.wisdomShuffle,
      isMidnightModeEnabled: settings.isMidnightModeEnabled,
      midnightStartHour: settings.midnightStartHour,
      midnightStartMinute: settings.midnightStartMinute,
      midnightEndHour: settings.midnightEndHour,
      midnightEndMinute: settings.midnightEndMinute,
      isPreAdzanAlertEnabled: settings.isPreAdzanAlertEnabled,
      isPreIqomahAlertEnabled: settings.isPreIqomahAlertEnabled,
      preAdzanAlertSeconds: settings.preAdzanAlertSeconds,
      preIqomahAlertSeconds: settings.preIqomahAlertSeconds,
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
    isWisdomEnabled,
    wisdomIntervalMinutes,
    wisdomDurationMinutes,
    wisdomStartHour,
    wisdomStartMinute,
    wisdomEndHour,
    wisdomEndMinute,
    wisdomShuffle,
    isMidnightModeEnabled,
    midnightStartHour,
    midnightStartMinute,
    midnightEndHour,
    midnightEndMinute,
    isPreAdzanAlertEnabled,
    isPreIqomahAlertEnabled,
    preAdzanAlertSeconds,
    preIqomahAlertSeconds,
  ];
}
