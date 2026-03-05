---
goal: "Implementasi penanganan khusus Sholat Jum'at — label, durasi layar mati, dan durasi iqomah yang berbeda dari Dzuhur hari biasa"
version: "1.0"
date_created: 2026-03-02
last_updated: 2026-03-03
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, prayer-time, state-machine, database-migration, settings-ui]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Sholat Jum'at adalah ibadah wajib pengganti Dzuhur yang dilaksanakan setiap hari Jumat. Durasi totalnya jauh lebih panjang dari Dzuhur biasa karena mencakup **khutbah Jum'at** (±25–30 menit) yang berlangsung sebelum sholat (2 rakaat, ±10 menit). Dengan durasi layar mati (`sholatDurationMinutes`) yang sama untuk semua hari (default 15 menit), layar TV akan menyala kembali di tengah berlangsungnya khutbah atau sholat Jum'at — situasi yang tidak diinginkan.

Plan ini mengimplementasikan:

1. **Label dinamis**: Waktu Dzuhur berganti nama menjadi `"Jum'at"` setiap hari Jumat.
2. **Durasi layar mati khusus**: `sholatJumatDurationMinutes` (default 45 menit) menggantikan `sholatDurationMinutes` saat label aktif adalah `"Jum'at"`.
3. **Durasi iqomah khusus Jum'at**: `iqomahJumat` (default 10 menit) — terpisah dari `iqomahDzuhur` karena iqomah Jum'at terjadi setelah khutbah selesai.
4. **Database migration**: Bump schema version ke 5 dengan `ALTER TABLE` untuk dua kolom baru.
5. **Settings UI**: Dua DPadStepper baru agar admin masjid bisa mengkonfigurasi nilai-nilai ini.

---

## 1. Requirements & Constraints

- **REQ-001**: Setiap hari Jumat, waktu Dzuhur harus ditampilkan dengan label `"Jum'at"` (bukan `"Dzuhur"`) pada seluruh tampilan UI (kartu sholat, state adzan, state iqomah, state sholat).
- **REQ-002**: State `SHOLAT` saat hari Jumat harus menggunakan `sholatJumatDurationMinutes` (default 45 menit) bukan `sholatDurationMinutes`.
- **REQ-003**: State `IQOMAH` saat hari Jumat harus menggunakan `iqomahJumat` (default 10 menit) bukan `iqomahDzuhur`.
- **REQ-004**: Durasi adzan Jum'at menggunakan `adzanDurationSeconds` yang sama dengan sholat lainnya.
- **REQ-005**: Perubahan label (`"Jum'at"`) harus dideteksi hanya di satu titik tunggal (Use Case layer) agar tidak ada duplikasi logika.
- **REQ-006**: Admin masjid dapat mengonfigurasi `sholatJumatDurationMinutes` (range 10–90 menit) dan `iqomahJumat` (range 1–30 menit) melalui Settings UI.
- **REQ-007**: Perubahan tidak boleh merusak behavior Dzuhur di hari Senin–Kamis dan Sabtu–Minggu.
- **SEC-001**: Tidak ada network call — semua data disimpan di SQLite lokal (offline-first).
- **CON-001**: Database schema harus di-migrate dari versi 4 ke versi 5 tanpa data loss menggunakan `ALTER TABLE`.
- **CON-002**: Field baru di `Settings` entity harus memiliki default value agar upgrade dari versi lama tidak crash.
- **CON-003**: Label `"Jum'at"` menggunakan apostrof sehingga harus menggunakan double-quote sebagai string delimiter di Dart (`"Jum'at"`).
- **GUD-001**: Deteksi hari Jumat dilakukan via `DateTime.weekday == DateTime.friday` menggunakan local time (`DateTime.now()`) agar zona waktu (WIB/WITA/WIT) ditangani dengan benar.
- **GUD-002**: Seluruh perubahan di Production Layer tidak boleh mengubah interface public yang sudah ada — hanya menambah field/method baru.
- **PAT-001**: Ikuti pola existing `iqomahMinutes` map di `TransitionConfig` untuk menyimpan durasi sholat per nama — tambah `"Jum'at"` ke dalam map.
- **PAT-002**: Method `getSholatDurationFor(String prayerName)` di `TransitionConfig` mengikuti pola `getIqomahFor(String prayerName)` yang sudah ada.

---

## 2. Implementation Steps

### Implementation Phase 1 — Domain Layer (Inner Layer)

