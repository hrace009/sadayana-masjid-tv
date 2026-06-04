---
applyTo: "**"
---

## Project Overview

<!-- markdownlint-disable -->

**Project**: Miqotul Khoir TV (MKT) — Aplikasi jam masjid digital & jadwal sholat untuk Android TV

| Field        | Value                                                                                                                         |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| **Platform** | Android TV (API 24+, landscape locked)                                                                                        |
| **Stack**    | Flutter + Dart 3, Cubit/BLoC, SQLite offline                                                                                  |
| **Version**  | 2.2.0                                                                                                                         |
| **Updated**  | 2026-06-04                                                                                                                    |
| **Related**  | [ARCHITECTURE_PATTERNS.md](docs/ARCHITECTURE_PATTERNS.md), [Product_Requirement_Document.md](Product_Requirement_Document.md) |

### Display State Priority Order

`prayer` → `midnight` → `slideshow` → `imam_schedule` → `wisdom` → `standby`

---

## Completed Features (Production Ready)

| Feature                                              | Completion Date | Tests                           | Status           |
| ---------------------------------------------------- | --------------- | ------------------------------- | ---------------- |
| **Database Infrastructure** (Plan 01)                | 2026-02-18      | 6 unit tests ✅                 | Production Ready |
| **Data Layer** (Plan 02)                             | 2026-02-18      | 16 unit tests ✅ (total: 22)    | Production Ready |
| **Theme System** (Plan 03)                           | 2026-02-18      | 42 unit tests ✅ (total: 64)    | Production Ready |
| **Prayer Time Logic** (Plan 05)                      | 2026-02-19      | Unit tests ✅                   | Production Ready |
| **Prayer Time State** (Plan 06)                      | 2026-02-19      | Cubit tests ✅                  | Production Ready |
| **Display State Logic** (Plan 07)                    | 2026-02-19      | Unit tests ✅                   | Production Ready |
| **Display State Machine** (Plan 08)                  | 2026-02-19      | Cubit tests ✅                  | Production Ready |
| **Setup Wizard Logic** (Plan 09)                     | 2026-02-20      | Cubit tests ✅                  | Production Ready |
| **Setup Wizard UI** (Plan 10)                        | 2026-02-20      | Widget tests ✅                 | Production Ready |
| **Settings Logic** (Plan 11)                         | 2026-02-20      | Unit tests ✅                   | Production Ready |
| **Settings UI** (Plan 12)                            | 2026-02-20      | Widget tests ✅                 | Production Ready |
| **Main Display UI** (Plan 13)                        | 2026-02-20      | Widget tests ✅                 | Production Ready |
| **Kata Mutiara Islam** (Wisdom Quote)                | 2026-03-10      | 14 phases, 257 total tests ✅   | Production Ready |
| **Mode Hemat Daya Tengah Malam** (Midnight Mode)     | 2026-03-16      | 7 phases, 306 total tests ✅    | Production Ready |
| **Alarm Tanda Waktu** (Pre-Adzan & Pre-Iqomah Alert) | 2026-03-17      | 6 phases, 20 new alarm tests ✅ | Production Ready |
| **Slideshow Pengumuman** (Announcement)              | 2026-05-08      | 8 phases, file_picker v11 ✅    | Production Ready |
| **Jadwal Imam Sholat Berjamaah** (Imam Schedule)     | 2026-05-25      | 10 phases, 98 total tests ✅    | Production Ready |

> **Note**: Plan 04 tidak ada — nomor plan tersebut di-skip dalam dokumen perencanaan proyek.

---

## Feature Implementation Details

Detail file, dependencies, dan lessons learned per fitur, diurutkan kronologis.

### Plan 01 — Database Infrastructure (2026-02-18)

| File                                              | Keterangan                                                              |
| ------------------------------------------------- | ----------------------------------------------------------------------- |
| `lib/data/datasources/database_helper.dart`       | Singleton `DatabaseHelper` — schema DDL, seed, migration, testing hooks |
| `assets/data/cities.json`                         | 514 kota/kabupaten, 34 provinsi Indonesia (71.7 KB)                     |
| `tools/generate_cities.py`                        | Script generator dataset kota dari BPS/wilayah-indonesia                |
| `test/data/datasources/database_helper_test.dart` | 6 unit tests dengan `sqflite_common_ffi` in-memory                      |

```yaml
dependencies:
  sqflite: ^2.4.1
  path: ^1.9.1
dev_dependencies:
  sqflite_common_ffi: ^2.4.0+2
```

### Plan 02 — Data Layer (2026-02-18)

File yang dibuat:

| File                                                        | Keterangan                                                              |
| ----------------------------------------------------------- | ----------------------------------------------------------------------- |
| `lib/domain/entities/settings.dart`                         | Immutable `Settings` entity — 27 fields, `Equatable`, `copyWith()`      |
| `lib/domain/entities/city.dart`                             | Immutable `City` entity — 5 fields, `Equatable`                         |
| `lib/domain/repositories/settings_repository.dart`          | Abstract `SettingsRepository` interface (zero infra imports)            |
| `lib/domain/repositories/city_repository.dart`              | Abstract `CityRepository` interface (zero infra imports)                |
| `lib/data/models/settings_model.dart`                       | `SettingsModel` — `fromMap`/`toMap`, snake_case ↔ camelCase, int ↔ bool |
| `lib/data/models/city_model.dart`                           | `CityModel` — `fromMap`/`toMap`                                         |
| `lib/data/datasources/settings_local_data_source.dart`      | SQLite ops — transactional writes, auto `updated_at`                    |
| `lib/data/datasources/city_local_data_source.dart`          | SQLite ops — LIKE search dengan input sanitization                      |
| `lib/data/repositories/settings_repository_impl.dart`       | Concrete impl — SHA-256 PIN hashing via `crypto`                        |
| `lib/data/repositories/city_repository_impl.dart`           | Concrete impl — pure delegation ke data source                          |
| `test/data/models/settings_model_test.dart`                 | 4 tests: fromMap default/custom, toMap, round-trip                      |
| `test/data/models/city_model_test.dart`                     | 3 tests: fromMap, toMap, round-trip                                     |
| `test/data/repositories/settings_repository_impl_test.dart` | 5 tests: defaults, update, firstRun, PIN lifecycle                      |
| `test/data/repositories/city_repository_impl_test.dart`     | 4 tests: provinces, citiesByProvince, search, getById                   |

```yaml
dependencies:
  equatable: 2.0.8 # Value equality untuk entities
  crypto: 3.0.7 # SHA-256 PIN hashing
```

### Plan 03 — Theme System (2026-02-18)

| File                                           | Keterangan                                                                   |
| ---------------------------------------------- | ---------------------------------------------------------------------------- |
| `lib/core/theme/islamic_colors.dart`           | 21 color constants — Primary, Accent, Background, Text, Glass, State, Prayer |
| `lib/core/theme/islamic_typography.dart`       | 7 text styles — Poppins font, `.sp` responsive, optional overrides           |
| `lib/core/theme/islamic_theme.dart`            | Material3 `ThemeData` — ColorScheme, TextTheme, AppBar, Card                 |
| `lib/core/theme/tv_safe_area.dart`             | `TVSafeArea` widget — 5% margin, `ignoreSafeArea` bypass                     |
| `lib/main.dart`                                | `ScreenUtilInit` (1920×1080), landscape lock, `IslamicTheme.darkTheme()`     |
| `test/core/theme/islamic_colors_test.dart`     | 15 tests: hex values, opacity validation, prayer state aliases               |
| `test/core/theme/islamic_typography_test.dart` | 10 tests: all 7 methods + optional parameter overrides                       |
| `test/core/theme/islamic_theme_test.dart`      | 17 tests: Material3, ColorScheme, TextTheme, AppBar, Card                    |

