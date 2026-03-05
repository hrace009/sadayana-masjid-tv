---
title: "Prayer Time Calculation Engine Specification"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
tags: [process, prayer-time, adhan, hijri, calculation, offline]
---

# Introduction

Spesifikasi ini mendefinisikan mesin kalkulasi waktu sholat untuk aplikasi Miqotul Khoir TV. Kalkulasi dilakukan **100% offline** menggunakan library `adhan-dart` (astronomical calculation) dengan tambahan manual correction (Ihtiyat) per waktu sholat.

Modul ini adalah **core business logic** aplikasi — outputnya menjadi input bagi State Machine (SPEC-04) untuk menentukan state transition.

## 1. Purpose & Scope

### Purpose

Menghitung 7 waktu sholat harian + tanggal Hijriah secara lokal tanpa internet, dengan dukungan koreksi manual per waktu sholat.

### Scope

- Kalkulasi 7 waktu: Subuh, Syuruq, Dhuha, Dzuhur, Ashar, Maghrib, Isya
- Manual correction (Ihtiyat) per waktu sholat
- Konversi tanggal Hijriah dengan manual adjustment
- Cubit state management (`PrayerTimeCubit`)
- Auto-recalculate saat hari berganti (midnight)

### Out of Scope

- Audio adzan (ditangani oleh SPEC-04: State Machine)
- UI display jadwal sholat (ditangani oleh SPEC-04)
- Input lokasi (ditangani oleh SPEC-05: Setup Wizard)

## 2. Definitions

| Term | Definition |
|------|-----------|
| **adhan-dart** | Library Dart untuk kalkulasi waktu sholat berdasarkan posisi matahari |
| **Ihtiyat** | Koreksi waktu (±menit) untuk menyesuaikan jadwal sholat dengan kebiasaan lokal masjid |
| **Syuruq** | Waktu matahari terbit |
| **Dhuha** | Waktu sholat Dhuha, dihitung dari Syuruq + offset |
| **CalculationMethod** | Parameter astronomi (sudut Subuh, sudut Isya) untuk kalkulasi |
| **Hijri** | Kalender Islam (Hijriah) berdasarkan fase bulan |
| **Umm al-Qura** | Metode konversi kalender Hijriah yang digunakan di Saudi Arabia |
| **Midnight Crossing** | Kondisi saat waktu Isya melewati pukul 00:00 |

## 3. Requirements, Constraints & Guidelines

### Requirements

- **REQ-001**: Kalkulasi waktu sholat dilakukan secara offline menggunakan `adhan-dart`
- **REQ-002**: 7 waktu ditampilkan: Subuh, Syuruq, Dhuha, Dzuhur, Ashar, Maghrib, Isya
- **REQ-003**: Waktu Dhuha dihitung dengan formula: `Syuruq + dhuha_offset_minutes` (default 20 menit)
- **REQ-004**: Setiap waktu sholat memiliki koreksi manual (Ihtiyat) range -10 s/d +10 menit
- **REQ-005**: Formula akhir: `DisplayTime = CalculatedTime + UserCorrectionMinutes`
- **REQ-006**: Default calculation method: Standar **Kemenag RI** (SIHAT) — Subuh 20°, Isya 18°, Ihtiyat bawaan +2 menit
- **REQ-007**: Tanggal Hijriah dihitung secara lokal dengan dukungan manual adjustment (H-2 s/d H+2 hari)
- **REQ-008**: Kalkulasi otomatis di-recalculate setiap hari berganti (midnight)
- **REQ-009**: Output harus include informasi "next prayer" (waktu sholat berikutnya) beserta durasi countdown

### Constraints

- **CON-001**: Tidak boleh menggunakan API internet untuk mendapatkan waktu sholat
- **CON-002**: Input location (lat/lng) dibaca dari SQLite `settings` table (SPEC-01)
- **CON-003**: Timezone dibaca dari `settings.timezone`, bukan dari system timezone
- **CON-004**: Kalkulasi harus deterministic — input yang sama selalu menghasilkan output yang sama

### Guidelines

- **GUD-001**: Cubit state harus immutable, gunakan `Equatable` untuk comparison
- **GUD-002**: Prayer time entity harus include raw calculated time dan corrected display time
- **GUD-003**: Use case harus pure function — tidak ada side effects, hanya kalkulasi