- **GOAL-001**: Tambahkan dua field baru ke `Settings` entity dan perbarui `TransitionConfig` untuk mengenal `"Jum'at"` sebagai waktu dengan durasi berbeda, serta update kedua Use Case.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | **`lib/domain/entities/settings.dart`** — Tambah dua field: `final int iqomahJumat` (default 10) dan `final int sholatJumatDurationMinutes` (default 45). Update `copyWith()` dengan kedua optional parameter baru. Update `props` list untuk include kedua field baru. | ✅ | 2026-03-02 |
| TASK-002 | **`lib/domain/entities/transition_config.dart`** — Tambah field `final int sholatJumatDurationMinutes`. Update `fromSettings()` untuk: (1) assign `sholatJumatDurationMinutes: settings.sholatJumatDurationMinutes`, (2) tambah entry `"Jum'at": settings.iqomahJumat` ke dalam map `iqomahMinutes`. Tambah method `int getSholatDurationFor(String prayerName)` — return `sholatJumatDurationMinutes` jika `prayerName == "Jum'at"`, otherwise return `sholatDurationMinutes`. Update `props` untuk include `sholatJumatDurationMinutes`. | ✅ | 2026-03-02 |
| TASK-003 | **`lib/domain/usecases/calculate_prayer_times_use_case.dart`** — Di method `execute()` dan `executeWithSettings()`: sebelum membuat `PrayerTime` Dzuhur, tambahkan deteksi `final isFriday = now.weekday == DateTime.friday`. Assign `final dzuhurLabel = isFriday ? "Jum'at" : 'Dzuhur'`. Gunakan `dzuhurLabel` sebagai parameter `name` di `_applyIhtiyat(dzuhurLabel, ...)`. Waktu sholat tetap dihitung dari `prayerTimes.dhuhr` (tidak ada perubahan kalkulasi waktunya). | ✅ | 2026-03-02 |
| TASK-004 | **`lib/domain/usecases/evaluate_display_state_use_case.dart`** — Di dalam loop evaluasi, ganti baris `Duration(minutes: config.sholatDurationMinutes)` menjadi `Duration(minutes: config.getSholatDurationFor(prayer.name))`. Update `totalSholatMinutes` di `SholatState` constructor menggunakan nilai yang sama: `config.getSholatDurationFor(prayer.name)`. | ✅ | 2026-03-02 |

### Implementation Phase 2 — Data Layer (Outer Layer)

- **GOAL-002**: Perbarui schema database (migration v4→v5) dan update `SettingsModel` untuk mapping dua kolom baru.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-005 | **`lib/data/datasources/database_helper.dart`** — Bump konstanta `_databaseVersion` dari `4` ke `5`. Di method `_createTables()`, tambahkan dua kolom baru di DDL CREATE TABLE settings (setelah kolom `iqomah_isya`): `iqomah_jumat INTEGER NOT NULL DEFAULT 10` dan `sholat_jumat_duration_minutes INTEGER NOT NULL DEFAULT 45`. Di method `_onUpgrade()`, tambahkan block baru `if (oldVersion < 5)` yang menjalankan dua `ALTER TABLE`: `ALTER TABLE settings ADD COLUMN iqomah_jumat INTEGER NOT NULL DEFAULT 10` dan `ALTER TABLE settings ADD COLUMN sholat_jumat_duration_minutes INTEGER NOT NULL DEFAULT 45`. | ✅ | 2026-03-03 |
| TASK-006 | **`lib/data/models/settings_model.dart`** — Update constructor: tambah `super.iqomahJumat` dan `super.sholatJumatDurationMinutes` ke named parameters. Update `SettingsModel.fromMap()`: tambah `iqomahJumat: map['iqomah_jumat'] as int` dan `sholatJumatDurationMinutes: map['sholat_jumat_duration_minutes'] as int`. Update `toMap()`: tambah `'iqomah_jumat': iqomahJumat` dan `'sholat_jumat_duration_minutes': sholatJumatDurationMinutes`. | ✅ | 2026-03-03 |

### Implementation Phase 3 — Presentation Layer

