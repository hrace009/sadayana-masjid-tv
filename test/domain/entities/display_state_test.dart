import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state_type.dart';
import 'package:miqotul_khoir_tv/domain/entities/prayer_time.dart';

class MockDailyPrayerTimes extends Mock implements DailyPrayerTimes {}

class MockPrayerTime extends Mock implements PrayerTime {}

void main() {
  late MockDailyPrayerTimes mockDailyPrayerTimes;
  late MockPrayerTime mockPrayerTime;

  setUp(() {
    mockDailyPrayerTimes = MockDailyPrayerTimes();
    mockPrayerTime = MockPrayerTime();
  });

  group('DisplayState', () {
    test('StandbyState has correct type', () {
      final state = StandbyState(currentTime: DateTime.now());
      expect(state.type, DisplayStateType.standby);
    });

    test('PreAdzanState has correct type and progress', () {
      final state = PreAdzanState(
        upcomingPrayer: mockPrayerTime,
        remainingDuration: const Duration(minutes: 5),
        totalPreAdzanMinutes: 10,
        dailyPrayerTimes: mockDailyPrayerTimes,
      );

      expect(state.type, DisplayStateType.preAdzan);
      // 10 menit total, sisa 5 menit -> progress 0.5
      expect(state.progress, 0.5);
    });

    test('AdzanState has correct type and progress', () {
      final state = AdzanState(
        currentPrayer: mockPrayerTime,
        remainingDuration: const Duration(seconds: 30),
        totalAdzanSeconds: 60,
        dailyPrayerTimes: mockDailyPrayerTimes,
      );

      expect(state.type, DisplayStateType.adzan);
      // 60 detik total, sisa 30 detik -> progress 0.5
      expect(state.progress, 0.5);
    });

    test('IqomahState has correct type and progress', () {
      final state = IqomahState(
        currentPrayer: mockPrayerTime,
        remainingDuration: const Duration(minutes: 2),
        totalIqomahMinutes: 10,
        dailyPrayerTimes: mockDailyPrayerTimes,
      );

      expect(state.type, DisplayStateType.iqomah);
      // 10 menit total, sisa 2 menit -> elapsed 8 menit -> progress 0.8
      expect(state.progress, 0.8);
    });

    test('SholatState has correct type and progress', () {
      final state = SholatState(
        currentPrayer: mockPrayerTime,
        remainingDuration: const Duration(minutes: 0),
        totalSholatMinutes: 10,
        dailyPrayerTimes: mockDailyPrayerTimes,
      );

      expect(state.type, DisplayStateType.sholat);
      // Sisa 0 -> progress 1.0
      expect(state.progress, 1.0);
    });

    test('Progress is clamped between 0.0 and 1.0', () {
      final state = PreAdzanState(
        upcomingPrayer: mockPrayerTime,
        remainingDuration: const Duration(minutes: 15), // Lebih dari total
        totalPreAdzanMinutes: 10,
        dailyPrayerTimes: mockDailyPrayerTimes,
      );

      // Sisa 15 dari 10 -> elapsed -5 -> progress 0.0 (clamped)
      // Wait formula: (total - remaining) / total
      // (10 - 15) / 10 = -0.5 -> Clamped to 0.0
      expect(state.progress, 0.0);
    });
  });
}
