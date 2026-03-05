import 'package:flutter_test/flutter_test.dart';
import 'package:miqotul_khoir_tv/domain/entities/prayer_time.dart';

void main() {
  group('PrayerTime', () {
    // Solusi: Hapus const keyword di tPrayerTime deklarasi karena tTime bukan const.
    // Perbaikan: gunakan tTime variabel.

    // Ulangi deklarasi variabel agar clean di dalam test block
    test('props are correct for Equatable', () {
      final prayer1 = PrayerTime(
        name: 'Dzuhur',
        time: DateTime(2025, 2, 19, 12, 5),
        originalTime: DateTime(2025, 2, 19, 12, 3),
        ihtiyatMinutes: 2,
      );
      final prayer2 = PrayerTime(
        name: 'Dzuhur',
        time: DateTime(2025, 2, 19, 12, 5),
        originalTime: DateTime(2025, 2, 19, 12, 3),
        ihtiyatMinutes: 2,
      );

      expect(prayer1, equals(prayer2));
    });

    test('formattedTime returns HH:mm format', () {
      final prayer = PrayerTime(
        name: 'Dzuhur',
        time: DateTime(2025, 2, 19, 5, 4), // 05:04
        originalTime: DateTime(2025, 2, 19, 5, 2),
        ihtiyatMinutes: 2,
      );

      expect(prayer.formattedTime, '05:04');

      final prayer2 = PrayerTime(
        name: 'Isya',
        time: DateTime(2025, 2, 19, 19, 30), // 19:30
        originalTime: DateTime(2025, 2, 19, 19, 28),
        ihtiyatMinutes: 2,
      );
      expect(prayer2.formattedTime, '19:30');
    });
  });
}