```yaml
dependencies:
  flutter_screenutil: ^5.9.3 # Responsive scaling (.sp, .w, .h, .r)
  google_fonts: ^8.0.2 # Poppins — bundled offline, allowRuntimeFetching = false
```

### Plan 05 — Prayer Time Calculation (2026-02-19)

| File                                                             | Keterangan             |
| ---------------------------------------------------------------- | ---------------------- |
| `lib/domain/usecases/calculate_prayer_times_use_case.dart`       | Core calculation logic |
| `lib/domain/entities/prayer_time.dart`                           | Entity definition      |
| `test/domain/usecases/calculate_prayer_times_use_case_test.dart` | Unit tests             |

Dependencies: `adhan`, `hijri`, `intl`

### Plan 06 — Prayer Time Cubit (2026-02-19)

| File                                                               | Keterangan       |
| ------------------------------------------------------------------ | ---------------- |
| `lib/presentation/cubits/prayer_time/prayer_time_cubit.dart`       | State management |
| `lib/presentation/cubits/prayer_time/prayer_time_state.dart`       | State definition |
| `test/presentation/cubits/prayer_time/prayer_time_cubit_test.dart` | Cubit tests      |

Dependencies: `flutter_bloc`, `bloc_test`, `mocktail`

### Plan 07 — State Evaluation (2026-02-19)

| File                                                             | Keterangan                  |
| ---------------------------------------------------------------- | --------------------------- |
| `lib/domain/usecases/evaluate_display_state_use_case.dart`       | Core state transition logic |
| `lib/domain/entities/display_state.dart`                         | Entity definition           |
| `test/domain/usecases/evaluate_display_state_use_case_test.dart` | Unit tests                  |

### Plan 08 — Display State Machine (2026-02-19)

| File                                                                   | Keterangan                   |
| ---------------------------------------------------------------------- | ---------------------------- |
| `lib/presentation/cubits/display_state/display_state_cubit.dart`       | State machine implementation |
| `lib/presentation/cubits/display_state/display_state.dart`             | State definition             |
| `test/presentation/cubits/display_state/display_state_cubit_test.dart` | Cubit tests                  |

### Plan 09 — Setup Wizard Logic (2026-02-20)

| File                                                                 | Keterangan       |
| -------------------------------------------------------------------- | ---------------- |
| `lib/presentation/cubits/setup_wizard/setup_wizard_cubit.dart`       | Setup flow logic |
| `lib/presentation/cubits/setup_wizard/setup_wizard_state.dart`       | Wizard states    |
| `test/presentation/cubits/setup_wizard/setup_wizard_cubit_test.dart` | Cubit tests      |

### Plan 10 — Setup Wizard UI (2026-02-20)

| File                                                               | Keterangan                                               |
| ------------------------------------------------------------------ | -------------------------------------------------------- |
| `lib/presentation/pages/setup_wizard/setup_wizard_page.dart`       | Root container, step navigation, step indicator          |
| `lib/presentation/pages/setup_wizard/steps/welcome_step.dart`      | Step 1: Branding & Welcome screen                        |
| `lib/presentation/pages/setup_wizard/steps/identity_step.dart`     | Step 2: Input Nama & Alamat Masjid                       |
| `lib/presentation/pages/setup_wizard/steps/location_step.dart`     | Step 3: Cascading Province → City Picker                 |
| `lib/presentation/pages/setup_wizard/steps/preview_step.dart`      | Step 4: Summary data & prayer time preview               |
| `lib/presentation/widgets/step_indicator_widget.dart`              | Visual progress indicator (1-4)                          |
| `lib/presentation/pages/splash_page.dart`                          | Startup logic: check `isFirstRun` → route to Wizard/Main |
| `test/presentation/pages/setup_wizard/setup_wizard_page_test.dart` | Comprehensive widget tests for all steps                 |

### Plan 11 — Settings Logic (2026-02-20)

| File                                                         | Keterangan                                                       |
| ------------------------------------------------------------ | ---------------------------------------------------------------- |
| `lib/presentation/cubits/settings/settings_cubit.dart`       | `SettingsCubit` implementasi auto-save & PIN logic               |
| `lib/presentation/cubits/settings/settings_state.dart`       | State definitions (Initial, Loading, Loaded, Error)              |
| `lib/presentation/cubits/settings/settings.dart`             | Barrel export file                                               |
| `test/presentation/cubits/settings/settings_cubit_test.dart` | Comprehensive unit tests (auto-save debounce, PIN, update logic) |

### Kata Mutiara Islam / Wisdom Quote (2026-03-10)

Fitur tampilan full-screen periodik dengan ayat Al-Quran dan Hadits. Menambahkan `WisdomQuoteState`
sebagai state ke-6 pada display state machine. 14 phase implementasi, 257 total tests.

File baru yang dibuat:

| File                                                                   | Keterangan                                                               |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `assets/data/wisdom_quotes.json`                                       | Katalog 11 item hardcoded (5 Quran + 6 Hadits)                           |
| `lib/domain/entities/wisdom_quote.dart`                                | Immutable entity — `id`, `type`, `label`, `translationText`, `reference` |
| `lib/domain/repositories/wisdom_quote_repository.dart`                 | Abstract interface                                                       |
| `lib/data/models/wisdom_quote_model.dart`                              | `fromJson()`, `toEntity()`                                               |
| `lib/data/datasources/wisdom_quote_local_data_source.dart`             | Loader JSON asset via `rootBundle`                                       |
| `lib/data/repositories/wisdom_quote_repository_impl.dart`              | Implementasi konkret                                                     |
| `lib/presentation/pages/main_display/layouts/wisdom_quote_layout.dart` | Layout full-screen — badge, translasi, referensi, progress bar           |
| `lib/presentation/pages/wisdom_preview_page.dart`                      | Halaman pratinjau item terpilih                                          |
| `lib/presentation/pages/settings/sections/wisdom_quote_section.dart`   | Section Settings UI — toggle, checklist, interval, durasi, waktu         |
| `lib/presentation/widgets/checklist_item_widget.dart`                  | Widget checklist reusable dengan badge tipe                              |

File yang dimodifikasi:

| File                                                             | Keterangan                                                      |
| ---------------------------------------------------------------- | --------------------------------------------------------------- |
| `lib/data/datasources/database_helper.dart`                      | Schema v7, migration DDL 9 kolom baru                           |
| `lib/data/models/settings_model.dart`                            | `fromMap`/`toMap` untuk 9 field wisdom                          |
| `lib/domain/entities/settings.dart`                              | 9 field baru (`isWisdomEnabled`, `wisdomIntervalMinutes`, dst.) |
| `lib/domain/entities/transition_config.dart`                     | 7 field wisdom + `fromSettings()` mapping                       |
| `lib/domain/entities/display_state_type.dart`                    | Tambah `wisdomQuote`                                            |
| `lib/domain/entities/display_state.dart`                         | Tambah `WisdomQuoteState`                                       |
| `lib/domain/usecases/evaluate_display_state_use_case.dart`       | Parameter `activeQuotes` + wisdom window logic                  |
| `lib/presentation/cubits/display_state/display_state_cubit.dart` | Load quotes, inject `activeQuotes` ke `evaluate()`              |
| `lib/presentation/pages/settings/settings_menu_page.dart`        | Tambah `WisdomQuoteSection` di categories                       |
| `lib/main.dart`                                                  | Instansiasi `WisdomQuoteRepositoryImpl`, `RepositoryProvider`   |

