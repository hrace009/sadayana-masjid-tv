// ignore_for_file: avoid_print
import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Script analisis perbandingan waktu sholat:
/// - Output kalkulasi app (Kemenag method + DPL correction) vs Jadwal Resmi Kemenag Bandung Maret 2026
///
/// Tujuan: Memvalidasi bahwa koreksi DPL menghasilkan selisih ≤1 menit.
void main() {
  test('Kemenag comparison analysis — Bandung March 2026 (WITH DPL correction)', () {
    // Koordinat Bandung (sesuai default app)
    const lat = -6.9175;
    const lng = 107.6191;
    const elevation = 698; // Bandung elevation from Open Elevation API
    final coordinates = Coordinates(lat, lng);
    final fmt = DateFormat('HH:mm');

    // Hitung koreksi DPL (sama persis dengan formula di CalculatePrayerTimesUseCase)
    final dipDeg = (2.70 * sqrt(elevation.toDouble())) / 60.0;
    final latRad = lat * pi / 180.0;
    final altitudeCorrection = ((4.0 * dipDeg) / cos(latRad)).round();
    print(
      'DPL Correction for elevation ${elevation}m: $altitudeCorrection minutes',
    );

    // Parameter Kemenag dengan koreksi DPL
    final params = CalculationMethod.other.getParameters();
    params.fajrAngle = 20;
    params.ishaAngle = 18;
    params.madhab = Madhab.shafi;
    params.adjustments.fajr = 2;
    params.adjustments.sunrise = -2 - altitudeCorrection;
    params.adjustments.dhuhr = 4; // Koreksi Dzuhur +4
    params.adjustments.asr = 2;
    params.adjustments.maghrib = 2 + altitudeCorrection;
    params.adjustments.isha = 2;

    // Data referensi Kemenag Bandung Maret 2026
    // Format: [day, imsak, subuh, terbit, duha, zuhur, asar, maghrib, isya]
    final kemenagData = [
      [
        1,
        '04:29',
        '04:39',
        '05:48',
        '06:19',
        '12:05',
        '15:07',
        '18:16',
        '19:21',
      ],
      [
        2,
        '04:29',
        '04:39',
        '05:48',
        '06:19',
        '12:05',
        '15:06',
        '18:16',
        '19:21',
      ],
      [
        3,
        '04:29',
        '04:39',
        '05:48',
        '06:19',
        '12:05',
        '15:05',
        '18:15',
        '19:20',
      ],
      [
        4,
        '04:29',
        '04:39',
        '05:48',
        '06:19',
        '12:05',
        '15:06',
        '18:15',
        '19:20',
      ],
      [
        5,
        '04:29',
        '04:39',
        '05:48',
        '06:19',
        '12:05',
        '15:06',
        '18:15',
        '19:20',
      ],
      [
        6,
        '04:29',
        '04:39',
        '05:47',
        '06:19',
        '12:04',
        '15:07',
        '18:14',
        '19:19',
      ],
      [
        7,
        '04:29',
        '04:39',
        '05:47',
        '06:19',
        '12:04',
        '15:07',
        '18:14',
        '19:19',
      ],
      [
        8,
        '04:29',
        '04:39',
        '05:47',
        '06:19',
        '12:04',
        '15:08',
        '18:13',
        '19:18',
      ],
      [
        9,
        '04:29',
        '04:39',
        '05:47',
        '06:19',
        '12:04',
        '15:08',
        '18:13',
        '19:17',
      ],
      [
        10,
        '04:29',
        '04:39',
        '05:47',
        '06:19',
        '12:03',
        '15:08',
        '18:12',
        '19:17',
      ],
      [
        11,
        '04:29',
        '04:39',
        '05:47',
        '06:18',
        '12:03',
        '15:09',
        '18:11',
        '19:16',
      ],
      [
        12,
        '04:29',
        '04:39',
        '05:47',
        '06:18',
        '12:03',
        '15:09',
        '18:11',
        '19:16',
      ],
      [
        13,
        '04:29',
        '04:39',
        '05:47',
        '06:18',
        '12:03',
        '15:09',
        '18:10',
        '19:15',
      ],
      [
        14,
        '04:29',
        '04:39',
        '05:47',
        '06:18',
        '12:02',
        '15:10',
        '18:10',
        '19:15',
      ],
      [
        15,
        '04:29',
        '04:39',
        '05:47',
        '06:18',
        '12:02',
        '15:10',
        '18:10',
        '19:15',
      ],
      [
        16,
        '04:29',
        '04:39',
        '05:47',
        '06:18',
        '12:02',
        '15:10',
        '18:10',
        '19:14',
      ],
      [
        17,
        '04:29',
        '04:39',
        '05:47',
        '06:18',
        '12:01',
        '15:09',
        '18:09',
        '19:14',
      ],
      [
        18,
        '04:29',
        '04:39',
        '05:47',
        '06:18',
        '12:01',
        '15:10',
        '18:09',
        '19:13',
      ],
      [
        19,
        '04:29',
        '04:39',
        '05:47',
        '06:18',
        '12:01',
        '15:11',
        '18:08',
        '19:13',
      ],
      [
        20,
        '04:29',
        '04:39',
        '05:46',
        '06:18',
        '12:01',
        '15:11',
        '18:08',
        '19:12',
      ],
      [
        21,
        '04:29',
        '04:39',
        '05:46',
        '06:18',
        '12:01',
        '15:11',
        '18:08',
        '19:12',
      ],
      [
        22,
        '04:29',
        '04:39',
        '05:46',
        '06:17',
        '12:00',
        '15:12',
        '18:07',
        '19:12',
      ],
      [
        23,
        '04:29',
        '04:39',
        '05:46',
        '06:17',
        '12:00',
        '15:11',
        '18:06',
        '19:11',
      ],
      [
        24,
        '04:29',
        '04:39',
        '05:46',
        '06:17',
        '11:59',
        '15:11',
        '18:06',
        '19:10',
      ],
      [
        25,
        '04:28',
        '04:38',
        '05:46',
        '06:17',
        '11:59',
        '15:12',
        '18:05',
        '19:10',
      ],
      [
        26,
        '04:28',
        '04:38',
        '05:46',
        '06:17',
        '11:59',
        '15:12',
        '18:05',
        '19:09',
      ],
      [
        27,
        '04:28',
        '04:38',
        '05:46',
        '06:17',
        '11:59',
        '15:12',
        '18:04',
        '19:09',
      ],
      [
        28,
        '04:28',
        '04:38',
        '05:46',
        '06:17',
        '11:58',
        '15:12',
        '18:04',
        '19:08',
      ],
      [
        29,
        '04:28',
        '04:38',
        '05:45',
        '06:17',
        '11:58',
        '15:12',
        '18:03',
        '19:08',
      ],
      [
        30,
        '04:28',
        '04:38',
        '05:45',
        '06:17',
        '11:58',
        '15:12',
        '18:03',
        '19:07',
      ],
      [
        31,
        '04:28',
        '04:38',
        '05:45',
        '06:17',
        '11:57',
        '15:12',
        '18:02',
        '19:07',
      ],
    ];

    // Header output
    print('');
    print('=== ANALISIS PERBANDINGAN WAKTU SHOLAT ===');
    print('Lokasi: Bandung ($lat, $lng)');
    print('Bulan: Maret 2026');
    print('Method: Kemenag SIHAT (Fajr 20°, Isha 18°, Ihtiyat +2 min)');
    print('');
    print('Tgl | Waktu     | App   | Kemenag | Selisih');
    print('----|-----------|-------|---------|--------');

    // Statistik per waktu sholat
    final diffs = <String, List<int>>{
      'Subuh': [],
      'Terbit': [],
      'Dzuhur': [],
      'Ashar': [],
      'Maghrib': [],
      'Isya': [],
    };

    for (final row in kemenagData) {
      final day = row[0] as int;
      final date = DateTime(2026, 3, day);
      final dateComponents = DateComponents.from(date);

      final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

      // Konversi ke WIB (UTC+7) — adhan mengembalikan UTC
      final subuh = prayerTimes.fajr.toLocal();
      final terbit = prayerTimes.sunrise.toLocal();
      final dzuhur = prayerTimes.dhuhr.toLocal();
      final ashar = prayerTimes.asr.toLocal();
      final maghrib = prayerTimes.maghrib.toLocal();
      final isya = prayerTimes.isha.toLocal();

      // Kemenag reference
      final kSubuh = row[2] as String;
      final kTerbit = row[3] as String;
      final kDzuhur = row[5] as String;
      final kAshar = row[6] as String;
      final kMaghrib = row[7] as String;
      final kIsya = row[8] as String;

      // Hitung selisih dalam menit
      int diffMinutes(DateTime appTime, String kemenagTime) {
        final parts = kemenagTime.split(':');
        final kTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        return appTime.difference(kTime).inMinutes;
      }

      final dSubuh = diffMinutes(subuh, kSubuh);
      final dTerbit = diffMinutes(terbit, kTerbit);
      final dDzuhur = diffMinutes(dzuhur, kDzuhur);
      final dAshar = diffMinutes(ashar, kAshar);
      final dMaghrib = diffMinutes(maghrib, kMaghrib);
      final dIsya = diffMinutes(isya, kIsya);

      diffs['Subuh']!.add(dSubuh);
      diffs['Terbit']!.add(dTerbit);
      diffs['Dzuhur']!.add(dDzuhur);
      diffs['Ashar']!.add(dAshar);
      diffs['Maghrib']!.add(dMaghrib);
      diffs['Isya']!.add(dIsya);

      // Print per hari
      String fmtDiff(int d) => '${d >= 0 ? "+" : ""}$d min';

      print(
        '${day.toString().padLeft(2)}  | Subuh     | ${fmt.format(subuh)} | $kSubuh   | ${fmtDiff(dSubuh)}',
      );
      print(
        '    | Terbit    | ${fmt.format(terbit)} | $kTerbit   | ${fmtDiff(dTerbit)}',
      );
      print(
        '    | Dzuhur    | ${fmt.format(dzuhur)} | $kDzuhur   | ${fmtDiff(dDzuhur)}',
      );
      print(
        '    | Ashar     | ${fmt.format(ashar)} | $kAshar   | ${fmtDiff(dAshar)}',
      );
      print(
        '    | Maghrib   | ${fmt.format(maghrib)} | $kMaghrib   | ${fmtDiff(dMaghrib)}',
      );
      print(
        '    | Isya      | ${fmt.format(isya)} | $kIsya   | ${fmtDiff(dIsya)}',
      );
      print('----|-----------|-------|---------|--------');
    }

    // Ringkasan statistik
    print('');
    print('=== RINGKASAN SELISIH (App - Kemenag) ===');
    print('Waktu     | Min | Max | Rata-rata | Dominan');
    print('----------|-----|-----|-----------|--------');

    for (final entry in diffs.entries) {
      final vals = entry.value;
      final min = vals.reduce((a, b) => a < b ? a : b);
      final max = vals.reduce((a, b) => a > b ? a : b);
      final avg = vals.reduce((a, b) => a + b) / vals.length;

      // Hitung modus (most common value)
      final counts = <int, int>{};
      for (final v in vals) {
        counts[v] = (counts[v] ?? 0) + 1;
      }
      final modeEntry = counts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      print(
        '${entry.key.padRight(9)} | ${min.toString().padLeft(3)} | ${max.toString().padLeft(3)} | ${avg.toStringAsFixed(1).padLeft(9)} | ${modeEntry.key} min (${modeEntry.value}/31 hari)',
      );
    }

    print('');
    print('=== REKOMENDASI KOREKSI ===');
    for (final entry in diffs.entries) {
      final vals = entry.value;
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      if (avg.abs() >= 1.0) {
        final correction = -avg.round();
        print(
          '${entry.key}: Perlu koreksi ${correction >= 0 ? "+" : ""}$correction menit (rata-rata selisih: ${avg.toStringAsFixed(1)} min)',
        );
      } else {
        print(
          '${entry.key}: Sudah akurat (rata-rata selisih: ${avg.toStringAsFixed(1)} min)',
        );
      }
    }
  });
}