- **GOAL-003**: Tambah method update baru di `SettingsCubit` dan dua `DPadStepper` baru pada Settings UI.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | **`lib/presentation/cubits/settings/settings_cubit.dart`** — Tambah method baru `void updateSholatJumatDuration(int minutes)`: validasi `minutes < 10 \|\| minutes > 90` → return early. Panggil `_debounceSave('sholat_jumat_duration', {'sholat_jumat_duration_minutes': minutes}, triggerConfigUpdate: true)`. | ✅ | 2026-03-03 |
| TASK-008 | **`lib/presentation/pages/settings/sections/display_timing_section.dart`** — Setelah `DPadStepper` "Durasi Layar Hitam (Saat Sholat)" yang sudah ada, tambahkan: `SizedBox(height: 16.h)` dan `DPadStepper` baru dengan label `"Durasi Layar Hitam Jum'at (Khutbah + Sholat)"`, value: `settings.sholatJumatDurationMinutes`, minValue: 10, maxValue: 90, step: 5, suffix: `'menit'`, onChanged: `(val) => cubit.updateSholatJumatDuration(val)`. | ✅ | 2026-03-03 |
| TASK-009 | **`lib/presentation/pages/settings/sections/iqomah_section.dart`** — Tambah `DPadStepper` baru di antara "Dzuhur" dan "Ashar" dengan memanggil `_buildStepper("Jum'at", settings.iqomahJumat, cubit)`. Tambahkan `SizedBox(height: 16.h)` separator sebelum dan sesudahnya sesuai pola existing. Catatan: method `_buildStepper` yang ada sudah memanggil `cubit.updateIqomahDuration(prayerName.toLowerCase(), val)` — ini akan memanggil `updateIqomahDuration("jum'at", val)`. Pastikan `updateIqomahDuration` di cubit memetakan nama ke field `iqomah_jumat`. | ✅ | 2026-03-03 |
| TASK-010 | **`lib/presentation/cubits/settings/settings_cubit.dart`** — Review method `updateIqomahDuration(String prayerName, int minutes)` yang sudah ada. Method ini saat ini menggunakan `final field = 'iqomah_${prayerName.toLowerCase()}'` — ini akan menghasilkan `iqomah_jum'at` yang tidak valid sebagai SQL column name. Tambahkan mapping khusus: jika `prayerName.toLowerCase() == "jum'at"`, gunakan field key `'iqomah_jumat'`. | ✅ | 2026-03-03 |}

### Implementation Phase 4 — Testing

- **GOAL-004**: Tambah unit tests untuk semua skenario baru hari Jumat dan validasi migration database.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-011 | **`test/domain/usecases/calculate_prayer_times_use_case_test.dart`** — Tambah 2 test case: (1) `"harus memberi label Jum'at untuk waktu Dzuhur pada hari Jumat"` — mock `DateTime` hari Jumat, verify `dailyPrayerTimes.dzuhur.name == "Jum'at"`. (2) `"harus tetap memberi label Dzuhur pada hari selain Jumat"` — mock `DateTime` hari Senin, verify `dailyPrayerTimes.dzuhur.name == 'Dzuhur'`. | ✅ | 2026-03-03 |
| TASK-012 | **`test/domain/usecases/evaluate_display_state_use_case_test.dart`** — Tambah 2 test case: (1) `"harus menggunakan sholatJumatDurationMinutes saat prayer adalah Jum'at"` — buat `TransitionConfig` dengan `sholatJumatDurationMinutes: 45`, buat `PrayerTime` dengan `name: "Jum'at"`, evaluasi state, verify `SholatState.totalSholatMinutes == 45`. (2) `"harus menggunakan iqomahJumat saat prayer adalah Jum'at"` — buat config dengan `iqomahMinutes: {"Jum'at": 10}`, verify `IqomahState.totalIqomahMinutes == 10`. | ✅ | 2026-03-03 |
| TASK-013 | **`test/data/models/settings_model_test.dart`** — Update test `fromMap` bestaan: pastikan map input menyertakan `iqomah_jumat: 10` dan `sholat_jumat_duration_minutes: 45`. Tambah assertion: `expect(model.iqomahJumat, 10)` dan `expect(model.sholatJumatDurationMinutes, 45)`. Update test `toMap` dan round-trip untuk memvalidasi field baru. | ✅ | 2026-03-03 |
| TASK-014 | **`test/data/datasources/database_helper_test.dart`** — Tambah 1 test case (TEST-007): `"migration v4→v5 menambah kolom iqomah_jumat dan sholat_jumat_duration_minutes dengan default values yang benar"` — buat database v4 secara manual via DDL tanpa dua kolom baru, insert row `{id: 1}`, lalu jalankan kedua `ALTER TABLE` yang identik dengan blok `_onUpgrade oldVersion < 5` (method private sehingga disimulasikan langsung), query settings, verify `iqomah_jumat == 10` dan `sholat_jumat_duration_minutes == 45`. | ✅ | 2026-03-03 |
| TASK-015 | **`test/presentation/cubits/settings/settings_cubit_test.dart`** — Tambah 3 test case dalam group `"Sholat Jum'at"`: (1) `"updateSholatJumatDuration menyimpan field dengan nilai valid (45 menit)"` — verify debounce save dipanggil dengan `{'sholat_jumat_duration_minutes': 45}` dan `displayStateCubit.onSettingsChanged()` dipanggil. (2) `"updateSholatJumatDuration diabaikan jika nilai di luar range [10, 90]"` — call dengan nilai 5 dan 95, verify `updateSettings` tidak pernah dipanggil. (3) `"updateIqomahDuration dengan nama Jum'at menggunakan DB key 'iqomah_jumat'"` — verify `updateSettings({'iqomah_jumat': 10})` dipanggil dan `updateSettings({"iqomah_jum'at": 10})` tidak pernah dipanggil (menutup TEST-008/RISK-001). | ✅ | 2026-03-03 |

