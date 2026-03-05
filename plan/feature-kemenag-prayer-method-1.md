---
goal: "Implementasi Metode Kalkulasi Kemenag (SIHAT) — Custom CalculationParameters, Ihtiyat Bawaan, Fix Inkonsistensi Default"
version: 1.0
date_created: 2026-02-28
last_updated: 2026-02-28
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, prayer-time, kemenag, sihat, ihtiyat, calculation, bugfix]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Plan ini bertujuan untuk **mengganti metode kalkulasi waktu sholat default** dari `CalculationMethod.singapore` (MUIS) menjadi **custom Kemenag (SIHAT)** agar waktu sholat yang ditampilkan sesuai dengan standar Kementerian Agama RI.

**Latar belakang**: Saat ini waktu sholat yang ditampilkan berbeda dengan Muslim Pro (metode SIHAT/Kemenag) dengan selisih 2-8 menit, terutama Maghrib (-8 menit). Ini terjadi karena:

1. **Tidak ada ihtiyat bawaan** — Kemenag menambahkan +2 menit pada setiap waktu sholat sebagai pengamanan
2. **Metode Singapore (MUIS) ≠ SIHAT** — Meskipun sudut Fajr/Isha sama (20°/18°), parameter ihtiyat berbeda
3. **Inkonsistensi default** — `SetupWizardData` default `'kemenag'` tapi `Settings` dan DDL default `'singapore'`, dan tidak ada handler `'kemenag'` di switch case

| Waktu | Aplikasi (Sekarang) | Muslim Pro (Kemenag) | Selisih |
|-------|:---:|:---:|:---:|
| Subuh | 04:36 | 04:39 | -3 min |
| Dzuhur | 12:03 | 12:06 | -3 min |
| Ashar | 15:06 | 15:08 | -2 min |
| Maghrib | 18:09 | 18:17 | **-8 min** |
| Isya | 19:19 | 19:22 | -3 min |

**Source Specification**: [spec-process-prayer-time.md](../spec/spec-process-prayer-time.md) (SPEC-03), Plan 05

## 1. Requirements & Constraints

### Parameter Standar Kemenag (SIHAT)

- **REQ-001**: Fajr angle = **20°** (sudut matahari di bawah horizon Timur untuk Subuh)
- **REQ-002**: Isha angle = **18°** (sudut matahari di bawah horizon Barat untuk Isya)
- **REQ-003**: Ihtiyat Subuh = **+2 menit** penambahan waktu setelah kalkulasi astronomis
- **REQ-004**: Ihtiyat Syuruq = **-2 menit** pengurangan waktu (agar sebelum matahari benar-benar terbit)
- **REQ-005**: Ihtiyat Dzuhur = **+2 menit** penambahan waktu setelah zawal
- **REQ-006**: Ihtiyat Ashar = **+2 menit** penambahan waktu
- **REQ-007**: Ihtiyat Maghrib = **+2 menit** penambahan waktu setelah sunset
- **REQ-008**: Ihtiyat Isya = **+2 menit** penambahan waktu
- **REQ-009**: Ihtiyat di-apply sebagai `methodAdjustments` (di level kalkulasi library), bukan di level offset user, sehingga offset user tetap bisa digunakan untuk koreksi tambahan secara **aditif** di atasnya
- **REQ-010**: Default `calculationMethod` di seluruh codebase harus konsisten: `'kemenag'`

### Constraints

- **CON-001**: Tidak boleh menghapus dukungan metode lain (Singapore, MWL, dll) — user tetap bisa memilih via Settings
- **CON-002**: Perubahan DDL default hanya berlaku untuk instalasi baru — database migration untuk user existing bersifat opsional
- **CON-003**: Library `adhan-dart` menggunakan `CalculationMethod.other` untuk custom method dan `adjustments` property dari `CalculationParameters` untuk ihtiyat
- **CON-004**: Ihtiyat Kemenag bersifat fixed (+2 menit), bukan configurable oleh user (berbeda dengan offset user)

### Guidelines & Patterns