### Mode Hemat Daya Tengah Malam / Midnight Mode (2026-03-16)

Fitur screensaver hemat daya yang menampilkan layar hitam dengan jam digital dan jadwal Subuh
pada jam-jam malam. Menambahkan `MidnightStandbyState` sebagai state ke-7 pada display state machine.
Anti burn-in drift animation, konfigurasi window waktu cross-midnight. 7 phase, 306 total tests.

File baru yang dibuat:

| File                                                                             | Keterangan                                                                                     |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `lib/presentation/pages/main_display/layouts/midnight_standby_layout.dart`       | Layout screensaver — background hitam, jam digital hijau-redup, info Subuh, anti burn-in drift |
| `lib/presentation/pages/settings/sections/midnight_mode_section.dart`            | Section Settings UI — toggle, stepper jam/menit mulai & berakhir, info bar                     |
| `test/presentation/pages/main_display/layouts/midnight_standby_layout_test.dart` | 4 widget tests: layout hitam, jam digital, info Subuh, AnimationController                     |
| `test/presentation/pages/main_display_page_test.dart`                            | 2 integration tests: MidnightStandbyLayout rendered, key OK → Settings                         |
| `test/presentation/pages/settings/sections/midnight_mode_section_test.dart`      | 6 widget tests: toggle ON/OFF, 4 stepper visible, info bar format, ExcludeFocus                |

File yang dimodifikasi:

| File                                                       | Keterangan                                                                 |
| ---------------------------------------------------------- | -------------------------------------------------------------------------- |
| `lib/data/datasources/database_helper.dart`                | Schema v8, migration DDL 5 kolom midnight baru                             |
| `lib/data/models/settings_model.dart`                      | `fromMap`/`toMap` untuk 5 field midnight                                   |
| `lib/domain/entities/settings.dart`                        | 5 field baru (`isMidnightModeEnabled`, `midnightStart/EndHour/Minute`)     |
| `lib/domain/entities/transition_config.dart`               | 5 field midnight + `fromSettings()` mapping                                |
| `lib/domain/entities/display_state_type.dart`              | Tambah `midnightStandby`                                                   |
| `lib/domain/entities/display_state.dart`                   | Tambah `MidnightStandbyState` (currentTime, subuhTime, subuhLabel)         |
| `lib/domain/usecases/evaluate_display_state_use_case.dart` | `_evaluateMidnightWindow()` + cross-midnight comparison (CON-002)          |
| `lib/presentation/cubits/settings/settings_cubit.dart`     | 5 method update midnight (updateMidnightModeEnabled, Start/EndHour/Minute) |
| `lib/presentation/pages/main_display_page.dart`            | Case `midnightStandby` di switch + import layout                           |
| `lib/presentation/pages/settings/settings_menu_page.dart`  | Tambah `MidnightModeSection` di categories + import                        |

### Alarm Tanda Waktu / Pre-Adzan & Pre-Iqomah Alert (2026-03-17)

Fitur alarm audio otomatis beberapa detik sebelum Adzan dan Iqomah. Konfigurasi independen
(enable/disable, durasi countdown 10–120 detik). Menggunakan `audioplayers` + abstract service pattern.
6 phase, 20 new alarm tests.

File baru yang dibuat:

| File                                                                         | Keterangan                                                             |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `lib/domain/services/audio_alert_service.dart`                               | Abstract interface `AudioAlertService` (playAlert, stopAlert, dispose) |
| `lib/data/services/audio_alert_service_impl.dart`                            | `AudioAlertServiceImpl` — audioplayers `AssetSource`, singleton-safe   |
| `lib/presentation/pages/settings/sections/alert_settings_section.dart`       | Section Settings UI — 2 toggle + 2 DPadStepper countdown seconds       |
| `test/presentation/pages/settings/sections/alert_settings_section_test.dart` | 6 widget tests: toggle ON/OFF, 2 stepper visible, callback wiring      |

File yang dimodifikasi:

| File                                                             | Keterangan                                                                                                                                |
| ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/data/datasources/database_helper.dart`                      | Schema v9, migration DDL 4 kolom alarm baru                                                                                               |
| `lib/data/models/settings_model.dart`                            | `fromMap`/`toMap` untuk 4 field alarm (snake_case)                                                                                        |
| `lib/domain/entities/settings.dart`                              | 4 field baru: `isPreAdzanAlertEnabled`, `isPreIqomahAlertEnabled`, `preAdzanAlertSeconds`(10), `preIqomahAlertSeconds`(10)                |
| `lib/domain/entities/transition_config.dart`                     | 4 field alarm + `fromSettings()` mapping                                                                                                  |
| `lib/presentation/cubits/settings/settings_cubit.dart`           | 4 method update: `updatePreAdzanAlertEnabled`, `updatePreIqomahAlertEnabled`, `updatePreAdzanAlertSeconds`, `updatePreIqomahAlertSeconds` |
| `lib/presentation/cubits/display_state/display_state_cubit.dart` | `_audioAlertService`, `_preAdzanAlertFired`, `_preIqomahAlertFired`; `_checkAlertTrigger()`, `_checkAlertStop()` di `_tick()`             |
| `lib/presentation/pages/settings/settings_menu_page.dart`        | Tambah `AlertSettingsSection` sebagai kategori ke-6                                                                                       |
| `lib/main.dart`                                                  | `AudioAlertServiceImpl` di-instantiate dan di-inject ke `DisplayStateCubit`                                                               |

Test yang dimodifikasi:

| File                                                                   | Keterangan                                                    |
| ---------------------------------------------------------------------- | ------------------------------------------------------------- |
| `test/data/models/settings_model_test.dart`                            | +4 tests: serialisasi 4 field alarm baru                      |
| `test/presentation/cubits/settings/settings_cubit_test.dart`           | +4 tests: update enable/disable + seconds alarm               |
| `test/presentation/cubits/display_state/display_state_cubit_test.dart` | +6 tests: trigger/stop Pre-Adzan & Pre-Iqomah alert lifecycle |

```yaml
dependencies:
  audioplayers: ^6.1.0
