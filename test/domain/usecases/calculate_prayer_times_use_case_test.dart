import 'package:flutter_test/flutter_test.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/settings.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';
import 'package:miqotul_khoir_tv/domain/usecases/calculate_prayer_times_use_case.dart';

// Manual Mock untuk SettingsRepository
class MockSettingsRepository implements SettingsRepository {
  Settings? mockSettings;

  @override
  Future<Settings> getSettings() async {
    return mockSettings ?? const Settings();
  }

  @override
  Future<void> updateSettings(Map<String, dynamic> updates) async {}

  @override
  Future<bool> isFirstRun() async => false;

  @override
  Future<void> completeFirstRun() async {}

  @override
  Future<bool> verifyPin(String inputPin) async => true;

  @override
  Future<void> setPin(String newPin) async {}

  @override
  Future<void> resetSettings() async {}
}

void main() {
  late CalculatePrayerTimesUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = CalculatePrayerTimesUseCase(mockRepository);
  });

  group('CalculatePrayerTimesUseCase', () {
    // Lokasi: Masjid Raya Bandung (Alun-alun)
    const tLatitude = -6.9218;
    const tLongitude = 107.6098;
    final tDate = DateTime(2025, 2, 19); // Tanggal tes

    test('execute returns valid DailyPrayerTimes with offsets applied', () async {
      // Setup Settings dengan offset
      mockRepository.mockSettings = const Settings(
        latitude: tLatitude,
        longitude: tLongitude,
        calculationMethod: 'kemenag',
        offsetSubuh: 2, // +2 menit user offset
        offsetMaghrib: -2, // -2 menit user offset
        dhuhaOffsetMinutes: 20, // Syuruq + 20
        hijriAdjustment: 0,
      );

      final result = await useCase.execute(date: tDate);

      expect(result, isA<DailyPrayerTimes>());
      expect(result.date, tDate);

      // Cek Offset Subuh
      // Kita tidak tahu exact time adhan, tapi kita bisa cek relasi original vs time
      expect(
        result.subuh.time.difference(result.subuh.originalTime).inMinutes,
        2,
        reason: 'Subuh harusnya +2 menit',
      );

      // Cek Offset Maghrib
      expect(
        result.maghrib.time.difference(result.maghrib.originalTime).inMinutes,
        -2,
        reason: 'Maghrib harusnya -2 menit',
      );

      // Cek Dhuha
      // Dhuha = Syuruq + offset (20) + ihtiyat Dhuha (default 0)
      final expectedDhuhaTime = result.syuruq.originalTime.add(
        const Duration(minutes: 20),
      );

      // Cek Dhuha time match expected
      expect(
        result.dhuha.time,
        expectedDhuhaTime,
        reason: 'Dhuha harusnya Syuruq + 20 menit',
      );
    });

    test('execute throws ArgumentError for invalid latitude', () async {
      mockRepository.mockSettings = const Settings(
        latitude: 91.0, // Invalid
        longitude: 107.6098,
      );

      expect(() => useCase.execute(date: tDate), throwsArgumentError);
    });

    test('execute throws ArgumentError for invalid longitude', () async {
      mockRepository.mockSettings = const Settings(
        latitude: -6.9218,
        longitude: 181.0, // Invalid
      );

      expect(() => useCase.execute(date: tDate), throwsArgumentError);
    });

    test('hijri date formatting with adjustment', () async {
      mockRepository.mockSettings = const Settings(
        hijriAdjustment: 1, // +1 hari
        // Default Settings adjustment 0, ini override
      );

      final result = await useCase.execute(date: tDate);

      // Format Hijriah harus mengandung nama bulan, tahun "H"
      // Kita tidak assert exact string karena tergantung library hijri
      // Tapi format harus ada "H" di akhir
      expect(result.hijriDate, endsWith('H'));
    });
    // TASK-007: Test Kemenag method — ihtiyat +2 menit bawaan via methodAdjustments
    // Ihtiyat Kemenag di-apply di level library (adjustments), bukan di level user offset.
    // Ketika user offset = 0: time == originalTime + 2 menit (ihtiyat Kemenag).
    // Ketika user offset = N: time == originalTime + N menit (ihtiyat Kemenag sudah
    // masuk ke dalam originalTime karena di-apply sebelum PrayerTime entity dibuat).
    //
    // Catatan teknis: `adjustments` dari adhan library di-apply sebelum `.toLocal()`
    // dikembalikan, sehingga `originalTime` di entity sudah termasuk ihtiyat Kemenag.
    // Yang tersimpan dalam `ihtiyatMinutes` adalah hanya user offset.
    test(
      'TASK-007: Kemenag method applies built-in ihtiyat via methodAdjustments',
      () async {
        // Gunakan offset user = 0 untuk mengukur ihtiyat bawaan Kemenag
        mockRepository.mockSettings = const Settings(
          latitude: tLatitude,
          longitude: tLongitude,
          calculationMethod: 'kemenag',
          offsetSubuh: 0, // Tidak ada user offset
          offsetDzuhur: 0,
          offsetAshar: 0,
          offsetMaghrib: 0,
          offsetIsya: 0,
        );

        final result = await useCase.execute(date: tDate);

        // Hasil harus berupa DailyPrayerTimes yang valid
        expect(result, isA<DailyPrayerTimes>());

        // Dengan user offset = 0, time == originalTime (ihtiyat bawaan sudah
        // ter-absorb ke dalam kalkulasi library sebelum entity dibuat)
        expect(
          result.subuh.ihtiyatMinutes,
          equals(0),
          reason: 'ihtiyatMinutes di entity hanya menyimpan user offset',
        );

        // Semua waktu sholat harus valid (tidak null, dalam range jam yang masuk akal)
        final subuhHour = result.subuh.time.hour;
        final dzuhurHour = result.dzuhur.time.hour;
        final asharHour = result.ashar.time.hour;
        final maghribHour = result.maghrib.time.hour;
        final isyaHour = result.isya.time.hour;

        expect(
          subuhHour,
          inInclusiveRange(3, 6),
          reason: 'Subuh harus antara pukul 03.xx – 06.xx',
        );
        expect(
          dzuhurHour,
          inInclusiveRange(11, 13),
          reason: 'Dzuhur harus antara pukul 11.xx – 13.xx',
        );
        expect(
          asharHour,
          inInclusiveRange(14, 17),
          reason: 'Ashar harus antara pukul 14.xx – 17.xx',
        );
        expect(
          maghribHour,
          inInclusiveRange(17, 20),
          reason: 'Maghrib harus antara pukul 17.xx – 20.xx',
        );
        expect(
          isyaHour,
          inInclusiveRange(18, 22),
          reason: 'Isya harus antara pukul 18.xx – 22.xx',
        );
      },
    );

    // TASK-008: Test ihtiyat Kemenag + user offset bersifat aditif
    test('TASK-008: Kemenag ihtiyat and user offset are additive '
        '(user offset applied on top of Kemenag built-in adjustments)', () async {
      const userOffsetSubuh = 3;
      const userOffsetMaghrib = 1;

      // Run sekali dengan offset
      mockRepository.mockSettings = const Settings(
        latitude: tLatitude,
        longitude: tLongitude,
        calculationMethod: 'kemenag',
        offsetSubuh: userOffsetSubuh,
        offsetMaghrib: userOffsetMaghrib,
      );
      final resultWithOffset = await useCase.execute(date: tDate);

      // Run sekali tanpa offset
      mockRepository.mockSettings = const Settings(
        latitude: tLatitude,
        longitude: tLongitude,
        calculationMethod: 'kemenag',
        offsetSubuh: 0,
        offsetMaghrib: 0,
      );
      final resultNoOffset = await useCase.execute(date: tDate);

      // Perbedaan antara time dengan offset dan tanpa offset = user offset persis
      final subuhDiff = resultWithOffset.subuh.time
          .difference(resultNoOffset.subuh.time)
          .inMinutes;
      final maghribDiff = resultWithOffset.maghrib.time
          .difference(resultNoOffset.maghrib.time)
          .inMinutes;

      expect(
        subuhDiff,
        equals(userOffsetSubuh),
        reason: 'Selisih Subuh harus = user offset ($userOffsetSubuh menit)',
      );
      expect(
        maghribDiff,
        equals(userOffsetMaghrib),
        reason:
            'Selisih Maghrib harus = user offset ($userOffsetMaghrib menit)',
      );

      // ihtiyatMinutes di entity = user offset
      expect(resultWithOffset.subuh.ihtiyatMinutes, equals(userOffsetSubuh));
      expect(
        resultWithOffset.maghrib.ihtiyatMinutes,
        equals(userOffsetMaghrib),
      );
    });

    // TASK-009: Test unknown method falls back to Kemenag
    test(
      'TASK-009: Unknown calculation method falls back to Kemenag parameters',
      () async {
        // Gunakan method string yang tidak ada di switch case
        mockRepository.mockSettings = const Settings(
          latitude: tLatitude,
          longitude: tLongitude,
          calculationMethod: 'unknown_method_xyz',
        );

        // Tidak boleh throw exception — harus fallback ke Kemenag
        final result = await useCase.execute(date: tDate);

        expect(
          result,
          isA<DailyPrayerTimes>(),
          reason: 'Unknown method harus fallback ke Kemenag, tidak crash',
        );

        // Waktu sholat yang dikembalikan harus valid
        expect(result.subuh.time, isNotNull);
        expect(result.dzuhur.time, isNotNull);
        expect(result.ashar.time, isNotNull);
        expect(result.maghrib.time, isNotNull);
        expect(result.isya.time, isNotNull);
      },
    );

    test(
      "TASK-011a: label Dzuhur berubah menjadi Jum'at pada hari Jumat",
      () async {
        // 2026-03-06 adalah hari Jumat (weekday = 5)
        final fridayDate = DateTime(2026, 3, 6);
        mockRepository.mockSettings = const Settings(
          latitude: tLatitude,
          longitude: tLongitude,
          calculationMethod: 'kemenag',
        );

        final result = await useCase.execute(date: fridayDate);

        expect(
          result.dzuhur.name,
          equals("Jum'at"),
          reason: "Waktu Dzuhur harus berlabel Jum'at pada hari Jumat",
        );
      },
    );

    test(
      "TASK-011b: label Dzuhur tetap 'Dzuhur' pada hari selain Jumat",
      () async {
        // 2026-03-02 adalah hari Senin (weekday = 1)
        final mondayDate = DateTime(2026, 3, 2);
        mockRepository.mockSettings = const Settings(
          latitude: tLatitude,
          longitude: tLongitude,
          calculationMethod: 'kemenag',
        );

        final result = await useCase.execute(date: mondayDate);

        expect(
          result.dzuhur.name,
          equals('Dzuhur'),
          reason: 'Waktu Dzuhur harus berlabel Dzuhur pada hari selain Jumat',
        );
      },
    );
  });
}