- **GUD-001**: Clean Architecture — perubahan hanya di domain layer (use case) dan data layer (default values)
- **GUD-002**: Backward compatible — fungsionalitas existing tidak boleh rusak
- **PAT-001**: Follow existing switch-case pattern di `_getCalculationParameters()`

## 2. Implementation Steps

### Phase 1: Custom Kemenag Calculation Parameters

- GOAL-001: Menambahkan case `'kemenag'` di method `_getCalculationParameters()` dengan parameter SIHAT

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Tambahkan case `'kemenag'` di `_getCalculationParameters()` di file `lib/domain/usecases/calculate_prayer_times_use_case.dart`. Gunakan `CalculationMethod.other.getParameters()` sebagai base, set `fajrAngle = 20`, `ishaAngle = 18`, dan set `adjustments` dengan ihtiyat standar Kemenag (Subuh +2, Sunrise -2, Dhuhr +2, Asr +2, Maghrib +2, Isha +2) | | |
| TASK-002 | Ubah default case (fallback) di switch dari `CalculationMethod.singapore` menjadi memanggil case `'kemenag'` agar unknown method string jatuh ke standar Kemenag | | |
| TASK-003 | Update komentar dokumentasi di method `_getCalculationParameters()` untuk menjelaskan parameter SIHAT/Kemenag | | |

### Phase 2: Fix Inkonsistensi Default Values

- GOAL-002: Menyelaraskan default `calculationMethod` di seluruh codebase dari `'singapore'` menjadi `'kemenag'`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-004 | Ubah default `calculationMethod` di `lib/domain/entities/settings.dart` (baris 69) dari `'singapore'` menjadi `'kemenag'` | | |
| TASK-005 | Ubah default SQL DDL di `lib/data/datasources/database_helper.dart` (baris 134) dari `DEFAULT 'singapore'` menjadi `DEFAULT 'kemenag'` | | |

### Phase 3: Update Unit Tests

- GOAL-003: Memperbarui semua assertion yang mengandalkan default `'singapore'` dan menambah test baru untuk metode Kemenag

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-006 | Update `test/domain/usecases/calculate_prayer_times_use_case_test.dart`: ubah `calculationMethod: 'singapore'` menjadi `'kemenag'` di existing test | | |
| TASK-007 | Tambah test baru di file yang sama: **Test Kemenag method** — verifikasi bahwa `'kemenag'` mengembalikan waktu yang sudah termasuk ihtiyat +2 menit bawaan (cek difference antara `time` dan `originalTime` = offset user + 2 menit ihtiyat) | | |
| TASK-008 | Tambah test baru: **Test Kemenag + user offset** — verifikasi bahwa ihtiyat bawaan Kemenag dan offset user bersifat **aditif** (misal: user offset +3, total = +3 user + 2 ihtiyat = +5 menit dari raw calculation) | | |
| TASK-009 | Tambah test baru: **Test fallback method** — verifikasi bahwa method string unknown (misal `'xyz'`) fallback ke parameter Kemenag | | |
| TASK-010 | Update `test/data/datasources/database_helper_test.dart`: ubah assertion `expect(row['calculation_method'], equals('singapore'))` menjadi `equals('kemenag')` | | |
| TASK-011 | Update `test/data/models/settings_model_test.dart`: ubah test data map dan assertion dari `'singapore'` menjadi `'kemenag'` | | |
| TASK-012 | Update `test/data/repositories/settings_repository_impl_test.dart`: ubah assertion default `calculationMethod` dari `'singapore'` menjadi `'kemenag'` | | |

### Phase 4: Verifikasi

- GOAL-004: Memastikan semua tests pass dan waktu sholat sesuai standar Kemenag

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-013 | Jalankan `flutter test --reporter=expanded` — semua test harus pass | | |
| TASK-014 | Manual: bandingkan output waktu sholat Bandung dengan Muslim Pro (SIHAT/Kemenag) — selisih ≤ 1 menit | | |

## 3. Alternatives

