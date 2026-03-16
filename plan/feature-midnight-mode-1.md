---
goal: "Implementasi Mode Hemat Daya Tengah Malam (Midnight Screensaver)"
version: 1.0
date_created: 2026-03-16
last_updated: 2026-03-16
owner: "Gulajava Ministudio"
status: "Planned"
tags: [feature, display, power-saving, screensaver, state-machine, settings]
---

## Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

Dokumen ini mendefinisikan rencana implementasi fitur **Mode Hemat Daya Tengah Malam** (*Midnight Screensaver*) untuk aplikasi Miqotul Khoir TV. Fitur ini menampilkan layar hitam hemat daya dengan informasi esensial (jam + jadwal Subuh) pada jam-jam malam saat masjid kosong, sekaligus mencegah *screen burn-in* melalui animasi pergeseran teks yang lambat. Fitur ini bersifat opsional, default OFF, dan DKM memiliki kendali penuh melalui menu Pengaturan.

Referensi PRD: [prd-plan-midnight-feature.md](prd-plan-midnight-feature.md)

## 1. Requirements & Constraints

- **REQ-001**: Tambahkan state baru `midnightStandby` pada `DisplayStateType` enum dan `MidnightStandbyState` sealed class pada `DisplayState`.
- **REQ-002**: Fitur dikendalikan oleh toggle utama `isMidnightModeEnabled` (default: `false` / OFF).
- **REQ-003**: DKM dapat mengatur `midnightStartHour`, `midnightStartMinute` (default: 23:00) dan `midnightEndHour`, `midnightEndMinute` (default: 03:30).
- **REQ-004**: Evaluasi pemicu hanya berjalan jika toggle utama AKTIF.
- **REQ-005**: Saat `now` berada dalam window midnight, state machine otomatis beralih ke `MidnightStandbyState` — **kecuali** jika sedang ada siklus sholat aktif (PreAdzan/Adzan/Iqomah/Sholat tetap didahulukan).
- **REQ-006**: Saat `now` melewati `Jam Berakhir`, state machine otomatis kembali ke `StandbyState`.
- **REQ-007**: Layout midnight menampilkan background hitam mutlak (`#000000`), jam digital (HH:mm) besar berwarna putih/hijau redup, dan info jadwal Subuh.
- **REQ-008**: Blok teks harus melayang/berpindah posisi secara berkala dan lambat (durasi transisi ~10-15 detik) untuk anti burn-in.
- **REQ-009**: Running text (marquee), timer countdown, dan animasi berat di-suspend selama mode ini aktif.
- **REQ-010**: Tombol OK/Enter/Escape pada remote TV harus tetap bisa membuka halaman Pengaturan saat mode ini aktif (escape hatch sudah ada di `MainDisplayPage`).
- **REQ-011**: Data konfigurasi disimpan di SQLite (tabel `settings`) dan di-load via `TransitionConfig`.

- **SEC-001**: Tidak ada data sensitif baru yang diperkenalkan. Konfigurasi menggunakan mekanisme penyimpanan yang sudah ada (`SettingsRepository`).

- **CON-001**: Window waktu midnight bisa **cross-midnight** (misal 23:00 → 03:30). Logic perbandingan waktu harus menangani kasus hari berganti, berbeda dari Wisdom Quote window yang selalu dalam satu hari.
- **CON-002**: Evaluasi midnight window disisipkan di `EvaluateDisplayStateUseCase.evaluate()` — **setelah** pengecekan siklus sholat (PreAdzan→Sholat) tapi **sebelum** pengecekan Wisdom Quote dan fallback Standby.
- **CON-003**: DB migration ke version 8 menggunakan pattern `ALTER TABLE` yang konsisten dengan migration sebelumnya (v2–v7).
- **CON-004**: `DisplayStateCubit._tick()` tetap polling setiap 1 detik — midnight mode tidak mengubah interval ini.