---

## 3. Alternatives

- **ALT-001**: **Per-sholat duration map** — Ubah `sholatDurationMinutes` dari `int` tunggal menjadi `Map<String, int>` lengkap (mirip pola `iqomahMinutes`). Ditolak karena merupakan breaking change besar yang memerlukan perubahan schema, model, dan UI yang jauh lebih luas, padahal hanya satu kasus khusus (Jum'at) yang membutuhkan durasi berbeda.
- **ALT-002**: **Deteksi hari Jumat di UI layer (widget)** — Cek `DateTime.now().weekday` di dalam widget untuk menampilkan label berbeda. Ditolak karena melanggar Clean Architecture — business logic tidak boleh berada di Presentation layer.
- **ALT-003**: **Field toggle boolean `enableJumatMode`** — Opsi boolean on/off tanpa field durasi khusus. Ditolak karena tidak fleksibel; setiap masjid memiliki durasi khutbah yang berbeda-beda.

---

## 4. Dependencies

- **DEP-001**: `sqflite` (sudah ada) — untuk `ALTER TABLE` migration v4→v5.
- **DEP-002**: `flutter_bloc` (sudah ada) — untuk `SettingsCubit` method baru.
- **DEP-003**: `equatable` (sudah ada) — untuk update `props` di `Settings` entity dan `TransitionConfig`.

Tidak ada dependency baru yang perlu ditambahkan.

---

## 5. Files

File Production yang Dimodifikasi:

- **FILE-001**: `lib/domain/entities/settings.dart` — +2 field, update `copyWith()`, update `props`.
- **FILE-002**: `lib/domain/entities/transition_config.dart` — +1 field, update `fromSettings()`, +1 method `getSholatDurationFor()`, update `props`.
- **FILE-003**: `lib/domain/usecases/calculate_prayer_times_use_case.dart` — Deteksi Jumat di `execute()` dan `executeWithSettings()`.
- **FILE-004**: `lib/domain/usecases/evaluate_display_state_use_case.dart` — Ganti `config.sholatDurationMinutes` → `config.getSholatDurationFor(prayer.name)`.
- **FILE-005**: `lib/data/datasources/database_helper.dart` — Bump `_databaseVersion` ke 5, update DDL, tambah migration block.
- **FILE-006**: `lib/data/models/settings_model.dart` — Update constructor, `fromMap()`, `toMap()`.
- **FILE-007**: `lib/presentation/cubits/settings/settings_cubit.dart` — +1 method `updateSholatJumatDuration()`, fix `updateIqomahDuration()` untuk key `"jum'at"`.
- **FILE-008**: `lib/presentation/pages/settings/sections/display_timing_section.dart` — +1 `DPadStepper` untuk `sholatJumatDurationMinutes`.
- **FILE-009**: `lib/presentation/pages/settings/sections/iqomah_section.dart` — +1 `DPadStepper` untuk `iqomahJumat`.

File Test yang Dimodifikasi:

- **FILE-010**: `test/domain/usecases/calculate_prayer_times_use_case_test.dart` — +2 test case.
- **FILE-011**: `test/domain/usecases/evaluate_display_state_use_case_test.dart` — +2 test case.
- **FILE-012**: `test/data/models/settings_model_test.dart` — Update existing + tambah assertion baru.
- **FILE-013**: `test/data/datasources/database_helper_test.dart` — +1 test case migration.
- **FILE-014**: `test/presentation/cubits/settings/settings_cubit_test.dart` — +3 test case dalam group `"Sholat Jum'at"` (menutup TEST-007 dan TEST-008).

---

## 6. Testing

- **TEST-001**: Label Dzuhur berubah menjadi `"Jum'at"` pada hari Jumat dan kembali `"Dzuhur"` pada hari lain — di `CalculatePrayerTimesUseCase`.
- **TEST-002**: `EvaluateDisplayStateUseCase` menghasilkan `SholatState` dengan `totalSholatMinutes == 45` saat `prayer.name == "Jum'at"`.
- **TEST-003**: `EvaluateDisplayStateUseCase` menghasilkan `IqomahState` dengan `totalIqomahMinutes == iqomahJumat` saat `prayer.name == "Jum'at"`.
- **TEST-004**: `SettingsModel.fromMap()` berhasil membaca `iqomah_jumat` dan `sholat_jumat_duration_minutes` dari map.
- **TEST-005**: `SettingsModel.toMap()` menghasilkan map yang menyertakan `iqomah_jumat` dan `sholat_jumat_duration_minutes`.
- **TEST-006**: Database migration dari v4 ke v5 berhasil menambah kedua kolom dengan nilai default yang benar.
- **TEST-007**: `updateSholatJumatDuration()` di `SettingsCubit` menyimpan dengan benar dan memvalidasi range.
- **TEST-008**: `updateIqomahDuration("jum'at", val)` menggunakan field key `iqomah_jumat` (bukan `iqomah_jum'at`).

---

## 7. Risks & Assumptions

- **RISK-001**: **SQL column name dengan apostrof** — `updateIqomahDuration` yang existing menggunakan interpolasi `'iqomah_${prayerName.toLowerCase()}'`, yang akan menghasilkan `iqomah_jum'at` — nama kolom SQLite yang invalid. **Mitigasi**: TASK-010 wajib diselesaikan bersamaan dengan TASK-009 untuk mencegah runtime error.
- **RISK-002**: **User yang sudah install versi sebelumnya** — Database mereka belum punya kolom baru. **Mitigasi**: Migration `ALTER TABLE` di `_onUpgrade` blok `oldVersion < 5` memastikan kolom ditambah dengan nilai default saat upgrade.
- **RISK-003**: **`mainPrayers` getter di `DailyPrayerTimes`** — Getter ini return list berdasarkan posisi (`[subuh, dzuhur, ashar, maghrib, isya]`), bukan berdasarkan nama. Label `"Jum'at"` hanya mengubah `PrayerTime.name`, bukan posisi dalam list. Tidak ada risiko breaking karena evaluasi state menggunakan `prayer.name` dari iterasi.
- **ASSUMPTION-001**: `DateTime.friday` di Dart bernilai `5` (Senin=1, Selasa=2, ..., Jumat=5, Sabtu=6, Minggu=7). `DateTime.now().weekday == DateTime.friday` memberikan hasil yang benar berdasarkan timezone lokal perangkat.
- **ASSUMPTION-002**: Durasi default 45 menit untuk `sholatJumatDurationMinutes` dianggap cukup mencakup kebutuhan mayoritas masjid di Indonesia (khutbah singkat s/d panjang). Admin dapat menyesuaikan via Settings UI.
- **ASSUMPTION-003**: Iqomah Jum'at default 10 menit dianggap cukup untuk jeda antara selesai khutbah dan dimulainya sholat.

---

## 8. Related Specifications / Further Reading

- [spec/spec-process-state-machine.md](../spec/spec-process-state-machine.md) — State machine 5-state; REQ-006 dan timeline state transitions
- [spec/spec-schema-database.md](../spec/spec-schema-database.md) — Schema table `settings` dan migration pattern
- [spec/spec-process-prayer-time.md](../spec/spec-process-prayer-time.md) — Spesifikasi kalkulasi waktu sholat dan Ihtiyat
- [plan/feature-state-evaluation-1.md](feature-state-evaluation-1.md) — Riwayat implementasi `EvaluateDisplayStateUseCase` dan `TransitionConfig`
- [plan/feature-settings-logic-1.md](feature-settings-logic-1.md) — Riwayat implementasi `SettingsCubit` dan metode update yang ada
- [plan/feature-settings-ui-1.md](feature-settings-ui-1.md) — Riwayat implementasi Settings UI sections termasuk `IqomahSection` dan `DisplayTimingSection`
- [AGENTS.md](../AGENTS.md) — Common pitfalls: Timer Memory Leaks, SQLite Transaction Safety
