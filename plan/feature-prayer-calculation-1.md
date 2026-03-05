---
goal: "Implementasi Prayer Time Calculation — Entities, Use Case, Adhan-Dart Integration & Hijri Conversion"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-19
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, prayer-time, calculation, adhan, hijri, domain, use-case]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Plan ini mencakup implementasi domain layer untuk kalkulasi waktu sholat: entities (`PrayerTime`, `DailyPrayerTimes`), integrasi library `adhan-dart` untuk kalkulasi astronomis, penerapan Ihtiyat (koreksi waktu), konversi Hijri, dan use case `CalculatePrayerTimesUseCase`. Plan ini murni **business logic** tanpa UI.

**Source Specification**: [spec-process-prayer-time.md](../spec/spec-process-prayer-time.md) (SPEC-03 Part A)

## 1. Requirements & Constraints

- **REQ-001**: Aplikasi harus menghitung 7 waktu sholat: Subuh, Syuruq, Dhuha, Dzuhur, Ashar, Maghrib, Isya
- **REQ-002**: Kalkulasi menggunakan library `adhan-dart` sebagai engine, bukan kalkulasi manual
- **REQ-003**: Setiap waktu sholat harus mendukung Ihtiyat (offset koreksi ±30 menit)
- **REQ-004**: Dhuha dihitung sebagai Syuruq + offset (default: 15 menit setelah Syuruq)
- **REQ-005**: Tanggal Hijri harus tersedia bersamaan dengan tanggal Masehi
- **REQ-006**: Semua kalkulasi harus pure function (deterministic, no side-effects)
- **REQ-007**: Hijri adjustment (±2 hari) harus configurable via settings
- **SEC-001**: Koordinat lokasi harus divalidasi (latitude: -90 to 90, longitude: -180 to 180)
- **CON-001**: Calculation method default: Kementerian Agama RI (Kemenag)
- **CON-002**: Timezone default: `Asia/Jakarta` (WIB, UTC+7)
- **CON-003**: Semua waktu direpresentasikan sebagai `DateTime` (local timezone)
- **GUD-001**: Entity harus immutable (final fields, const constructor)
- **GUD-002**: Use case harus mengembalikan `DailyPrayerTimes` — bukan individual times
- **PAT-001**: Clean Architecture — Use case di domain layer, tidak import dari data/presentation

## 2. Implementation Steps

### Phase 1: Package Dependencies

- GOAL-001: Menambahkan packages untuk kalkulasi waktu sholat dan konversi Hijri

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Jalankan `flutter pub add adhan` — Prayer time calculation engine (`adhan 2.0.0+1`) | ✅ | 2026-02-19 |
| TASK-002 | Jalankan `flutter pub add hijri` — Hijri calendar conversion (`hijri 3.0.0`) | ✅ | 2026-02-19 |
| TASK-003 | Jalankan `flutter pub add intl` — Date/time formatting (`intl 0.20.2`) | ✅ | 2026-02-19 |
| TASK-004 | Jalankan `flutter pub get` | ✅ | 2026-02-19 |

### Phase 2: Prayer Time Entity

- GOAL-002: Membuat domain entity yang merepresentasikan satu waktu sholat (immutable)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-005 | Buat file `lib/domain/entities/prayer_time.dart` | ✅ | 2026-02-19 |
| TASK-006 | Implementasi `PrayerTime` class dengan `const` constructor. Fields: `String name`, `DateTime time`, `DateTime originalTime`, `int ihtiyatMinutes`. Extend `Equatable` | ✅ | 2026-02-19 |
| TASK-007 | Tambahkan getter `String formattedTime` yang mengembalikan waktu dalam format "HH:mm" menggunakan `intl` DateFormat | ✅ | 2026-02-19 |

### Phase 3: DailyPrayerTimes Entity

- GOAL-003: Membuat entity yang merepresentasikan semua 7 waktu sholat untuk satu hari

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-008 | Buat file `lib/domain/entities/daily_prayer_times.dart` | ✅ | 2026-02-19 |
| TASK-009 | Implementasi `DailyPrayerTimes` class. Fields: `DateTime date`, `String hijriDate`, `PrayerTime subuh`, `PrayerTime syuruq`, `PrayerTime dhuha`, `PrayerTime dzuhur`, `PrayerTime ashar`, `PrayerTime maghrib`, `PrayerTime isya`. Extend `Equatable` | ✅ | 2026-02-19 |
| TASK-010 | Tambahkan getter `List<PrayerTime> allPrayers` yang mengembalikan list 7 PrayerTime dalam urutan kronologis: `[subuh, syuruq, dhuha, dzuhur, ashar, maghrib, isya]` | ✅ | 2026-02-19 |
| TASK-011 | Tambahkan getter `List<PrayerTime> mainPrayers` yang hanya mengembalikan 5 waktu sholat wajib (tanpa Syuruq dan Dhuha): `[subuh, dzuhur, ashar, maghrib, isya]` | ✅ | 2026-02-19 |
| TASK-012 | Tambahkan method `PrayerTime? currentPrayer(DateTime now)` yang mengembalikan waktu sholat terdekat yang sudah lewat berdasarkan `now` (waktu sekarang), atau null jika belum ada sholat hari ini | ✅ | 2026-02-19 |
| TASK-013 | Tambahkan method `PrayerTime? nextPrayer(DateTime now)` yang mengembalikan waktu sholat berikutnya setelah `now`, atau null jika semua sudah lewat hari ini | ✅ | 2026-02-19 |

