import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state_type.dart';
import 'package:miqotul_khoir_tv/domain/entities/prayer_time.dart';
import 'package:miqotul_khoir_tv/domain/entities/transition_config.dart';
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
  });
}