```

Planning doc: `plan/feature-alarm-alert-1.md` (v1.5, Completed)

### Slideshow Pengumuman / Announcement Slideshow (2026-05-08)

Fitur tampilan gambar pengumuman secara periodik pada layar utama. Menggunakan `SlideshowAnnouncementState`
sebagai state ke-5 (sebelum Wisdom Quote). Mendukung 3 slot gambar dengan manajemen file lokal,
konfigurasi jadwal aktif, interval antar slot, dan durasi per gambar.
8 phase implementasi, migrasi `file_picker` v11.0.2.

File baru yang dibuat:

| File                                                                           | Keterangan                                                                 |
| ------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| `lib/domain/entities/slideshow_image.dart`                                     | Entity — `slotIndex`, `fileName`, `storedPath`, `mimeType`, `width/height` |
| `lib/domain/repositories/slideshow_image_repository.dart`                      | Abstract interface (CRUD slot 1-3)                                         |
| `lib/data/models/slideshow_image_model.dart`                                   | `fromMap`/`toMap` SQLite serialization                                     |
| `lib/data/services/slideshow_file_storage_service.dart`                        | Abstract interface untuk manajemen file I/O (import, delete)               |
| `lib/data/services/slideshow_file_storage_service_impl.dart`                   | Implementasi `path_provider` & `File` ops (sandboxed directory)            |
| `lib/data/repositories/slideshow_image_repository_impl.dart`                   | Concrete impl — SQLite ops (replace-on-conflict per slot)                  |
| `lib/presentation/cubits/slideshow_section/slideshow_section_cubit.dart`       | Manajemen slot UI (pick, import, replace, delete)                          |
| `lib/presentation/pages/settings/sections/slideshow_section.dart`              | Settings UI — toggle, stepper jadwal/durasi, 3-slot card management        |
| `lib/presentation/pages/main_display/layouts/slideshow_layout.dart`            | Layout display — full screen image dengan progress bar & slot info         |
| `lib/presentation/pages/slideshow_preview_page.dart`                           | Halaman pratinjau full screen dari menu settings                           |
| `test/data/repositories/slideshow_image_repository_impl_test.dart`             | Unit tests SQLite ops                                                      |
| `test/presentation/cubits/slideshow_section/slideshow_section_cubit_test.dart` | 12 tests: file picker mocking (v11), CRUD lifecycle, state transitions     |

File yang dimodifikasi:

| File                                                             | Keterangan                                                                                                       |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `lib/data/datasources/database_helper.dart`                      | Schema v10, migration DDL table `slideshow_images`, 8 kolom settings baru                                        |
| `lib/data/models/settings_model.dart`                            | `fromMap`/`toMap` untuk 8 field slideshow baru                                                                   |
| `lib/domain/entities/settings.dart`                              | 8 field baru: `isSlideshowEnabled`, `slideshowStart/EndHour/Minute`, `Interval`, `SlotDuration`, `ImageDuration` |
| `lib/domain/entities/transition_config.dart`                     | 8 field slideshow + `fromSettings()` mapping                                                                     |
| `lib/domain/usecases/evaluate_display_state_use_case.dart`       | Logika siklus absolut (TS-P5-002), index gambar (TS-P5-004), priority 4                                          |
| `lib/presentation/cubits/settings/settings_cubit.dart`           | 8 method update slideshow settings                                                                               |
| `lib/presentation/cubits/display_state/display_state_cubit.dart` | `_slideshowImageRepository`, `_activeSlideshowImages`; refresh images on `onSettingsChanged()`                   |
| `lib/presentation/pages/main_display_page.dart`                  | Case `slideshowAnnouncement` di switch + `onSettingsChanged()` refresh saat kembali dari Settings                |
| `lib/presentation/pages/settings/settings_menu_page.dart`        | Tambah `SlideshowSection` sebagai kategori ke-7                                                                  |
| `lib/main.dart`                                                  | Injection `SlideshowImageRepository` & `SlideshowFileStorageService`                                             |

**Technical Lessons Learned:**

- **Absolute Cycle Logic**: Slideshow menggunakan jadwal absolut dari `windowStart` agar sinkron antar-device.
- **FilePicker v11**: `FilePicker.platform.pickFiles` dihapus → gunakan `FilePicker.pickFiles`. Mock via `FilePickerPlatform.instance`.
- **FocusableWidget HitTest**: Tombol di atas layer transparan butuh `HitTestBehavior.opaque` agar responsif ke remote TV.
- **State Sync**: `SlideshowSectionCubit` memicu `DisplayStateCubit.onSettingsChanged()` setelah operasi file.

Planning doc: `plan/feature-slideshow-pengumuman-1.md` (Completed)

### Jadwal Imam Sholat Berjamaah (2026-05-25)

Fitur tampilan full-screen periodik jadwal imam sholat berjamaah untuk hari ini. Menambahkan
`ImamScheduleState` sebagai State ke-9. Mendukung maksimal 10 imam, jadwal 7 hari (Senin–Minggu),
tampilan khusus Jumat dengan pemisahan Khatib dan Imam. Data dari tabel SQLite `imams` + `imam_schedules`
dengan foreign key enforcement. 10 phase, 98 total tests baru.

File baru yang dibuat:

| File                                                                    | Keterangan                                                               |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `lib/domain/entities/imam.dart`                                         | Immutable entity — `id`, `name`, `isActive`, `Equatable`                 |
| `lib/domain/entities/imam_schedule.dart`                                | Immutable entity — `id`, `dayOfWeek`, `prayerName`, `imamId`, `khatibId` |
| `lib/domain/entities/imam_schedule_display.dart`                        | DTO normalized+resolved untuk display & dropdown binding                 |
| `lib/domain/repositories/imam_repository.dart`                          | Abstract interface CRUD imam (zero infra imports)                        |
| `lib/domain/repositories/imam_schedule_repository.dart`                 | Abstract interface jadwal imam                                           |
| `lib/data/models/imam_model.dart`                                       | `fromMap`/`toMap`, `is_active` int↔bool                                  |
| `lib/data/models/imam_schedule_model.dart`                              | `fromMap`/`toMap`, snake_case mapping                                    |
| `lib/data/datasources/imam_local_data_source.dart`                      | SQLite CRUD imam, validasi maks 10 entri                                 |
| `lib/data/datasources/imam_schedule_local_data_source.dart`             | SQLite ops + LEFT JOIN, normalisasi slot Jumat, upsert                   |
| `lib/data/repositories/imam_repository_impl.dart`                       | Implementasi konkret CRUD imam                                           |
| `lib/data/repositories/imam_schedule_repository_impl.dart`              | Implementasi konkret jadwal imam                                         |
| `lib/presentation/cubits/imam_schedule/imam_schedule_cubit.dart`        | CRUD cubit admin UI, sinkronisasi ke `DisplayStateCubit`                 |
| `lib/presentation/cubits/imam_schedule/imam_schedule_state.dart`        | State definitions (Initial, Loading, Loaded, Error)                      |
| `lib/presentation/pages/settings/sections/imam_schedule_section.dart`   | Settings UI — toggle, lock, stepper, CRUD imam, grid jadwal 7 hari       |
| `lib/presentation/pages/main_display/layouts/imam_schedule_layout.dart` | Layout full-screen — header, tabel 5 slot, footer progress bar           |

File yang dimodifikasi:

| File                                                             | Keterangan                                                                                                           |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `lib/data/datasources/database_helper.dart`                      | Schema v11, `_onConfigure()` FK enforcement, migrasi tabel `imams`+`imam_schedules`, 8 kolom settings                |
| `lib/domain/entities/settings.dart`                              | 8 field baru: `isImamScheduleEnabled`, interval, duration, start/end hour/minute, `isImamScheduleLocked`             |
| `lib/data/models/settings_model.dart`                            | `fromMap`/`toMap` untuk 8 field imam baru (snake_case)                                                               |
| `lib/domain/entities/transition_config.dart`                     | 7 field imam + `fromSettings()` mapping (`isImamScheduleLocked` dikecualikan)                                        |
| `lib/domain/entities/display_state_type.dart`                    | Tambah `imamSchedule`                                                                                                |
| `lib/domain/entities/display_state.dart`                         | Tambah `ImamScheduleState` (dayName, hijriDate, slots, currentTime, remainingSeconds)                                |
| `lib/domain/usecases/evaluate_display_state_use_case.dart`       | `_evaluateImamScheduleWindow()` — siklus absolut, guard empty schedule, priority setelah slideshow                   |
| `lib/presentation/cubits/settings/settings_cubit.dart`           | 8 method update imam schedule; lock tidak memicu `triggerConfigUpdate`                                               |
| `lib/presentation/cubits/display_state/display_state_cubit.dart` | Inject `ImamScheduleRepository`, cache `_todayImamSchedule`, reload saat weekday berganti & `onSettingsChanged()`    |
| `lib/presentation/pages/main_display_page.dart`                  | Case `imamSchedule` → `ImamScheduleLayout`                                                                           |
| `lib/presentation/pages/settings/settings_menu_page.dart`        | Tambah `ImamScheduleSection` setelah Slideshow dan sebelum Mode Hemat Daya                                           |
| `lib/main.dart`                                                  | Instansiasi `ImamLocalDataSource`, `ImamScheduleLocalDataSource`, `ImamRepositoryImpl`, `ImamScheduleRepositoryImpl` |

Test yang dibuat/dimodifikasi:

| File                                                                          | Keterangan                                                      |
| ----------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `test/data/models/imam_model_test.dart`                                       | 4 tests: fromMap, toMap, round-trip, `isActive` int↔bool        |
| `test/data/models/imam_schedule_model_test.dart`                              | 4 tests: fromMap nullable, toMap, round-trip                    |
| `test/data/repositories/imam_repository_impl_test.dart`                       | 18 tests: getAll, insert, insert max-10, update, delete, count  |
| `test/data/repositories/imam_schedule_repository_impl_test.dart`              | 8+ tests: JOIN resolves names, slot normalisasi, Jumat FK       |
| `test/presentation/cubits/imam_schedule/imam_schedule_cubit_test.dart`        | 24 tests: loadAll, CRUD, sinkronisasi ke DisplayStateCubit      |
| `test/presentation/pages/settings/sections/imam_schedule_section_test.dart`   | 13 tests: toggle, lock, stepper, CRUD imam, character counter   |
| `test/presentation/pages/main_display/layouts/imam_schedule_layout_test.dart` | 12 tests: render, slot kosong/terisi, badge hari, Jumat         |
| `test/data/models/settings_model_test.dart`                                   | +8 tests: serialisasi 8 field imam baru                         |
| `test/data/datasources/database_helper_test.dart`                             | +tests: migration v11, FK enforcement aktif                     |
| `test/presentation/cubits/settings/settings_cubit_test.dart`                  | +8 tests: 8 method update imam schedule                         |
| `test/domain/usecases/evaluate_display_state_use_case_test.dart`              | +13 tests: imam window aktif/nonaktif, empty schedule, priority |
| `test/presentation/cubits/display_state/display_state_cubit_test.dart`        | +tests: cache jadwal hari ini, day-rollover handling            |

**Technical Lessons Learned:**

- **FK Enforcement via `_onConfigure()`**: Aktifkan `PRAGMA foreign_keys = ON` di `_onConfigure(Database db)` → `ON DELETE SET NULL` berlaku saat imam dihapus.
- **Jumat Normalization di DataSource**: Konversi `dzuhur`→`jumat` saat `dayOfWeek==5` dilakukan di `ImamScheduleLocalDataSource.setSchedule()`.
- **Cache Jadwal Harian**: `DisplayStateCubit` cache `_todayImamSchedule` + `_todayImamScheduleDayOfWeek`; reload otomatis saat weekday berubah.
- **Domain Adapter Pattern**: `ImamRepositoryImpl.update()` konversi `Imam` → `ImamModel` eksplisit untuk hindari runtime cast error.
- **`isImamScheduleLocked` dikecualikan dari `TransitionConfig`**: Hanya mempengaruhi UI admin Settings, bukan evaluator display.

Planning doc: `plan/feature-imam-schedule-1.md` (v1.4, Completed)

---

## Local Workflow

**Testing Wajib per Phase:** Setelah setiap phase implementasi, WAJIB dilakukan testing dan semua test harus lulus sebelum melanjutkan ke phase berikutnya.

```bash
flutter doctor && flutter pub get    # Setup environment
dart format . && dart analyze        # Code quality check
flutter test --reporter=expanded     # Run tests (REQUIRED format)
flutter run                          # Development di Android Emulator
flutter run -d windows               # Development di Windows
flutter run -d <android-tv-id>       # Deploy ke Android TV
```

## Quick Reference Guides

- **[Specification Overview](docs/SPECIFICATION_OVERVIEW.md)** — Overview 6 technical specs, dependency map, key design decisions, recommended execution order
- **[Architecture Patterns](docs/ARCHITECTURE_PATTERNS.md)** — State machine, offline-first data, prayer time calculation, timer management, setup wizard
- **[Development Workflow](docs/DEVELOPMENT_WORKFLOW.md)** — Git workflow, commit standards, testing procedures, code quality guidelines
- **[Execution Workflow](docs/EXECUTION_WORKFLOW.md)** — Phased execution strategy dengan checkpoint gates, testing verification, user approval workflow
- **[Testing Guide](docs/TESTING_GUIDE.md)** — Comprehensive testing strategies untuk SQLite, Cubit, dan widget testing
- **[UI/UX Guide](docs/UI_UX_GUIDE.md)** — Android TV design guidelines, D-Pad navigation, glassmorphism theme, remote-friendly UI patterns

---

## Proven Implementation Patterns

### Architecture Patterns

| Pattern                     | Description                                                                                                      | When to Use              |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------- | ------------------------ |
| **State Machine Pattern**   | 9-state display transition: STANDBY → PRE-ADZAN → ADZAN → IQOMAH → SHOLAT → SLIDESHOW → IMAM → WISDOM → MIDNIGHT | Core display logic       |
| **Offline-First Data**      | SQLite sebagai single source of truth                                                                            | Semua data persistence   |
| **Prayer Time Calculation** | Astronomical calculation dengan adhan-dart + manual correction (Kemenag RI)                                      | Jadwal sholat            |
| **Timer Management**        | Countdown timers dengan lifecycle management                                                                     | Adzan, Iqomah countdowns |
| **Setup Wizard Pattern**    | Multi-step first-run configuration                                                                               | Initial setup            |
| **Cubit Pattern**           | Simple state management tanpa events                                                                             | Semua features           |

### UI Patterns

| Pattern                              | Description                                                                                                                                       | When to Use                         |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| **D-Pad Navigation**                 | Focus traversal dengan remote control                                                                                                             | Semua interactive UI                |
| **Landscape 16:9 Layout**            | Fixed orientation untuk TV display                                                                                                                | Semua pages                         |
| **State-Based Display**              | UI berubah otomatis berdasarkan state machine                                                                                                     | Main display screen                 |
| **Countdown Timer Widget**           | Large countdown dengan auto-refresh                                                                                                               | Pre-Adzan, Iqomah states            |
| **Marquee Running Text**             | Scrolling text di footer                                                                                                                          | Information display                 |
| **Glassmorphism Card**               | Semi-transparent cards dengan blur effect                                                                                                         | Prayer time cards                   |
| **Screen Burn-in Prevention**        | Auto-dimming dan blank screen saat sholat                                                                                                         | SHOLAT state                        |
| **ScreenUtil Responsive**            | Proportional scaling via `flutter_screenutil` (design size 1920×1080)                                                                             | Semua sizing dan font               |
| **DPadStepper Vertical-Only Layout** | `DPadStepper` mengonsumsi ArrowLeft/Right. **JANGAN** pakai `Row` untuk dua stepper — gunakan `Column` agar ArrowDown/Up berpindah antar-stepper. | Semua section dengan pair Jam+Menit |

---

## Code Style & Design Guidelines

### Style Notes

- Follow Effective Dart guidelines untuk code style
- Gunakan `const` constructors dimana mungkin untuk performance
- Prefer Stateless widgets over Stateful ketika state tidak diperlukan
- Gunakan meaningful names sesuai Dart naming conventions
- Implement proper error handling dengan try-catch blocks
- Gunakan `async`/`await` untuk asynchronous operations
- **Android TV Specific**: Semua interactive elements harus accessible via D-Pad
- **Switch.adaptive colors**: Jangan `activeColor` (deprecated Flutter v3.31+). Gunakan `activeThumbColor` + `activeTrackColor`.
- **Color opacity**: Gunakan `Color.withValues(alpha: x)` bukan `Color.withOpacity(x)` (deprecated Dart 3.6+).
- **google_fonts offline**: Set `GoogleFonts.config.allowRuntimeFetching = false` di `main()`. Font TTF harus ada di `assets/fonts/` DAN terdaftar di **dua section** pubspec.yaml: `assets:` dan `fonts:`.

### Islamic Glassmorphism Theme

| Element       | Value                                            |
| ------------- | ------------------------------------------------ |
| Primary Color | Deep Emerald Green `#004D40`                     |
| Accent Color  | Gold / Amber `#FFD700`                           |
| Background    | Masjid image dengan dark overlay                 |
| Clock Font    | Digital monospace bold                           |
| Text Font     | Sans-serif (Montserrat / Roboto)                 |
| Glass Effect  | Semi-transparent containers dengan blur backdrop |