### Phase 4: CalculatePrayerTimesUseCase

- GOAL-004: Implementasi use case yang mengintegrasikan adhan-dart, menerapkan Ihtiyat, dan mengembalikan DailyPrayerTimes

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-014 | Buat file `lib/domain/usecases/calculate_prayer_times_use_case.dart` | ✅ | 2026-02-19 |
| TASK-015 | Implementasi `CalculatePrayerTimesUseCase` class. Constructor menerima `SettingsRepository` | ✅ | 2026-02-19 |
| TASK-016 | Implementasi method utama `Future<DailyPrayerTimes> execute({DateTime? date})` | ✅ | 2026-02-19 |
| TASK-017 | Implementasi private method `CalculationParameters _getCalculationParameters(String methodName)` | ✅ | 2026-02-19 |
| TASK-018 | Implementasi private method `PrayerTime _applyIhtiyat(String name, DateTime originalTime, int offsetMinutes)` | ✅ | 2026-02-19 |
| TASK-019 | Implementasi private method `String _formatHijriDate(DateTime date, int adjustment)` | ✅ | 2026-02-19 |
| TASK-020 | Validasi koordinat: throw `ArgumentError` jika latitude ∉ [-90, 90] atau longitude ∉ [-180, 180] | ✅ | 2026-02-19 |

### Phase 5: Unit Tests

- GOAL-005: Comprehensive unit tests untuk entities dan use case

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-021 | Buat file `test/domain/entities/prayer_time_test.dart` | ✅ | 2026-02-19 |
| TASK-022 | TEST: `PrayerTime` equality — dua instance dengan field identik harus equal | ✅ | 2026-02-19 |
| TASK-023 | TEST: `formattedTime` getter returns "HH:mm" format | ✅ | 2026-02-19 |
| TASK-024 | Buat file `test/domain/entities/daily_prayer_times_test.dart` | ✅ | 2026-02-19 |
| TASK-025 | TEST: `allPrayers` returns 7 prayer times in chronological order | ✅ | 2026-02-19 |
| TASK-026 | TEST: `mainPrayers` returns 5 prayer times (excludes Syuruq, Dhuha) | ✅ | 2026-02-19 |
| TASK-027 | TEST: `currentPrayer(now)` returns correct prayer when `now` is between Dzuhur and Ashar → returns Dzuhur | ✅ | 2026-02-19 |
| TASK-028 | TEST: `nextPrayer(now)` returns correct next prayer when `now` is between Dzuhur and Ashar → returns Ashar | ✅ | 2026-02-19 |
| TASK-029 | TEST: `nextPrayer(now)` returns null when `now` is after Isya (semua sholat sudah lewat) | ✅ | 2026-02-19 |
| TASK-030 | Buat file `test/domain/usecases/calculate_prayer_times_use_case_test.dart` — Setup: mock `SettingsRepository` | ✅ | 2026-02-19 |
| TASK-031 | TEST: `execute()` returns `DailyPrayerTimes` with 7 valid prayer times for Bandung coordinates (-6.9175, 107.6191) | ✅ | 2026-02-19 |
| TASK-032 | TEST: Ihtiyat offsets are correctly applied — jika `offsetSubuh = 2`, maka `subuh.time` = `subuh.originalTime + 2 menit` | ✅ | 2026-02-19 |
| TASK-033 | TEST: Dhuha time = Syuruq time + `dhuhaOffsetMinutes` (default: 15 menit) | ✅ | 2026-02-19 |
| TASK-034 | TEST: Hijri date is correctly formatted dengan adjustment | ✅ | 2026-02-19 |
| TASK-035 | TEST: Invalid coordinates throw `ArgumentError` | ✅ | 2026-02-19 |
| TASK-036 | Jalankan `flutter test test/domain/ --reporter=expanded` dan pastikan semua pass | ✅ | 2026-02-19 |

## 3. Alternatives

