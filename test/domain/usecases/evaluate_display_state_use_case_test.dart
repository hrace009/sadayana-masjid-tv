import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state_type.dart';
import 'package:miqotul_khoir_tv/domain/entities/prayer_time.dart';
import 'package:miqotul_khoir_tv/domain/entities/transition_config.dart';
import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';
import 'package:miqotul_khoir_tv/domain/usecases/evaluate_display_state_use_case.dart';

class MockDailyPrayerTimes extends Mock implements DailyPrayerTimes {}

class MockPrayerTime extends Mock implements PrayerTime {}

void main() {
  late EvaluateDisplayStateUseCase useCase;
  late MockDailyPrayerTimes mockDailyPrayerTimes;
  late TransitionConfig config;

  // Setup Prayer Times

  final subuhTime = DateTime(2026, 2, 19, 4, 30);
  final dzuhurTime = DateTime(2026, 2, 19, 12, 0);
  final asharTime = DateTime(2026, 2, 19, 15, 30);
  final maghribTime = DateTime(2026, 2, 19, 18, 0);
  final isyaTime = DateTime(2026, 2, 19, 19, 30);

  // Helper to create PrayerTime
  PrayerTime createPT(String name, DateTime time) {
    return PrayerTime(
      name: name,
      time: time,
      originalTime: time,
      ihtiyatMinutes: 0,
    );
  }

  final subuh = createPT('Subuh', subuhTime);
  final dzuhur = createPT('Dzuhur', dzuhurTime);
  final ashar = createPT('Ashar', asharTime);
  final maghrib = createPT('Maghrib', maghribTime);
  final isya = createPT('Isya', isyaTime);

  final mainPrayers = [subuh, dzuhur, ashar, maghrib, isya];

  setUp(() {
    useCase = const EvaluateDisplayStateUseCase();
    mockDailyPrayerTimes = MockDailyPrayerTimes();

    // Config:
    // PreAdzan: 10 min
    // Adzan: 3 min (180 sec)
    // Iqomah: 10 min (all)
    // Sholat: 10 min
    config = const TransitionConfig(
      preAdzanMinutes: 10,
      adzanDurationSeconds: 180,
      sholatDurationMinutes: 10,
      iqomahMinutes: {
        'Subuh': 10,
        'Dzuhur': 10,
        'Ashar': 10,
        'Maghrib': 10,
        'Isya': 10,
      },
    );

    when(() => mockDailyPrayerTimes.mainPrayers).thenReturn(mainPrayers);
  });

  group('EvaluateDisplayStateUseCase', () {
    test('returns StandbyState when outside all windows (11:00)', () {
      final now = DateTime(2026, 2, 19, 11, 0);
      when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(dzuhur);

      final result = useCase.evaluate(
        now: now,
        dailyPrayerTimes: mockDailyPrayerTimes,
        config: config,
      );

      expect(result, isA<StandbyState>());
      expect((result as StandbyState).nextPrayer, dzuhur);
      expect(result.type, DisplayStateType.standby);
    });

    test('returns PreAdzanState when 5 mins before Dzuhur (11:55)', () {
      final now = DateTime(2026, 2, 19, 11, 55);
      // PreAdzan window: 11:50 - 12:00

      final result = useCase.evaluate(
        now: now,
        dailyPrayerTimes: mockDailyPrayerTimes,
        config: config,
      );

      expect(result, isA<PreAdzanState>());
      final state = result as PreAdzanState;
      expect(state.upcomingPrayer.name, 'Dzuhur');
      expect(state.remainingDuration, const Duration(minutes: 5));
      expect(state.type, DisplayStateType.preAdzan);
    });

    test('returns AdzanState at exactly Dzuhur time (12:00)', () {
      final now = DateTime(2026, 2, 19, 12, 0);
      // Adzan window: 12:00:00 - 12:03:00

      final result = useCase.evaluate(
        now: now,
        dailyPrayerTimes: mockDailyPrayerTimes,
        config: config,
      );

      expect(result, isA<AdzanState>());
      final state = result as AdzanState;
      expect(state.currentPrayer.name, 'Dzuhur');
      expect(state.remainingDuration, const Duration(minutes: 3));
      expect(state.type, DisplayStateType.adzan);
    });

    test('returns IqomahState after Adzan finishes (12:03:01)', () {
      final now = DateTime(2026, 2, 19, 12, 3, 1);
      // Iqomah window: 12:03:00 - 12:13:00

      final result = useCase.evaluate(
        now: now,
        dailyPrayerTimes: mockDailyPrayerTimes,
        config: config,
      );

      expect(result, isA<IqomahState>());
      final state = result as IqomahState;
      expect(state.currentPrayer.name, 'Dzuhur');
      expect(state.type, DisplayStateType.iqomah);
      // Sisa: End (12:13:00) - Now (12:03:01) = 09:59
      expect(state.remainingDuration.inSeconds, (9 * 60) + 59);
    });

    test('returns SholatState after Iqomah finishes (12:13:01)', () {
      final now = DateTime(2026, 2, 19, 12, 13, 1);
      // Sholat window: 12:13:00 - 12:23:00

      final result = useCase.evaluate(
        now: now,
        dailyPrayerTimes: mockDailyPrayerTimes,
        config: config,
      );

      expect(result, isA<SholatState>());
      final state = result as SholatState;
      expect(state.currentPrayer.name, 'Dzuhur');
      expect(state.type, DisplayStateType.sholat);
    });

    test('returns StandbyState after Sholat finishes (12:23:01)', () {
      final now = DateTime(2026, 2, 19, 12, 23, 1);
      when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(ashar);

      final result = useCase.evaluate(
        now: now,
        dailyPrayerTimes: mockDailyPrayerTimes,
        config: config,
      );

      expect(result, isA<StandbyState>());
      expect((result as StandbyState).nextPrayer, ashar);
    });

    group("Sholat Jum'at — durasi sholat dan iqomah khusus", () {
      // Override: ganti prayer Dzuhur dengan Jum'at (nama berbeda, waktu sama)
      final jumat = createPT("Jum'at", dzuhurTime);
      final jumatMainPrayers = [subuh, jumat, ashar, maghrib, isya];

      const jumatConfig = TransitionConfig(
        preAdzanMinutes: 10,
        adzanDurationSeconds: 180,
        sholatDurationMinutes: 10,
        sholatJumatDurationMinutes: 45,
        iqomahMinutes: {
          'Subuh': 10,
          "Jum'at": 10,
          'Ashar': 10,
          'Maghrib': 10,
          'Isya': 10,
        },
      );

      setUp(() {
        when(
          () => mockDailyPrayerTimes.mainPrayers,
        ).thenReturn(jumatMainPrayers);
      });

      test(
        "SholatState menggunakan sholatJumatDurationMinutes (45) saat prayer adalah Jum'at",
        () {
          // Jum'at sholat window: 12:00 + 3min (adzan) + 10min (iqomah) = 12:13:00
          // SholatState berlangsung 12:13:00 – 12:58:00 (45 menit)
          final now = DateTime(2026, 2, 19, 12, 13, 1);

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: jumatConfig,
          );

          expect(result, isA<SholatState>());
          final state = result as SholatState;
          expect(state.currentPrayer.name, equals("Jum'at"));
          expect(
            state.totalSholatMinutes,
            equals(45),
            reason:
                "Durasi sholat Jum'at harus 45 menit (bukan 10 menit Dzuhur biasa)",
          );
        },
      );

      test(
        "IqomahState menggunakan iqomahJumat (10) saat prayer adalah Jum'at",
        () {
          // Iqomah window: 12:00 + 3min (adzan) = 12:03:00 s/d 12:13:00
          final now = DateTime(2026, 2, 19, 12, 3, 1);

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: jumatConfig,
          );

          expect(result, isA<IqomahState>());
          final state = result as IqomahState;
          expect(state.currentPrayer.name, equals("Jum'at"));
          expect(
            state.totalIqomahMinutes,
            equals(10),
            reason: "Durasi iqomah Jum'at harus 10 menit sesuai config",
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // Wisdom Quote window tests
    // -------------------------------------------------------------------------

    group('Wisdom Quote Window', () {
      // Config wisdom: enabled, interval 15 min, duration 3 min, jam 6:00-21:00
      // Siklus: [0-3 min = tampil] [3-18 min = jeda] [18-21 min = tampil] dst.
      const wisdomConfig = TransitionConfig(
        preAdzanMinutes: 10,
        adzanDurationSeconds: 180,
        sholatDurationMinutes: 10,
        iqomahMinutes: {
          'Subuh': 10,
          'Dzuhur': 10,
          'Ashar': 10,
          'Maghrib': 10,
          'Isya': 10,
        },
        isWisdomEnabled: true,
        wisdomIntervalMinutes: 15,
        wisdomDurationMinutes: 3,
        wisdomStartHour: 6,
        wisdomStartMinute: 0,
        wisdomEndHour: 21,
        wisdomEndMinute: 0,
        wisdomShuffle: false,
      );

      final quoteA = const WisdomQuote(
        id: 'quran_001',
        type: 'quran',
        label: 'Ayat Al-Quran',
        translationText: 'Karena sesungguhnya bersama kesulitan ada kemudahan.',
        reference: 'QS. Al-Insyirah [94]: 6',
      );

      final quoteB = const WisdomQuote(
        id: 'hadith_001',
        type: 'hadith',
        label: 'Hadits',
        translationText:
            'Sesungguhnya setiap amal itu tergantung pada niatnya.',
        reference: 'HR. Bukhari No. 1',
      );

      final activeQuotes = [quoteA, quoteB];

      test(
        'returns WisdomQuoteState saat berada dalam wisdom window aktif',
        () {
          // 06:00 adalah awal window. Siklus pertama: 06:00-06:03 → tampil.
          final now = DateTime(2026, 2, 19, 6, 1, 30);
          when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(dzuhur);

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: wisdomConfig,
            activeQuotes: activeQuotes,
          );

          expect(result, isA<WisdomQuoteState>());
          final state = result as WisdomQuoteState;
          expect(state.type, DisplayStateType.wisdomQuote);
          expect(
            state.currentQuote,
            quoteA,
          ); // index 0 di siklus pertama (urut)
          expect(state.currentIndex, 0);
          expect(state.totalItems, 2);
          expect(state.totalDurationSeconds, 3 * 60); // 3 menit
          expect(state.remainingSeconds, greaterThan(0));
        },
      );

      test(
        'returns StandbyState saat dalam jeda wisdom (positionInCycle >= duration)',
        () {
          // 06:05 = 5 menit setelah windowStart.
          // positionInCycle = 5 % 18 = 5. wisdomDuration = 3 → jeda!
          final now = DateTime(2026, 2, 19, 6, 5);
          when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(dzuhur);

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: wisdomConfig,
            activeQuotes: activeQuotes,
          );

          expect(result, isA<StandbyState>());
        },
      );

      test('returns StandbyState saat activeQuotes kosong (guard check)', () {
        // Waktu berada dalam wisdom window, tapi tidak ada item terpilih.
        final now = DateTime(2026, 2, 19, 6, 1);
        when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(dzuhur);

        final result = useCase.evaluate(
          now: now,
          dailyPrayerTimes: mockDailyPrayerTimes,
          config: wisdomConfig,
          activeQuotes: const [], // kosong!
        );

        expect(result, isA<StandbyState>());
      });

      test('returns StandbyState saat activeQuotes null', () {
        final now = DateTime(2026, 2, 19, 6, 1);
        when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(dzuhur);

        final result = useCase.evaluate(
          now: now,
          dailyPrayerTimes: mockDailyPrayerTimes,
          config: wisdomConfig,
          activeQuotes: null, // null tidak ditangani!
        );

        expect(result, isA<StandbyState>());
      });

      test(
        'prayer window lebih prioritas daripada wisdom window (PreAdzan menang)',
        () {
          // Sholat Dzuhur 12:00. PreAdzan window: 11:50-12:00.
          // Wisdom siklus: 11:50 = 350 menit dari 06:00. 350 % 18 = 350 - (19*18) = 350-342 = 8 > 3 → jeda.
          // Tapi kita ubah timing agar overlapping lebih jelas:
          // Coba 06:01 — berada di wisdom window DAN tidak ada prayer window.
          // Lalu coba 11:55 — PreAdzan window, meski wisdom mungkin aktif juga.
          final now = DateTime(2026, 2, 19, 11, 55);
          // 11:55 → PreAdzan Dzuhur window aktif (11:50-12:00).
          // Wisdom check: 11:55 = 355 menit dari 06:00. 355 % 18 = 355-19*18=355-342=13 → jeda (>3).
          // Jadi test ini lebih ke: prayer window sudah diproses duluan.

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: wisdomConfig,
            activeQuotes: activeQuotes,
          );

          expect(
            result,
            isA<PreAdzanState>(),
            reason:
                'PreAdzan harus menang ketika prayer window dan wisdom window overlap',
          );
        },
      );

      test(
        'returns StandbyState saat isWisdomEnabled = false meski dalam window',
        () {
          const disabledWisdomConfig = TransitionConfig(
            preAdzanMinutes: 10,
            adzanDurationSeconds: 180,
            sholatDurationMinutes: 10,
            iqomahMinutes: {
              'Subuh': 10,
              'Dzuhur': 10,
              'Ashar': 10,
              'Maghrib': 10,
              'Isya': 10,
            },
            isWisdomEnabled: false, // disabled!
            wisdomIntervalMinutes: 15,
            wisdomDurationMinutes: 3,
            wisdomStartHour: 6,
            wisdomStartMinute: 0,
            wisdomEndHour: 21,
            wisdomEndMinute: 0,
          );

          final now = DateTime(2026, 2, 19, 6, 1);
          when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(dzuhur);

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: disabledWisdomConfig,
            activeQuotes: activeQuotes,
          );

          expect(result, isA<StandbyState>());
        },
      );

      test(
        'mode urut: siklus ke-0 = item index 0, siklus ke-1 = item index 1',
        () {
          // cycleLength = (15 + 3) * 60 = 1080 detik (18 menit)
          // Siklus 0: 06:00:00 - 06:03:00 → index 0 (quoteA)
          // Siklus 1: 06:18:00 - 06:21:00 → index 1 (quoteB)
          final nowCycle0 = DateTime(2026, 2, 19, 6, 0, 30);
          when(
            () => mockDailyPrayerTimes.nextPrayer(nowCycle0),
          ).thenReturn(dzuhur);

          final result0 = useCase.evaluate(
            now: nowCycle0,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: wisdomConfig,
            activeQuotes: activeQuotes,
          );

          expect(result0, isA<WisdomQuoteState>());
          expect((result0 as WisdomQuoteState).currentQuote, quoteA);
          expect(result0.currentIndex, 0);

          final nowCycle1 = DateTime(2026, 2, 19, 6, 18, 30);
          when(
            () => mockDailyPrayerTimes.nextPrayer(nowCycle1),
          ).thenReturn(dzuhur);

          final result1 = useCase.evaluate(
            now: nowCycle1,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: wisdomConfig,
            activeQuotes: activeQuotes,
          );

          expect(result1, isA<WisdomQuoteState>());
          expect((result1 as WisdomQuoteState).currentQuote, quoteB);
          expect(result1.currentIndex, 1);
        },
      );

      test(
        'mode acak: seed yang sama menghasilkan urutan yang sama (deterministik)',
        () {
          const shuffleConfig = TransitionConfig(
            preAdzanMinutes: 10,
            adzanDurationSeconds: 180,
            sholatDurationMinutes: 10,
            iqomahMinutes: {
              'Subuh': 10,
              'Dzuhur': 10,
              'Ashar': 10,
              'Maghrib': 10,
              'Isya': 10,
            },
            isWisdomEnabled: true,
            wisdomIntervalMinutes: 15,
            wisdomDurationMinutes: 3,
            wisdomStartHour: 6,
            wisdomStartMinute: 0,
            wisdomEndHour: 21,
            wisdomEndMinute: 0,
            wisdomShuffle: true, // acak!
          );

          final now1 = DateTime(2026, 2, 19, 6, 0, 30);
          final now2 = DateTime(2026, 2, 19, 6, 0, 45); // beda detik, hari sama
          when(() => mockDailyPrayerTimes.nextPrayer(now1)).thenReturn(dzuhur);
          when(() => mockDailyPrayerTimes.nextPrayer(now2)).thenReturn(dzuhur);

          final result1 = useCase.evaluate(
            now: now1,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: shuffleConfig,
            activeQuotes: activeQuotes,
          );

          final result2 = useCase.evaluate(
            now: now2,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: shuffleConfig,
            activeQuotes: activeQuotes,
          );

          // Seed = hari yang sama → indeks pertama harus sama
          expect(result1, isA<WisdomQuoteState>());
          expect(result2, isA<WisdomQuoteState>());
          expect(
            (result1 as WisdomQuoteState).currentIndex,
            equals((result2 as WisdomQuoteState).currentIndex),
            reason:
                'Seed yang sama (hari yang sama) harus menghasilkan index sama',
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // Midnight Mode window tests
    // -------------------------------------------------------------------------

    group('Midnight Mode', () {
      // Config dasar dengan midnight enabled, window 23:00 – 03:30 (cross-midnight)
      const midnightConfig = TransitionConfig(
        preAdzanMinutes: 10,
        adzanDurationSeconds: 180,
        sholatDurationMinutes: 10,
        iqomahMinutes: {
          'Subuh': 10,
          'Dzuhur': 10,
          'Ashar': 10,
          'Maghrib': 10,
          'Isya': 10,
        },
        isMidnightModeEnabled: true,
        midnightStartHour: 23,
        midnightStartMinute: 0,
        midnightEndHour: 3,
        midnightEndMinute: 30,
      );

      // Skenario (a): fitur OFF → tidak pernah return MidnightStandbyState
      test(
        'fitur OFF: returns StandbyState meskipun waktu dalam window (23:30)',
        () {
          const offConfig = TransitionConfig(
            preAdzanMinutes: 10,
            adzanDurationSeconds: 180,
            sholatDurationMinutes: 10,
            iqomahMinutes: {
              'Subuh': 10,
              'Dzuhur': 10,
              'Ashar': 10,
              'Maghrib': 10,
              'Isya': 10,
            },
            isMidnightModeEnabled: false, // OFF
            midnightStartHour: 23,
            midnightStartMinute: 0,
            midnightEndHour: 3,
            midnightEndMinute: 30,
          );

          final now = DateTime(2026, 2, 19, 23, 30);
          when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: offConfig,
          );

          expect(result, isA<StandbyState>());
        },
      );

      // Skenario (b): fitur ON + dalam window → return MidnightStandbyState
      test('fitur ON + dalam window (23:30): returns MidnightStandbyState', () {
        final now = DateTime(2026, 2, 19, 23, 30);
        when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);
        when(() => mockDailyPrayerTimes.subuh).thenReturn(subuh);

        final result = useCase.evaluate(
          now: now,
          dailyPrayerTimes: mockDailyPrayerTimes,
          config: midnightConfig,
        );

        expect(result, isA<MidnightStandbyState>());
        final state = result as MidnightStandbyState;
        expect(state.type, DisplayStateType.midnightStandby);
        expect(state.currentTime, now);
        expect(state.subuhTime, subuhTime);
        expect(state.subuhLabel, 'Subuh - 04:30');
      });

      // Skenario (b lanjut): dalam window setelah tengah malam (02:00)
      test(
        'fitur ON + dalam window setelah tengah malam (02:00): returns MidnightStandbyState',
        () {
          final now = DateTime(2026, 2, 20, 2, 0); // hari berikutnya
          when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);
          when(() => mockDailyPrayerTimes.subuh).thenReturn(subuh);

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: midnightConfig,
          );

          expect(result, isA<MidnightStandbyState>());
        },
      );

      // Skenario (c): fitur ON + di luar window → StandbyState
      test('fitur ON + di luar window (10:00): returns StandbyState', () {
        final now = DateTime(2026, 2, 19, 10, 0);
        when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(dzuhur);

        final result = useCase.evaluate(
          now: now,
          dailyPrayerTimes: mockDailyPrayerTimes,
          config: midnightConfig,
        );

        expect(result, isA<StandbyState>());
      });

      // Skenario (c lanjut): tepat di batas akhir window (03:30) → sudah di luar
      test(
        'fitur ON + tepat batas akhir window (03:30): returns StandbyState',
        () {
          final now = DateTime(2026, 2, 19, 3, 30);
          when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: midnightConfig,
          );

          // 03:30 adalah endMinutes → nowMinutes < endMinutes → false → di luar window
          expect(result, isA<StandbyState>());
        },
      );

      // Skenario (d): fitur ON + dalam window TAPI siklus sholat aktif → sholat menang
      test(
        'fitur ON + dalam window TAPI Isya sedang Adzan (19:30): sholat menang',
        () {
          // Isya adzan mulai 19:30, durasi 3 menit
          // midnight window 23:00–03:30 → 19:30 sebenarnya di luar window, tapi
          // test ini membuktikan bahwa evaluasi sholat berjalan lebih dulu
          const lateNightConfig = TransitionConfig(
            preAdzanMinutes: 10,
            adzanDurationSeconds: 180,
            sholatDurationMinutes: 10,
            iqomahMinutes: {
              'Subuh': 10,
              'Dzuhur': 10,
              'Ashar': 10,
              'Maghrib': 10,
              'Isya': 10,
            },
            isMidnightModeEnabled: true,
            midnightStartHour: 19, // window mulai jam 19 untuk test ini
            midnightStartMinute: 0,
            midnightEndHour: 3,
            midnightEndMinute: 30,
          );

          // Isya adzan jam 19:30, now = 19:30 (tepat mulai adzan)
          final now = DateTime(2026, 2, 19, 19, 30);
          when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);
          when(() => mockDailyPrayerTimes.subuh).thenReturn(subuh);

          final result = useCase.evaluate(
            now: now,
            dailyPrayerTimes: mockDailyPrayerTimes,
            config: lateNightConfig,
          );

          // Sholat (AdzanState) lebih prioritas dari midnight
          expect(result, isA<AdzanState>());
          expect((result as AdzanState).currentPrayer.name, 'Isya');
        },
      );

      // Skenario (e): cross-midnight boundary — 23:59 dalam window
      test('cross-midnight boundary: 23:59 dalam window', () {
        final now = DateTime(2026, 2, 19, 23, 59);
        when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);
        when(() => mockDailyPrayerTimes.subuh).thenReturn(subuh);

        final result = useCase.evaluate(
          now: now,
          dailyPrayerTimes: mockDailyPrayerTimes,
          config: midnightConfig,
        );

        expect(result, isA<MidnightStandbyState>());
      });

      // Skenario (e lanjut): cross-midnight boundary — 00:01 dalam window
      test('cross-midnight boundary: 00:01 dalam window', () {
        final now = DateTime(2026, 2, 20, 0, 1);
        when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);
        when(() => mockDailyPrayerTimes.subuh).thenReturn(subuh);

        final result = useCase.evaluate(
          now: now,
          dailyPrayerTimes: mockDailyPrayerTimes,
          config: midnightConfig,
        );

        expect(result, isA<MidnightStandbyState>());
      });

      // Skenario (f): window non-cross-midnight (01:00 – 03:00)
      test('window non-cross-midnight: 01:30 dalam window (01:00–03:00)', () {
        const nonCrossConfig = TransitionConfig(
          preAdzanMinutes: 10,
          adzanDurationSeconds: 180,
          sholatDurationMinutes: 10,
          iqomahMinutes: {
            'Subuh': 10,
            'Dzuhur': 10,
            'Ashar': 10,
            'Maghrib': 10,
            'Isya': 10,
          },
          isMidnightModeEnabled: true,
          midnightStartHour: 1,
          midnightStartMinute: 0,
          midnightEndHour: 3,
          midnightEndMinute: 0,
        );

        final now = DateTime(2026, 2, 20, 1, 30);
        when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);
        when(() => mockDailyPrayerTimes.subuh).thenReturn(subuh);

        final result = useCase.evaluate(
          now: now,
          dailyPrayerTimes: mockDailyPrayerTimes,
          config: nonCrossConfig,
        );

        expect(result, isA<MidnightStandbyState>());
      });

      // Skenario (f lanjut): di luar window non-cross-midnight
      test('window non-cross-midnight: 23:30 di luar window (01:00–03:00)', () {
        const nonCrossConfig = TransitionConfig(
          preAdzanMinutes: 10,
          adzanDurationSeconds: 180,
          sholatDurationMinutes: 10,
          iqomahMinutes: {
            'Subuh': 10,
            'Dzuhur': 10,
            'Ashar': 10,
            'Maghrib': 10,
            'Isya': 10,
          },
          isMidnightModeEnabled: true,
          midnightStartHour: 1,
          midnightStartMinute: 0,
          midnightEndHour: 3,
          midnightEndMinute: 0,
        );

        final now = DateTime(2026, 2, 19, 23, 30);
        when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);

        final result = useCase.evaluate(
          now: now,
          dailyPrayerTimes: mockDailyPrayerTimes,
          config: nonCrossConfig,
        );

        // 23:30 tidak dalam window 01:00–03:00
        expect(result, isA<StandbyState>());
      });

      // Verifikasi subuhLabel formatted correctly
      test('subuhLabel ter-format HH:mm dengan padding nol', () {
        // Ganti subuh ke jam yang perlu padding (04:05)
        final subuhWithPadding = createPT('Subuh', DateTime(2026, 2, 19, 4, 5));
        final mainPrayersWithPadding = [
          subuhWithPadding,
          dzuhur,
          ashar,
          maghrib,
          isya,
        ];
        when(
          () => mockDailyPrayerTimes.mainPrayers,
        ).thenReturn(mainPrayersWithPadding);
        when(() => mockDailyPrayerTimes.subuh).thenReturn(subuhWithPadding);

        final now = DateTime(2026, 2, 19, 23, 30);
        when(() => mockDailyPrayerTimes.nextPrayer(now)).thenReturn(subuh);

        final result = useCase.evaluate(
          now: now,
          dailyPrayerTimes: mockDailyPrayerTimes,
          config: midnightConfig,
        );

        expect(result, isA<MidnightStandbyState>());
        expect((result as MidnightStandbyState).subuhLabel, 'Subuh - 04:05');

        // Restore main prayers untuk test lain
        when(() => mockDailyPrayerTimes.mainPrayers).thenReturn(mainPrayers);
      });
    });
  });
}