---

## State Management

Project menggunakan **Flutter BLoC (Cubit)** untuk semua state management.

### Cubit Pattern Guidelines

- Gunakan **Cubit** untuk semua state management (simple, no events needed)
- Apply Clean Architecture dengan SQLite repository pattern
- Gunakan **Equatable** untuk state classes untuk proper state comparison
- Implement proper dependency injection dengan BlocProvider
- **No caching needed**: SQLite sudah menjadi persistent cache
- **No retry mechanism**: Offline-first berarti tidak ada network errors

---

## Testing

**Required format**: `flutter test --reporter=expanded`

### Testing Priority

1. **SQLite Operations** — Test semua CRUD operations dan transactions
2. **Prayer Time Calculations** — Test dengan berbagai coordinates dan dates
3. **State Machine Transitions** — Test semua state transitions
4. **Timer Management** — Test lifecycle dan disposal
5. **Widget Tests** — Test D-Pad navigation dan focus management

Untuk comprehensive strategies, lihat [Testing Guide](docs/TESTING_GUIDE.md).

---

## Performance

Key performance principles:

- Minimize `setState()` calls dalam timer callbacks
- Gunakan `const` constructors dimana mungkin
- Implement proper timer disposal untuk prevent memory leaks
- Optimize SQLite queries dengan proper indexing
- **Target**: 60 FPS rendering pada Android TV devices

