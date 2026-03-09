import 'dart:math';

import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state.dart';
import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';

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
    List<WisdomQuote>? activeQuotes,
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

    // 3. Wisdom Quote window check (sebelum fallback ke Standby)
    if (config.isWisdomEnabled &&
        activeQuotes != null &&
        activeQuotes.isNotEmpty) {
      final wisdomState = _evaluateWisdomWindow(
        now: now,
        config: config,
        activeQuotes: activeQuotes,
      );
      if (wisdomState != null) return wisdomState;
    }

    // 4. Fallback: Standby State
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

  /// Evaluasi apakah waktu [now] berada dalam wisdom display slot.
  /// Mengembalikan [WisdomQuoteState] jika ya, null jika tidak.
  WisdomQuoteState? _evaluateWisdomWindow({
    required DateTime now,
    required TransitionConfig config,
    required List<WisdomQuote> activeQuotes,
  }) {
    final windowStart = DateTime(
      now.year,
      now.month,
      now.day,
      config.wisdomStartHour,
      config.wisdomStartMinute,
    );
    final windowEnd = DateTime(
      now.year,
      now.month,
      now.day,
      config.wisdomEndHour,
      config.wisdomEndMinute,
    );

    if (!now.isAfterOrEqual(windowStart) || !now.isBefore(windowEnd)) {
      return null;
    }

    final cycleLengthSeconds =
        (config.wisdomIntervalMinutes + config.wisdomDurationMinutes) * 60;
    final wisdomDurationSeconds = config.wisdomDurationMinutes * 60;
    final secondsSinceStart = now.difference(windowStart).inSeconds;
    final positionInCycle = secondsSinceStart % cycleLengthSeconds;

    if (positionInCycle >= wisdomDurationSeconds) return null;

    final cycleNumber = secondsSinceStart ~/ cycleLengthSeconds;
    final count = activeQuotes.length;

    final quoteIndex = config.wisdomShuffle
        ? _buildShuffledIndices(count, now)[cycleNumber % count]
        : cycleNumber % count;

    final currentCycleStart = windowStart.add(
      Duration(seconds: cycleNumber * cycleLengthSeconds),
    );
    final wisdomDisplayEnd = currentCycleStart.add(
      Duration(minutes: config.wisdomDurationMinutes),
    );
    final remainingSeconds = wisdomDisplayEnd.difference(now).inSeconds;

    return WisdomQuoteState(
      currentQuote: activeQuotes[quoteIndex],
      currentIndex: quoteIndex,
      totalItems: count,
      currentTime: now,
      totalDurationSeconds: wisdomDurationSeconds,
      remainingSeconds: remainingSeconds.clamp(0, wisdomDurationSeconds),
    );
  }

  /// Menghasilkan daftar indeks teracak deterministik berdasarkan tanggal.
  /// Seed: `year*10000 + month*100 + day` sehingga urutan konsisten per hari.
  List<int> _buildShuffledIndices(int count, DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final rng = Random(seed);
    final indices = List<int>.generate(count, (i) => i);
    for (var i = count - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = indices[i];
      indices[i] = indices[j];
      indices[j] = temp;
    }
    return indices;
  }
}

/// Helper extension untuk perbandingan waktu inclusive start, exclusive end.
extension DateTimeComparison on DateTime {
  bool isAfterOrEqual(DateTime other) {
    return isAtSameMomentAs(other) || isAfter(other);
  }
}
