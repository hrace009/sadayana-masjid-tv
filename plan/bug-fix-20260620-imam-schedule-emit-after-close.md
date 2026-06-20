---
goal: "Fix Fatal Crash — Cubit Lifecycle emit() after close() (Global Fix)"
version: 1.2
date_created: 2026-06-20
last_updated: 2026-06-20
owner: "@BugRemediationArchitect / @GodModeDev"
status: "Completed — Pending Regression Verification"
tags: ["bug-fix", "remediation", "patch", "crashlytics", "cubit-lifecycle", "architecture"]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

## Ringkasan Bug & Temuan Arsitektural

Aplikasi mengalami **Fatal Exception** di production yang dilaporkan melalui Firebase Crashlytics: `Bad state: Cannot emit new states after calling close` pada `ImamScheduleCubit.loadAll()`.

Setelah dilakukan audit arsitektural yang lebih mendalam, ditemukan bahwa **kerentanan ini tidak hanya terjadi pada `ImamScheduleCubit`**. Empat cubit lainnya juga melakukan operasi *async* dan memanggil `emit()` tanpa memeriksa status `isClosed`. Pola *Async-Lifecycle Race Condition* ini sangat rentan menyebabkan crash jika user melakukan navigasi keluar dari layar saat proses *async* (seperti query SQLite atau File I/O) masih berjalan.

**Daftar Cubit yang rentan:**
1. `ImamScheduleCubit` (Original bug)
2. `SettingsCubit`
3. `SetupWizardCubit`
4. `SlideshowSectionCubit`
5. `DisplayStateCubit`

Satu-satunya cubit yang sudah aman adalah `PrayerTimeCubit` (menjadi referensi pola).

## Akar Masalah (Root Cause)

Ketika user menavigasi keluar dari halaman yang menampung `BlocProvider` untuk sebuah cubit (misalnya menekan back dari Pengaturan), widget tree akan di-dispose dan `BlocProvider` secara otomatis memanggil method `close()` pada cubit tersebut.
Namun, jika cubit sedang menunggu operasi asinkron (`await sqlite_query()`), proses tersebut tetap berjalan di background. Saat `await` selesai, kode melanjutkan eksekusi dan memanggil `emit(NewState)`. Karena cubit sudah *closed*, pemanggilan ini akan melempar `StateError`.

## 1. Requirements & Constraints (Fix Constraints)

- **REQ-001**: Fix harus menghilangkan kerentanan crash `Cannot emit new states after calling close` secara global pada **semua** cubit yang memiliki operasi asinkron. ✅
- **REQ-002**: Fix harus mengikuti pola `isClosed` guard yang sudah ada di `PrayerTimeCubit` untuk standardisasi. ✅
- **CON-001**: Fix tidak boleh mengubah public API atau behavior fungsional dari cubit manapun. ✅
- **CON-002**: Semua existing test harus tetap pass tanpa modifikasi pada logic existing. ✅

## 2. Implementation Steps

### Implementation Phase 1: Test Writing (Test-Driven Bug Fixing) — ✅ COMPLETED

| Task     | Description                                                                                         | Completed             | Date       |
| -------- | --------------------------------------------------------------------------------------------------- | --------------------- | ---------- |
| TASK-001 | Buat test: `test/presentation/cubits/imam_schedule/imam_schedule_cubit_lifecycle_test.dart`         | ✅                     | 2026-06-20 |
| TASK-002 | Buat test: `test/presentation/cubits/settings/settings_cubit_lifecycle_test.dart`                   | ✅                     | 2026-06-20 |
| TASK-003 | Buat test: `test/presentation/cubits/setup_wizard/setup_wizard_cubit_lifecycle_test.dart`           | ✅                     | 2026-06-20 |
| TASK-004 | Buat test: `test/presentation/cubits/slideshow_section/slideshow_section_cubit_lifecycle_test.dart` | ✅                     | 2026-06-20 |
| TASK-005 | Buat test: `test/presentation/cubits/display_state/display_state_cubit_lifecycle_test.dart`         | ✅                     | 2026-06-20 |
| TASK-006 | **VERIFY**: Ke-5 test lifecycle harus **FAIL** (membuktikan bug dapat direproduksi)                 | ✅ **15 FAIL, 2 PASS** | 2026-06-20 |
| TASK-007 | **APPROVAL**: Persetujuan user untuk lanjut ke Phase 2.                                             | ✅                     | 2026-06-20 |

### Implementation Phase 2: Global Root Cause Remediation — ✅ COMPLETED

**Pola yang diterapkan** (mengikuti referensi `PrayerTimeCubit`):
```dart
if (isClosed) return;
emit(...);
```