- **ALT-001**: Menggunakan offset user sebagai ihtiyat (ubah default offset +2) — **Ditolak** karena mencampurkan concern ihtiyat standar dengan koreksi user. Jika user mengubah offset, ihtiyat Kemenag hilang
- **ALT-002**: Tetap menggunakan `CalculationMethod.singapore` ditambah offset — **Ditolak** karena parameter internal Singapore dan Kemenag tidak 100% identik (terutama Maghrib), dan pendekatan ini tidak semantik
- **ALT-003**: Mengambil data dari API SIHAT Kemenag secara online — **Ditolak** karena melanggar prinsip offline-first dan memerlukan koneksi internet

## 4. Dependencies

- **DEP-001**: `adhan` (^2.0.0+1) — Library sudah ter-install, perlu API `CalculationMethod.other` dan `adjustments` property ✅
- **DEP-002**: Plan 05 (`feature-prayer-calculation-1.md`) — Prerequisite, sudah completed ✅
- **DEP-003**: Plan 02 (`feature-data-layer-1.md`) — Settings entity & repository, sudah completed ✅

## 5. Files

- **FILE-001**: `lib/domain/usecases/calculate_prayer_times_use_case.dart` — [MODIFY] Tambah case `'kemenag'` di `_getCalculationParameters()`, ubah default fallback
- **FILE-002**: `lib/domain/entities/settings.dart` — [MODIFY] Ubah default `calculationMethod` ke `'kemenag'`
- **FILE-003**: `lib/data/datasources/database_helper.dart` — [MODIFY] Ubah SQL DEFAULT ke `'kemenag'`
- **FILE-004**: `test/domain/usecases/calculate_prayer_times_use_case_test.dart` — [MODIFY] Update existing test + tambah 3 test baru
- **FILE-005**: `test/data/datasources/database_helper_test.dart` — [MODIFY] Update assertion default
- **FILE-006**: `test/data/models/settings_model_test.dart` — [MODIFY] Update test data + assertion
- **FILE-007**: `test/data/repositories/settings_repository_impl_test.dart` — [MODIFY] Update assertion default

## 6. Testing

- **TEST-001**: Existing test `execute returns valid DailyPrayerTimes` — update ke method `'kemenag'`
- **TEST-002**: [NEW] Test Kemenag method returns correct angles and built-in ihtiyat
- **TEST-003**: [NEW] Test Kemenag ihtiyat + user offset are additive
- **TEST-004**: [NEW] Test unknown method falls back to Kemenag
- **TEST-005**: Default `calculation_method` di database = `'kemenag'`
- **TEST-006**: Default `calculationMethod` di Settings model = `'kemenag'`
- **TEST-007**: Default `calculationMethod` di repository = `'kemenag'`

**Test Command**: `flutter test --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: Ihtiyat +2 menit mungkin belum cukup menutup selisih Maghrib (saat ini -8 menit). Library `adhan` mungkin menghitung sunset berbeda dari SIHAT — **Mitigasi**: Bandingkan hasil setelah implementasi. Jika masih ada selisih signifikan di Maghrib, pertimbangkan koreksi ketinggian tempat (DPL) sebagai enhancement terpisah
- **RISK-002**: `CalculationMethod.other.getParameters()` menggunakan default angle 0° — harus di-set eksplisit ke 20°/18° — **Mitigasi**: Test memvalidasi angle diterapkan
- **ASSUMPTION-001**: `adjustments` property dari `CalculationParameters` di library `adhan-dart` bersifat aditif terhadap kalkulasi astronomis dasar
- **ASSUMPTION-002**: Ihtiyat standar Kemenag adalah +2 menit untuk semua waktu sholat (kecuali Syuruq -2 menit)
- **ASSUMPTION-003**: Perubahan default DDL hanya perlu untuk instalasi baru — user existing cukup mengganti method via Settings secara manual

## 8. Related Specifications / Further Reading

- [SPEC-03: Prayer Time Calculation](../spec/spec-process-prayer-time.md) — Source specification
- [Plan 05: Prayer Calculation](../plan/feature-prayer-calculation-1.md) — Original prayer implementation
- [SIHAT Kemenag RI](https://bimasislam.kemenag.go.id/) — Referensi standar Kemenag
- [adhan-dart Documentation](https://pub.dev/packages/adhan) — Library API reference
- [Muslim Pro SIHAT Method](https://www.muslimpro.com/) — Referensi perbandingan