- **GUD-001**: Ikuti pattern fitur Wisdom Quote untuk integrasi Settings (entity → model → data source → repository → cubit → UI section).
- **GUD-002**: `MidnightStandbyLayout` sebaiknya menggunakan `OverflowBox` untuk fullscreen hitam (pattern dari `SholatLayout`).
- **GUD-003**: Timer animasi drift posisi teks harus self-contained di dalam `MidnightStandbyLayout` (pattern `DigitalClockWidget` — timer internal, bukan dari parent).
- **GUD-004**: `buildWhen` pada `BlocBuilder` di `MainDisplayPage` tidak perlu optimasi khusus untuk `midnightStandby` — cukup selalu rebuild (sama seperti state countdown lainnya, karena `currentTime` berubah tiap detik untuk memperbarui tampilan **jam digital**). Animasi drift posisi teks bersifat self-contained dan tidak bergantung pada rebuild dari parent (lihat GUD-003).
- **GUD-005**: **D-Pad Toggle Pattern** — Toggle "Aktifkan" menggunakan `FocusableWidget(onSelect: () => cubit.updateMidnightModeEnabled(!settings.isMidnightModeEnabled))`. `Switch.adaptive` di dalam boks toggle bersifat **visual-only** (`onChanged: null`), tidak menerima focus D-Pad. Pattern identik dengan `WisdomQuoteSection`.
- **GUD-006**: **D-Pad Stepper Disable Pattern** — Keempat `DPadStepper` waktu dibungkus satu blok `ExcludeFocus(excluding: !isMidnightModeEnabled)` + `IgnorePointer(ignoring: !isMidnightModeEnabled)` + `Opacity(opacity: enabled ? 1.0 : 0.4)`. Jam + Menit di-pair dalam `Row([Expanded(DPadStepper(...)), SizedBox(width: 16.w), Expanded(DPadStepper(step: 5, ...))])`. Pattern identik dengan `WisdomQuoteSection`.

- **PAT-001**: Sealed class pattern — `MidnightStandbyState` extends `DisplayState`, Dart exhaustive switch memberikan compile-time safety.
- **PAT-002**: Cross-midnight time comparison: `if (start > end) → now >= start || now < end`.
- **PAT-003**: Anti burn-in drift — `AnimationController` + `Tween` menggerakkan `Alignment` blok teks secara periodik dan random.

## 2. Implementation Steps

### Phase 1 — Domain Layer: Entity & Use Case

- GOAL-001: Menambahkan `MidnightStandbyState` ke state machine dan logic evaluasi midnight window pada use case.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Tambahkan value `midnightStandby` di `DisplayStateType` enum (`lib/domain/entities/display_state_type.dart`). | | |
| TASK-002 | Buat class `MidnightStandbyState extends DisplayState` di `lib/domain/entities/display_state.dart` dengan field: `currentTime` (DateTime), `subuhTime` (DateTime), `subuhLabel` (String). Property `type` return `DisplayStateType.midnightStandby`. | | |
| TASK-003 | Tambahkan 5 field midnight ke `Settings` entity (`lib/domain/entities/settings.dart`): `isMidnightModeEnabled` (bool, default false), `midnightStartHour` (int, default 23), `midnightStartMinute` (int, default 0), `midnightEndHour` (int, default 3), `midnightEndMinute` (int, default 30). Update `copyWith()`, `props`, dan constructor defaults. | | |
| TASK-004 | Tambahkan 5 field midnight ke `TransitionConfig` (`lib/domain/entities/transition_config.dart`): `isMidnightModeEnabled`, `midnightStartHour`, `midnightStartMinute`, `midnightEndHour`, `midnightEndMinute`. Update `fromSettings()` factory, constructor, dan `props`. | | |
| TASK-005 | Tambahkan method `_evaluateMidnightWindow()` di `EvaluateDisplayStateUseCase` (`lib/domain/usecases/evaluate_display_state_use_case.dart`). Method menerima `now`, `config`, `dailyPrayerTimes`. Return `MidnightStandbyState` jika `isMidnightModeEnabled == true` DAN `now` berada dalam window (cross-midnight safe). Return `null` jika tidak. Ambil jadwal Subuh dari `dailyPrayerTimes` untuk field `subuhTime` dan `subuhLabel`. | | |
| TASK-006 | Panggil `_evaluateMidnightWindow()` di method `evaluate()` — sisipkan **setelah** loop `for (final prayer in mainPrayers)` (setelah semua pengecekan siklus sholat) tapi **sebelum** pengecekan Wisdom Quote (`_evaluateWisdomWindow`). Jika return non-null, langsung return hasilnya. | | |
| TASK-007 | Tulis unit test untuk `_evaluateMidnightWindow` di `test/domain/usecases/evaluate_display_state_use_case_test.dart`. Skenario: (a) fitur OFF → return null, (b) fitur ON + dalam window 23:00–03:30 → return `MidnightStandbyState`, (c) fitur ON + di luar window → return null, (d) fitur ON + dalam window TAPI siklus sholat aktif (misal Isya Adzan jam 19:15) → siklus sholat didahulukan, (e) cross-midnight boundary test (23:59 → 00:01), (f) window non-cross-midnight (misal 01:00–03:00). | | |

