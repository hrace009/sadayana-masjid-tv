import 'package:equatable/equatable.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/prayer_time.dart';

import 'display_state_type.dart';

/// Base class untuk status tampilan layar.
/// Menggunakan sealed class untuk pattern matching yang aman.
sealed class DisplayState extends Equatable {
  const DisplayState();

  DisplayStateType get type;

  @override
  List<Object?> get props => [type];
}

/// Menunggu waktu sholat berikutnya. Status default.
class StandbyState extends DisplayState {
  final DailyPrayerTimes? dailyPrayerTimes;
  final PrayerTime? nextPrayer;
  final Duration? timeToNextPrayer;
  final String? runningText;
  final String? hijriDate;
  final DateTime currentTime;

  const StandbyState({
    this.dailyPrayerTimes,
    this.nextPrayer,
    this.timeToNextPrayer,
    this.runningText,
    this.hijriDate,
    required this.currentTime,
  });

  @override
  DisplayStateType get type => DisplayStateType.standby;

  @override
  List<Object?> get props => [
    dailyPrayerTimes,
    nextPrayer,
    timeToNextPrayer,
    runningText,
    hijriDate,
    currentTime,
  ];
}

/// Keadaan saat countdown menuju waktu Adzan.
class PreAdzanState extends DisplayState {
  final PrayerTime upcomingPrayer;
  final Duration remainingDuration;
  final int totalPreAdzanMinutes;
  final DailyPrayerTimes dailyPrayerTimes;

  const PreAdzanState({
    required this.upcomingPrayer,
    required this.remainingDuration,
    required this.totalPreAdzanMinutes,
    required this.dailyPrayerTimes,
  });

  @override
  DisplayStateType get type => DisplayStateType.preAdzan;

  double get progress {
    if (totalPreAdzanMinutes <= 0) return 1.0;
    final totalSeconds = totalPreAdzanMinutes * 60;
    final remainingSeconds = remainingDuration.inSeconds;
    final elapsed = totalSeconds - remainingSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    upcomingPrayer,
    remainingDuration,
    totalPreAdzanMinutes,
    dailyPrayerTimes,
  ];
}

/// Keadaan saat Adzan sedang berkumandang.
class AdzanState extends DisplayState {
  final PrayerTime currentPrayer;
  final Duration remainingDuration;
  final int totalAdzanSeconds;
  final DailyPrayerTimes dailyPrayerTimes;

  const AdzanState({
    required this.currentPrayer,
    required this.remainingDuration,
    required this.totalAdzanSeconds,
    required this.dailyPrayerTimes,
  });

  @override
  DisplayStateType get type => DisplayStateType.adzan;

  double get progress {
    if (totalAdzanSeconds <= 0) return 1.0;
    final elapsed = totalAdzanSeconds - remainingDuration.inSeconds;
    return (elapsed / totalAdzanSeconds).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    currentPrayer,
    remainingDuration,
    totalAdzanSeconds,
    dailyPrayerTimes,
  ];
}

/// Keadaan saat menunggu Iqomah (Countdown Sholat).
class IqomahState extends DisplayState {
  final PrayerTime currentPrayer;
  final Duration remainingDuration;
  final int totalIqomahMinutes;
  final DailyPrayerTimes dailyPrayerTimes;

  const IqomahState({
    required this.currentPrayer,
    required this.remainingDuration,
    required this.totalIqomahMinutes,
    required this.dailyPrayerTimes,
  });

  @override
  DisplayStateType get type => DisplayStateType.iqomah;

  double get progress {
    if (totalIqomahMinutes <= 0) return 1.0;
    final totalSeconds = totalIqomahMinutes * 60;
    final remainingSeconds = remainingDuration.inSeconds;
    final elapsed = totalSeconds - remainingSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    currentPrayer,
    remainingDuration,
    totalIqomahMinutes,
    dailyPrayerTimes,
  ];
}

/// Keadaan saat Sholat sedang berlangsung (Layar Silent/Gelap).
class SholatState extends DisplayState {
  final PrayerTime currentPrayer;
  final Duration remainingDuration;
  final int totalSholatMinutes;
  final DailyPrayerTimes dailyPrayerTimes;

  const SholatState({
    required this.currentPrayer,
    required this.remainingDuration,
    required this.totalSholatMinutes,
    required this.dailyPrayerTimes,
  });

  @override
  DisplayStateType get type => DisplayStateType.sholat;

  double get progress {
    if (totalSholatMinutes <= 0) return 1.0;
    final totalSeconds = totalSholatMinutes * 60;
    final remainingSeconds = remainingDuration.inSeconds;
    final elapsed = totalSeconds - remainingSeconds;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
    currentPrayer,
    remainingDuration,
    totalSholatMinutes,
    dailyPrayerTimes,
  ];
}