### Patterns

- **PAT-001**: Use Case Pattern — `CalculatePrayerTimesUseCase` di `domain/usecases/`
- **PAT-002**: Cubit Pattern — `PrayerTimeCubit` emit state baru setiap recalculation

## 4. Interfaces & Data Contracts

### 4.1. PrayerTime Entity

```dart
/// domain/entities/prayer_time.dart
class PrayerTime {
  final String name;           // "Subuh", "Syuruq", "Dhuha", etc.
  final DateTime rawTime;      // Waktu hasil kalkulasi (sebelum koreksi)
  final DateTime displayTime;  // Waktu setelah koreksi (rawTime + offset)
  final int offsetMinutes;     // Koreksi yang diterapkan
  final bool isNext;           // Apakah ini waktu sholat berikutnya

  const PrayerTime({...});
}
```

### 4.2. DailyPrayerTimes Entity

```dart
/// domain/entities/daily_prayer_times.dart
class DailyPrayerTimes {
  final DateTime date;                // Tanggal Masehi
  final String hijriDate;             // Tanggal Hijriah (formatted string)
  final int hijriDay;
  final int hijriMonth;
  final int hijriYear;
  final String hijriMonthName;
  final List<PrayerTime> prayerTimes; // 7 waktu sholat (sorted by time)
  final PrayerTime? nextPrayer;       // Waktu sholat berikutnya
  final Duration? timeToNextPrayer;   // Durasi menuju waktu sholat berikutnya

  const DailyPrayerTimes({...});
}
```

### 4.3. Use Case

```dart
/// domain/usecases/calculate_prayer_times_use_case.dart
class CalculatePrayerTimesUseCase {
  /// Hitung 7 waktu sholat untuk tanggal dan lokasi tertentu
  ///
  /// [date] — tanggal yang dihitung
  /// [latitude] — latitude lokasi masjid
  /// [longitude] — longitude lokasi masjid
  /// [timezone] — timezone string (e.g. 'Asia/Jakarta')
  /// [calculationMethod] — metode kalkulasi (default: 'singapore')
  /// [offsets] — Map<String, int> koreksi per waktu sholat
  /// [dhuhaOffsetMinutes] — offset Dhuha dari Syuruq
  /// [hijriAdjustment] — adjustment hari Hijriah
  DailyPrayerTimes execute({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String timezone,
    String calculationMethod = 'singapore',
    Map<String, int> offsets = const {},
    int dhuhaOffsetMinutes = 20,
    int hijriAdjustment = 0,
  });
}
```

### 4.4. Cubit States

```dart
/// presentation/cubits/prayer_time/prayer_time_state.dart
abstract class PrayerTimeState extends Equatable {}

class PrayerTimeInitial extends PrayerTimeState {}

class PrayerTimeLoading extends PrayerTimeState {}

class PrayerTimeLoaded extends PrayerTimeState {
  final DailyPrayerTimes dailyPrayerTimes;
}

class PrayerTimeError extends PrayerTimeState {
  final String message;
}
```

### 4.5. Cubit

```dart
/// presentation/cubits/prayer_time/prayer_time_cubit.dart
class PrayerTimeCubit extends Cubit<PrayerTimeState> {
  final CalculatePrayerTimesUseCase _calculatePrayerTimes;
  final SettingsRepository _settingsRepository;
  Timer? _midnightTimer;

  PrayerTimeCubit({
    required CalculatePrayerTimesUseCase calculatePrayerTimes,
    required SettingsRepository settingsRepository,
  });

  /// Load dan hitung prayer times berdasarkan settings terkini
  Future<void> loadPrayerTimes();

  /// Recalculate saat settings berubah (location, offsets, etc.)
  Future<void> recalculate();

  /// Update "next prayer" indicator (dipanggil setiap menit)
  void updateNextPrayer(DateTime now);

  /// Schedule recalculation saat hari berganti
  void _scheduleMidnightRecalculation();

  @override
  Future<void> close() {
    _midnightTimer?.cancel();
    return super.close();
  }
}
```

### 4.6. Calculation Flow

