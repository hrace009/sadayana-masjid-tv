import 'dart:math';

import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule_display.dart';
import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';
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
    List<SlideshowImage>? slideshowImages,
    List<ImamScheduleDisplay>? todayImamSchedule,
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

    // 3. Midnight Mode window check (setelah sholat, sebelum Wisdom Quote)
    // Siklus sholat tetap diprioritaskan — midnight hanya aktif di luar sholat.
    if (config.isMidnightModeEnabled) {
      final midnightState = _evaluateMidnightWindow(
        now: now,
        config: config,
        dailyPrayerTimes: dailyPrayerTimes,
      );
      if (midnightState != null) return midnightState;
    }

    // 4. Slideshow Announcement window check (setelah midnight, sebelum imam)
    // Urutan eksplisit: prayer -> midnight -> slideshow -> imam_schedule -> wisdom -> standby
    if (config.isSlideshowEnabled &&
        slideshowImages != null &&
        slideshowImages.isNotEmpty) {
      final slideshowState = _evaluateSlideshowWindow(
        now: now,
        config: config,
        activeImages: slideshowImages,
      );
      if (slideshowState != null) return slideshowState;
    }

    // 5. Imam Schedule window check (setelah slideshow, sebelum wisdom)
    if (config.isImamScheduleEnabled &&
        todayImamSchedule != null &&
        todayImamSchedule.isNotEmpty) {
      final imamState = _evaluateImamScheduleWindow(
        now: now,
        config: config,
        todaySchedule: todayImamSchedule,
        hijriDate: hijriDate ?? '',
      );
      if (imamState != null) return imamState;
    }

    // 6. Wisdom Quote window check (sebelum fallback ke Standby)
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

    // 7. Fallback: Standby State
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

  /// Daftar nama hari dalam Bahasa Indonesia (indeks 0 tidak dipakai;
  /// 1=Senin...7=Minggu mengikuti ISO 8601 / [DateTime.weekday]).
  static const _dayNames = [
    '',
    'SENIN',
    'SELASA',
    'RABU',
    'KAMIS',
    "JUM'AT",
    'SABTU',
    'MINGGU',
  ];

  /// Evaluasi apakah waktu [now] berada dalam window dan slot aktif
  /// jadwal imam sholat berjamaah.
  ///
  /// **Logika siklus**:
  /// - `cycleLength = intervalMinutes * 60 + durationSeconds`
  /// - `positionInCycle = secondsSinceWindowStart % cycleLength`
  /// - Jika `positionInCycle < durationSeconds` → dalam slot aktif, tampilkan jadwal.
  /// - Jika `positionInCycle >= durationSeconds` → dalam jeda interval, kembalikan null.
  ///
  /// Mengembalikan [ImamScheduleState] jika dalam slot aktif, null jika tidak.
  ImamScheduleState? _evaluateImamScheduleWindow({
    required DateTime now,
    required TransitionConfig config,
    required List<ImamScheduleDisplay> todaySchedule,
    required String hijriDate,
  }) {
    // 1. Cek apakah now berada dalam window aktif jadwal imam
    final windowStart = DateTime(
      now.year,
      now.month,
      now.day,
      config.imamScheduleStartHour,
      config.imamScheduleStartMinute,
    );
    final windowEnd = DateTime(
      now.year,
      now.month,
      now.day,
      config.imamScheduleEndHour,
      config.imamScheduleEndMinute,
    );

    if (!now.isAfterOrEqual(windowStart) || !now.isBefore(windowEnd)) {
      return null;
    }

    // 2. Hitung parameter siklus
    final durationSeconds = config.imamScheduleDurationSeconds;
    final intervalSeconds = config.imamScheduleIntervalMinutes * 60;
    final cycleLength = durationSeconds + intervalSeconds;

    final secondsSinceStart = now.difference(windowStart).inSeconds;
    final positionInCycle = secondsSinceStart % cycleLength;

    // 3. Jika posisi berada dalam jeda interval, bukan dalam slot aktif
    if (positionInCycle >= durationSeconds) return null;

    // 4. Bangun state dengan sisa waktu dan nama hari
    final remainingSeconds = durationSeconds - positionInCycle;
    final dayName = _dayNames[now.weekday];

    return ImamScheduleState(
      dayName: dayName,
      hijriDate: hijriDate,
      slots: todaySchedule,
      currentTime: now,
      totalDurationSeconds: durationSeconds,
      remainingSeconds: remainingSeconds.clamp(0, durationSeconds),
    );
  }

  /// Evaluasi apakah waktu [now] berada dalam window midnight mode.
  ///
  /// Mendukung window **cross-midnight** (misal 23:00 – 03:30): jika
  /// `startMinutes > endMinutes`, digunakan logika OR.
  /// Window non-cross-midnight (misal 01:00 – 03:00) menggunakan logika AND.
  ///
  /// Mengembalikan [MidnightStandbyState] jika dalam window, null jika tidak.
  MidnightStandbyState? _evaluateMidnightWindow({
    required DateTime now,
    required TransitionConfig config,
    required DailyPrayerTimes dailyPrayerTimes,
  }) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes =
        config.midnightStartHour * 60 + config.midnightStartMinute;
    final endMinutes = config.midnightEndHour * 60 + config.midnightEndMinute;

    final bool isInWindow;
    if (startMinutes > endMinutes) {
      // Cross-midnight window: misal 23:00 – 03:30
      isInWindow = nowMinutes >= startMinutes || nowMinutes < endMinutes;
    } else {
      // Window dalam satu hari: misal 01:00 – 03:00
      isInWindow = nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }

    if (!isInWindow) return null;

    final subuh = dailyPrayerTimes.subuh;
    final subuhHour = subuh.time.hour.toString().padLeft(2, '0');
    final subuhMinute = subuh.time.minute.toString().padLeft(2, '0');

    return MidnightStandbyState(
      currentTime: now,
      subuhTime: subuh.time,
      subuhLabel: 'Subuh - $subuhHour:$subuhMinute',
    );
  }

  /// Evaluasi apakah waktu [now] berada dalam slot aktif slideshow.
  ///
  /// **Rumus siklus (TS-P5-002)**:
  /// - `slotDurationSeconds = slideshowSlotDurationMinutes * 60`
  /// - `intervalSeconds     = slideshowIntervalMinutes * 60`
  /// - `cycleLengthSeconds  = slotDurationSeconds + intervalSeconds`
  ///
  /// **Posisi dalam siklus (TS-P5-003)**:
  /// - `positionInCycle = secondsSinceWindowStart % cycleLengthSeconds`
  /// - Jika `positionInCycle >= slotDurationSeconds` → dalam jeda interval,
  ///   kembalikan `null` dan lanjut ke wisdom atau standby.
  ///
  /// **Index gambar (TS-P5-004)**:
  /// - `(positionInCycle ~/ imageDurationSeconds) % activeImages.length`
  ///
  /// Slot kosong sudah diabaikan oleh caller — [activeImages] hanya memuat
  /// slot yang benar-benar terisi, diurutkan naik berdasarkan `slotIndex`
  /// sesuai TS-P5-001.
  ///
  /// Mengembalikan [SlideshowAnnouncementState] jika dalam slot aktif,
  /// atau `null` jika di luar window atau dalam jeda interval.
  SlideshowAnnouncementState? _evaluateSlideshowWindow({
    required DateTime now,
    required TransitionConfig config,
    required List<SlideshowImage> activeImages,
  }) {
    // 1. Cek apakah now berada dalam window aktif slideshow
    final windowStart = DateTime(
      now.year,
      now.month,
      now.day,
      config.slideshowStartHour,
      config.slideshowStartMinute,
    );
    final windowEnd = DateTime(
      now.year,
      now.month,
      now.day,
      config.slideshowEndHour,
      config.slideshowEndMinute,
    );

    if (!now.isAfterOrEqual(windowStart) || !now.isBefore(windowEnd)) {
      return null;
    }

    // 2. Hitung parameter siklus
    final slotDurationSeconds = config.slideshowSlotDurationMinutes * 60;
    final intervalSeconds = config.slideshowIntervalMinutes * 60;
    final cycleLengthSeconds = slotDurationSeconds + intervalSeconds;
    final imageDurationSeconds = config.slideshowImageDurationSeconds;

    final secondsSinceWindowStart = now.difference(windowStart).inSeconds;
    final positionInCycle = secondsSinceWindowStart % cycleLengthSeconds;

    // 3. Jika posisi berada dalam jeda interval, bukan dalam slot aktif
    if (positionInCycle >= slotDurationSeconds) return null;

    // 4. Pilih gambar berdasarkan posisi dalam slot (TS-P5-004)
    final imageIndex =
        (positionInCycle ~/ imageDurationSeconds) % activeImages.length;
    final currentImage = activeImages[imageIndex];

    // 5. Hitung sisa waktu slot dan sisa waktu gambar
    final remainingSlotSeconds = slotDurationSeconds - positionInCycle;
    final positionInImage = positionInCycle % imageDurationSeconds;
    final remainingImageSeconds = imageDurationSeconds - positionInImage;

    return SlideshowAnnouncementState(
      currentImage: currentImage,
      currentIndex: imageIndex,
      totalItems: activeImages.length,
      currentTime: now,
      totalSlotDurationSeconds: slotDurationSeconds,
      remainingSlotSeconds: remainingSlotSeconds.clamp(0, slotDurationSeconds),
      imageDurationSeconds: imageDurationSeconds,
      remainingImageSeconds: remainingImageSeconds.clamp(
        0,
        imageDurationSeconds,
      ),
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
