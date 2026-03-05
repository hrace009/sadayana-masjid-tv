import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/prayer_time.dart';
import 'package:miqotul_khoir_tv/domain/entities/settings.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';

/// Use case untuk menghitung jadwal sholat harian.
///
/// Proses:
/// 1. Mengambil konfigurasi lokasi dan metode kalkulasi dari [SettingsRepository].
/// 2. Menghitung waktu sholat dasar menggunakan library `adhan`.
/// 3. Menerapkan koreksi waktu (Ihtiyat) sesuai konfigurasi.
/// 4. Menghitung waktu Dhuha (Syuruq + offset).
/// 5. Mengonversi tanggal ke kalender Hijriah dengan adjustment.
///
/// Ref: Plan 05 — Phase 4, SPEC-03
class CalculatePrayerTimesUseCase {
  final SettingsRepository repository;

  CalculatePrayerTimesUseCase(this.repository);

  /// Menghitung jadwal sholat untuk tanggal [date].
  /// Jika [date] null, menggunakan tanggal hari ini.
  Future<DailyPrayerTimes> execute({DateTime? date}) async {
    final now = date ?? DateTime.now();
    final settings = await repository.getSettings();

    // 1. Validasi Koordinat
    if (settings.latitude < -90 || settings.latitude > 90) {
      throw ArgumentError('Invalid latitude: ${settings.latitude}');
    }
    if (settings.longitude < -180 || settings.longitude > 180) {
      throw ArgumentError('Invalid longitude: ${settings.longitude}');
    }

    final coordinates = Coordinates(settings.latitude, settings.longitude);

    // 2. Tentukan Metode Kalkulasi
    final params = _getCalculationParameters(
      settings.calculationMethod,
      elevation: settings.elevation,
      latitude: settings.latitude,
    );

    // Jika ada parameter adjustment spesifik, bisa di-set di sini
    // params.madhab = Madhab.shafi; // Default

    // 3. Hitung Waktu Sholat (Raw)
    final DateComponents dateComponents = DateComponents.from(now);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    // 4. Apply Ihtiyat (Koreksi Waktu) & Buat Entity
    final subuh = _applyIhtiyat(
      'Subuh',
      prayerTimes.fajr.toLocal(),
      settings.offsetSubuh,
    );

    final syuruq = _applyIhtiyat(
      'Syuruq',
      prayerTimes.sunrise.toLocal(),
      settings.offsetSyuruq,
    );

    // Dhuha = Syuruq + offset (default 20 menit)
    // Note: Dhuha tidak ada di standar CalculationParameters adhan, hitung manual
    // Gunakan prayerTimes.sunrise.toLocal() sebagai base agar konsisten
    final dhuhaOriginal = prayerTimes.sunrise.toLocal().add(
      Duration(minutes: settings.dhuhaOffsetMinutes),
    );
    final dhuha = _applyIhtiyat('Dhuha', dhuhaOriginal, settings.offsetDhuha);

    // Label Dzuhur berubah menjadi "Jum'at" setiap hari Jumat (REQ-001, REQ-005)
    final dzuhurLabel = now.weekday == DateTime.friday ? "Jum'at" : 'Dzuhur';
    final dzuhur = _applyIhtiyat(
      dzuhurLabel,
      prayerTimes.dhuhr.toLocal(),
      settings.offsetDzuhur,
    );

    final ashar = _applyIhtiyat(
      'Ashar',
      prayerTimes.asr.toLocal(),
      settings.offsetAshar,
    );

    final maghrib = _applyIhtiyat(
      'Maghrib',
      prayerTimes.maghrib.toLocal(),
      settings.offsetMaghrib,
    );

    final isya = _applyIhtiyat(
      'Isya',
      prayerTimes.isha.toLocal(),
      settings.offsetIsya,
    );

    // 5. Konversi Hijriah
    final hijriDateStr = _formatHijriDate(now, settings.hijriAdjustment);

    return DailyPrayerTimes(
      date: now,
      hijriDate: hijriDateStr,
      subuh: subuh,
      syuruq: syuruq,
      dhuha: dhuha,
      dzuhur: dzuhur,
      ashar: ashar,
      maghrib: maghrib,
      isya: isya,
    );
  }

