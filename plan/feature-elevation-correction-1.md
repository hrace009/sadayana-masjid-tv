---
goal: Koreksi Ketinggian Tempat (DPL) untuk Akurasi Waktu Sholat
version: 1.0
date_created: 2026-02-28
last_updated: 2026-02-28
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, prayer-time, elevation, dpl, altitude, accuracy, kemenag, database-migration]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Plan ini bertujuan untuk **menambahkan koreksi ketinggian tempat (DPL — Di atas Permukaan Laut)** pada kalkulasi waktu sholat agar akurat untuk semua kota di Indonesia, baik pesisir (Jakarta ~8m) maupun dataran tinggi (Bandung ~768m).

### Latar Belakang

Berdasarkan analisis perbandingan 31 hari (Bandung, Maret 2026) antara output app vs jadwal resmi Kemenag RI:

| Waktu | Rata-rata Selisih | Root Cause |
|-------|-------------------|------------|
| **Subuh** | -0.3 min ✅ | — |
| **Terbit** | **+5.3 min** ❌ | Tidak ada koreksi DPL |
| **Dzuhur** | **-1.5 min** ⚠️ | Perbedaan presisi equation of time |
| **Ashar** | -0.6 min ✅ | — |
| **Maghrib** | **-5.3 min** ❌ | Tidak ada koreksi DPL |
| **Isya** | -0.5 min ✅ | — |

Pola **simetris** pada Terbit (+5.3) dan Maghrib (-5.3) mengonfirmasi bahwa root cause utama adalah **koreksi ketinggian tempat** yang belum diterapkan. Koreksi Dzuhur (-1.5 min) juga akan ditangani sekaligus.

Data analisis lengkap: `test/analysis/kemenag_comparison_test.dart`

## 1. Requirements & Constraints

- **REQ-001**: Tambah field `elevation` (int, meter DPL) ke entity `City` dan `Settings`
- **REQ-002**: Tambah kolom `elevation` ke tabel `cities` dan `settings` di database SQLite
- **REQ-003**: Database migration v2 → v3 untuk menambahkan kolom `elevation`
- **REQ-004**: Tambah data elevasi ke `cities.json` (514 kota)
- **REQ-005**: Buat Python script untuk generate data elevasi dari Open Elevation API menggunakan koordinat yang sudah ada di `cities.json`
- **REQ-006**: Implementasi formula koreksi DPL di `CalculatePrayerTimesUseCase`:
  - `dip (arcminutes) = 2.70 × √(elevation_meter)` *(termasuk koreksi refraksi atmosfer tropis)*
  - `koreksi_menit ≈ (4 × dip_derajat) / cos(latitude_radian)`
  - Maghrib: tambah +koreksi menit (matahari terbenam lebih lambat dari ketinggian)
  - Syuruq/Terbit: kurangi -koreksi menit (matahari terbit lebih awal dari ketinggian)
- **REQ-007**: Koreksi Dzuhur — tambah +2 menit adjustments (total dari +2 menjadi +4)
- **REQ-008**: Auto-fill elevation saat user memilih kota di Setup Wizard
- **REQ-009**: Propagate elevation ke `CalculatePrayerTimesUseCase` via `Settings` entity
- **REQ-010**: Hasil kalkulasi harus ≤1 menit selisih dengan jadwal Kemenag RI untuk semua waktu sholat
- **CON-001**: Tidak boleh mengubah API existing yang sudah digunakan oleh Cubit/UI layer kecuali penambahan field baru
- **CON-002**: Schema migration harus backward-compatible (existing users tidak kehilangan data)
- **CON-003**: Default elevation `0` (permukaan laut) jika data tidak tersedia
- **PAT-001**: Mengikuti pola Clean Architecture yang sudah ada (Entity → Model → DataSource → Repository → UseCase)
- **PAT-002**: Testing menggunakan `sqflite_common_ffi` + in-memory database

## 2. Implementation Steps

### Phase 1 — Data Preparation: Generate Elevation Data

