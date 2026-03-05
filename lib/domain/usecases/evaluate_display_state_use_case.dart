import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state.dart';

import 'package:miqotul_khoir_tv/domain/entities/transition_config.dart';

/// Use case (Pure Function) untuk mengevaluasi status tampilan saat ini.
/// input: Waktu sekarang, Jadwal Sholat, Konfigurasi Durasi.
/// output: [DisplayState] yang sesuai.
class EvaluateDisplayStateUseCase {
  const EvaluateDisplayStateUseCase();

  DisplayState evaluate({
    required DateTime now,
    required DailyPrayerTimes dailyPrayerTimes,
    required TransitionConfig config,
    String? runningText,
    String? hijriDate,
  }) {
    // 1. Iterasi hanya sholat wajib (5 waktu)
    final mainPrayers = dailyPrayerTimes.mainPrayers;

    for (final prayer in mainPrayers) {
      // Hitung window waktu untuk setiap fase
      final adzanStart = prayer.time;
      final adzanEnd = adzanStart.add(
        Duration(seconds: config.adzanDurationSeconds),
      );

      final iqomahDurationMinutes = config.getIqomahFor(prayer.name);
      final iqomahStart = adzanEnd;
      final iqomahEnd = iqomahStart.add(
        Duration(minutes: iqomahDurationMinutes),
      );

      final sholatStart = iqomahEnd;
      final sholatDurationMinutes = config.getSholatDurationFor(prayer.name);
      final sholatEnd = sholatStart.add(
        Duration(minutes: sholatDurationMinutes),
      );

      final preAdzanStart = adzanStart.subtract(
        Duration(minutes: config.preAdzanMinutes),
      );

      // 2. Cek apakah 'now' berada dalam salah satu window

      // PRE-ADZAN
      if (now.isAfterOrEqual(preAdzanStart) && now.isBefore(adzanStart)) {
        return PreAdzanState(
          upcomingPrayer: prayer,
          remainingDuration: adzanStart.difference(now),
          totalPreAdzanMinutes: config.preAdzanMinutes,
          dailyPrayerTimes: dailyPrayerTimes,
        );
      }

      // ADZAN
      if (now.isAfterOrEqual(adzanStart) && now.isBefore(adzanEnd)) {
        return AdzanState(
          currentPrayer: prayer,
          remainingDuration: adzanEnd.difference(now),
          totalAdzanSeconds: config.adzanDurationSeconds,
          dailyPrayerTimes: dailyPrayerTimes,
        );
      }

      // IQOMAH
      if (now.isAfterOrEqual(iqomahStart) && now.isBefore(iqomahEnd)) {
        return IqomahState(
          currentPrayer: prayer,
          remainingDuration: iqomahEnd.difference(now),
          totalIqomahMinutes: iqomahDurationMinutes,
          dailyPrayerTimes: dailyPrayerTimes,
        );
      }

      // SHOLAT
      if (now.isAfterOrEqual(sholatStart) && now.isBefore(sholatEnd)) {
        return SholatState(
          currentPrayer: prayer,
          remainingDuration: sholatEnd.difference(now),
          totalSholatMinutes: sholatDurationMinutes,
          dailyPrayerTimes: dailyPrayerTimes,
        );
      }
    }

    // 3. Fallback: Standby State
    final nextPrayer = dailyPrayerTimes.nextPrayer(now);
    Duration? timeToNext;

    if (nextPrayer != null) {
      timeToNext = nextPrayer.time.difference(now);
    }

    return StandbyState(
      dailyPrayerTimes: dailyPrayerTimes,
      nextPrayer: nextPrayer,
      timeToNextPrayer: timeToNext,
      runningText: runningText,
      hijriDate: hijriDate,
      currentTime: now,
    );
  }
}

/// Helper extension untuk perbandingan waktu inclusive start, exclusive end.
extension DateTimeComparison on DateTime {
  bool isAfterOrEqual(DateTime other) {
    return isAtSameMomentAs(other) || isAfter(other);
  }
}