  /// Versi synchronous yang menerima [Settings] langsung (tanpa repository).
  ///
  /// Digunakan untuk preview sebelum settings disimpan, misalnya di Setup Wizard.
  /// Kalkulasi identik dengan [execute], hanya tanpa langkah fetch repository.
  DailyPrayerTimes executeWithSettings(Settings settings, {DateTime? date}) {
    final now = date ?? DateTime.now();

    if (settings.latitude < -90 || settings.latitude > 90) {
      throw ArgumentError('Invalid latitude: ${settings.latitude}');
    }
    if (settings.longitude < -180 || settings.longitude > 180) {
      throw ArgumentError('Invalid longitude: ${settings.longitude}');
    }

    final coordinates = Coordinates(settings.latitude, settings.longitude);
    final params = _getCalculationParameters(
      settings.calculationMethod,
      elevation: settings.elevation,
      latitude: settings.latitude,
    );

    final DateComponents dateComponents = DateComponents.from(now);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    final subuh = _applyIhtiyat(
      'Subuh',
      prayerTimes.fajr.toLocal(),
      settings.offsetSubuh,
    );
    final syuruq = _applyIhtiyat(
      'Syuruq',
      prayerTimes.sunrise.toLocal(),
      settings.offsetSyuruq,
    );
    final dhuhaOriginal = prayerTimes.sunrise.toLocal().add(
      Duration(minutes: settings.dhuhaOffsetMinutes),
    );
    final dhuha = _applyIhtiyat('Dhuha', dhuhaOriginal, settings.offsetDhuha);
    // Label Dzuhur berubah menjadi "Jum'at" setiap hari Jumat (REQ-001, REQ-005)
    final dzuhurLabel = now.weekday == DateTime.friday ? "Jum'at" : 'Dzuhur';
    final dzuhur = _applyIhtiyat(
      dzuhurLabel,
      prayerTimes.dhuhr.toLocal(),
      settings.offsetDzuhur,
    );
    final ashar = _applyIhtiyat(
      'Ashar',
      prayerTimes.asr.toLocal(),
      settings.offsetAshar,
    );
    final maghrib = _applyIhtiyat(
      'Maghrib',
      prayerTimes.maghrib.toLocal(),
      settings.offsetMaghrib,
    );
    final isya = _applyIhtiyat(
      'Isya',
      prayerTimes.isha.toLocal(),
      settings.offsetIsya,
    );

    return DailyPrayerTimes(
      date: now,
      hijriDate: _formatHijriDate(now, settings.hijriAdjustment),
      subuh: subuh,
      syuruq: syuruq,
      dhuha: dhuha,
      dzuhur: dzuhur,
      ashar: ashar,
      maghrib: maghrib,
      isya: isya,
    );
  }