### Android TV Performance Patterns (Low-End Device)

Ditemukan saat optimasi `RunningTextWidget` di device Android TV Android 11.

- **`BackdropFilter` + animated widget = GPU jank**: `ImageFilter.blur` di widget yang continuous animated (Marquee, countdown) menyebabkan severe GPU jank. Ganti dengan solid semi-transparent `Container` atau `RepaintBoundary`. → Lihat juga [Common Pitfall #8](#8-backdropfilter-pada-animated-widget--gpu-jank-di-android-tv).

- **`RepaintBoundary`**: Wrap widget yang sering repaint (footer marquee, jam digital) agar Flutter membuat compositing layer terpisah.

- **`buildWhen` pada `BlocBuilder`**: Untuk `StandbyLayout` yang update per menit, gunakan `buildWhen: (prev, next) => next.currentTime.minute != prev.currentTime.minute`.

- **Self-contained timer**: Jam digital yang update per detik — letakkan `Timer.periodic` di dalam widget sendiri, bukan di cubit.

```dart
// ✅ CORRECT — DigitalClockWidget mengelola timer sendiri
class _DigitalClockWidgetState extends State<DigitalClockWidget> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
```

- **Cache `DateFormat` locale**: Simpan hasil format di state, update hanya saat hari berganti.

```dart
void _updateDateIfNeeded(DateTime now) {
  if (now.day != _cachedDay) {
    _masehiDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    _cachedDay = now.day;
  }
}
```

- **`adhan` prayer calculation — no Isolate needed**: Kalkulasi ~1ms (pure math). Overhead `compute()` ~100ms. Gunakan `async/await` biasa.

---

## UI/UX

- Follow Android TV design guidelines (Leanback library concepts)
- Implement D-Pad navigation untuk semua interactive elements
- Support remote control dengan clear focus indicators
- Gunakan Landscape 16:9 layout (1920x1080 design size, adaptive via ScreenUtil)
- Gunakan `flutter_screenutil` extensions (`.sp`, `.w`, `.h`, `.r`) untuk responsive sizing
- Implement Islamic Glassmorphism theme dengan consistency
- Ensure text readable dari jarak (min 24.sp untuk body text)

Untuk comprehensive guidelines, lihat [UI/UX Guide](docs/UI_UX_GUIDE.md).

---

## Security & Data Integrity

- Validate semua user inputs (coordinates, text fields)
- Gunakan SQLite transactions untuk data integrity
- Implement proper error handling dan graceful degradation
- Handle edge cases untuk prayer time calculations
- No sensitive data (offline-first, no authentication)
- Prevent SQL injection dengan parameterized queries

---

## Platform-Specific Considerations

### Android TV Requirements

| Setting       | Value                                          |
| ------------- | ---------------------------------------------- |
| Min API Level | 24 (Android 7.0)                               |
| TV Support    | LEANBACK launcher + TV banner icon             |
| Orientation   | Locked to Landscape                            |
| Navigation    | D-Pad / Remote control only (no touch)         |
| Launcher      | Configured as TV launcher atau boot on startup |

### Manifest Configuration

`AndroidManifest.xml` harus menyertakan:

- `<uses-feature android:name="android.software.leanback" android:required="false" />` (jika APK juga mendukung HP/tablet), atau `true` bila TV-only
- `<uses-feature android:name="android.hardware.touchscreen" android:required="false" />`
- `screenOrientation="landscape"` for all activities
- `MAIN` + `LAUNCHER` untuk non-TV, dan `MAIN` + `LEANBACK_LAUNCHER` untuk Android TV

### Screen Timeout / Ambient Mode

`MainActivity` harus memasang `FLAG_KEEP_SCREEN_ON` agar layar tidak mati setelah idle:

```kotlin
class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
  }
}
```

Jika gejala "sekitar 10 menit layar mati", prioritaskan diagnosis screen timeout sistem / Ambient Mode sebelum menyalahkan state machine Flutter. Lihat [Common Pitfall #9](#9-android-screen-timeout--ambient-mode--layar-mati-setelah-idle).

---

## Git & Code Review

### Git Control Policy (CRITICAL)

**DILARANG KERAS** melakukan command berikut tanpa izin eksplisit dari user:

- `git commit`
- `git push`

Agent harus: 1) jelaskan perubahan, 2) minta konfirmasi user, 3) baru execute.

### Commit Message Format

Gunakan conventional commit format. Lihat [Development Workflow Guide](docs/DEVELOPMENT_WORKFLOW.md).

### Pull Request Checklist