```
Settings (lat, lng, offsets)
        │
        ▼
┌──────────────────────┐
│  adhan-dart library  │
│  CalculationMethod   │
│  Coordinates         │
│  DateComponents      │
└──────┬───────────────┘
       │ Raw times: Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha
       ▼
┌──────────────────────┐
│  Apply Corrections   │
│  + Ihtiyat offsets   │
│  + Dhuha = Sunrise   │
│    + dhuha_offset    │
└──────┬───────────────┘
       │ 7 corrected times
       ▼
┌──────────────────────┐
│  Determine Next      │
│  Prayer + Countdown  │
└──────┬───────────────┘
       │
       ▼
  DailyPrayerTimes entity
```

### 4.7. Mapping adhan-dart Output ke 7 Waktu

| Display Name | adhan-dart Property | Correction Field |
|-------------|--------------------|--------------------|
| Subuh | `prayerTimes.fajr` | `offset_subuh` |
| Syuruq | `prayerTimes.sunrise` | `offset_syuruq` |
| Dhuha | `prayerTimes.sunrise + dhuha_offset` | `offset_dhuha` |
| Dzuhur | `prayerTimes.dhuhr` | `offset_dzuhur` |
| Ashar | `prayerTimes.asr` | `offset_ashar` |
| Maghrib | `prayerTimes.maghrib` | `offset_maghrib` |
| Isya | `prayerTimes.isha` | `offset_isya` |

### 4.8. File Structure

```
lib/
├── domain/
│   ├── entities/
│   │   ├── prayer_time.dart             # Single prayer time
│   │   └── daily_prayer_times.dart      # All 7 times + hijri + next prayer
│   └── usecases/
│       └── calculate_prayer_times_use_case.dart
├── data/
│   └── services/
│       ├── adhan_prayer_service.dart    # Wrapper around adhan-dart
│       └── hijri_date_service.dart      # Hijri date conversion
├── presentation/
│   └── cubits/
│       └── prayer_time/
│           ├── prayer_time_cubit.dart
│           └── prayer_time_state.dart
```

## 5. Acceptance Criteria

- **AC-001**: Given coordinates Bandung (-6.9175, 107.6191) on 2026-01-15, When prayer times are calculated using `singapore` method, Then Subuh ≈ 04:20, Dzuhur ≈ 11:58, Ashar ≈ 15:18, Maghrib ≈ 18:12, Isya ≈ 19:24 (±5 minutes tolerance)
- **AC-002**: Given offset_subuh = +2 minutes, When Subuh calculated as 04:20, Then displayTime = 04:22
- **AC-003**: Given offset_subuh = -3 minutes, When Subuh calculated as 04:20, Then displayTime = 04:17
- **AC-004**: Given Syuruq = 05:48 and dhuha_offset = 20, When Dhuha is calculated, Then Dhuha = 06:08
- **AC-005**: Given current time 15:00, When next prayer is Maghrib at 18:12, Then `nextPrayer.name` = "Maghrib" and `timeToNextPrayer` = 3h 12m
- **AC-006**: Given current time 19:30 dan Isya sudah lewat, When next prayer is determined, Then `nextPrayer` = Subuh besok
- **AC-007**: Given hijriAdjustment = +1, When Hijri date is 10 Ramadhan, Then displayed as 11 Ramadhan
- **AC-008**: Given midnight passes (00:00), When midnight timer fires, Then prayer times are recalculated for the new day
- **AC-009**: Given settings location changes, When `recalculate()` is called, Then new prayer times are emitted reflecting new location
- **AC-010**: Given the use case with same input parameters, When called multiple times, Then output is identical (deterministic)

## 6. Test Automation Strategy

### Test Levels

| Level | Scope | Framework |
|-------|-------|-----------|
| **Unit** | `CalculatePrayerTimesUseCase` — pure function | `flutter_test` |
| **Unit** | `HijriDateService` — date conversion | `flutter_test` |
| **Unit** | `PrayerTimeCubit` — state transitions | `flutter_test` + `bloc_test` |

### Required Tests