  /// Mapping nama metode ke object [CalculationParameters] library adhan.
  ///
  /// Metode yang didukung:
  /// - `kemenag` (default): SIHAT — Sistem Informasi Hisab Rukyat Indonesia.
  ///   Fajr 20°, Isha 18°, ihtiyat +2 menit bawaan untuk semua waktu (Syuruq -2 menit).
  ///   Ditambah koreksi ketinggian tempat (DPL) untuk Maghrib dan Syuruq.
  /// - `singapore`: MUIS (Majlis Ugama Islam Singapura). Fajr 20°, Isha 18°, tanpa ihtiyat bawaan.
  /// - Metode lainnya: MWL, Egyptian, Karachi, Umm Al-Qura, Dubai, Qatar, Kuwait, Moonsighting, North America.
  CalculationParameters _getCalculationParameters(
    String methodName, {
    int elevation = 0,
    double latitude = 0,
  }) {
    switch (methodName.toLowerCase()) {
      case 'kemenag':
        // SIHAT — Standar Kemenag RI (Sistem Informasi Hisab Rukyat Indonesia)
        // Fajr: -20° di bawah horizon Timur
        // Isha: -18° di bawah horizon Barat
        // Ihtiyat bawaan: +2 menit (kecuali Syuruq: -2 menit)
        // Koreksi DPL: ditambahkan ke Maghrib, dikurangi dari Syuruq
        // Ref: Plan feature-kemenag-prayer-method-1.md, feature-elevation-correction-1.md
        final params = CalculationMethod.other.getParameters();
        params.fajrAngle = 20;
        params.ishaAngle = 18;

        // Hitung koreksi ketinggian tempat (DPL)
        final altitudeCorrection = _calculateAltitudeCorrectionMinutes(
          elevation,
          latitude,
        );

        params.adjustments.fajr = 2;
        params.adjustments.sunrise = -2 - altitudeCorrection;
        params.adjustments.dhuhr =
            2; // Ihtiyat standar SIHAT/Kemenag RI: +2 menit
        params.adjustments.asr = 2;
        params.adjustments.maghrib = 2 + altitudeCorrection;
        params.adjustments.isha = 2;
        return params;
      case 'singapore': // MUIS (Majlis Ugama Islam Singapura)
        return CalculationMethod.singapore.getParameters();
      case 'muslim_world_league':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'egyptian':
        return CalculationMethod.egyptian.getParameters();
      case 'karachi':
        return CalculationMethod.karachi.getParameters();
      case 'umm_al_qura':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'dubai':
        return CalculationMethod.dubai.getParameters();
      case 'qatar':
        return CalculationMethod.qatar.getParameters();
      case 'kuwait':
        return CalculationMethod.kuwait.getParameters();
      case 'moonsighting':
        return CalculationMethod.moon_sighting_committee.getParameters();
      case 'north_america':
        return CalculationMethod.north_america.getParameters();
      default:
        // Fallback ke Kemenag (SIHAT) sebagai standar default Indonesia
        return _getCalculationParameters(
          'kemenag',
          elevation: elevation,
          latitude: latitude,
        );
    }
  }

  /// Menghitung koreksi waktu (menit) berdasarkan ketinggian tempat DPL.
  ///
  /// Formula koreksi Kemenag RI:
  /// - `dip` (derajat) = 2.70 * sqrt(elevation_meter) / 60
  /// - `koreksi_menit` = (4 * dip) / cos(latitude_radian)
  ///
  /// Koefisien 2.70 arcminutes/√m mencakup:
  /// - Dip geometris murni (1.76 arcmin/√m)
  /// - Koreksi refraksi atmosfer tropis Indonesia (~0.94 arcmin/√m)
  /// Validasi: Bandung (698m) → ~5 menit, sesuai jadwal Kemenag.
  ///
  /// Hasil koreksi:
  /// - Maghrib: ditambah +koreksi menit (sunset lebih lambat dari ketinggian)
  /// - Syuruq/Terbit: dikurangi -koreksi menit (sunrise lebih awal dari ketinggian)
  int _calculateAltitudeCorrectionMinutes(
    int elevationMeter,
    double latitudeDeg,
  ) {
    if (elevationMeter <= 0) return 0;

    // Dip angle in degrees (2.70 arcmin/√m, including tropical refraction)
    final dipDeg = (2.70 * sqrt(elevationMeter.toDouble())) / 60.0;

    // Time correction in minutes
    // 4 minutes per degree of arc at equator, adjusted by latitude
    final latRad = latitudeDeg * pi / 180.0;
    final correctionMin = (4.0 * dipDeg) / cos(latRad);

    return correctionMin.round();
  }