- [ ] All tests pass (`flutter test`)
- [ ] No analyzer warnings (`dart analyze`)
- [ ] Code is formatted (`dart format .`)
- [ ] App builds successfully untuk Android TV
- [ ] UI berfungsi dengan D-Pad remote control
- [ ] Tidak ada memory leaks dari timers
- [ ] Performance acceptable (60fps target)
- [ ] SQLite transactions benar dan aman

### What Reviewers Look For

- **Widget architecture**: Proper widget composition dan separation of concerns
- **State management**: Effective use of Cubit patterns dan state handling
- **Offline-first compliance**: Semua data access melalui SQLite, tidak ada network calls
- **Performance**: Efficient rendering dan memory management
- **Android TV compliance**: Following Android TV design guidelines
- **D-Pad navigation**: Proper focus management dan keyboard/remote handling
- **Code quality**: Null safety compliance dan error handling
- **Timer management**: Proper disposal dan lifecycle handling
- **SQLite safety**: Transaction management dan error handling
- **Prayer time accuracy**: Correct astronomical calculations dan manual corrections

---

## Common Pitfalls & Solutions

### 1. Timer Memory Leaks

**Issue**: Timers tidak di-dispose saat widget destroyed, menyebabkan memory leak.

**Problem**:

```dart
// ❌ WRONG - Timer tidak di-dispose, missing dispose()
class _ClockWidgetState extends State<ClockWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }
}
```

**Solution**:

```dart
// ✅ CORRECT - Timer di-dispose dengan benar
class _ClockWidgetState extends State<ClockWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
```

**Prevention**: Semua countdown timers dan clock widgets WAJIB implement `dispose()`.

### 2. D-Pad Focus Traversal

**Issue**: UI elements tidak bisa di-navigate dengan remote control.

**Problem**:

```dart
// ❌ WRONG - No focus management
ListView.builder(
  itemBuilder: (context, index) => Card(child: Text(items[index])),
)
```

**Solution**:

```dart
// ✅ CORRECT - Proper focus management
ListView.builder(
  itemBuilder: (context, index) => Focus(
    autofocus: index == 0,
    child: InkWell(
      onTap: () => _handleSelection(index),
      child: Card(child: Text(items[index])),
    ),
  ),
)
```

**Prevention**: Setup Wizard, Settings Menu, City Selector — semua WAJIB implement focus management.

### 3. SQLite Transaction Safety

**Issue**: Data corruption saat mati listrik mendadak.

**Problem**:

```dart
// ❌ WRONG - No transaction
Future<void> updateSettings(Settings settings) async {
  await db.update('settings', settings.toMap(), where: 'id = ?', whereArgs: [1]);
  await db.update('cities', cityData, where: 'id = ?', whereArgs: [settings.cityId]);
  // Jika mati listrik di sini → data inkonsisten!
}
```

**Solution**:

```dart
// ✅ CORRECT - Atomic transaction
Future<void> updateSettings(Settings settings) async {
  await db.transaction((txn) async {
    await txn.update('settings', settings.toMap(), where: 'id = ?', whereArgs: [1]);
    await txn.update('cities', cityData, where: 'id = ?', whereArgs: [settings.cityId]);
  });
}
```

**Prevention**: SELALU gunakan `db.transaction()` untuk multiple writes.

### 4. Prayer Time Calculation Edge Cases

**Issue**: Prayer times incorrect pada tanggal tertentu atau lokasi ekstrem.

**Solution**:

```dart
// ✅ CORRECT - Kemenag RI (SIHAT): Subuh 20°, Isya 18°, Ihtiyat +2 menit
PrayerTimes? calculatePrayerTimes(DateTime date, Coordinates coords) {
  if (coords.latitude < -90 || coords.latitude > 90) return null;
  if (coords.longitude < -180 || coords.longitude > 180) return null;
  try {
    final params = CalculationMethod.other.getParameters();
    params.fajrAngle = 20.0;
    params.ishaAngle = 18.0;
    params.adjustments.fajr = 2;
    params.adjustments.sunrise = -2;
    params.adjustments.dhuhr = 2;
    params.adjustments.asr = 2;
    params.adjustments.maghrib = 2;
    params.adjustments.isha = 2;
    return _applyCorrections(PrayerTimes(coords, date, params));
  } catch (e) {
    debugPrint('Prayer time calculation failed: $e');
    return null;
  }
}
```

### 5. Screen Burn-in Prevention

**Issue**: Static content di TV menyebabkan screen burn-in pada OLED displays.

**Solution**: Implement `SholatState` dengan blank/dimmed screen dan posisi clock yang berubah tiap menit.

**Prevention**: Test pada OLED devices, implement auto screen-off setelah durasi sholat.

### 6. DropdownButton Value-Not-In-Items (Equatable + Async Race Condition)

**Issue**: `DropdownButton` blank/kosong saat back navigation.

**Root Cause**: Objek dummy dengan ID placeholder tidak cocok dengan real entity via `Equatable` comparison.

**Problem**:

```dart
// ❌ WRONG - Dummy City(id=0) tidak cocok dengan items dari DB
_selectedCity = City(id: 0, cityName: cubitData.cityName, ...);
_loadCities(_selectedProvince!); // items belum tersedia!
```

**Solution**:

```dart
// ✅ CORRECT - null dulu, preselect setelah data real tersedia
void _syncWithCubit() {
  setState(() => _selectedProvince = cubitData.provinceName);
  _loadCities(cubitData.provinceName, preselectCityName: cubitData.cityName);
}

Future<void> _loadCities(String province, {String? preselectCityName}) async {
  final cities = await repo.getCitiesByProvince(province);
  if (mounted) {
    setState(() {
      _cities = cities;
      if (preselectCityName != null) {
        try { _selectedCity = cities.firstWhere((c) => c.cityName == preselectCityName); }
        catch (_) { _selectedCity = null; }
      }
    });
  }
}
```

**Real Case**: `LocationStep` — back navigation dari Preview ke Location step.

### 7. IME Tidak Muncul saat TextField Dibuka via D-Pad

**Issue**: Soft keyboard tidak muncul meskipun `requestFocus()` terpanggil.

**Root Cause**: `requestFocus()` synchronous di dalam key-event handler — Flutter belum selesai memproses event.

**Solution**:

```dart
// ✅ CORRECT - Gunakan addPostFrameCallback
final _textFieldFocusNode = FocusNode(skipTraversal: true);

FocusableWidget(
  onSelect: () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textFieldFocusNode.requestFocus();
    });
  },
  builder: (isFocused) => TextField(focusNode: _textFieldFocusNode),
)
```

**Prevention**:

- Semua widget yang buka TextField via `onSelect` WAJIB pakai `addPostFrameCallback`
- Inner `FocusNode` harus `skipTraversal: true`
- Jangan gunakan `SystemChannels.textInput` secara manual

### 8. BackdropFilter pada Animated Widget — GPU Jank di Android TV

**Issue**: Jank (frame drops) pada widget yang menggunakan `BackdropFilter` + animasi konstan.

**Root Cause**: `ImageFilter.blur` memaksa GPU re-capture snapshot seluruh layer di setiap frame.

**Solution**:

```dart
// ❌ WRONG
ClipRRect(child: BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  child: Marquee(text: text),
))

// ✅ CORRECT — Option 1: Hapus BackdropFilter
RunningTextWidget(showBackground: false)

// ✅ CORRECT — Option 2: Isolasi layer
RepaintBoundary(child: RunningTextWidget(...))
```