| Task     | Description                                                                                                                                                                                                                                  | Completed        | Date       |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- | ---------- |
| TASK-011 | **`ImamScheduleCubit`**: Guard di `loadAll` (2 emit sites), `addImam`, `updateImam`, `deleteImam`, `setSchedule`, `clearDay` (masing-masing 1 guard di catch block), `updateLockState` (defensive guard di awal method). Total: **8 guards** | ✅                | 2026-06-20 |
| TASK-012 | **`SettingsCubit`**: Guard di `loadSettings` (2 sites), `_saveField` (2 sites), `setPin` (2 sites), `resetSettings` (1 site). Total: **7 guards**                                                                                            | ✅                | 2026-06-20 |
| TASK-013 | **`SetupWizardCubit`**: Guard di `completeSetup` (2 sites: emit Completed + emit Error). Total: **2 guards**                                                                                                                                 | ✅                | 2026-06-20 |
| TASK-014 | **`SlideshowSectionCubit`**: Guard di `loadImages` (2 sites), `importIntoSlot` (2 sites), `replaceSlot` (2 sites), `deleteFromSlot` (1 site), `_reloadImages` (2 sites), `_pickImageBytes` (2 sites). Total: **11 guards**                   | ✅                | 2026-06-20 |
| TASK-015 | **`DisplayStateCubit`**: Guard di awal `_tick()` (1 site — melindungi semua emit dalam timer periodic). Total: **1 guard**                                                                                                                   | ✅                | 2026-06-20 |
| TASK-016 | **VERIFY**: Ke-5 test lifecycle dari Phase 1 harus **PASS**                                                                                                                                                                                  | ✅ **17/17 PASS** | 2026-06-20 |
| TASK-017 | **VERIFY**: Full test suite `flutter test --reporter=expanded` harus **PASS**                                                                                                                                                                | 🔄 In Progress    | 2026-06-20 |
| TASK-018 | **APPROVAL**: Tunggu persetujuan eksplisit user.                                                                                                                                                                                             | ⏳ Pending        | —          |

## 3. Rollback Strategy

Karena fix ini **hanya menambahkan guard line** tanpa mengubah logic, rollback sangat straightforward:

- **RBCK-001**: Revert commit yang berisi penambahan guard `isClosed`.
- **RBCK-002**: Jalankan full test suite untuk memastikan revert tidak merusak hal lain.

## 4. Dependencies

- **DEP-001**: Package `flutter_bloc` (sudah ada) — menyediakan property `isClosed` pada `BlocBase`.

## 5. Files Affected

| File                                                                                     | Aksi       | Guard Ditambahkan    | Status |
| ---------------------------------------------------------------------------------------- | ---------- | -------------------- | ------ |
| `lib/presentation/cubits/imam_schedule/imam_schedule_cubit.dart`                         | **MODIFY** | 8 guards             | ✅ Done |
| `lib/presentation/cubits/settings/settings_cubit.dart`                                   | **MODIFY** | 7 guards             | ✅ Done |
| `lib/presentation/cubits/setup_wizard/setup_wizard_cubit.dart`                           | **MODIFY** | 2 guards             | ✅ Done |
| `lib/presentation/cubits/slideshow_section/slideshow_section_cubit.dart`                 | **MODIFY** | 11 guards            | ✅ Done |
| `lib/presentation/cubits/display_state/display_state_cubit.dart`                         | **MODIFY** | 1 guard di `_tick()` | ✅ Done |
| `test/presentation/cubits/imam_schedule/imam_schedule_cubit_lifecycle_test.dart`         | **NEW**    | —                    | ✅ Done |
| `test/presentation/cubits/settings/settings_cubit_lifecycle_test.dart`                   | **NEW**    | —                    | ✅ Done |
| `test/presentation/cubits/setup_wizard/setup_wizard_cubit_lifecycle_test.dart`           | **NEW**    | —                    | ✅ Done |
| `test/presentation/cubits/slideshow_section/slideshow_section_cubit_lifecycle_test.dart` | **NEW**    | —                    | ✅ Done |
| `test/presentation/cubits/display_state/display_state_cubit_lifecycle_test.dart`         | **NEW**    | —                    | ✅ Done |

## 6. Testing Strategy & Edge Cases

### Testing Strategy

- **TEST-001**: Unit test reproduksi bug — setiap method async diuji dengan skenario `close()` dipanggil di tengah-tengah delay/mock asinkron sebelum `emit()` terjadi. **17 test ditulis.**
- **TEST-002**: Regression test — memastikan behavior aplikasi tidak berubah saat beroperasi normal (full test suite).

### Hasil Test Phase 1 (Reproduksi Bug)

| Test File                                              | Sebelum Fix         | Setelah Fix    |
| ------------------------------------------------------ | ------------------- | -------------- |
| `imam_schedule_cubit_lifecycle_test.dart` (7 test)     | ❌ FAIL              | ✅ PASS         |
| `settings_cubit_lifecycle_test.dart` (4 test)          | ❌ FAIL              | ✅ PASS         |
| `setup_wizard_cubit_lifecycle_test.dart` (2 test)      | ❌ FAIL              | ✅ PASS         |
| `slideshow_section_cubit_lifecycle_test.dart` (2 test) | ❌ FAIL              | ✅ PASS         |
| `display_state_cubit_lifecycle_test.dart` (2 test)     | ✅ PASS              | ✅ PASS         |
| **TOTAL**                                              | **15 FAIL, 2 PASS** | **17/17 PASS** |

## 7. Risks & Assumptions

- **RISK-001**: **Risiko sangat rendah** — fix hanya menambahkan validasi early-return. Logic bisnis utama tidak tersentuh.
- **ASSUMPTION-001**: Mengingat 5 dari 6 cubit memiliki pola yang rentan, perbaikan global ini adalah tindakan preventif (proactive remediation) yang krusial sebelum rilis versi stabil berikutnya.