  /// Membuat [PrayerTime] dengan menerapkan offset (ihtiyat).
  /// Menerapkan offset ihtiyat pada waktu sholat.
  ///
  /// Mengikuti konvensi Kemenag SIHAT: waktu mentah dari library dibulatkan
  /// ke atas (ceiling) terlebih dahulu sebelum menambahkan ihtiyat.
  ///
  /// Contoh: raw = 04:36:31 → ceiling = 04:37 → +2 ihtiyat = **04:39**
  /// Tanpa ceiling: 04:36:31 → truncate = 04:36 → +2 ihtiyat = **04:38** ❌
  ///
  /// Ceiling hanya diterapkan jika ada detik > 0 (bukan waktu bulat).
  PrayerTime _applyIhtiyat(String name, DateTime original, int offsetMinutes) {
    // Ceiling: bulatkan ke atas ke menit berikutnya jika ada sisa detik
    final ceiled =
        (original.second > 0 ||
            original.millisecond > 0 ||
            original.microsecond > 0)
        ? DateTime(
            original.year,
            original.month,
            original.day,
            original.hour,
            original.minute,
          ).add(const Duration(minutes: 1))
        : DateTime(
            original.year,
            original.month,
            original.day,
            original.hour,
            original.minute,
          );

    // Apply offset ihtiyat
    final adjusted = ceiled.add(Duration(minutes: offsetMinutes));

    return PrayerTime(
      name: name,
      time: adjusted,
      originalTime: original,
      ihtiyatMinutes: offsetMinutes,
    );
  }

  /// Format tanggal Hijriah: "dd MMMM yyyy H"
  /// Contoh: "12 Rajab 1447 H"
  String _formatHijriDate(DateTime date, int adjustment) {
    // Set locale ke Indonesia
    // HijriCalendar.setLocal('id');

    final hijri = HijriCalendar.fromDate(date);

    // Apply adjustment (jika ada)
    // Note: HijriCalendar tidak punya method addDays yang handle bulan/tahun rollover scara otomatis
    // Namun library ini handle hDay > lengthOfMonth saat toFormat dipanggil?
    // Tidak, kita sebaiknya tidak sembarangan tambah hDay.
    // Tapi karena library simple, kita coba mekanisme built-in atau manual check.

    // Cek dokumentasi/source code asumsi: hDay adalah pure integer.
    // Jika adjustment menyebabkan perpindahan bulan, kita harus handle manual atau cari cara lain.
    // Untungnya: Spec bilang "settings adjustment", library hijri mungkin punya property _adjust?
    // Tidak, API publicnya fromDate assign hDay, hMonth, hYear.

    // Workaround Aman: Konversi Masehi + adjustment days?
    // TIDAK BOLEH. Masehi harus tetap hari ini.

    // Solusi: Kita tambah hDay, lalu validasi validitas tanggal jika library punya method validasi.
    // Atau jika hDay <= 0 atau > lengthOfMonth, kita geser bulan.

    if (adjustment != 0) {
      // Simplest approach: convert dari (date + adjustment)
      // Ini asumsi bahwa kalender Hijriah linear dengan Masehi (walau tidak selalu tepat 100%)
      // Tapi adjustment ini tujuannya memang menggeser "hari ini dianggap tanggal sekian".
      // Jika user set +1, berarti hari ini (misal senin) dianggap tanggal (X+1).
      // Tanggal (X+1) itu adalah tanggal hijriah untuk (Masehi besok).

      // Jadi: HijriCalendar.fromDate(date.add(Duration(days: adjustment))) adalah pendekatan logis
      // untuk "menganggap hari ini adalah besok/kemarin" dalam konteks tanggal.
      final adjHijri = HijriCalendar.fromDate(
        date.add(Duration(days: adjustment)),
      );
      return '${adjHijri.hDay} ${adjHijri.longMonthName} ${adjHijri.hYear} H';
    }

    return '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} H';
  }
}
