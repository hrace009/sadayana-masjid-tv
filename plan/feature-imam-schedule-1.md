---
goal: "Implementasi Fitur Jadwal Imam Sholat Berjamaah"
version: "1.4"
date_created: "2026-05-17"
last_updated: "2026-05-25"
owner: "MKT Dev Team"
status: "Completed"
tags: [feature, state-machine, android-tv, settings, display, sqlite, migration]
---

# Introduction

<!-- markdownlint-disable  -->
![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Fitur **Jadwal Imam Sholat Berjamaah** menambahkan sebuah tampilan full-screen tambahan (State ke-9)
pada mesin tampilan utama (_display state machine_) aplikasi Miqotul Khoir TV. Secara periodik —
sesuai interval yang dikonfigurasi admin — layar standby digantikan sementara oleh jadwal imam sholat
untuk **hari ini saja**, yang mencakup 5 waktu sholat wajib (Subuh, Dzuhur, Ashar, Maghrib, Isya).

Khusus hari Jumat, slot Dzuhur diganti menjadi slot **"Jumat"** dengan pemisahan antara **Khatib** dan
**Imam**. Data imam bersumber dari tabel master `imams` (maks 10 imam) dan jadwal mingguan dari tabel
`imam_schedules` di SQLite lokal. Fitur ini **bukan overlay** di atas `StandbyLayout`, melainkan
`DisplayState` baru (`ImamScheduleState`) yang dikelola sepenuhnya oleh `EvaluateDisplayStateUseCase`
dan ditampilkan melalui `AnimatedSwitcher` yang sudah ada. Data jadwal hari ini di-cache oleh
`DisplayStateCubit`, direfresh setelah mutasi admin, dan diperbarui otomatis saat pergantian hari.

Prioritas display: `prayer` → `midnight` → `slideshow` (pengumuman) → `imam_schedule` → `wisdom` → `standby`.

## Sketsa Layout

### ImamScheduleLayout — Hari Biasa (Full-Screen)

```text
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  [JAM DIGITAL 00:00]        SENIN, 17 MEI 2026        [25 DZULQA'DAH 1447 H]        │  ← Header
├──────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│                        ┌──────────────────────────────────┐                          │
│                        │   🕌  JADWAL IMAM SHOLAT          │  ← Title                │
│                        │       Masjid Miqotul Khoir        │  ← Mosque Name          │
│                        └──────────────────────────────────┘                          │
│                                                                                      │
│                 ┌──────────────────────────────────────────────┐                     │
│                 │              ══ SENIN ══                     │                     │
│                 │                                              │                     │
│                 │   Subuh    │  Ust. Ahmad Fauzi               │                     │
│                 │   Dzuhur   │  Ust. Budi Santoso              │                     │
│                 │   Ashar    │  Ust. Ahmad Fauzi               │                     │
│                 │   Maghrib  │  Imam belum tersedia             │                     │
│                 │   Isya     │  Ust. Dani Kurniawan             │                     │
│                 │                                              │                     │
│                 └──────────────────────────────────────────────┘                     │
│                                                                                      │
├──────────────────────────────────────────────────────────────────────────────────────┤
│  ████████████████████░░░░░░░░░░  (progress bar)              Masjid Miqotul Khoir   │  ← Footer
└──────────────────────────────────────────────────────────────────────────────────────┘
```

### ImamScheduleLayout — Hari Jumat (Full-Screen)

```text
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  [JAM DIGITAL 00:00]        JUM'AT, 22 MEI 2026       [27 DZULQA'DAH 1447 H]        │
├──────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                      │
│                 ┌──────────────────────────────────────────────┐                     │
│                 │              ══ JUM'AT ══                    │                     │
│                 │                                              │                     │
│                 │   Subuh    │  Ust. Ahmad Fauzi               │                     │
│                 │   Jumat    │  Khatib: Ust. Ali Mahmud        │                     │
│                 │            │  Imam:   Ust. Budi Santoso      │                     │
│                 │   Ashar    │  Ust. Ahmad Fauzi               │                     │
│                 │   Maghrib  │  Ust. Dani Kurniawan            │                     │
│                 │   Isya     │  Khatib belum tersedia          │                     │
│                 │                                              │                     │
│                 └──────────────────────────────────────────────┘                     │
│                                                                                      │
├──────────────────────────────────────────────────────────────────────────────────────┤
│  ████████████████████░░░░░░░░░░  (progress bar)              Masjid Miqotul Khoir   │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

## 1. Requirements & Constraints

### Functional Requirements

- **REQ-001**: Mendukung maksimal 10 data imam yang dapat didaftarkan di tabel master `imams`.
- **REQ-002**: Jadwal harian diatur per waktu sholat (Subuh, Dzuhur, Ashar, Maghrib, Isya) untuk 7 hari (Senin–Minggu).
- **REQ-003**: Khusus hari Jumat (day_of_week=5), slot Dzuhur diganti `prayer_name="jumat"` dengan kolom terpisah untuk `khatib_id` dan `imam_id`.
- **REQ-004**: Tampilan berupa layar penuh (slideshow periodik) yang hanya menampilkan jadwal **hari ini**.
- **REQ-005**: Fitur dapat diaktifkan/dinonaktifkan admin via toggle di halaman Settings.
- **REQ-006**: Interval kemunculan dikonfigurasi 5–60 menit (default: 15 menit).
- **REQ-007**: Durasi tampil dikonfigurasi 10–120 detik (default: 30 detik).
- **REQ-008**: Admin dapat membatasi jam aktif fitur (jam mulai dan jam selesai).
- **REQ-009**: Tersedia fitur **"Kunci Jadwal"** (lock/unlock) agar jadwal tidak terubah secara tidak sengaja.
- **REQ-010**: Jika slot sholat kosong (imam_id NULL), tampilkan teks "Imam belum tersedia".
- **REQ-011**: Jika slot Jumat kosong (khatib_id NULL), tampilkan teks "Khatib belum tersedia".
- **REQ-012**: State sholat, midnight, dan slideshow pengumuman selalu lebih prioritas — dievaluasi lebih dahulu.
- **REQ-013**: Perubahan jadwal imam dari halaman Settings harus langsung merefresh cache jadwal hari ini tanpa perlu restart aplikasi.
- **REQ-014**: Saat tanggal berganti, evaluator harus otomatis memakai jadwal weekday baru pada tick berikutnya.

### Security Requirements

- **SEC-001**: Input nama imam melalui UI Settings menggunakan parameterized query SQLite.
- **SEC-002**: Tidak ada network call — semua data bersumber dari SQLite lokal.

### Constraints

- **CON-001**: Offline-first — tidak ada network calls sama sekali.
- **CON-002**: Platform target: Android TV 1920×1080 (utama) dan 1280×720 (fallback), navigasi D-Pad.
- **CON-003**: Total row `imam_schedules` maksimal 35 (7 hari × 5 waktu sholat).
- **CON-004**: `day_of_week`: 1=Senin, 2=Selasa, ..., 7=Minggu (mengikuti ISO 8601, `DateTime.now().weekday`).
- **CON-005**: SQLite foreign key enforcement wajib diaktifkan (`PRAGMA foreign_keys = ON`) agar `ON DELETE SET NULL` benar-benar berlaku.

### Guidelines

- **GUD-001**: Tambahkan `imamSchedule` sebagai State ke-9 di `DisplayStateType` (bukan sub-mode overlay).
- **GUD-002**: Guard kondisi wajib: jika `todaySchedule.isEmpty` → skip imam check → fallback ke wisdom/standby.
- **GUD-003**: Gunakan `LayoutBuilder` + `FittedBox(fit: BoxFit.scaleDown)` untuk kompatibilitas multi-resolusi.
- **GUD-004**: Semua elemen interaktif wajib accessible via D-Pad menggunakan `FocusableWidget`.
- **GUD-005**: `isImamScheduleLocked` hanya mempengaruhi UI admin di halaman Settings dan tidak ikut dimasukkan ke `TransitionConfig` maupun evaluator display.
- **GUD-006**: `DisplayStateCubit` wajib menyegarkan `todayImamSchedule` setelah CRUD jadwal/imam dan saat `weekday` berubah.
- **GUD-007**: Urutan kategori Settings yang sudah ada dipertahankan; item baru disisipkan tanpa merombak posisi `Kata Mutiara`, `Slideshow Pengumuman`, dan `Mode Hemat Daya`.

### Patterns to Follow

- **PAT-001**: Ikuti pola migrasi database `if (oldVersion < N)` di `DatabaseHelper._onUpgrade()`.
- **PAT-002**: Ikuti pola `_debounceSave()` untuk input bertipe stepper di `SettingsCubit`.
- **PAT-003**: Ikuti pola `SlideshowSection` / `WisdomQuoteSection` untuk Settings UI (toggle + conditional fields).
- **PAT-004**: Ikuti pola header clock+tanggal dari `StandbyLayout` untuk `ImamScheduleLayout`.
- **PAT-005**: Gunakan `RepositoryProvider` di `main.dart` untuk dependency injection.
- **PAT-006**: Ikuti pola `SlideshowSectionCubit` untuk sinkronisasi data runtime ke `DisplayStateCubit` setelah admin mengubah konten yang dipakai layar utama.

## 2. Implementation Steps

### Implementation Phase 1 — Database Schema, Integritas SQLite, & Migrasi v11

- **GOAL-001**: Menambahkan tabel `imams` dan `imam_schedules`, 8 kolom baru di tabel `settings`, serta mengaktifkan foreign key enforcement SQLite agar integritas `ON DELETE SET NULL` benar-benar berjalan.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Completed | Date       |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-001 | Di `lib/data/datasources/database_helper.dart`: naikkan `_databaseVersion` dari `10` ke `11`.                                                                                                                                                                                                                                                                                                                                                                                                                                                       | ✅         | 2026-05-17 |
| TASK-002 | Tambah DDL tabel `imams` di `_createTables()`: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `name TEXT NOT NULL UNIQUE`, `is_active INTEGER NOT NULL DEFAULT 1`, `created_at TEXT NOT NULL DEFAULT (datetime('now','localtime'))`.                                                                                                                                                                                                                                                                                                                       | ✅         | 2026-05-17 |
| TASK-003 | Tambah DDL tabel `imam_schedules` di `_createTables()`: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `day_of_week INTEGER NOT NULL CHECK(day_of_week BETWEEN 1 AND 7)`, `prayer_name TEXT NOT NULL CHECK(prayer_name IN ('subuh','dzuhur','ashar','maghrib','isya','jumat'))`, `imam_id INTEGER REFERENCES imams(id) ON DELETE SET NULL`, `khatib_id INTEGER REFERENCES imams(id) ON DELETE SET NULL`, `UNIQUE(day_of_week, prayer_name)`. Catatan implementasi: aturan Jumat vs Dzuhur ditegakkan di data source, bukan oleh CHECK lintas-baris SQLite. | ✅         | 2026-05-17 |
| TASK-004 | Tambah 8 kolom settings di DDL `CREATE TABLE settings`: `is_imam_schedule_enabled INTEGER NOT NULL DEFAULT 0`, `imam_schedule_interval_minutes INTEGER NOT NULL DEFAULT 15`, `imam_schedule_duration_seconds INTEGER NOT NULL DEFAULT 30`, `imam_schedule_start_hour INTEGER NOT NULL DEFAULT 6`, `imam_schedule_start_minute INTEGER NOT NULL DEFAULT 0`, `imam_schedule_end_hour INTEGER NOT NULL DEFAULT 21`, `imam_schedule_end_minute INTEGER NOT NULL DEFAULT 0`, `is_imam_schedule_locked INTEGER NOT NULL DEFAULT 0`.                       | ✅         | 2026-05-17 |
| TASK-005 | Tambah method `_onConfigure(Database db)` berisi `await db.execute('PRAGMA foreign_keys = ON')` lalu daftarkan ke `openDatabase(...)`. Setelah itu, tambah migration block `if (oldVersion < 11)` di `_onUpgrade()` dengan: `CREATE TABLE imams (...)`, `CREATE TABLE imam_schedules (...)`, dan 8 pernyataan `ALTER TABLE settings ADD COLUMN` untuk setiap kolom baru.                                                                                                                                                                            | ✅         | 2026-05-17 |

### Implementation Phase 2 — Domain Entities & Interface Repository

- **GOAL-002**: Mendefinisikan kontrak domain (entity + repository interface) untuk imam dan jadwal imam. Fase ini murni domain layer — zero infrastructure imports.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                 | Completed | Date       |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-006 | Buat `lib/domain/entities/imam.dart` — immutable `Imam` entity: `id` (int), `name` (String), `isActive` (bool). Extends `Equatable`, `props: [id]`.                                                                                                                                                                                                                                         | ✅         | 2026-05-17 |
| TASK-007 | Buat `lib/domain/entities/imam_schedule.dart` — immutable `ImamSchedule` entity: `id` (int), `dayOfWeek` (int, 1–7), `prayerName` (String), `imamId` (int?), `khatibId` (int?). Extends `Equatable`, `props: [id]`.                                                                                                                                                                         | ✅         | 2026-05-17 |
| TASK-008 | Buat `lib/domain/entities/imam_schedule_display.dart` — DTO normalized+resolved untuk tampilan dan binding UI: `dayOfWeek` (int), `prayerName` (String key: `subuh`/`dzuhur`/`jumat`/dll), `prayerLabel` (String), `imamId` (int?), `imamName` (String?), `khatibId` (int?), `khatibName` (String?).                                                                                        | ✅         | 2026-05-17 |
| TASK-009 | Buat `lib/domain/repositories/imam_repository.dart` — abstract interface: `Future<List<Imam>> getAll()`, `Future<Imam?> getById(int id)`, `Future<int> insert(String name)`, `Future<void> update(Imam imam)`, `Future<void> delete(int id)`, `Future<int> count()`. Zero infrastructure imports.                                                                                           | ✅         | 2026-05-17 |
| TASK-010 | Buat `lib/domain/repositories/imam_schedule_repository.dart` — abstract interface: `Future<List<ImamScheduleDisplay>> getScheduleForDay(int dayOfWeek)`, `Future<List<ImamSchedule>> getRawScheduleForDay(int dayOfWeek)`, `Future<void> setSchedule({required int dayOfWeek, required String prayerName, int? imamId, int? khatibId})`, `Future<void> clearScheduleForDay(int dayOfWeek)`. | ✅         | 2026-05-17 |

### Implementation Phase 3 — Data Layer (Models, DataSources, Repositories)

- **GOAL-003**: Menyediakan implementasi konkret untuk operasi CRUD imam dan jadwal ke SQLite.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Completed | Date       |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- | ---------- |
| TASK-011 | Buat `lib/data/models/imam_model.dart` — factory `ImamModel.fromMap(Map<String, dynamic>)` dan method `Map<String, dynamic> toMap()`, `Imam toEntity()`. Mapping: `is_active` (int) ↔ `isActive` (bool).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | ✅         | 2026-05-17 |
| TASK-012 | Buat `lib/data/models/imam_schedule_model.dart` — factory `ImamScheduleModel.fromMap(Map<String, dynamic>)` dan method `toMap()`, `ImamSchedule toEntity()`. Mapping: `day_of_week` ↔ `dayOfWeek`, `prayer_name` ↔ `prayerName`, `imam_id` ↔ `imamId`, `khatib_id` ↔ `khatibId`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | ✅         | 2026-05-17 |
| TASK-013 | Buat `lib/data/datasources/imam_local_data_source.dart` — class `ImamLocalDataSource` dengan method: `getAll()`, `getById(int)`, `insert(String name)` (dengan validasi `count() < 10`), `update(Imam)`, `delete(int)`, `count()`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | ✅         | 2026-05-17 |
| TASK-014 | Buat `lib/data/datasources/imam_schedule_local_data_source.dart` — class `ImamScheduleLocalDataSource` dengan method: `getScheduleForDay(int)` yang **mengembalikan list kosong bila belum ada satu pun row untuk hari target**, tetapi bila minimal satu row ada maka hasilnya dinormalisasi menjadi 5 slot (Jumat memakai urutan `subuh`,`jumat`,`ashar`,`maghrib`,`isya`; hari biasa memakai `subuh`,`dzuhur`,`ashar`,`maghrib`,`isya`) melalui `LEFT JOIN imams AS imam` dan `LEFT JOIN imams AS khatib`; `getRawScheduleForDay(int)`; `setSchedule(...)` (upsert via `ConflictAlgorithm.replace` dengan normalisasi aturan Jumat: `dzuhur`→`jumat` untuk `dayOfWeek == 5`, tolak `jumat` untuk non-Jumat, dan hapus row legacy konflik jika ada); `clearScheduleForDay(int)` (khusus Jumat juga membersihkan `dzuhur` dan `jumat` untuk menjaga konsistensi). | ✅         | 2026-05-17 |
| TASK-015 | Buat `lib/data/repositories/imam_repository_impl.dart` — `ImamRepositoryImpl` mengimplementasikan `ImamRepository`, delegasi ke `ImamLocalDataSource`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | ✅         | 2026-05-17 |
| TASK-016 | Buat `lib/data/repositories/imam_schedule_repository_impl.dart` — `ImamScheduleRepositoryImpl` mengimplementasikan `ImamScheduleRepository`, delegasi ke `ImamScheduleLocalDataSource`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | ✅         | 2026-05-17 |

### Implementation Phase 4 — Settings & TransitionConfig Update

- **GOAL-004**: Memperbarui `Settings`, `SettingsModel`, dan `TransitionConfig` untuk mengakomodasi 8 field konfigurasi jadwal imam, dengan catatan field lock hanya hidup di layer Settings UI dan tidak ikut evaluator display.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Completed | Date       |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-017 | Update `lib/domain/entities/settings.dart` — tambah 8 field baru ke constructor: `isImamScheduleEnabled` (default `false`), `imamScheduleIntervalMinutes` (default `15`), `imamScheduleDurationSeconds` (default `30`), `imamScheduleStartHour` (default `6`), `imamScheduleStartMinute` (default `0`), `imamScheduleEndHour` (default `21`), `imamScheduleEndMinute` (default `0`), `isImamScheduleLocked` (default `false`). Update `copyWith()` dan `props`.                                                                                                                                                                                                                                                                                                                             | ✅         | 2026-05-17 |
| TASK-018 | Update `lib/data/models/settings_model.dart` — tambah mapping `fromMap` untuk 8 kolom baru (snake_case, fallback `?? default`) dan tambah entry `toMap` (camelCase → snake_case, bool → int).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | ✅         | 2026-05-17 |
| TASK-019 | Update `lib/domain/entities/transition_config.dart` — tambah **7 field**: `isImamScheduleEnabled`, `imamScheduleIntervalMinutes`, `imamScheduleDurationSeconds`, `imamScheduleStartHour`, `imamScheduleStartMinute`, `imamScheduleEndHour`, `imamScheduleEndMinute`. `isImamScheduleLocked` **tidak** masuk `TransitionConfig`. Update factory `TransitionConfig.fromSettings()`.                                                                                                                                                                                                                                                                                                                                                                                                           | ✅         | 2026-05-17 |
| TASK-020 | Tambah 8 method di `lib/presentation/cubits/settings/settings_cubit.dart`: `updateImamScheduleEnabled(bool)` → `_saveField(..., triggerConfigUpdate: true)`, `updateImamScheduleIntervalMinutes(int)` → `_debounceSave(..., triggerConfigUpdate: true)`, `updateImamScheduleDurationSeconds(int)` → `_debounceSave(..., triggerConfigUpdate: true)`, `updateImamScheduleStartHour(int)` → `_debounceSave(..., triggerConfigUpdate: true)`, `updateImamScheduleStartMinute(int)` → `_debounceSave(..., triggerConfigUpdate: true)`, `updateImamScheduleEndHour(int)` → `_debounceSave(..., triggerConfigUpdate: true)`, `updateImamScheduleEndMinute(int)` → `_debounceSave(..., triggerConfigUpdate: true)`, `updateImamScheduleLocked(bool)` → `_saveField()` tanpa `triggerConfigUpdate`. | ✅         | 2026-05-17 |

### Implementation Phase 5 — Display State Machine Update

- **GOAL-005**: Menambahkan `ImamScheduleState` sebagai State ke-9 pada display state machine dan mengintegrasikan evaluasi jadwal imam ke `EvaluateDisplayStateUseCase`.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | Completed | Date       |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-021 | Update `lib/domain/entities/display_state_type.dart` — tambah nilai `imamSchedule` ke enum `DisplayStateType`, posisi setelah `slideshowAnnouncement` dan sebelum `wisdomQuote`.                                                                                                                                                                                                                                                                                                                               | ✅         | 2026-05-17 |
| TASK-022 | Update `lib/domain/entities/display_state.dart` — tambah `final class ImamScheduleState extends DisplayState` dengan field: `String dayName`, `String hijriDate`, `List<ImamScheduleDisplay> slots`, `DateTime currentTime`, `int totalDurationSeconds`, `int remainingSeconds`. Override `type` return `DisplayStateType.imamSchedule`.                                                                                                                                                                       | ✅         | 2026-05-17 |
| TASK-023 | Update signature `evaluate()` di `lib/domain/usecases/evaluate_display_state_use_case.dart` — tambah named parameter `List<ImamScheduleDisplay>? todayImamSchedule`.                                                                                                                                                                                                                                                                                                                                           | ✅         | 2026-05-17 |
| TASK-024 | Implementasikan `_evaluateImamScheduleWindow()` di `evaluate_display_state_use_case.dart` — setelah slideshow check dan sebelum wisdom check. Guard: `config.isImamScheduleEnabled && todayImamSchedule != null && todayImamSchedule.isNotEmpty`. Logika siklus: `cycleLength = intervalMinutes * 60 + durationSeconds`, `positionInCycle = secondsSinceStart % cycleLength`, jika `positionInCycle < durationSeconds` → return `ImamScheduleState(dayName: ..., hijriDate: dailyPrayerTimes.hijriDate, ...)`. | ✅         | 2026-05-17 |

### Implementation Phase 6 — ImamScheduleCubit (CRUD State Management)

- **GOAL-006**: Membuat Cubit khusus untuk operasi CRUD imam dan jadwal dari halaman Settings. Cubit ini terpisah dari `DisplayStateCubit` dan bertanggung jawab atas interaksi UI admin.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Completed | Date       |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-025 | Buat `lib/presentation/cubits/imam_schedule/imam_schedule_state.dart` — states: `ImamScheduleInitial`, `ImamScheduleLoading`, `ImamScheduleLoaded` (field: `List<Imam> imams`, `Map<int, List<ImamScheduleDisplay>> weeklySchedule`, `bool isLocked`), `ImamScheduleError(String message)`.                                                                                                                                                                                                                                                                                                                                                                                                                                         | ✅         | 2026-05-17 |
| TASK-026 | Buat `lib/presentation/cubits/imam_schedule/imam_schedule_cubit.dart` — constructor menerima `ImamRepository`, `ImamScheduleRepository`, dan `DisplayStateCubit?` untuk sinkronisasi runtime. Method: `loadAll()` (loop `dayOfWeek` 1..7, ambil `getRawScheduleForDay()`, lalu bangun `weeklySchedule` editable 5-slot untuk setiap hari agar UI tetap lengkap meski DB hari tersebut masih kosong), `addImam(String name)`, `updateImam(Imam)`, `deleteImam(int id)`, `setSchedule({dayOfWeek, prayerName, imamId, khatibId})`, `clearDay(int dayOfWeek)`. Operasi yang mengubah master/jadwal (`updateImam`, `deleteImam`, `setSchedule`, `clearDay`) wajib reload state lalu memanggil `displayStateCubit?.onSettingsChanged()`. | ✅         | 2026-05-17 |

### Implementation Phase 7 — Settings UI (ImamScheduleSection)

- **GOAL-007**: Membuat section Settings lengkap untuk manajemen imam dan jadwal, mengikuti pola `SlideshowSection` dan `WisdomQuoteSection`. Semua fields jadwal disabled saat toggle off atau jadwal terkunci.

| Task     | Description                                                                                                                                                                                                                                                                                                                                    | Completed | Date       |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-027 | Buat `lib/presentation/pages/settings/sections/imam_schedule_section.dart` — ikuti pola `SlideshowSection`: widget wrapper menyediakan `BlocProvider<ImamScheduleCubit>` lokal dan trigger `..loadAll()` pada `create`, lalu render konten di widget terpisah.                                                                                 | ✅         | 2026-05-18 |
| TASK-028 | Implementasi **header section**: ikon masjid + judul "Jadwal Imam Sholat" + deskripsi singkat. Pattern `GlassmorphismCard`.                                                                                                                                                                                                                    | ✅         | 2026-05-18 |
| TASK-029 | Implementasi **toggle aktif**: `FocusableWidget` + `Switch.adaptive` → `settingsCubit.updateImamScheduleEnabled(value)`. Saat nonaktif, `ExcludeFocus` + `Opacity(0.4)` pada area di bawahnya.                                                                                                                                                 | ✅         | 2026-05-18 |
| TASK-030 | Implementasi **toggle kunci jadwal**: `FocusableWidget` + `Switch.adaptive` → `settingsCubit.updateImamScheduleLocked(value)`. Saat terkunci, area CRUD imam dan jadwal menjadi `ExcludeFocus` + `Opacity(0.4)`.                                                                                                                               | ✅         | 2026-05-18 |
| TASK-031 | Implementasi **DPadStepper interval**: label "Tampil Setiap", range 5–60, satuan "menit", step 5 → `updateImamScheduleIntervalMinutes()`.                                                                                                                                                                                                      | ✅         | 2026-05-18 |
| TASK-032 | Implementasi **DPadStepper durasi**: label "Lama Tampil", range 10–120, satuan "detik", step 5 → `updateImamScheduleDurationSeconds()`.                                                                                                                                                                                                        | ✅         | 2026-05-18 |
| TASK-033 | Implementasi **pengaturan jam aktif** (4 DPadStepper): jam mulai (0–23) + menit (0–59) + jam selesai (0–23) + menit (0–59).                                                                                                                                                                                                                    | ✅         | 2026-05-18 |
| TASK-034 | Implementasi **daftar master imam**: ListView menampilkan semua imam, tombol "Tambah Imam" (disabled saat count >= 10), tombol edit, tombol hapus. Input nama via `TextField` dengan D-Pad support.                                                                                                                                            | ✅         | 2026-05-18 |
| TASK-035 | Implementasi **grid jadwal mingguan**: 7 tab hari (Senin–Minggu), masing-masing menampilkan 5 slot waktu sholat dengan dropdown picker imam berbasis `imamId`. Khusus Jumat: slot Dzuhur diganti "Jumat" dengan 2 dropdown (`khatibId` + `imamId`). Sumber binding berasal dari `ImamScheduleDisplay` yang sudah membawa ID dan nama resolved. | ✅         | 2026-05-18 |

### Implementation Phase 8 — ImamScheduleLayout (Main Display)

- **GOAL-008**: Membuat widget layout full-screen baru yang menampilkan jadwal imam hari ini sesuai desain Islamic Glassmorphism. Kompatibel dengan 1920×1080 dan 1280×720.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                | Completed | Date       |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-036 | Buat `lib/presentation/pages/main_display/layouts/imam_schedule_layout.dart` — `StatelessWidget` menerima parameter `ImamScheduleState state`.                                                                                                                                                                                                                             | ✅         | 2026-05-17 |
| TASK-037 | Implementasi **header**: gunakan `HeaderWidget` dengan pola yang sama seperti `StandbyLayout`, memanfaatkan `state.currentTime` dan `state.hijriDate`. Nama masjid tetap dibaca dari `SettingsCubit` seperti layout utama lain.                                                                                                                                            | ✅         | 2026-05-17 |
| TASK-038 | Implementasi **body**: `GlassmorphismCard` centered dengan judul "JADWAL IMAM SHOLAT", nama masjid, badge hari (misal "══ SENIN ══"), lalu tabel 5 row dengan kolom kiri `prayerLabel` dan kolom kanan `imamName`. Khusus Jumat: row "Jumat" menampilkan 2 baris (Khatib + Imam). Slot kosong → "Imam belum tersedia" / "Khatib belum tersedia" dengan style italic redup. | ✅         | 2026-05-17 |
| TASK-039 | Implementasi **footer**: progress bar (`LinearProgressIndicator`, value = `1 - remainingSeconds / totalDurationSeconds`) dan nama masjid.                                                                                                                                                                                                                                  | ✅         | 2026-05-17 |
| TASK-040 | Di `lib/presentation/pages/main_display_page.dart`: tambah import dan case `DisplayStateType.imamSchedule:` → return `ImamScheduleLayout(state: displayState as ImamScheduleState)`.                                                                                                                                                                                       | ✅         | 2026-05-17 |

### Implementation Phase 9 — Dependency Injection, Integration & Testing

- **GOAL-009**: Menghubungkan semua layer melalui DI di `main.dart`, mendaftarkan section di Settings, dan memastikan seluruh komponen terlindungi test suite.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Completed | Date       |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-041 | Di `lib/main.dart`: instansiasi `ImamLocalDataSource`, `ImamScheduleLocalDataSource`, `ImamRepositoryImpl`, `ImamScheduleRepositoryImpl`. Tambah `RepositoryProvider<ImamRepository>` dan `RepositoryProvider<ImamScheduleRepository>` ke `MultiRepositoryProvider`.                                                                                                                                                                                                                                                                   | ✅         | 2026-05-17 |
| TASK-042 | Update `DisplayStateCubit` constructor — tambah required parameter `ImamScheduleRepository imamScheduleRepository`. Tambah field cache `_todayImamSchedule` dan `_todayImamScheduleDayOfWeek`. Di `_loadConfig({DateTime? referenceTime})`, load jadwal hari ini berdasarkan `referenceTime?.weekday ?? DateTime.now().weekday`. Di `_tick()`, jika `now.weekday != _todayImamScheduleDayOfWeek`, reload jadwal hari itu sebelum memanggil `evaluate()`. Di `onSettingsChanged()`, reload config + schedule hari ini lalu re-evaluate. | ✅         | 2026-05-17 |
| TASK-043 | Di `lib/presentation/pages/settings/settings_menu_page.dart`: tambah import dan entri "Jadwal Imam" ke `_categories` serta `ImamScheduleSection()` ke `_sections` dengan posisi **setelah `Slideshow Pengumuman` dan sebelum `Mode Hemat Daya`**, tanpa mengubah urutan kategori existing lain.                                                                                                                                                                                                                                        | ✅         | 2026-05-17 |
| TASK-044 | Jalankan seluruh test suite: `flutter test --reporter=expanded`. Pastikan semua test lama tetap pass (regresi). **Hasil: 98 test baru lulus, 0 regresi pada test imam schedule**.                                                                                                                                                                                                                                                                                                                                                      | ✅         | 2026-05-17 |

### Implementation Phase 10 — UI Polish & Layout Hotfixes

- **GOAL-010**: Memperbaiki masalah visual yang ditemukan saat pengujian di device nyata:
  `ImamScheduleLayout` mengalami dua bug pada resolusi non-1920×1080 — label "Khatib:"/"Imam:" wrap ke baris kedua,
  dan baris Isya terpotong di bawah card. `ImamScheduleSection` ditambahkan input constraint dan counter karakter.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Completed | Date       |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-045 | **Layout: ukuran font & lebar kolom** — Naikkan font prayer label (`26.sp`→`36.sp`), separator (`26.sp`→`36.sp`), imam name regular (`26.sp`→`36.sp`), sub-label Khatib/Imam (`24.sp`→`34.sp`), imam name Jumat (`24.sp`→`34.sp`). Lebarkan kolom prayer label `120.w`→`200.w`, sub-label Khatib/Imam `100.w`→`160.w`. Tambah `maxLines:1` + `TextOverflow.ellipsis` pada semua nama imam. Lebarkan `ConstrainedBox` body dari `960.w` → `1400.w`. Subtitle nama masjid `24.sp`→`32.sp`. Badge hari `28.sp`→`36.sp` dengan warna solid putih.                                                                                                                                                                                                           | ✅         | 2026-05-25 |
| TASK-046 | **Layout: Khatib/Imam label wrapping (HOTFIX)** — `SizedBox(width: 100.w)` di `_buildPersonLine` terlalu sempit untuk teks "Khatib:" pada `34.sp` → wraps ke baris ke-2 di device nyata. Fix: naikkan ke `SizedBox(width: 160.w)`. Semua test lama tetap pass.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | ✅         | 2026-05-25 |
| TASK-047 | **Layout: Isya row terpotong (HOTFIX)** — `_buildBody` menggunakan `ConstrainedBox(maxWidth: 1400.w)` tanpa batasan tinggi, sehingga `GlassmorphismCard` tumbuh melebihi ruang `Expanded` dan baris terakhir (Isya) ter-clip oleh `ClipRRect` card. Fix: bungkus `_buildBody` dengan `LayoutBuilder` dan tambahkan `maxHeight: constraints.maxHeight` ke `ConstrainedBox`. Kurangi spacing internal card: `vertical: 40.h`→`28.h`, `SizedBox(28.h)`→`16.h` sebelum slot, `SizedBox(6.h)`→`4.h` sebelum mosque name, `SizedBox(24.h)`→`16.h` sebelum badge, `vertical: 6.h`→`4.h` antar baris slot. Semua 12 test pass.                                                                                                                                  | ✅         | 2026-05-25 |
| TASK-048 | **Settings: input constraint nama imam** — Tambah `maxLength: 60` dengan `counterText: ''` (sembunyikan counter bawaan Material) pada `TextField` di dialog input nama imam di `ImamScheduleSection`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | ✅         | 2026-05-25 |
| TASK-049 | **Settings: karakter counter nama imam** — Tambah `ValueListenableBuilder<TextEditingValue>` di bawah `TextField` yang menampilkan `"${length}/60"` secara real-time (`fontSize: 26.sp`, `color: Colors.white`). Tambah test baru: counter tampil dan menampilkan jumlah karakter yang benar → `imam_schedule_section_test.dart` menjadi 13 test.                                                                                                                                                                                                                                                                                                                                                                                                       | ✅         | 2026-05-25 |
| TASK-050 | **Data layer: runtime type cast bug di `ImamRepositoryImpl.update()` (HOTFIX)** — `update()` menggunakan `imam as dynamic` sebagai workaround cast ke `ImanModel`. Saat `_showEditImamDialog` membuat `Imam(...)` biasa (bukan `ImanModel`), cast lolos kompilasi namun gagal di runtime dengan pesan `"type 'Imam' is not a subtype of type 'ImanModel'"` karena `ImanLocalDataSource.update()` memanggil `.toMap()` yang hanya ada di `ImanModel`. Fix: tambah import `imam_model.dart` dan ganti `imam as dynamic` dengan konversi eksplisit `ImanModel(id: imam.id, name: imam.name, isActive: imam.isActive)` sesuai pola Clean Architecture — repository adalah adapter domain ↔ data layer. Semua 18 test `imam_repository_impl_test.dart` pass. | ✅         | 2026-05-25 |

## 3. Alternatives

- **ALT-001**: **Menyimpan jadwal di `settings` table** — Ditolak karena 35 slot (7×5) akan menambah 70+ kolom ke tabel settings yang sudah besar. Tabel terpisah `imam_schedules` lebih scalable dan maintainable.
- **ALT-002**: **Menampilkan jadwal seluruh minggu** — Ditolak karena layar TV akan terlalu padat. Hanya jadwal hari ini yang ditampilkan, sesuai keputusan desain user.
- **ALT-003**: **Custom cubit terpisah `ImamDisplayCubit`** — Ditolak untuk menjaga konsistensi; logika penjadwalan display cukup berada di `EvaluateDisplayStateUseCase` yang menerima input `now`, `config`, dan `todayImamSchedule` dari `DisplayStateCubit`.
- **ALT-004**: **Overlay di atas `StandbyLayout`** — Ditolak karena akan memperumit manajemen timer dan tidak memanfaatkan `AnimatedSwitcher` yang sudah ada.
- **ALT-005**: **Membaca jadwal imam dari SQLite pada setiap tick 1 detik** — Ditolak karena menambah I/O periodik yang tidak perlu. Strategi terpilih adalah cache di `DisplayStateCubit` dengan refresh saat `weekday` berubah atau saat admin melakukan mutasi data.

---

## 4. Dependencies

- **DEP-001**: `sqflite` (sudah ada) — migrasi database v11, tabel baru.
- **DEP-002**: `flutter_bloc` (sudah ada) — `BlocBuilder`, `BlocProvider`, `context.read<>()`.
- **DEP-003**: `equatable` (sudah ada) — `Imam`, `ImamSchedule` entities.
- **DEP-004**: `flutter_screenutil` (sudah ada) — `.sp`, `.w`, `.h` di `ImamScheduleLayout`.
- **DEP-005**: `google_fonts` (sudah ada) — tipografi di layout baru.
- **DEP-006**: **Tidak ada dependency baru** — semua kebutuhan terpenuhi oleh package yang sudah ada.

---

## 5. Files

### File Baru

- **FILE-001**: `lib/domain/entities/imam.dart` — Immutable entity imam.
- **FILE-002**: `lib/domain/entities/imam_schedule.dart` — Immutable entity jadwal imam.
- **FILE-003**: `lib/domain/entities/imam_schedule_display.dart` — DTO normalized+resolved (stable IDs + resolved names).
- **FILE-004**: `lib/domain/repositories/imam_repository.dart` — Abstract interface CRUD imam.
- **FILE-005**: `lib/domain/repositories/imam_schedule_repository.dart` — Abstract interface jadwal.
- **FILE-006**: `lib/data/models/imam_model.dart` — Data model (DB ↔ entity).
- **FILE-007**: `lib/data/models/imam_schedule_model.dart` — Data model (DB ↔ entity).
- **FILE-008**: `lib/data/datasources/imam_local_data_source.dart` — SQLite ops imam.
- **FILE-009**: `lib/data/datasources/imam_schedule_local_data_source.dart` — SQLite ops + JOIN.
- **FILE-010**: `lib/data/repositories/imam_repository_impl.dart` — Implementasi konkret.
- **FILE-011**: `lib/data/repositories/imam_schedule_repository_impl.dart` — Implementasi konkret.
- **FILE-012**: `lib/presentation/cubits/imam_schedule/imam_schedule_cubit.dart` — CRUD cubit.
- **FILE-013**: `lib/presentation/cubits/imam_schedule/imam_schedule_state.dart` — State definitions.
- **FILE-014**: `lib/presentation/pages/settings/sections/imam_schedule_section.dart` — Settings UI.
- **FILE-015**: `lib/presentation/pages/main_display/layouts/imam_schedule_layout.dart` — Display layout.

### File Dimodifikasi

- **FILE-016**: `lib/data/datasources/database_helper.dart` — Versi naik ke 11, `_onConfigure()`, DDL, dan migration.
- **FILE-017**: `lib/domain/entities/settings.dart` — 8 field baru.
- **FILE-018**: `lib/data/models/settings_model.dart` — fromMap/toMap 8 field baru.
- **FILE-019**: `lib/domain/entities/transition_config.dart` — 7 field imam baru.
- **FILE-020**: `lib/domain/entities/display_state_type.dart` — Tambah `imamSchedule`.
- **FILE-021**: `lib/domain/entities/display_state.dart` — Tambah `ImamScheduleState` + `hijriDate`.
- **FILE-022**: `lib/domain/usecases/evaluate_display_state_use_case.dart` — Parameter + logika baru.
- **FILE-023**: `lib/presentation/cubits/settings/settings_cubit.dart` — 8 method baru.
- **FILE-024**: `lib/presentation/cubits/display_state/display_state_cubit.dart` — Inject repo, cache jadwal hari ini, refresh saat settings berubah dan saat weekday berganti.
- **FILE-025**: `lib/presentation/pages/main_display_page.dart` — Tambah case imamSchedule.
- **FILE-026**: `lib/presentation/pages/settings/settings_menu_page.dart` — Tambah kategori + section.
- **FILE-027**: `lib/main.dart` — Instansiasi dan inject ImamRepository + ImamScheduleRepository.

### File Test Baru

- **FILE-028**: `test/data/models/imam_model_test.dart`
- **FILE-029**: `test/data/models/imam_schedule_model_test.dart`
- **FILE-030**: `test/data/repositories/imam_repository_impl_test.dart`
- **FILE-031**: `test/data/repositories/imam_schedule_repository_impl_test.dart`
- **FILE-032**: `test/presentation/cubits/imam_schedule/imam_schedule_cubit_test.dart`
- **FILE-033**: `test/presentation/pages/settings/sections/imam_schedule_section_test.dart`
- **FILE-034**: `test/presentation/pages/main_display/layouts/imam_schedule_layout_test.dart`

### File Test Dimodifikasi

- **FILE-035**: `test/data/models/settings_model_test.dart` — +8 tests field baru.
- **FILE-036**: `test/data/datasources/database_helper_test.dart` — +migration v11 dan verifikasi `foreign_keys` aktif.
- **FILE-037**: `test/presentation/cubits/settings/settings_cubit_test.dart` — +8 update methods.
- **FILE-038**: `test/domain/usecases/evaluate_display_state_use_case_test.dart` — +imam window tests.
- **FILE-039**: `test/presentation/cubits/display_state/display_state_cubit_test.dart` — +inject repo, reload cache hari ini, dan day-rollover handling.

---

## 6. Testing

### Hasil Verifikasi (2026-05-17)

**Total: 98 test baru lulus ✅** (dijalankan bersama test suite yang ada)

| File Test                                                        | Jumlah Test  | Status |
| ---------------------------------------------------------------- | ------------ | ------ |
| `evaluate_display_state_use_case_test.dart` (grup Imam Schedule) | 13 test baru | ✅      |
| `imam_schedule_cubit_test.dart`                                  | 24 test      | ✅      |
| `imam_schedule_layout_test.dart`                                 | 12 test      | ✅      |
| `imam_schedule_section_test.dart`                                | 13 test      | ✅      |

### Catatan Implementasi Test

- **`evaluate_display_state_use_case_test.dart`**: Saat men-test slot aktif, `now` harus tepat di `windowStart` (`06:00:00`) agar `positionInCycle = 0 < durationSeconds`. Menggunakan `now=10:00` menyebabkan `positionInCycle = 14400 % 930 = 450 >= 30` (dalam jeda), sehingga evaluator tidak mengembalikan `ImamScheduleState`.
- **`imam_schedule_cubit_test.dart`**: Diperlukan `registerFallbackValue(const Imam(...))` di `setUpAll` karena mocktail butuh fallback value untuk tipe `Imam` saat menggunakan matcher `any()`. `onSettingsChanged()` mengembalikan `Future<void>` sehingga stub harus menggunakan `thenAnswer((_) async {})`, bukan `thenReturn(null)`.
- **`imam_schedule_layout_test.dart`**: Diperlukan `await initializeDateFormatting('id')` di `setUpAll` karena `HeaderWidget` menggunakan `DateFormat('id')` yang harus diinisialisasi sebelum widget di-render di lingkungan test.
- **`imam_schedule_section_test.dart`**: Diperlukan stub lengkap pada `MockDisplayStateCubit` meliputi `.state` (mengembalikan `StandbyState(currentTime: ...)`) dan `.stream` (mengembalikan `Stream<DisplayState>.empty()`), karena `ImamScheduleSection` mengakses `context.read<DisplayStateCubit>()` untuk keperluan inject ke cubit lokal.

### Rincian Test per Spesifikasi

- **TEST-001**: `ImamModel` — `fromMap` default/custom, `toMap`, round-trip, `isActive` int↔bool.
- **TEST-002**: `ImamScheduleModel` — `fromMap` dengan imam_id null, `fromMap` dengan khatib_id, `toMap`, round-trip.
- **TEST-003**: `ImamRepositoryImpl` — `getAll()` mengembalikan list, `insert()` berhasil, `insert()` gagal saat count >= 10, `update()`, `delete()`, `count()`.
- **TEST-004**: `ImamScheduleRepositoryImpl` — `getScheduleForDay(1)` JOIN resolves names, hari kosong mengembalikan list kosong, hari terkonfigurasi mengembalikan 5 slot normalized, `setSchedule()` menormalisasi aturan Jumat, `clearScheduleForDay(5)` membersihkan `dzuhur` dan `jumat`, dan delete imam menghasilkan `imam_id`/`khatib_id` null melalui FK.
- **TEST-005**: `SettingsModel` — `fromMap` dengan 8 default values, `fromMap` custom, `toMap`, round-trip.
- **TEST-006**: `SettingsCubit` — `updateImamScheduleEnabled(true)`, `updateImamScheduleIntervalMinutes(30)`, `updateImamScheduleLocked(true)`, dan verifikasi lock tidak memicu `triggerConfigUpdate` ke `DisplayStateCubit`.
- **TEST-007**: `EvaluateDisplayStateUseCase` — imam window aktif → return `ImamScheduleState`; imam window tidak aktif → skip; `todayImamSchedule.isEmpty` → skip; ada prayer window → prayer menang; imam dievaluasi setelah slideshow dan sebelum wisdom; `remainingSeconds` berkurang seiring waktu; `dayName` menggunakan nama hari Indonesia kapital. ✅ **13 test baru**
- **TEST-008**: `ImamScheduleCubit` — `loadAll()` emit `[Loading, Loaded]` dengan 7 hari × 5 slot editable, imam dari repository, Jumat memakai slot `jumat` (bukan `dzuhur`), `isLocked` dipertahankan saat reload; `addImam()` berhasil + TIDAK memanggil `onSettingsChanged` (GUD-005); `updateImam()` + `deleteImam()` memanggil `onSettingsChanged`; `setSchedule()` + `clearDay()` memanggil `onSettingsChanged`; null-safe saat `displayStateCubit = null`. ✅ **24 test**
- **TEST-009**: `ImamScheduleLayout` — render tanpa overflow pada 1920×1080, `HeaderWidget` tidak crash (intl terinitialisasi), badge hari tampil, 5 label waktu sholat tampil, slot kosong "Imam belum tersedia", slot terisi menampilkan nama imam, `GlassmorphismCard` ada, `LinearProgressIndicator` dengan nilai benar, Jumat: badge `JUM'AT`, Khatib+Imam terpisah, slot kosong imam Jumat menampilkan "Imam belum tersedia", nama masjid dari `SettingsCubit`. ✅ **12 test**
- **TEST-010**: `ImamScheduleSection` — render tanpa overflow, toggle "Aktifkan Jadwal Imam" tampil dengan nilai sesuai settings, tap toggle memanggil `updateImamScheduleEnabled(false)`, disabled → `ExcludeFocus(excluding:true)` ada, enabled → 6 `DPadStepper` tampil, toggle "Kunci Jadwal" tampil, tap kunci memanggil `updateImamScheduleLocked(true)`, info bar jam aktif format `HH:MM – HH:MM`, daftar imam kosong → "Belum ada imam terdaftar", daftar imam terisi → nama tampil, counter `1/10` tampil, 7 tab hari tampil, **character counter `"0/60"` tampil di dialog input imam** (ditambahkan TASK-049). ✅ **13 test**
- **TEST-011**: `DisplayStateCubit` — reload `todayImamSchedule` saat `onSettingsChanged()` dan saat `weekday` berubah pada `_tick()`.
- **TEST-012**: `DatabaseHelper` — migration v11 membuat tabel baru, kolom settings baru tersedia, dan `PRAGMA foreign_keys` aktif.


---

## 7. Risks & Assumptions

- **RISK-001**: **JOIN query performance** — `imam_schedules LEFT JOIN imams` (maks 5 row × 2 join) sangat ringan. Tidak perlu optimasi.
- **RISK-002**: **Imam dihapus saat masih ada jadwal** — Mitigasi: aktifkan `PRAGMA foreign_keys = ON` dan gunakan `ON DELETE SET NULL`, sehingga jadwal tetap ada tapi imam_id/khatib_id menjadi NULL → tampil "Imam belum tersedia" / "Khatib belum tersedia".
- **RISK-003**: **Migrasi database v11 pada device yang sudah install v10** — `_onUpgrade()` dipanggil otomatis. Perlu di-test pada emulator dengan DB v10 existing.
- **RISK-004**: **Slot Jumat dan Dzuhur di hari Jumat** — Mitigasi: normalisasi dilakukan di `ImamScheduleLocalDataSource.setSchedule()`, `clearScheduleForDay(5)`, dan query normalized untuk display. SQLite schema tidak dipaksa dengan trigger tambahan agar solusi tetap sederhana.
- **RISK-005**: **Cache jadwal harian stale setelah pergantian tanggal** — Mitigasi: `DisplayStateCubit` menyimpan `todayImamScheduleDayOfWeek` dan me-reload jadwal pada tick pertama setelah `weekday` berubah.

- **ASSUMPTION-001**: `DateTime.now().weekday` mengikuti ISO 8601 (1=Monday ... 7=Sunday), sesuai dengan `day_of_week` di database.
- **ASSUMPTION-002**: Setiap hari memiliki tepat 5 slot waktu sholat. Hari Jumat mengganti slot "dzuhur" dengan slot "jumat".
- **ASSUMPTION-003**: `ImamScheduleDisplay` adalah DTO normalized+resolved yang membawa ID stabil untuk binding dropdown UI dan nama resolved untuk display layar utama.

---

## 8. Related Specifications / Further Reading

### Algoritma Penjadwalan (Pseudocode)

```text
Input: now (DateTime), config (TransitionConfig), todaySchedule (List<ImamScheduleDisplay>)

Caller responsibility:
  `DisplayStateCubit` telah memastikan `todaySchedule` direfresh saat admin mengubah jadwal
  dan saat `weekday` berubah.

GUARD:
  if !config.isImamScheduleEnabled → skip
  if todaySchedule.isEmpty → skip

JAM AKTIF CHECK:
  startSeconds = config.imamScheduleStartHour * 3600 + config.imamScheduleStartMinute * 60
  endSeconds   = config.imamScheduleEndHour * 3600 + config.imamScheduleEndMinute * 60
  nowSeconds   = now.hour * 3600 + now.minute * 60 + now.second
  if nowSeconds < startSeconds OR nowSeconds >= endSeconds → skip

SIKLUS:
  secondsSinceStart = nowSeconds - startSeconds
  cycleLength       = config.imamScheduleIntervalMinutes * 60 + config.imamScheduleDurationSeconds
  positionInCycle   = secondsSinceStart % cycleLength

WINDOW CHECK:
  if positionInCycle >= config.imamScheduleDurationSeconds → skip (dalam interval jeda)

RETURN ImamScheduleState:
  dayName              = nama hari (dari now.weekday)
  hijriDate            = dailyPrayerTimes.hijriDate
  slots                = todaySchedule
  currentTime          = now
  totalDurationSeconds = config.imamScheduleDurationSeconds
  remainingSeconds     = config.imamScheduleDurationSeconds - positionInCycle
```

### Referensi Dokumen

- [plan/feature-wisdom-quote-1.md](feature-wisdom-quote-1.md) — Referensi pola state machine + evaluator
- [plan/feature-slideshow-pengumuman-1.md](feature-slideshow-pengumuman-1.md) — Referensi pola Settings UI + display layout
- [spec/spec-process-state-machine.md](../spec/spec-process-state-machine.md)
- [spec/spec-schema-database.md](../spec/spec-schema-database.md)