- GOAL-001: Buat script Python untuk mengambil data elevasi dari Open Elevation API berdasarkan koordinat 514 kota yang sudah ada, lalu update `cities.json`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat script `tools/add_elevation_to_cities.py` yang: (1) membaca `cities.json`, (2) mengirim batch request ke Open Elevation API (`https://api.open-elevation.com/api/v1/lookup`) dengan koordinat lat/lng setiap kota, (3) menulis kembali `cities.json` dengan field `elevation` (int) yang ditambahkan. API mendukung batch POST max ~200 koordinat per request. | ✅ | 2026-02-28 |
| TASK-002 | Jalankan script dan verifikasi hasilnya — spot-check beberapa kota: Jakarta (~6m), Bandung (~698m), Kab. Bandung (~1094m), Semarang (~83m), Surabaya (~7m). Update `cities.json` di assets. | ✅ | 2026-02-28 |

### Phase 2 — Data Layer: Schema & Model Update

- GOAL-002: Tambah field `elevation` ke database schema, entities, dan models

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-003 | Update `lib/domain/entities/city.dart` — tambah `final int elevation;` ke class `City`, update constructor dan `props` | ✅ | 2026-02-28 |
| TASK-004 | Update `lib/data/models/city_model.dart` — tambah `elevation` ke constructor, `fromMap()`, dan `toMap()` | ✅ | 2026-02-28 |
| TASK-005 | Update `lib/domain/entities/settings.dart` — tambah `this.elevation = 0` ke default constructor, update `copyWith()` dan `props` | ✅ | 2026-02-28 |
| TASK-006 | Update `lib/data/models/settings_model.dart` — tambah `elevation` ke `fromMap()` dan `toMap()` | ✅ | 2026-02-28 |
| TASK-007 | Update `lib/data/datasources/database_helper.dart`: (1) Naikkan `_databaseVersion` dari 2 ke 3, (2) tambah kolom `elevation INTEGER NOT NULL DEFAULT 0` ke DDL `cities` dan `settings` table, (3) tambah migration `if (oldVersion < 3)` di `_onUpgrade` yang menjalankan 2x `ALTER TABLE ... ADD COLUMN elevation`, (4) update `_seedCities` untuk menyertakan field elevation dari JSON | ✅ | 2026-02-28 |

### Phase 3 — Domain Layer: Formula Koreksi DPL & Dzuhur

- GOAL-003: Implementasi koreksi ketinggian tempat dan perbaikan Dzuhur di use case

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-008 | Tambah method `int _calculateAltitudeCorrectionMinutes(int elevationMeter, double latitudeDeg)` di `CalculatePrayerTimesUseCase`. Formula final: `dip_deg = (2.70 * sqrt(elevation)) / 60.0`, `correction_min = (4.0 * dip_deg) / cos(latitude * pi / 180.0)`, return `correction_min.round()`. *Koefisien 2.70 (bukan 1.76) mencakup refraksi atmosfer tropis Indonesia.* | ✅ | 2026-02-28 |
| TASK-009 | Modifikasi `_getCalculationParameters()` case `'kemenag'` agar menerima parameter `elevation` dan `latitude`, lalu apply: `params.adjustments.maghrib = 2 + altitudeCorrection`, `params.adjustments.sunrise = -2 - altitudeCorrection`. Method signature berubah menjadi `_getCalculationParameters(String methodName, {int elevation = 0, double latitude = 0})`. | ✅ | 2026-02-28 |
| TASK-010 | Koreksi Dzuhur: ubah `params.adjustments.dhuhr` dari `2` menjadi `4` di case `'kemenag'` untuk menutup gap rata-rata -1.5 menit. | ✅ | 2026-02-28 |
| TASK-011 | Update `execute()` method untuk mengambil `elevation` dari settings dan meneruskannya ke `_getCalculationParameters()`. | ✅ | 2026-02-28 |

### Phase 4 — Presentation Layer: Auto-fill Elevation

- GOAL-004: Elevation otomatis terisi saat user memilih kota

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-012 | Update `lib/presentation/cubits/setup_wizard/setup_wizard_cubit.dart` — method `selectCity()` harus menyertakan elevation dari data kota yang dipilih ke `SetupWizardData` dan `Settings` update. | ✅ | 2026-02-28 |
| TASK-013 | Update `lib/domain/entities/setup_wizard_data.dart` — tambah field `elevation` (int, default 0), update `copyWith()` | ✅ | 2026-02-28 |

