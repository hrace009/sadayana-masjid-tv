import 'package:flutter_test/flutter_test.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/prayer_time.dart';

void main() {
  group('DailyPrayerTimes', () {
    final tDate = DateTime(2025, 2, 19);

    // Helper untuk membuat PrayerTime dengan cepat
    PrayerTime createPT(String name, int hour, int minute) {
      return PrayerTime(
        name: name,
        time: DateTime(2025, 2, 19, hour, minute),
        originalTime: DateTime(2025, 2, 19, hour, minute),
        ihtiyatMinutes: 0,
      );
    }

    final subuh = createPT('Subuh', 4, 30);
    final syuruq = createPT('Syuruq', 6, 0);
    final dhuha = createPT('Dhuha', 6, 20);
    final dzuhur = createPT('Dzuhur', 12, 0);
    final ashar = createPT('Ashar', 15, 15);
    final maghrib = createPT('Maghrib', 18, 10);
    final isya = createPT('Isya', 19, 25);

    final daily = DailyPrayerTimes(
      date: tDate,
      hijriDate: '20 Syaban 1446 H',
      subuh: subuh,
      syuruq: syuruq,
      dhuha: dhuha,
      dzuhur: dzuhur,
      ashar: ashar,
      maghrib: maghrib,
      isya: isya,
    );

    test('allPrayers returns 7 prayers chronologically', () {
      expect(daily.allPrayers, [
        subuh,
        syuruq,
        dhuha,
        dzuhur,
        ashar,
        maghrib,
        isya,
      ]);
    });

    test('mainPrayers returns 5 fard prayers', () {
      expect(daily.mainPrayers, [subuh, dzuhur, ashar, maghrib, isya]);
    });

    group('currentPrayer', () {
      test('returns null before Subuh', () {
        final now = DateTime(2025, 2, 19, 4, 0); // 04:00 (Subuh 04:30)
        expect(daily.currentPrayer(now), null);
      });

      test('returns Subuh during Subuh time', () {
        final now = DateTime(2025, 2, 19, 5, 0); // 05:00
        expect(daily.currentPrayer(now), subuh);
      });

      test('returns Dzuhur during Dzuhur time', () {
        final now = DateTime(2025, 2, 19, 13, 0); // 13:00
        expect(daily.currentPrayer(now), dzuhur);
      });

      test('returns Isya after Isya time', () {
        final now = DateTime(2025, 2, 19, 23, 0); // 23:00
        expect(daily.currentPrayer(now), isya);
      });
    });

    group('nextPrayer', () {
      test('returns Subuh before Subuh time', () {
        final now = DateTime(2025, 2, 19, 4, 0); // 04:00
        expect(daily.nextPrayer(now), subuh);
      });

      test('returns Syuruq after Subuh', () {
        final now = DateTime(2025, 2, 19, 5, 0); // 05:00
        expect(daily.nextPrayer(now), syuruq);
      });

      test('returns Ashar after Dzuhur', () {
        final now = DateTime(2025, 2, 19, 13, 0); // 13:00
        expect(daily.nextPrayer(now), ashar);
      });

      test('returns null after Isya', () {
        final now = DateTime(2025, 2, 19, 20, 0); // 20:00 (Isya 19:25)
        expect(daily.nextPrayer(now), null);
      });
    });
  });
}