### Phase 2 — Data Layer: Database & Model

- GOAL-002: Memperluas schema SQLite, model, dan data source untuk menyimpan konfigurasi midnight mode.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-008 | Naikkan `_databaseVersion` dari `7` ke `8` di `DatabaseHelper` (`lib/data/datasources/database_helper.dart`). | | |
| TASK-009 | Tambahkan migration block `if (oldVersion < 8)` di `_onUpgrade()` dengan 5 `ALTER TABLE settings ADD COLUMN`: `is_midnight_mode_enabled INTEGER NOT NULL DEFAULT 0`, `midnight_start_hour INTEGER NOT NULL DEFAULT 23`, `midnight_start_minute INTEGER NOT NULL DEFAULT 0`, `midnight_end_hour INTEGER NOT NULL DEFAULT 3`, `midnight_end_minute INTEGER NOT NULL DEFAULT 30`. | | |
| TASK-010 | Tambahkan 5 kolom yang sama di DDL `_createTables()` (blok `CREATE TABLE settings`) untuk fresh install. | | |
| TASK-011 | Update `SettingsModel` (`lib/data/models/settings_model.dart`): tambah 5 field midnight di constructor `super.*`, `fromMap()` mapping (snake_case → camelCase, int→bool untuk `is_midnight_mode_enabled`), dan `toMap()` mapping (camelCase → snake_case, bool→int). | | |
| TASK-012 | Update unit test `SettingsModel` (`test/data/models/settings_model_test.dart`): tambahkan assertion untuk 5 field midnight baru di test `fromMap`, `toMap`, dan round-trip. | | |

### Phase 3 — Presentation Layer: Cubit Update

- GOAL-003: Menambahkan method update midnight settings di SettingsCubit dan memastikan DisplayStateCubit memproses config baru.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-013 | Tambahkan 5 method update di `SettingsCubit` (`lib/presentation/cubits/settings/settings_cubit.dart`): `updateMidnightModeEnabled(bool)` — menggunakan `_saveField` dengan `triggerConfigUpdate: true`; `updateMidnightStartHour(int)`, `updateMidnightStartMinute(int)`, `updateMidnightEndHour(int)`, `updateMidnightEndMinute(int)` — menggunakan `_debounceSave` dengan `triggerConfigUpdate: true`. | | |
| TASK-014 | Verifikasi bahwa `DisplayStateCubit.onSettingsChanged()` sudah memanggil `_loadConfig()` → `TransitionConfig.fromSettings()` → `_tick()`. Tidak perlu modifikasi jika flow ini sudah ada (konfirmasi saja). | | |
| TASK-015 | Tulis unit test untuk `SettingsCubit` method baru di `test/presentation/cubits/settings/settings_cubit_test.dart`: (a) `updateMidnightModeEnabled` toggle ON/OFF persists ke repository, (b) `updateMidnightStartHour` debounce save, (c) verifikasi `triggerConfigUpdate` dipanggil. | | |

### Phase 4 — Presentation Layer: UI Layout (Midnight Screensaver)