**Prevention**: Hindari `BackdropFilter` pada widget dengan continuous animation. Selalu `RepaintBoundary` untuk widget yang sering repaint.

### 9. Android Screen Timeout / Ambient Mode — Layar Mati Setelah Idle

**Issue**: Layar mati setelah ~10 menit meskipun app masih aktif di foreground.

**Root Cause**: `Activity` tidak memasang `FLAG_KEEP_SCREEN_ON`.

**Solution**:

```kotlin
// ✅ CORRECT
class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
  }
}
```

**Prevention**: Untuk semua app display Android TV, audit `MainActivity` lebih dulu sebelum mendiagnosis state machine Flutter.

---

## API Deprecations & Breaking Changes

### Switch.adaptive — activeColor Deprecated (Flutter v3.31+)

```dart
// ❌ SALAH
Switch.adaptive(value: isEnabled, onChanged: null, activeColor: IslamicColors.goldAmber)

// ✅ BENAR
Switch.adaptive(
  value: isEnabled,
  onChanged: null,
  activeThumbColor: IslamicColors.goldAmber,
  activeTrackColor: IslamicColors.goldAmber.withValues(alpha: 0.5),
)
```

**File yang sudah diperbaiki**: `midnight_mode_section.dart`, `wisdom_quote_section.dart`, `treasury_section.dart`.

### Color.withOpacity() Deprecated (Dart 3.6 / Flutter 3.27+)

```dart
// ❌ SALAH
color.withOpacity(0.5)

// ✅ BENAR
color.withValues(alpha: 0.5)
```

### FilePicker v11 Migration

```dart
// ❌ SALAH (v10-)
FilePicker.platform.pickFiles(...)

// ✅ BENAR (v11+)
FilePicker.pickFiles(...)
```

**Testing**: Mock menggunakan `FilePickerPlatform.instance`:

```dart
class MockFilePicker extends Mock with MockPlatformInterfaceMixin implements FilePickerPlatform {}

setUp(() => FilePickerPlatform.instance = MockFilePicker());
```

### XFile.name Behavior on IO Platform (cross_file)

Di IO platform, parameter `name` pada konstruktor `XFile` selalu **diabaikan**. `XFile.name` getter = `path.split(Platform.pathSeparator).last`.

```dart
// ❌ SALAH — gagal di Windows
final xfile = XFile.fromData(bytes, path: '/cache/tmp_file');
expect(xfile.name, equals('tmp_file')); // FAIL di Windows!

// ✅ BENAR — gunakan p.join() untuk cross-platform path
import 'package:path/path.dart' as p;
final xfile = XFile.fromData(bytes, path: p.join('cache', 'tmp_file'));
expect(xfile.name, equals('tmp_file')); // PASS semua platform
```

---

## Android TV — Specific Patterns

### D-Pad & Soft Keyboard Patterns

**TextField via D-Pad** — WAJIB `addPostFrameCallback`:

```dart
final _fieldFocusNode = FocusNode(skipTraversal: true);

FocusableWidget(
  onSelect: () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fieldFocusNode.requestFocus();
    });
  },
  builder: (isFocused) => TextField(focusNode: _fieldFocusNode),
)
```

**Jangan** bungkus `TextField` dengan `ExcludeFocus()` tanpa `excluding: false` — defaultnya `true` → `requestFocus()` diabaikan.

**Soft Keyboard untuk Widget Non-TextField (misal PIN input)** — gunakan hidden `Offstage(TextField)`:

```dart
Offstage(
  child: TextField(
    focusNode: _hiddenFocusNode, // skipTraversal: true
    controller: _hiddenController,
    keyboardType: TextInputType.number,
  ),
)
```

**Teks Tombol FocusableWidget Tidak Rata Tengah** — Fix: `AnimatedContainer(alignment: Alignment.center)` + `IntrinsicHeight`.

**Dialog dengan FocusableWidget Buttons** — `AlertDialog.actions` pakai `OverflowBar` → layout rusak. Fix: Gunakan `Dialog` biasa + `Column`/`Row` custom.

**Multi-Resolusi (1920×1080 vs 1280×720)** — `SingleChildScrollView(physics: NeverScrollableScrollPhysics)` memotong konten. Fix: `LayoutBuilder` + `FittedBox(fit: BoxFit.scaleDown)`.

**Multiline TextField — Tombol Done** — `maxLines > 1` otomatis set `TextInputAction.newline`. Fix: `textInputAction: TextInputAction.done` + `onSubmitted: (_) => focusNode.unfocus()`.

### DPadStepper Layout Constraint

`DPadStepper` mengonsumsi `ArrowRight` (increment) dan `ArrowLeft` (decrement). Dua stepper dalam `Row` → fokus stuck di stepper pertama.

```dart
// ❌ SALAH — D-Pad kanan stuck di Jam
Row(children: [DPadStepper(label: 'Jam'), DPadStepper(label: 'Menit')])

// ✅ BENAR — D-Pad bawah dari Jam pindah ke Menit
Column(children: [DPadStepper(label: 'Jam'), DPadStepper(label: 'Menit')])
```

**Aturan**: `DPadStepper` dirancang untuk layout **vertikal saja**. Selalu gunakan `Column` untuk pair Jam+Menit.

### FocusableWidget Interaction Pattern

Tombol di atas layer transparan (`Stack` + `BackdropFilter`) → gunakan `HitTestBehavior.opaque`:

```dart
// lib/presentation/widgets/focusable_widget.dart
GestureDetector(
  behavior: HitTestBehavior.opaque, // WAJIB untuk tombol di layer transparan
  onTap: () {
    _focusNode.requestFocus();
    if (widget.onSelect != null) widget.onSelect!();
  },
  child: ...,
)
```

---

## Flutter Testing Patterns

### DateFormat Locale di Widget Test

```dart
import 'package:intl/date_symbol_data_local.dart';

setUpAll(() async {
  await initializeDateFormatting('id_ID', null);
});
```

**Berlaku untuk**: Semua widget test yang merender widget dengan `DateFormat` locale non-default.

### Mocktail Stub — Semua Named Arg Harus Disebutkan

Jika method dipanggil dengan optional named parameter non-null, stub `when()` WAJIB menyebutkannya.

```dart
// ❌ SALAH — stub miss jika activeQuotes tidak disebutkan
when(() => mockEvaluate.evaluate(...)).thenReturn(StandbyState());

// ✅ BENAR — sebutkan semua named params atau gunakan any(named:)
when(() => mockEvaluate.evaluate(
  config: any(named: 'config'),
  currentTime: any(named: 'currentTime'),
  prayerTimes: any(named: 'prayerTimes'),
  hijriDate: any(named: 'hijriDate'),
  activeQuotes: any(named: 'activeQuotes'),
)).thenReturn(StandbyState());
```

### IndexedStack + Offstage + ListView Lazy

`IndexedStack` membungkus child tidak aktif dengan `Offstage(offstage: true)`. `ListView` di dalamnya tidak membangun children → `find.byType()` menemukan 0 hasil.

```dart
// ❌ SALAH — section bukan default, ListView-nya tidak build
expect(find.byType(DPadStepper), findsNWidgets(6));

// ✅ BENAR — navigate ke section dulu, baru assert
await tester.tap(find.text('Durasi Iqomah').first);
await tester.pumpAndSettle();
expect(find.byType(DPadStepper), findsNWidgets(6));
```

**Berlaku untuk**: `SettingsMenuPage` (IndexedStack categories) dan halaman serupa.