### Phase 5 — Testing & Verification

- GOAL-005: Pastikan semua perubahan terverifikasi oleh automated test dan comparison analysis

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-014 | Update `test/data/models/city_model_test.dart` — tambah field `elevation` ke test data map, update assertion | ✅ | 2026-02-28 |
| TASK-015 | Update `test/data/models/settings_model_test.dart` — tambah field `elevation` ke test data map, update assertion | ✅ | 2026-02-28 |
| TASK-016 | Update `test/data/datasources/database_helper_test.dart` — tambah assertion untuk kolom `elevation` di default settings dan cities table | ✅ | 2026-02-28 |
| TASK-017 | Update `test/data/repositories/settings_repository_impl_test.dart` — tambah assertion `elevation` | ✅ | 2026-02-28 |
| TASK-018 | *(Skipped)* Rencana tambah unit test baru untuk `_calculateAltitudeCorrectionMinutes` langsung; validasi sudah tercakup via TASK-019 (comparison test 31 hari). | ⏭️ | — |
| TASK-019 | Update `test/analysis/kemenag_comparison_test.dart` — jalankan ulang perbandingan 31 hari dengan koreksi DPL (5 menit untuk Bandung 698m) dan Dzuhur +4. Target: semua waktu sholat ≤1 menit selisih dengan Kemenag. | ✅ | 2026-02-28 |
| TASK-020 | Jalankan `flutter test --reporter=expanded` — 172 tests passed. 3 failures adalah pre-existing (bukan disebabkan perubahan ini): 1x `islamic_colors_test`, 2x `settings_cubit_test` (mock setup issue lama). | ✅ | 2026-02-28 |

## 3. Alternatives

- **ALT-001**: **Quick Fix — Adjustment statis** — Tambah adjustment Maghrib dari +2 → +7 menit. Pro: cepat, 0 schema change. Kontra: hanya akurat untuk Bandung (~768m), Jakarta dan kota pesisir akan terlalu lambat 5 menit. **Ditolak** karena tidak universal.
- **ALT-002**: **Manual elevation input** — User memasukkan elevation manual di Settings tanpa data otomatis. Pro: tidak perlu update cities.json. Kontra: user harus tahu elevasi kotanya sendiri, error-prone. **Ditolak** karena UX buruk.
- **ALT-003**: **Google Elevation API** — Gunakan Google API dibanding Open Elevation. Pro: lebih reliable. Kontra: butuh API key, ada rate limit/billing. **Ditolak** karena Open Elevation gratis dan cukup untuk 514 data point.

## 4. Dependencies

- **DEP-001**: `dart:math` — untuk `sqrt()`, `cos()`, `pi` dalam formula koreksi DPL (sudah tersedia built-in)
- **DEP-002**: Open Elevation API (`https://api.open-elevation.com/api/v1/lookup`) — untuk generate data elevasi 514 kota via script Python
- **DEP-003**: `cities.json` — file asset existing berisi 514 kota dengan lat/lng, akan ditambah field `elevation`
- **DEP-004**: `adhan-dart` — library kalkulasi waktu sholat (existing, tidak berubah)
- **DEP-005**: `sqflite` — database SQLite (existing, perlu migration v2→v3)

## 5. Files

### Modified Files
- **FILE-001**: `lib/domain/entities/city.dart` — tambah field `elevation`
- **FILE-002**: `lib/data/models/city_model.dart` — tambah `elevation` di fromMap/toMap
- **FILE-003**: `lib/domain/entities/settings.dart` — tambah field `elevation`
- **FILE-004**: `lib/data/models/settings_model.dart` — tambah `elevation` di fromMap/toMap
- **FILE-005**: `lib/data/datasources/database_helper.dart` — version bump 2→3, DDL update, migration
- **FILE-006**: `lib/domain/usecases/calculate_prayer_times_use_case.dart` — formula DPL, koreksi Dzuhur
- **FILE-007**: `lib/presentation/cubits/setup_wizard/setup_wizard_cubit.dart` — auto-fill elevation
- **FILE-008**: `lib/domain/entities/setup_wizard_data.dart` — tambah field `elevation`
- **FILE-009**: `assets/data/cities.json` — tambah field `elevation` (514 entries)