- GOAL-004: Membuat widget `MidnightStandbyLayout` dengan layar hitam, jam digital, info Subuh, dan anti burn-in drift animation.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-016 | Buat file `lib/presentation/pages/main_display/layouts/midnight_standby_layout.dart`. Widget `MidnightStandbyLayout` sebagai `StatefulWidget` menerima prop `MidnightStandbyState state`. | | |
| TASK-017 | Implementasi layout: `OverflowBox` fullscreen (pattern `SholatLayout`) → `Container(color: Colors.black)` → `AnimatedBuilder(animation: _driftAnimation, builder: (_, __) => Align(alignment: _driftAnimation.value, child: Column([...])))` berisi jam digital (`DigitalClockWidget` dengan custom style putih/hijau redup, opacity 0.85) dan teks info Subuh ("Subuh - HH:mm"). Gunakan `AnimatedBuilder` + `Align` (bukan `AnimatedAlign`) agar posisi dikontrol penuh oleh `AnimationController` eksplisit dari TASK-018. | | |
| TASK-018 | Implementasi anti burn-in drift: `AnimationController` di `initState()` dengan duration ~30 detik, repeat mode `reverse`. Gunakan `Tween<Alignment>` untuk menggerakkan posisi blok teks secara acak dalam batas layar. Seed posisi awal random deterministik (berdasarkan waktu). Transisi harus sangat lambat dan halus (~10-15 detik per gerakan). | | |
| TASK-019 | Pastikan `MidnightStandbyLayout` TIDAK merender running text, countdown timer, atau background glassmorphism — hanya layar hitam + content minimal. Ini otomatis terjadi karena widget hanya digunakan saat state `midnightStandby`. | | |
| TASK-020 | Tulis widget test di `test/presentation/pages/main_display/layouts/midnight_standby_layout_test.dart`: (a) verifikasi Container hitam fullscreen rendered, (b) verifikasi jam digital ditampilkan, (c) verifikasi info Subuh ditampilkan dengan waktu yang benar, (d) verifikasi AnimationController initialized dan running. | | |

### Phase 5 — Presentation Layer: Main Display Integration

- GOAL-005: Mengintegrasikan `MidnightStandbyState` ke dalam switch-case `MainDisplayPage` dan memastikan AnimatedSwitcher transisi halus.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-021 | Tambahkan case `DisplayStateType.midnightStandby` di `switch (state.type)` pada `MainDisplayPage` (`lib/presentation/pages/main_display_page.dart`). Assign `layoutWidget = MidnightStandbyLayout(key: const ValueKey('midnight_standby'), state: state as MidnightStandbyState)`. | | |
| TASK-022 | Import `midnight_standby_layout.dart` di `main_display_page.dart`. | | |
| TASK-023 | Verifikasi bahwa `onKeyEvent` handler (OK/Enter/Escape → `_openSettings()`) tetap berfungsi saat `MidnightStandbyState` aktif. Handler berada di level parent, jadi seharusnya tidak terpengaruh — konfirmasi melalui manual test atau widget test. | | |
| TASK-024 | Tulis widget test integrasi di `test/presentation/pages/main_display_page_test.dart`: (a) saat cubit emit `MidnightStandbyState`, pastikan `MidnightStandbyLayout` rendered, (b) tekan key OK → navigasi ke Settings tetap jalan. | | |

### Phase 6 — Presentation Layer: Settings UI Section