- **TEST-001**: Use case returns 7 prayer times for valid coordinates
- **TEST-002**: Use case applies manual correction correctly (positive offset)
- **TEST-003**: Use case applies manual correction correctly (negative offset)
- **TEST-004**: Use case calculates Dhuha from Syuruq + offset
- **TEST-005**: Next prayer is correctly identified based on current time
- **TEST-006**: Next prayer wraps to Subuh after Isya
- **TEST-007**: Hijri date conversion produces valid output
- **TEST-008**: Hijri adjustment applies correctly
- **TEST-009**: `PrayerTimeCubit` emits `PrayerTimeLoaded` after `loadPrayerTimes()`
- **TEST-010**: `PrayerTimeCubit` emits new state after `recalculate()`
- **TEST-011**: `PrayerTimeCubit` cancels midnight timer on `close()`
- **TEST-012**: Edge case — coordinates near equator (0°, 0°) produce valid times
- **TEST-013**: Edge case — extreme latitudes (60°+) handled gracefully

## 7. Rationale & Context

### Mengapa adhan-dart, bukan API?

- PRD §4.1 mensyaratkan 100% offline capability
- Astronomical calculation memberikan akurasi tinggi tanpa network dependency
- Library `adhan` sudah terbukti dan widely used

### Mengapa Dhuha Dihitung Terpisah?

Library `adhan-dart` tidak menyediakan waktu Dhuha secara langsung. Dhuha dihitung dari Syuruq + offset karena:
- Tidak ada standar astronomi untuk Dhuha (bervariasi antar madzhab)
- Offset configurable memungkinkan penyesuaian per masjid

### Mengapa Next Prayer Include Wrap-around?

Setelah Isya, "next prayer" harus wrap ke Subuh besok. Ini penting untuk:
- Pre-Adzan countdown (SPEC-04) agar tetap berfungsi setelah Isya
- Menghitung durasi yang benar lintas midnight

## 8. Dependencies & External Integrations

### Third-Party Packages

- **DEP-001**: `adhan` — Astronomical prayer time calculation library
- **DEP-002**: `hijri` — Hijri calendar conversion (Umm al-Qura method)
- **DEP-003**: `intl` — Date formatting dengan locale `id_ID`

### Internal Dependencies

- **INT-001**: SPEC-01 `SettingsRepository` — Membaca koordinat, offsets, dan timezone
- **INT-002**: SPEC-01 `Settings` entity — Data source untuk kalkulasi parameters

## 9. Examples & Edge Cases

### Edge Case: Waktu Isya Melewati Midnight

```dart
// Pada latitude tinggi, Isya bisa melewati 00:00
// Formula: jika Isya < Maghrib, maka Isya adalah hari berikutnya
final isya = prayerTimes.isha;
final maghrib = prayerTimes.maghrib;
if (isya.isBefore(maghrib)) {
  // Isya wraps to next day — adjust accordingly
}
```

### Edge Case: Semua Offset = 0

```dart
// Ketika semua offset 0, displayTime == rawTime
// Ini adalah behavior default saat pertama kali setup
assert(prayerTime.displayTime == prayerTime.rawTime);
```

### Edge Case: Next Prayer Setelah Isya

```dart
// Setelah Isya, next prayer = Subuh besok
// timeToNextPrayer harus dihitung lintas midnight
if (now.isAfter(isya.displayTime)) {
  final tomorrowSubuh = calculatePrayerTimes(tomorrow).first;
  nextPrayer = tomorrowSubuh;
  timeToNextPrayer = tomorrowSubuh.displayTime.difference(now);
}
```

## 10. Validation Criteria

- [ ] 7 waktu sholat dihitung untuk coordinate Indonesia yang valid
- [ ] Manual correction diterapkan dengan benar (positif dan negatif)
- [ ] Dhuha = Syuruq + configurable offset
- [ ] Next prayer wrap-around berfungsi setelah Isya
- [ ] Hijri date sesuai dengan referensi (±1 hari karena metode konversi)
- [ ] Cubit tidak memancarkan state duplicate
- [ ] Midnight timer terjadwal dan fires pada 00:00

## 11. Related Specifications / Further Reading

- [PRD §3.1 — Prayer Time Calculation](file:///d:/AndroidProject/LatihanFlutter/sadayana_masjid_tv/Product_Requirement_Document.md)
- [PRD §3.3 — Hijri Date](file:///d:/AndroidProject/LatihanFlutter/sadayana_masjid_tv/Product_Requirement_Document.md)
- SPEC-01: Database Schema — `settings` table fields (offsets, coordinates)
- SPEC-04: Display State Machine — Consumer of prayer times for state transitions