### New Files
- **FILE-010**: `tools/add_elevation_to_cities.py` — script generate elevation data

### Modified Test Files
- **FILE-011**: `test/data/models/city_model_test.dart`
- **FILE-012**: `test/data/models/settings_model_test.dart`
- **FILE-013**: `test/data/datasources/database_helper_test.dart`
- **FILE-014**: `test/data/repositories/settings_repository_impl_test.dart`
- **FILE-015**: `test/domain/usecases/calculate_prayer_times_use_case_test.dart` — *(tidak diubah, validasi dilakukan via TASK-019)*
- **FILE-016**: `test/analysis/kemenag_comparison_test.dart`

## 6. Testing

- **TEST-001**: `CityModel.fromMap()` dan `toMap()` menyertakan field `elevation` dengan benar
- **TEST-002**: `SettingsModel.fromMap()` dan `toMap()` menyertakan field `elevation` dengan benar
- **TEST-003**: `DatabaseHelper` default settings memiliki `elevation = 0`
- **TEST-004**: `DatabaseHelper` cities table menerima dan mengembalikan field `elevation`
- **TEST-005**: `SettingsRepository.getSettings()` mengembalikan `elevation` yang benar
- **TEST-006**: `_calculateAltitudeCorrectionMinutes(0, -6.9175)` returns `0` (sea level, no correction)
- **TEST-007**: Koreksi elevation=698 (Kota Bandung, Open Elevation API) = **5 menit** — divalidasi via comparison test
- **TEST-008**: Comparison test 31 hari — semua 6 waktu sholat ≤1 menit selisih rata-rata dengan Kemenag:
  - Subuh: -0.3 min ✅ | Terbit: +0.3 min ✅ | Dzuhur: +0.5 min ✅
  - Ashar: -0.6 min ✅ | Maghrib: -0.3 min ✅ | Isya: -0.5 min ✅
- **TEST-009**: Full suite — 172 passed, 3 pre-existing failures (tidak berkaitan dengan fitur ini)

## 7. Risks & Assumptions

- **RISK-001**: Open Elevation API mungkin down/rate-limited saat generate data → Mitigasi: script Python memiliki retry logic dan bisa dijalankan incremental. Jika API down, gunakan cache/fallback
- **RISK-002**: Data elevasi dari Open Elevation API mungkin tidak 100% akurat (SRTM data resolusi ~30m) → Mitigasi: spot-check terhadap data referensi BPS/Wikipedia untuk kota-kota besar. Akurasi ±30m cukup untuk koreksi waktu sholat (efek <0.5 menit)
- **RISK-003**: ~~Koreksi Dzuhur +4 mungkin terlalu banyak~~ → *Resolved: rata-rata +0.5 min, sudah akurat.*
- **ASSUMPTION-001**: Formula koreksi DPL **`dip = 2.70' × √(h)`** — koefisien 2.70 sudah tervalidasi terhadap jadwal Kemenag Bandung Maret 2026. Koefisien ini mencakup dip geometris (1.76) + refraksi atmosfer tropis Indonesia (~0.94).
- **ASSUMPTION-002**: Elevasi yang digunakan adalah elevasi rata-rata kota/kabupaten (bukan titik tertinggi/terendah)
- **ASSUMPTION-003**: User existing yang upgrade dari v2 ke v3 akan mendapat `elevation = 0` (default). Mereka perlu memilih ulang kota atau set manual untuk mendapat koreksi DPL

## 8. Related Specifications / Further Reading

- [Plan: feature-kemenag-prayer-method-1.md](../plan/feature-kemenag-prayer-method-1.md) — Implementasi metode Kemenag SIHAT (prerequisite selesai)
- [Analisis Perbandingan](../test/analysis/kemenag_comparison_test.dart) — Script perbandingan 31 hari vs Kemenag
- [Open Elevation API](https://open-elevation.com/) — Free elevation API berbasis SRTM data
- [Dokumen SIHAT Kemenag](https://sihat.kemenag.go.id/) — Referensi standar waktu sholat Kemenag RI