- GOAL-006: Membuat section baru di halaman Pengaturan untuk mengontrol Mode Hemat Daya Malam.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-025 | Buat file `lib/presentation/pages/settings/sections/midnight_mode_section.dart`. Widget `MidnightModeSection` sebagai `StatelessWidget`, menggunakan `BlocBuilder<SettingsCubit, SettingsState>`. Ikuti struktur `WisdomQuoteSection` secara langsung. Lihat wireframe di **Section 3** dokumen ini. | | |
| TASK-026 | Implementasi UI section sesuai wireframe Section 3: **(a)** Toggle row: `FocusableWidget(autofocus: true, onSelect: () => cubit.updateMidnightModeEnabled(!s.isMidnightModeEnabled), builder: (f) => Container(border: f ? goldAmber : glassBorder, child: Row([Text('Aktifkan...'), Switch.adaptive(value: s.isMidnightModeEnabled, onChanged: null)])))`. **(b)** Jam Mulai + Menit Mulai: `Row([Expanded(DPadStepper(label:'Jam Mulai', value:s.midnightStartHour, maxValue:23, onChanged:cubit.updateMidnightStartHour)), SizedBox(width:16.w), Expanded(DPadStepper(label:'Menit', value:s.midnightStartMinute, maxValue:59, step:5, onChanged:cubit.updateMidnightStartMinute))])`. **(c)** Jam Berakhir + Menit Berakhir dengan Row identik. **(d)** Area keempat stepper dibungkus: `ExcludeFocus(excluding: !s.isMidnightModeEnabled, child: IgnorePointer(ignoring: !s.isMidnightModeEnabled, child: Opacity(opacity: s.isMidnightModeEnabled ? 1.0 : 0.4, child: Column([...]))))`. **(e)** Info bar: `'ℹ Aktif setiap hari: ${h(s.midnightStartHour)}:${m(s.midnightStartMinute)} – ${h(s.midnightEndHour)}:${m(s.midnightEndMinute)}'` dengan helper `h/m` = `n.toString().padLeft(2,'0')`. | | |
| TASK-027 | Daftarkan `MidnightModeSection` di `SettingsMenuPage` (`lib/presentation/pages/settings/settings_menu_page.dart`): (a) Tambahkan string "Mode Hemat Daya" di `_categories` list (sebelum "Reset Data"), (b) Tambahkan `const MidnightModeSection()` di `_sections` list pada posisi yang sama, (c) Import file section baru. | | |
| TASK-028 | Tulis widget test di `test/presentation/pages/settings/sections/midnight_mode_section_test.dart`: (a) toggle ON/OFF memanggil `updateMidnightModeEnabled`, (b) stepper jam mulai/berakhir visible dan interactable, (c) stepper disabled saat toggle OFF. | | |

### Phase 7 — Testing & Integration Verification

- GOAL-007: Memastikan seluruh fitur terintegrasi dengan benar melalui test komprehensif dan verifikasi manual.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-029 | Jalankan seluruh test suite (`flutter test`) dan pastikan tidak ada regresi pada test yang sudah ada — terutama `evaluate_display_state_use_case_test.dart` dan `display_state_cubit_test.dart`. | | |
| TASK-030 | Verifikasi skenario end-to-end: (a) Kondisi bawaan — fitur OFF, layar tidak berubah saat tengah malam, (b) Aktifkan fitur + set 23:00–03:30, layar hitam muncul saat jam masuk window, (c) Jam melewati 03:30 → kembali ke Standby, (d) Saat midnight mode aktif tapi ada sholat Isya → siklus sholat didahulukan, (e) Tekan OK saat layar hitam → Settings terbuka. | | |
| TASK-031 | Update `AGENTS.md` di section "Completed Features" untuk menambahkan entry fitur Midnight Mode setelah semua task selesai. | | |

## 3. Settings UI Mockup

*Wireframe ASCII* untuk Settings section **Mode Hemat Daya Malam** (`midnight_mode_section.dart`) di dalam `SettingsMenuPage`:

```
┌──────────────────────────────────────────────────────────────────────┐
│  PENGATURAN                                                           │
│  ┌──────────────────────┐  ┌──────────────────────────────────────┐  │
│  │ ...                  │  │  🌙  Mode Hemat Daya Malam           │  │
│  │ Kata Mutiara         │  │                                      │  │
│  │▶ Mode Hemat Daya    │  │  ┌──────────────────────────────┐   │  │
│  │ Reset Data           │  │  │ Aktifkan Mode Hemat Daya     │   │  │  ← FocusableWidget (toggle)
│  │ Tentang Aplikasi     │  │  │                    [ ON  ]   │   │  │
│  └──────────────────────┘  │  └──────────────────────────────┘   │  │
│                             │  ── Konfigurasi Waktu ─────────────  │  │
│                             │  ┌────────────────┐ ┌────────────┐  │  │
│                             │  │  Jam Mulai     │ │ Menit Mulai│  │  │  ← Row([Expanded, SizedBox(16.w), Expanded])
│                             │  │  [◀]  23  [▶]  │ │ [◀] 00 [▶]│  │  │  ← DPadStepper (step:1 / step:5)
│                             │  └────────────────┘ └────────────┘  │  │
│                             │  ┌────────────────┐ ┌────────────┐  │  │
│                             │  │  Jam Berakhir  │ │ Mnt Berakhir│  │  │  ← step:5 untuk Menit
│                             │  │  [◀]   3  [▶]  │ │ [◀] 30 [▶]│  │  │
│                             │  └────────────────┘ └────────────┘  │  │
│                             │  ℹ Aktif setiap hari: 23:00–03:30  │  │
│                             └──────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### Catatan Penting D-Pad (Android TV)

1. **Toggle Row — `FocusableWidget`**: Baris "Aktifkan Mode Hemat Daya" adalah satu `FocusableWidget` penuh. `Switch.adaptive` di dalamnya adalah **visual-only** (`onChanged: null`). Aksi toggle dipicu oleh `FocusableWidget.onSelect` → `cubit.updateMidnightModeEnabled(!settings.isMidnightModeEnabled)`. Pattern identik dengan toggle di `WisdomQuoteSection`.

2. **Konfigurasi Jam/Menit — Pair Pattern**: Setiap pasang Jam + Menit menggunakan satu `Row([Expanded(DPadStepper(label:'Jam...', maxValue:23)), SizedBox(width:16.w), Expanded(DPadStepper(label:'Menit...', maxValue:59, step:5))])`. Parameter `step:5` pada menit mengikuti pattern `WisdomQuoteSection`.

3. **Disable Area saat Toggle OFF**: Keempat `DPadStepper` dibungkus dalam satu blok `ExcludeFocus(excluding: !enabled)` + `IgnorePointer(ignoring: !enabled)` + `Opacity(opacity: enabled ? 1.0 : 0.4)`. Ini mencegah D-Pad traverse ke stepper saat mode OFF — identik dengan `WisdomQuoteSection`.

4. **Info Bar Dinamis**: Teks "ℹ Aktif setiap hari: HH:mm – HH:mm" dirender dari `settings.midnight*` fields dengan `n.toString().padLeft(2,'0')`. Selalu tampil (tidak conditional) agar DKM selalu tahu konfigurasi aktif.

5. **FocusTraversal Order**: Toggle (`autofocus: true`) → Jam Mulai → Menit Mulai → Jam Berakhir → Menit Berakhir. Urutan natural top-to-bottom, left-to-right via `ReadingOrderTraversalPolicy` default Flutter.

## 4. Alternatives

- **ALT-001**: **Timer terpisah (bukan evaluasi di use case)** — Menggunakan `Timer` khusus di `DisplayStateCubit` yang hanya aktif saat fitur ON, alih-alih mengevaluasi setiap detik di `EvaluateDisplayStateUseCase`. Ditolak karena: (a) menambah kompleksitas lifecycle timer, (b) melanggar prinsip single-source-of-truth untuk state evaluation, (c) race condition potensial antara timer midnight dan timer tick utama.
- **ALT-002**: **Mematikan TV via CEC command** — Alih-alih menampilkan layar hitam, kirim perintah CEC untuk mematikan TV. Ditolak karena: (a) tidak semua Android TV box mendukung CEC, (b) mematikan TV menghilangkan fungsionalitas bagi jamaah qiyamullail/i'tikaf, (c) menyalakan kembali TV memerlukan interaksi fisik.
- **ALT-003**: **Reuse `SholatLayout` untuk midnight mode** — Tidak membuat layout baru, cukup extend `SholatState` dengan duration sangat panjang. Ditolak karena: (a) `SholatState` memiliki countdown yang tidak relevan untuk midnight mode, (b) midnight mode perlu info Subuh dan anti burn-in drift yang tidak ada di `SholatLayout`, (c) melanggar Single Responsibility Principle.

## 5. Dependencies

- **DEP-001**: `DisplayStateType` enum — file `lib/domain/entities/display_state_type.dart` (existing, akan dimodifikasi).
- **DEP-002**: `DisplayState` sealed class — file `lib/domain/entities/display_state.dart` (existing, akan dimodifikasi).
- **DEP-003**: `Settings` entity — file `lib/domain/entities/settings.dart` (existing, akan dimodifikasi).
- **DEP-004**: `TransitionConfig` — file `lib/domain/entities/transition_config.dart` (existing, akan dimodifikasi).
- **DEP-005**: `EvaluateDisplayStateUseCase` — file `lib/domain/usecases/evaluate_display_state_use_case.dart` (existing, akan dimodifikasi).
- **DEP-006**: `DatabaseHelper` — file `lib/data/datasources/database_helper.dart` (existing, migration v8).
- **DEP-007**: `SettingsModel` — file `lib/data/models/settings_model.dart` (existing, akan dimodifikasi).
- **DEP-008**: `SettingsCubit` — file `lib/presentation/cubits/settings/settings_cubit.dart` (existing, akan dimodifikasi).
- **DEP-009**: `MainDisplayPage` — file `lib/presentation/pages/main_display_page.dart` (existing, 1 case baru).
- **DEP-010**: `SettingsMenuPage` — file `lib/presentation/pages/settings/settings_menu_page.dart` (existing, 1 entry baru).
- **DEP-011**: `DigitalClockWidget` — file `lib/presentation/widgets/digital_clock_widget.dart` (existing, reuse as-is).
- **DEP-012**: `DPadStepper` — file `lib/presentation/widgets/dpad_stepper.dart` (existing, reuse di Settings section).
- **DEP-013**: `FocusableWidget` — file `lib/presentation/widgets/focusable_widget.dart` (existing, reuse di Settings section).
- **DEP-014**: Tidak ada dependency package baru yang perlu ditambahkan. Semua animasi menggunakan Flutter SDK bawaan (`AnimationController`, `AnimatedAlign`).

## 6. Files

- **FILE-001**: `lib/domain/entities/display_state_type.dart` — Tambah enum value `midnightStandby`.
- **FILE-002**: `lib/domain/entities/display_state.dart` — Tambah class `MidnightStandbyState`.
- **FILE-003**: `lib/domain/entities/settings.dart` — Tambah 5 field midnight, update `copyWith()` dan `props`.
- **FILE-004**: `lib/domain/entities/transition_config.dart` — Tambah 5 field midnight, update `fromSettings()` dan `props`.
- **FILE-005**: `lib/domain/usecases/evaluate_display_state_use_case.dart` — Tambah method `_evaluateMidnightWindow()` dan panggil di `evaluate()`.
- **FILE-006**: `lib/data/datasources/database_helper.dart` — DB version 8, migration `_onUpgrade`, DDL `_createTables`.
- **FILE-007**: `lib/data/models/settings_model.dart` — Update constructor, `fromMap()`, `toMap()`.
- **FILE-008**: `lib/presentation/cubits/settings/settings_cubit.dart` — Tambah 5 method update midnight.
- **FILE-009**: `lib/presentation/pages/main_display/layouts/midnight_standby_layout.dart` — **FILE BARU** — Layout screensaver midnight.
- **FILE-010**: `lib/presentation/pages/main_display_page.dart` — Tambah case `midnightStandby` di switch + import.
- **FILE-011**: `lib/presentation/pages/settings/sections/midnight_mode_section.dart` — **FILE BARU** — Settings section.
- **FILE-012**: `lib/presentation/pages/settings/settings_menu_page.dart` — Tambah entry menu + import.
- **FILE-013**: `test/domain/usecases/evaluate_display_state_use_case_test.dart` — Tambah test group midnight.
- **FILE-014**: `test/data/models/settings_model_test.dart` — Update assertion untuk 5 field baru.
- **FILE-015**: `test/presentation/cubits/settings/settings_cubit_test.dart` — Tambah test method midnight.
- **FILE-016**: `test/presentation/pages/main_display/layouts/midnight_standby_layout_test.dart` — **FILE BARU** — Widget test layout.
- **FILE-017**: `test/presentation/pages/main_display_page_test.dart` — Tambah test case midnight state.
- **FILE-018**: `test/presentation/pages/settings/sections/midnight_mode_section_test.dart` — **FILE BARU** — Widget test section.

## 7. Testing

- **TEST-001**: Unit test `EvaluateDisplayStateUseCase` — 6 skenario midnight window (TASK-007): fitur OFF, dalam window, di luar window, siklus sholat prioritas, cross-midnight boundary, window non-cross-midnight.
- **TEST-002**: Unit test `SettingsModel` — Round-trip 5 field midnight baru (TASK-012).
- **TEST-003**: Unit test `SettingsCubit` — Toggle enable/disable, debounce save jam, trigger config update (TASK-015).
- **TEST-004**: Widget test `MidnightStandbyLayout` — Render hitam fullscreen, jam digital, info Subuh, animation controller (TASK-020).
- **TEST-005**: Widget test `MainDisplayPage` integration — `MidnightStandbyState` → layout rendered, key press escape hatch (TASK-024).
- **TEST-006**: Widget test `MidnightModeSection` — Toggle, stepper visible/disabled, value changes (TASK-028).
- **TEST-007**: Regression test — Seluruh existing test suite tetap passing setelah modifikasi (TASK-029).
- **TEST-008**: End-to-end manual verification — 5 skenario dari PRD (TASK-030).

## 8. Risks & Assumptions

- **RISK-001**: **Cross-midnight logic error** — Window 23:00→03:30 melewati pergantian hari. Jika logic salah mengevaluasi tanggal, fitur bisa tidak aktif atau aktif terus-menerus. *Mitigasi*: Unit test khusus untuk boundary 23:59→00:01 dan edge case 00:00 tepat.
- **RISK-002**: **AnimationController memory leak** — Jika `dispose()` tidak dipanggil dengan benar saat state berganti dari `midnightStandby` ke state lain, animation controller bisa leak. *Mitigasi*: `AnimatedSwitcher` di `MainDisplayPage` otomatis menghancurkan widget lama → `dispose()` terpanggil.
- **RISK-003**: **Midnight mode konflik dengan Wisdom Quote window** — Jika Wisdom Quote window overlap dengan midnight window (misal wisdom 06:00–23:30, midnight 23:00–03:30), ada overlap 30 menit. *Mitigasi*: CON-002 memastikan midnight dievaluasi lebih dulu (prioritas lebih tinggi dari wisdom). Midnight menang pada window overlap.
- **RISK-004**: **Screen burn-in pada teks drift yang terlalu lambat** — Jika animasi terlalu lambat atau range drift terlalu kecil, teks masih bisa menyebabkan burn-in. *Mitigasi*: Range drift harus mencakup setidaknya 60-70% area layar, durasi 1 siklus penuh ~30 detik.

- **ASSUMPTION-001**: Jam sistem Android TV akurat (NTP sync aktif). Fitur bergantung pada `DateTime.now()` yang sudah menjadi asumsi seluruh state machine.
- **ASSUMPTION-002**: DKM memahami bahwa default OFF berarti fitur tidak aktif sampai mereka mengonfigurasinya secara eksplisit.
- **ASSUMPTION-003**: `DigitalClockWidget` yang sudah ada dapat digunakan kembali dengan custom style (warna putih/hijau redup) tanpa modifikasi widget itu sendiri.

## 9. Related Specifications / Further Reading

- [PRD: Mode Hemat Daya Tengah Malam](prd-plan-midnight-feature.md)
- [Spec: Display State Machine](../spec/spec-process-state-machine.md)
- [Spec: Database Schema](../spec/spec-schema-database.md)
- [Spec: Settings Process](../spec/spec-process-settings.md)
- [Plan: Wisdom Quote Feature (pattern reference)](feature-wisdom-quote-1.md)