- **ALT-001**: Kalkulasi manual tanpa library — Ditolak karena kalkulasi waktu sholat melibatkan astronomi kompleks (solar position, equation of time) yang rentan error
- **ALT-002**: Menggunakan API online untuk prayer times — Ditolak karena aplikasi harus offline-first, tidak boleh bergantung pada koneksi internet
- **ALT-003**: Menyimpan pre-calculated prayer times untuk setahun — Ditolak karena memerlukan storage besar dan tidak akurat jika user pindah lokasi

## 4. Implementation Notes

- **Timezone Handling**: Semua waktu yang dikembalikan oleh `adhan-dart` (UTC) telah dikonversi secara eksplisit ke Local Time menggunakan `.toLocal()` sebelum disimpan ke entity. (Fix untuk CON-003).
- **Hijri Locale**: Penggunaan `HijriCalendar.setLocal('id')` sementara dikomentari di use case karena isu loading asset saat unit testing. Default locale (English transliteration) digunakan saat ini.

## 5. Dependencies

- **DEP-001**: `adhan` (^2.0.0+1) — Prayer time calculation library (adhan-dart) ✅
- **DEP-002**: `hijri` (^3.0.0) — Hijri calendar conversion ✅
- **DEP-003**: `intl` (^0.20.2) — Date/time formatting ✅
- **DEP-004**: Plan 02 `SettingsRepository` — Interface untuk baca koordinat, offsets, calculation method
- **DEP-005**: Plan 02 `Settings` entity — Digunakan untuk mendapatkan parameter kalkulasi

## 5. Files

- **FILE-001**: `lib/domain/entities/prayer_time.dart` — [NEW] PrayerTime entity
- **FILE-002**: `lib/domain/entities/daily_prayer_times.dart` — [NEW] DailyPrayerTimes entity
- **FILE-003**: `lib/domain/usecases/calculate_prayer_times_use_case.dart` — [NEW] Prayer calculation use case
- **FILE-004**: `pubspec.yaml` — [MODIFY] Add adhan, hijri, intl
- **FILE-005**: `test/domain/entities/prayer_time_test.dart` — [NEW] PrayerTime tests
- **FILE-006**: `test/domain/entities/daily_prayer_times_test.dart` — [NEW] DailyPrayerTimes tests
- **FILE-007**: `test/domain/usecases/calculate_prayer_times_use_case_test.dart` — [NEW] Use case tests

## 6. Testing

- **TEST-001**: `PrayerTime` value equality works correctly
- **TEST-002**: `PrayerTime.formattedTime` returns "HH:mm" format
- **TEST-003**: `DailyPrayerTimes.allPrayers` returns 7 times chronologically
- **TEST-004**: `DailyPrayerTimes.mainPrayers` returns 5 fard prayers only
- **TEST-005**: `currentPrayer()` returns correct prayer based on current time
- **TEST-006**: `nextPrayer()` returns correct next prayer, null after Isya
- **TEST-007**: `execute()` returns valid DailyPrayerTimes for Bandung coordinates
- **TEST-008**: Ihtiyat offsets are correctly applied to prayer times
- **TEST-009**: Dhuha = Syuruq + offset
- **TEST-010**: Hijri formatting with adjustment
- **TEST-011**: Invalid coordinates validation

**Test Command**: `flutter test test/domain/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: `adhan-dart` mungkin tidak memiliki exact "Kemenag" calculation method — Mitigasi: gunakan `CalculationMethod.singapore` yang paling mendekati, atau custom parameters. Verifikasi dengan jadwal Kemenag resmi
- **RISK-002**: Hijri conversion mungkin berbeda 1-2 hari dari kalender lokal — Mitigasi: `hijriAdjustment` setting memungkinkan user koreksi manual
- **RISK-003**: `adhan-dart` package mungkin memerlukan timezone handling yang spesifik — Mitigasi: test dengan multiple timezones Indonesia (WIB, WITA, WIT)
- **ASSUMPTION-001**: Plan 02 `SettingsRepository` sudah selesai dan tested
- **ASSUMPTION-002**: `adhan` package kompatibel dengan Flutter version yang digunakan
- **ASSUMPTION-003**: Kordinat default Bandung (-6.9175, 107.6191) sudah benar

## 8. Related Specifications / Further Reading

- [SPEC-03: Prayer Time Calculation](../spec/spec-process-prayer-time.md) — Source specification
- [SPEC-01: Database Schema](../spec/spec-schema-database.md) — Settings fields untuk offsets dan lokasi
- Plan 02: `feature-data-layer-1.md` — Prerequisite (SettingsRepository interface)
- Plan 06: `feature-prayer-cubit-1.md` — Next plan yang membungkus use case dalam Cubit
- [adhan-dart Documentation](https://pub.dev/packages/adhan) — Library reference
