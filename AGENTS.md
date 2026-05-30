# AGENTS.md - Miqotul Khoir TV Contributor Guide

Selamat datang di repositori project **Miqotul Khoir TV (MKT)** — aplikasi jam masjid digital dan jadwal sholat berbasis Android TV untuk masjid.

File ini berisi panduan utama untuk kontributor baru dan AI assistant yang bekerja dengan project Flutter/Dart untuk platform Android TV.

**Last Updated**: May 30, 2026

<!-- markdownlint-disable -->

## Repository Overview

- **Main Application**: `lib/main.dart` — Entry point aplikasi
- **Core Layer**: `lib/core/` — Utilities, constants, dan service layer
- **Data Layer**: `lib/data/` — SQLite models, repositories, dan data sources
- **Domain Layer**: `lib/domain/` — Business logic, entities, dan use cases
- **Presentation Layer**: `lib/presentation/` — UI components, pages, dan state management (Cubit)
- **Tests**: `test/` dengan unit, widget, dan integration test directories
- **Assets**: `assets/` untuk images, fonts, dan resources lainnya
- **Specification**: `spec/` untuk technical specification documents (output @SpecificationArchitect)
- **Planning**: `plan/` untuk feature implementation plans dengan task tracking
- **Documentation**: `docs/` untuk technical specifications dan design documents
- **Database**: SQLite lokal untuk settings, city presets, dan konfigurasi

### State Management Structure

```
lib/presentation/cubits/
├── prayer_times/              # Cubit untuk kalkulasi waktu sholat
├── display_state/            # Cubit untuk state machine display
├── settings/                 # Cubit untuk pengaturan masjid
└── setup_wizard/             # Cubit untuk initial setup flow
```

**Pattern**: Cubit digunakan untuk semua state management, dengan fokus pada local data dan state transitions.

## Completed Features (Production Ready)

| Feature                                              | Completion Date | Tests                          | Status           |
| ---------------------------------------------------- | --------------- | ------------------------------ | ---------------- |
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

### Plan 01 — Database Infrastructure (COMPLETED)

File yang dibuat/dimodifikasi:

| File                                              | Keterangan                                                              |
| ------------------------------------------------- | ----------------------------------------------------------------------- |
| `lib/data/datasources/database_helper.dart`       | Singleton `DatabaseHelper` — schema DDL, seed, migration, testing hooks |
| `assets/data/cities.json`                         | 514 kota/kabupaten, 34 provinsi Indonesia (71.7 KB)                     |
| `tools/generate_cities.py`                        | Script generator dataset kota dari BPS/wilayah-indonesia                |
| `test/data/datasources/database_helper_test.dart` | 6 unit tests dengan `sqflite_common_ffi` in-memory                      |

Dependencies yang ditambahkan:

```yaml
dependencies:
  sqflite: ^2.4.1
  path: ^1.9.1

dev_dependencies:
  sqflite_common_ffi: ^2.4.0+2
```

### Plan 02 — Data Layer (COMPLETED)

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

Dependencies yang ditambahkan:

```yaml
dependencies:
  equatable: 2.0.8   # Value equality untuk entities
  crypto: 3.0.7      # SHA-256 PIN hashing
```

### Plan 03 — Theme System (COMPLETED)

File yang dibuat/dimodifikasi:

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

Dependencies yang ditambahkan:

```yaml
dependencies:
  flutter_screenutil: ^5.9.3  # Responsive scaling (.sp, .w, .h, .r)
  google_fonts: ^8.0.2        # Poppins font — bundled offline (assets/fonts/), allowRuntimeFetching = false
```


### Plan 05 — Prayer Time Calculation (COMPLETED)

File yang dibuat:

| File                                                             | Keterangan             |
| ---------------------------------------------------------------- | ---------------------- |
| `lib/domain/usecases/calculate_prayer_times_use_case.dart`       | Core calculation logic |
| `lib/domain/entities/prayer_time.dart`                           | Entity definition      |
| `test/domain/usecases/calculate_prayer_times_use_case_test.dart` | Unit tests             |

Dependencies: `adhan`, `hijri`, `intl`

### Plan 06 — Prayer Time Cubit (COMPLETED)

File yang dibuat:

| File                                                               | Keterangan       |
| ------------------------------------------------------------------ | ---------------- |
| `lib/presentation/cubits/prayer_time/prayer_time_cubit.dart`       | State management |
| `lib/presentation/cubits/prayer_time/prayer_time_state.dart`       | State definition |
| `test/presentation/cubits/prayer_time/prayer_time_cubit_test.dart` | Cubit tests      |

Dependencies: `flutter_bloc`, `bloc_test`, `mocktail`

### Plan 07 — State Evaluation (COMPLETED)

File yang dibuat:

| File                                                             | Keterangan                  |
| ---------------------------------------------------------------- | --------------------------- |
| `lib/domain/usecases/evaluate_display_state_use_case.dart`       | Core state transition logic |
| `lib/domain/entities/display_state.dart`                         | Entity definition           |
| `test/domain/usecases/evaluate_display_state_use_case_test.dart` | Unit tests                  |

### Plan 08 — Display State Machine (COMPLETED)

File yang dibuat:

| File                                                                   | Keterangan                   |
| ---------------------------------------------------------------------- | ---------------------------- |
| `lib/presentation/cubits/display_state/display_state_cubit.dart`       | State machine implementation |
| `lib/presentation/cubits/display_state/display_state.dart`             | State definition             |
| `test/presentation/cubits/display_state/display_state_cubit_test.dart` | Cubit tests                  |

### Plan 09 — Setup Wizard Logic (COMPLETED)

File yang dibuat:

| File                                                                 | Keterangan       |
| -------------------------------------------------------------------- | ---------------- |
| `lib/presentation/cubits/setup_wizard/setup_wizard_cubit.dart`       | Setup flow logic |
| `lib/presentation/cubits/setup_wizard/setup_wizard_state.dart`       | Wizard states    |
| `test/presentation/cubits/setup_wizard/setup_wizard_cubit_test.dart` | Cubit tests      |

### Plan 10 — Setup Wizard UI (COMPLETED)

File yang dibuat:

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

Dependencies yang digunakan:
- `flutter_bloc`: State management
- `flutter_screenutil`: Responsive layout
- `google_fonts`: Typography (bundled offline — lihat catatan di bawah)

### Plan 11 — Settings Logic (COMPLETED)

File yang dibuat:

| File                                                         | Keterangan                                                       |
| ------------------------------------------------------------ | ---------------------------------------------------------------- |
| `lib/presentation/cubits/settings/settings_cubit.dart`       | `SettingsCubit` implementasi auto-save & PIN logic               |
| `lib/presentation/cubits/settings/settings_state.dart`       | State definitions (Initial, Loading, Loaded, Error)              |
| `lib/presentation/cubits/settings/settings.dart`             | Barrel export file                                               |
| `test/presentation/cubits/settings/settings_cubit_test.dart` | Comprehensive unit tests (auto-save debounce, PIN, update logic) |

Dependencies yang digunakan:
- `flutter_bloc`: State management
- `equatable`: State comparison
- `bloc_test`: Testing utilities
- `mocktail`: Mocking dependencies

### Alarm Tanda Waktu / Pre-Adzan & Pre-Iqomah Alert (COMPLETED — 2026-03-17)

Fitur alarm audio otomatis yang membunyikan suara tanda peringatan beberapa detik sebelum waktu Adzan
dan sebelum Iqomah dimulai. Konfigurasi independen untuk Pre-Adzan dan Pre-Iqomah (enable/disable
dan durasi countdown 10–120 detik). Menggunakan `audioplayers` dengan abstract service pattern.
6 phase implementasi, 20 new alarm tests.

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

Dependencies yang ditambahkan:

```yaml
dependencies:
  audioplayers: ^6.1.0
```

Planning doc: `plan/feature-alarm-alert-1.md` (v1.5, status: Completed)

---

### Mode Hemat Daya Tengah Malam / Midnight Mode (COMPLETED — 2026-03-16)

Fitur screensaver hemat daya yang menampilkan layar hitam dengan jam digital dan jadwal Subuh
pada jam-jam malam. Menambahkan `MidnightStandbyState` sebagai state ke-7 pada display state machine.
Dilengkapi anti burn-in drift animation dan konfigurasi window waktu cross-midnight.
7 phase implementasi, selesai dengan 306 total tests.

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

### Kata Mutiara Islam / Wisdom Quote (COMPLETED — 2026-03-10)

Fitur tampilan full-screen periodik dengan ayat Al-Quran dan Hadits. Menambahkan `WisdomQuoteState`
sebagai state ke-6 pada display state machine. 14 phase implementasi, selesai dengan 257 total tests.

File baru yang dibuat:

| File                                                                   | Keterangan                                                               |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `assets/data/wisdom_quotes.json`                                       | Katalog 11 item hardcoded (5 Quran + 6 Hadits)                           |
| `lib/domain/entities/wisdom_quote.dart`                                | Immutable entity — `id`, `type`, `label`, `translationText`, `reference` |
| `lib/domain/repositories/wisdom_quote_repository.dart`                 | Abstract interface                                                       |
| `lib/data/models/wisdom_quote_model.dart`                              | `fromJson()`, `toEntity()`                                               |
| `lib/data/datasources/wisdom_quote_local_data_source.dart`             | Loader JSON asset via `rootBundle`                                       |
| `lib/data/repositories/wisdom_quote_repository_impl.dart`              | Implementasi konkret                                                     |
| `lib/presentation/pages/main_display/layouts/wisdom_quote_layout.dart` | Layout full-screen — badge, tranSlasi, referensi, progress bar           |
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


## Local Workflow

**Testing Wajib per Phase:** Setelah setiap phase implementasi, WAJIB dilakukan testing (unit/widget/integration test) dan semua test harus lulus sebelum fase dianggap selesai atau lanjut ke fase berikutnya.

Essential commands untuk memulai development:

```bash
flutter doctor && flutter pub get    # Setup environment
dart format . && dart analyze       # Code quality check
flutter test --reporter=expanded    # Run tests (REQUIRED format)
flutter run              # Development di Android Emulator
flutter run -d windows              # Development di Windows
flutter run -d <android-tv-id>      # Deploy ke Android TV
```

Untuk comprehensive workflow termasuk testing procedures dan deployment strategies, lihat [Development Workflow Guide](docs/DEVELOPMENT_WORKFLOW.md).

## Quick Reference Guides

Untuk detailed implementation guidance, lihat dokumentasi specialized kami:

- **[Specification Overview](docs/SPECIFICATION_OVERVIEW.md)** - Overview 6 technical specs, dependency map, key design decisions, dan recommended execution order
- **[Architecture Patterns](docs/ARCHITECTURE_PATTERNS.md)** - State machine pattern, offline-first data, prayer time calculation, timer management, dan setup wizard patterns
- **[Development Workflow](docs/DEVELOPMENT_WORKFLOW.md)** - Git workflow, commit standards, testing procedures, dan code quality guidelines
- **[Execution Workflow](docs/EXECUTION_WORKFLOW.md)** - Phased execution strategy dengan checkpoint gates, testing verification, dan user approval workflow
- **[Testing Guide](docs/TESTING_GUIDE.md)** - Comprehensive testing strategies untuk SQLite, Cubit, dan widget testing
- **[UI/UX Guide](docs/UI_UX_GUIDE.md)** - Android TV design guidelines, D-Pad navigation, glassmorphism theme, dan remote-friendly UI patterns

## Proven Implementation Patterns

### Architecture Patterns

| Pattern                     | Description                                                                                                  | When to Use              |
| --------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------ |
| **State Machine Pattern**   | 7-state display transition (STANDBY → PRE-ADZAN → ADZAN → IQOMAH → SHOLAT → KATA MUTIARA → MIDNIGHT STANDBY) | Core display logic       |
| **Offline-First Data**      | SQLite sebagai single source of truth                                                                        | Semua data persistence   |
| **Prayer Time Calculation** | Astronomical calculation dengan adhan-dart + manual correction                                               | Jadwal sholat            |
| **Timer Management**        | Countdown timers dengan lifecycle management                                                                 | Adzan, Iqomah countdowns |
| **Setup Wizard Pattern**    | Multi-step first-run configuration                                                                           | Initial setup            |
| **Cubit Pattern**           | Simple state management tanpa events                                                                         | Semua features           |

### UI Patterns

| Pattern                              | Description                                                                                                                                                                                                                | When to Use                         |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| **D-Pad Navigation**                 | Focus traversal dengan remote control                                                                                                                                                                                      | Semua interactive UI                |
| **Landscape 16:9 Layout**            | Fixed orientation untuk TV display                                                                                                                                                                                         | Semua pages                         |
| **State-Based Display**              | UI berubah otomatis berdasarkan state machine                                                                                                                                                                              | Main display screen                 |
| **Countdown Timer Widget**           | Large countdown dengan auto-refresh                                                                                                                                                                                        | Pre-Adzan, Iqomah states            |
| **Marquee Running Text**             | Scrolling text di footer                                                                                                                                                                                                   | Information display                 |
| **Glassmorphism Card**               | Semi-transparent cards dengan blur effect                                                                                                                                                                                  | Prayer time cards                   |
| **Screen Burn-in Prevention**        | Auto-dimming dan blank screen saat sholat                                                                                                                                                                                  | SHOLAT state                        |
| **ScreenUtil Responsive**            | Proportional scaling via `flutter_screenutil` (design size 1920×1080)                                                                                                                                                      | Semua sizing dan font               |
| **DPadStepper Vertical-Only Layout** | `DPadStepper` mengonsumsi ArrowLeft/Right untuk decrement/increment. **JANGAN** tempatkan dua `DPadStepper` dalam `Row` — fokus tidak bisa berpindah horizontal. Günakan `Column` agar ArrowDown/Up bekerja antar-stepper. | Semua section dengan pair Jam+Menit |

## Style Notes

- Follow Effective Dart guidelines untuk code style
- Gunakan `const` constructors dimana mungkin untuk performance
- Prefer Stateless widgets over Stateful ketika state tidak diperlukan
- Gunakan meaningful names sesuai Dart naming conventions
- Implement proper error handling dengan try-catch blocks
- Gunakan `async`/`await` untuk asynchronous operations
- **Android TV Specific**: Semua interactive elements harus accessible via D-Pad
- **Switch.adaptive colors**: Jangan gunakan `activeColor` (deprecated sejak Flutter v3.31). Gunakan `activeThumbColor` untuk thumb dan `activeTrackColor` untuk track. Gunakan `withValues(alpha: 0.5)` bukan `withOpacity()` (deprecated Dart 3.6+) untuk track color.
- **Color opacity**: Gunakan `Color.withValues(alpha: x)` bukan `Color.withOpacity(x)` (deprecated sejak Dart 3.6 / Flutter 3.27).
- **google_fonts offline**: Set `GoogleFonts.config.allowRuntimeFetching = false` di `main()` sebelum `runApp`. Seluruh font TTF harus ada di `assets/fonts/` DAN terdaftar di **dua section** pubspec.yaml: `assets:` (untuk `rootBundle`) dan `fonts:` (untuk Flutter font engine). Audit semua `FontWeight` di seluruh `lib/` sebelum bundling.

### Islamic Glassmorphism Theme

Project ini mengimplementasikan **Modern Islamic Glassmorphism** design system:

- **Primary Color**: Deep Emerald Green (`#004D40`)
- **Accent Color**: Gold / Amber (`#FFD700`)
- **Background**: Masjid image dengan dark overlay
- **Clock Font**: Digital monospace bold font
- **Text Font**: Sans-serif (Montserrat / Roboto)
- **Glass Effect**: Semi-transparent containers dengan blur backdrop

## Commit Message Format

Gunakan conventional commit format untuk consistent versioning dan changelog generation. Lihat [Development Workflow Guide](docs/DEVELOPMENT_WORKFLOW.md) untuk detailed examples dan standards.

## Git Control Policy (CRITICAL)

**DILARANG KERAS** melakukan command berikut secara otomatis tanpa izin eksplisit dari user:
- `git commit`
- `git push`

Agent harus selalu:
1. Menjelaskan perubahan yang akan di-commit
2. Meminta konfirmasi user
3. Baru melakukan commit/push setelah diizinkan

## Pull Request Expectations

PRs should include:

- **Summary**: Clear description of functionality dan perubahan UX
- **Screenshots**: Visual proof dari Android TV device atau emulator
- **Performance impact**: Frame rate dan memory usage considerations
- **Platform compatibility**: Testing pada Android TV 7.0+ (API Level 24+)
- **D-Pad navigation**: Verifikasi bahwa semua elements accessible via remote

Before submitting, ensure:

- [ ] All tests pass (`flutter test`)
- [ ] No analyzer warnings (`dart analyze`)
- [ ] Code is formatted (`dart format .`)
- [ ] App builds successfully untuk Android TV
- [ ] UI berfungsi dengan D-Pad remote control
- [ ] Tidak ada memory leaks dari timers
- [ ] Performance acceptable (60fps target)
- [ ] SQLite transactions benar dan aman

## What Reviewers Look For

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

## Common Pitfalls & Solutions

### 1. Timer Memory Leaks

**Issue**: Timers tidak di-dispose saat widget destroyed, menyebabkan memory leak.

**Problem**:
```dart
// ❌ WRONG - Timer tidak di-dispose
class ClockWidget extends StatefulWidget {
  @override
  _ClockWidgetState createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {}); // Update clock
    });
  }
  // Missing dispose()!
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
      if (mounted) { // Check mounted before setState
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer
    _timer = null;
    super.dispose();
  }
}
```

**Why This Works**:
- Timer di-cancel sebelum widget destroyed
- `mounted` check prevents setState on unmounted widget
- Null safety dengan `_timer?`
- Prevents memory leaks dan runtime errors

**Real Case Pattern**: Semua countdown timers dan clock widgets harus implement pattern ini.

### 2. D-Pad Focus Traversal

**Issue**: UI elements tidak bisa di-navigate dengan remote control.

**Problem**:
```dart
// ❌ WRONG - No focus management
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return Card(
      child: Text(items[index]),
    );
  },
)
```

**Solution**:
```dart
// ✅ CORRECT - Proper focus management
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return Focus(
      autofocus: index == 0, // First item auto-focused
      onKey: (node, event) {
        // Handle custom key events if needed
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: () => _handleSelection(index),
        child: Card(
          child: Text(items[index]),
        ),
      ),
    );
  },
)
```

**Prevention**:
1. **Wrap interactive elements** dengan `Focus` widget
2. **Set autofocus** pada first item atau active item
3. **Test dengan keyboard** di desktop sebelum deploy ke TV
4. **Verify focus indicators** terlihat jelas

**Real Case Pattern**: Setup Wizard, Settings Menu, City Selector harus implement focus management.

### 3. SQLite Transaction Safety

**Issue**: Data corruption saat mati listrik mendadak karena tidak menggunakan transaction.

**Problem**:
```dart
// ❌ WRONG - No transaction, data bisa corrupt
Future<void> updateSettings(Settings settings) async {
  final db = await database;
  await db.update('settings', settings.toMap(), where: 'id = ?', whereArgs: [1]);
  await db.update('cities', cityData, where: 'id = ?', whereArgs: [settings.cityId]);
  // Jika mati listrik di sini, data inkonsisten!
}
```

**Solution**:
```dart
// ✅ CORRECT - Atomic transaction
Future<void> updateSettings(Settings settings) async {
  final db = await database;
  await db.transaction((txn) async {
    await txn.update('settings', settings.toMap(), 
      where: 'id = ?', whereArgs: [1]);
    await txn.update('cities', cityData, 
      where: 'id = ?', whereArgs: [settings.cityId]);
  });
  // Transaction ensures atomic operation
}
```

**Why This Matters**:
- **Atomic operations**: All-or-nothing guarantee
- **Data integrity**: Prevents partial updates
- **Power-safe**: Critical untuk device yang bisa mati listrik
- **Rollback support**: Automatic rollback on error

**Prevention**:
1. **Always use transactions** untuk multiple writes
2. **Test edge cases** dengan simulated interruptions
3. **Validate data** sebelum commit
4. **Handle errors** dengan proper rollback

**Real Cases**: Update settings dengan prayer time corrections, initial setup wizard data save.

### 4. Prayer Time Calculation Edge Cases

**Issue**: Prayer times incorrect pada tanggal tertentu atau lokasi ekstrem.

**Example**:
```dart
// ❌ WRONG - No validation atau error handling
PrayerTimes calculatePrayerTimes(DateTime date, Coordinates coords) {
  // ❌ No Kemenag RI params configured — menggunakan method default
  final params = CalculationMethod.other.getParameters();
  return PrayerTimes(coords, date, params);
  // Bagaimana jika coords invalid? Bagaimana di polar regions?
}
```

**Solution**:
```dart
// ✅ CORRECT - Proper validation dan fallback
PrayerTimes? calculatePrayerTimes(DateTime date, Coordinates coords) {
  // Validate coordinates
  if (coords.latitude < -90 || coords.latitude > 90) {
    debugPrint('❌ Invalid latitude: ${coords.latitude}');
    return null;
  }
  
  if (coords.longitude < -180 || coords.longitude > 180) {
    debugPrint('❌ Invalid longitude: ${coords.longitude}');
    return null;
  }
  
  try {
    // Kemenag RI (SIHAT): Subuh 20°, Isya 18°, Ihtiyat +2 menit
    final params = CalculationMethod.other.getParameters();
    params.fajrAngle = 20.0;
    params.ishaAngle = 18.0;
    params.adjustments.fajr = 2;
    params.adjustments.sunrise = -2;
    params.adjustments.dhuhr = 2;
    params.adjustments.asr = 2;
    params.adjustments.maghrib = 2;
    params.adjustments.isha = 2;
    final times = PrayerTimes(coords, date, params);
    
    // Apply manual corrections
    return _applyCorrections(times);
  } catch (e) {
    debugPrint('❌ Prayer time calculation failed: $e');
    return null;
  }
}
```

**Prevention**:
1. **Validate coordinates** sebelum calculation
2. **Handle edge cases** (polar regions, extreme latitudes)
3. **Apply manual corrections** dari database
4. **Test dengan berbagai lokasi** (equator, tropics, high latitudes)
5. **Log calculation errors** untuk debugging

**Real Case**: Setup Wizard coordinate validation, daily prayer time refresh.

### 5. Screen Burn-in Prevention

**Issue**: Static content di TV menyebabkan screen burn-in pada OLED displays.

**Problem**:
```dart
// ❌ WRONG - Static clock selalu di posisi sama
Container(
  alignment: Alignment.topRight,
  child: Text(
    currentTime,
    style: TextStyle(fontSize: 48, color: Colors.white),
  ),
)
// Jam selalu di posisi sama → burn-in risk!
```

**Solution**:
```dart
// ✅ CORRECT - Implement SHOLAT state dengan dimmed/blank screen
BlocBuilder<DisplayStateCubit, DisplayState>(
  builder: (context, state) {
    if (state is SholatState) {
      // Option 1: Blank screen
      return Container(color: Colors.black);
      
      // Option 2: Dimmed clock yang bergerak
      return _buildDimmedMovingClock();
    }
    return _buildNormalDisplay();
  },
)

Widget _buildDimmedMovingClock() {
  // Clock position berubah sedikit tiap menit
  final offset = _calculatePositionOffset();
  return Positioned(
    left: offset.dx,
    top: offset.dy,
    child: Text(
      currentTime,
      style: TextStyle(fontSize: 24, color: Colors.grey.withOpacity(0.3)),
    ),
  );
}
```

**Prevention**:
1. **Implement SHOLAT state** dengan blank/dimmed screen
2. **Vary position** untuk elements yang selalu visible
3. **Use lower brightness** saat idle
4. **Auto screen-off** setelah durasi sholat
5. **Test pada OLED devices** jika memungkinkan

**Real Case**: State machine SHOLAT state, idle timeout setelah Iqomah.

### 6. DropdownButton Value-Not-In-Items (Equatable + Async Race Condition)

**Issue**: `DropdownButton` menampilkan blank/kosong saat back navigation karena `value` tidak ditemukan di `items` list.

**Root Cause**: Terjadi ketika kode membuat objek "dummy" dengan ID placeholder untuk pre-fill dropdown, padahal entity menggunakan `Equatable` yang membandingkan **semua field termasuk `id`**. Flutter akan assertion error jika `value != null` tapi tidak ada item yang `==` dengan `value`.

**Problem**:
```dart
// ❌ WRONG - Dummy City dengan id=0 menyebabkan assertion error
void _syncWithCubit() {
  setState(() {
    // DropdownButton.value = City(id=0), tapi items = []
    // Flutter assertion: "value not in items" → widget blank/error
    _selectedCity = City(
      id: 0, // ← MASALAH: id dummy tidak cocok dengan City real dari DB
      cityName: cubitData.cityName,
      provinceName: cubitData.provinceName,
      ...
    );
    _selectedProvince = cubitData.provinceName;
  });
  _loadCities(_selectedProvince!); // Items baru tersedia SETELAH async ini selesai
}
```

**Solution**:
```dart
// ✅ CORRECT - Jangan buat dummy object. Preselect hanya setelah data real tersedia.
void _syncWithCubit() {
  setState(() {
    // Hanya set province (String sederhana, tidak pakai Equatable)
    _selectedProvince = cubitData.provinceName;
    // _selectedCity SENGAJA dibiarkan null sampai _loadCities selesai
  });
  _loadCities(cubitData.provinceName, preselectCityName: cubitData.cityName);
}

Future<void> _loadCities(String provinceName, {String? preselectCityName}) async {
  final cities = await repo.getCitiesByProvince(provinceName);
  if (mounted) {
    setState(() {
      _cities = cities;
      // Preselect SETELAH items tersedia — cari objek real, bukan dummy
      if (preselectCityName != null) {
        try {
          _selectedCity = cities.firstWhere((c) => c.cityName == preselectCityName);
        } catch (_) {
          _selectedCity = null;
        }
      }
    });
  }
}
```

**Why This Works**:
- `DropdownButton.value` selalu `null` saat `items` belum diisi → tidak ada assertion error
- Preselect dilakukan dalam satu `setState` bersamaan dengan pengisian `items` → konsisten
- Menggunakan objek real dari database → `Equatable` comparison selalu cocok

**Prevention**:
1. **Jangan gunakan dummy/placeholder object** untuk Equatable entities di dropdown
2. **Hindari dua setState terpisah** yang membuat window invalid state (value != null, items = [])
3. **Pass preselect via parameter** ke fungsi async, bukan via shared state yang di-set sebelumnya
4. **Waspada dengan Equatable**: entity yang `props`-nya menyertakan `id` tidak boleh dibuat dengan ID dummy

**Real Case**: `LocationStep` – back navigation dari Preview ke Location step di Setup Wizard.

### 7. IME Tidak Muncul saat TextField Dibuka via D-Pad

**Issue**: Soft keyboard (IME) tidak muncul saat user menekan SELECT/ENTER pada
`FocusableWidget` yang membungkus `TextField`, meskipun `requestFocus()` terpanggil.

**Root Cause**: `requestFocus()` dipanggil secara synchronous di dalam key-event handler
(`onSelect`). Pada Android TV, Flutter belum selesai memproses key event saat
`requestFocus()` dieksekusi sehingga IME tidak ter-trigger.

**Problem**:
```dart
// ❌ WRONG - requestFocus() synchronous di dalam key-event handler
FocusableWidget(
  onSelect: () {
    _textFieldFocusNode.requestFocus(); // ← IME tidak muncul!
    SystemChannels.textInput.invokeMethod('TextInput.show'); // ← juga tidak membantu
  },
  builder: (isFocused) => TextField(focusNode: _textFieldFocusNode),
)
```

**Solution**:
```dart
// ✅ CORRECT - requestFocus() via addPostFrameCallback
// skipTraversal: true — D-pad tidak auto-landing di TextField,
// tapi requestFocus() programatik tetap berfungsi
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

**Why This Works**:
- `addPostFrameCallback` menunda `requestFocus()` sampai frame berikutnya — setelah
  key event selesai diproses Flutter
- `skipTraversal: true` mencegah D-pad "terdampar" langsung di TextField
- `SystemChannels.textInput.invokeMethod('TextInput.show')` tidak reliable di Android TV,
  hapus saja

**Prevention**:
1. **Semua custom widget** yang membuka TextField via `onSelect` WAJIB pakai `addPostFrameCallback`
2. **Inner `FocusNode`** harus `skipTraversal: true` agar D-pad tidak bypass outer widget
3. **Jangan gunakan** `SystemChannels.textInput` secara manual

**Real Case**: `FocusableTextField` widget di Settings page — tombol ✏️ ditekan via D-pad
tapi keyboard tidak muncul sama sekali.

### 8. BackdropFilter pada Animated Widget — GPU Jank di Android TV

**Issue**: Jank (frame drops, stuttering) pada `RunningTextWidget` / `Marquee`
yang menggunakan `BackdropFilter` (glassmorphism blur) di device Android TV low-end.

**Root Cause**: `BackdropFilter` dengan `ImageFilter.blur` memaksa GPU men-capture snapshot
seluruh layer di belakangnya di **setiap frame**. Dikombinasikan dengan continuous animation
(marquee scroll), GPU terbebani sangat berat karena harus re-blur setiap frame.

**Problem**:
```dart
// ❌ WRONG - BackdropFilter pada widget yang terus beranimasi
ClipRRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // re-evaluated tiap frame!
    child: Marquee(text: longRunningText),             // animasi konstan ↑
  ),
)
```

**Solution**:
```dart
// ✅ CORRECT — Option 1: Hapus BackdropFilter, gunakan solid semi-transparent
RunningTextWidget(showBackground: false) // atau pakai Container solid

// ✅ CORRECT — Option 2: Wrap dengan RepaintBoundary untuk isolasi layer
RepaintBoundary(
  child: RunningTextWidget(...),
)
```

**Why This Works**:
- Menghapus `BackdropFilter` menghilangkan per-frame GPU cost terbesar pada layer blur
- `RepaintBoundary` membuat Flutter cache layer terpisah → hanya footer yang direpaint,
  bukan seluruh layar
- Solid semi-transparent `Container` jauh lebih murah secara GPU daripada blur effect

**Prevention**:
1. **Hindari `BackdropFilter`** pada semua widget yang memiliki internal animation
   (`Marquee`, countdown timer, animasi lain yang berjalan terus)
2. **Selalu `RepaintBoundary`** pada widget yang sering repaint (footer marquee, jam digital)
3. Test performance di device low-end sejak awal, bukan hanya emulator

**Real Case**: `RunningTextWidget` di `StandbyLayout` — glassmorphism background dengan
`BackdropFilter` + `Marquee` → severe GPU jank di Android TV low-end (Android 11).

### 9. Android Screen Timeout / Ambient Mode — Layar Mati Setelah Idle

**Issue**: Layar perangkat menjadi hitam setelah sekitar 10 menit meskipun aplikasi masih aktif
di layar utama. User sering mengira app berpindah ke mode standby internal, padahal app masih
berjalan normal di foreground.

**Root Cause**: `Activity` Android tidak memasang `FLAG_KEEP_SCREEN_ON`, sehingga sistem tetap
menerapkan screen timeout biasa. Pada Android TV ini dapat terlihat sebagai Ambient Mode; pada
HP/tablet terlihat sebagai layar mati karena timeout layar. Ini **bukan** transisi ke
`SholatState` atau `MidnightStandbyState`.

**Problem**:
```kotlin
// ❌ WRONG - Activity tidak menahan layar tetap menyala
package gulajava.mini.miqotul_khoir_tv

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

**Solution**:
```kotlin
// ✅ CORRECT - Pasang FLAG_KEEP_SCREEN_ON di foreground activity
package gulajava.mini.miqotul_khoir_tv

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
   override fun onCreate(savedInstanceState: Bundle?) {
      super.onCreate(savedInstanceState)
      window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
   }
}
```

**Why This Works**:
- Android tidak lagi mematikan layar karena idle selama activity tetap di foreground
- Perilaku ini adalah solusi resmi Android untuk app display / kiosk / TV foreground
- Saat app masuk background, sistem kembali boleh menerapkan timeout layar normal tanpa perlu
  `clearFlags()` manual

**Prevention**:
1. Untuk semua app display Android TV / kiosk, audit `MainActivity` lebih dulu sebelum
  mendiagnosis state machine Flutter
2. Jika keluhan user berbunyi "sekitar 10 menit layar mati", prioritaskan diagnosis screen timeout
  sistem, bukan bug `SholatState`
3. Bedakan gejala ini dari layar hitam internal app: `SholatState` dan `MidnightStandbyState`
  tetap membuat layar perangkat **menyala**, hanya kontennya yang memang hitam
4. Uji di device nyata dengan screen timeout singkat (misal 30 detik atau 1 menit) untuk
  membuktikan fix

**Real Case**: Review Google Play melaporkan aplikasi "kembali ke standby layar hitam" setelah
sekitar 10 menit pada Android TV, tablet, dan HP. Root cause terkonfirmasi sebagai screen timeout
sistem, bukan logika display state internal.

## Flutter Architecture Guidelines

- Follow Clean Architecture principles dengan clear layer separation
- Gunakan Feature-First directory structure untuk scalability
- Implement Repository pattern untuk data access abstraction
- Apply MVVM pattern dengan proper separation of concerns
- Gunakan dependency injection untuk better testability
- **Offline-First**: SQLite sebagai single source of truth, tidak ada network calls

## Widget Best Practices

- Prefer composition over inheritance untuk widget design
- Gunakan `const` constructors untuk improve performance
- Implement proper `Key` usage untuk widget identity
- Create reusable widgets dengan clear, focused responsibilities
- Gunakan `Builder` widgets untuk manage context scope appropriately
- Implement proper disposal of resources di `dispose()` methods
- **Android TV**: Ensure proper focus management untuk semua interactive widgets

## State Management

Project ini menggunakan **Flutter BLoC (Cubit)** untuk state management dengan pattern sebagai berikut:

### Cubit Pattern Guidelines

- Gunakan **Cubit** untuk semua state management (simple, no events needed)
- Apply Clean Architecture dengan SQLite repository pattern
- Gunakan **Equatable** untuk state classes untuk proper state comparison
- Implement proper dependency injection dengan BlocProvider
- **No caching needed**: SQLite sudah menjadi persistent cache
- **No retry mechanism**: Offline-first berarti tidak ada network errors

### State Management Examples

Untuk detailed implementation examples dan patterns, lihat [Architecture Patterns Guide](docs/ARCHITECTURE_PATTERNS.md).

Key patterns covered:

- **Cubit Pattern untuk MKT**: Standard state management implementation
- **State Machine Pattern**: Display state transitions
- **Timer State Pattern**: Countdown dan periodic updates
- **Settings State Pattern**: SQLite-backed configuration management

## Testing

Untuk comprehensive testing strategies termasuk SQLite testing, Cubit testing, dan widget testing, lihat [Testing Guide](docs/TESTING_GUIDE.md).

Basic testing workflow:

Semua testing commands dan detailed procedures didokumentasikan di [Development Workflow Guide](docs/DEVELOPMENT_WORKFLOW.md).

**Required**: Selalu gunakan `flutter test --reporter=expanded` untuk detailed debugging output.

### Testing Priority

1. **SQLite Operations**: Test semua CRUD operations dan transactions
2. **Prayer Time Calculations**: Test dengan berbagai coordinates dan dates
3. **State Machine Transitions**: Test semua state transitions
4. **Timer Management**: Test lifecycle dan disposal
5. **Widget Tests**: Test D-Pad navigation dan focus management

## Performance

Untuk detailed performance optimization strategies dan best practices, lihat [Performance Guide](docs/PERFORMANCE_GUIDE.md).

Key performance principles:

- Minimize `setState()` calls dalam timer callbacks
- Gunakan `const` constructors dimana mungkin
- Implement proper timer disposal untuk prevent memory leaks
- Optimize SQLite queries dengan proper indexing
- Monitor performance dengan Flutter DevTools
- **Target**: 60 FPS rendering pada Android TV devices

### Android TV Performance Patterns (Low-End Device)

Pattern-pattern ini ditemukan saat optimasi `RunningTextWidget` di device Android TV Android 11:

- **`BackdropFilter` + animated widget = GPU jank**: Jangan gunakan `ImageFilter.blur` pada
  widget yang memiliki continuous animation (marquee, countdown, dll). Ganti dengan solid
  semi-transparent `Container`. Lihat pitfall #8.

- **`RepaintBoundary`**: Wrap widget yang sering repaint (footer marquee, jam digital) agar
  Flutter membuat compositing layer terpisah. Tanpa ini, setiap tick jam → full-screen repaint.

- **`buildWhen` pada `BlocBuilder`**: Untuk layout yang hanya perlu update per menit (Standby),
  gunakan `buildWhen: (prev, next) => next.currentTime.minute != prev.currentTime.minute`.
  Hindari rebuild 60x/menit hanya karena cubit tick setiap detik.

- **Self-contained timer di `StatefulWidget`**: Jika sebuah widget hanya perlu update dirinya
  sendiri (contoh: jam digital per detik), letakkan `Timer.periodic` di dalam widget — bukan
  di cubit. Widget memanggil `DateTime.now()` langsung, tidak menerima `currentTime` dari parent.

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

- **Cache `DateFormat` locale**: `DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date)` mahal
  bila dipanggil setiap detik. Simpan hasil format di state, update hanya saat tanggal berubah:

```dart
// ✅ CORRECT — update hanya saat hari berganti
void _updateDateIfNeeded(DateTime now) {
  if (now.day != _cachedDay) {
    _masehiDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    _cachedDay = now.day;
  }
}
```

- **`adhan` prayer calculation — no Isolate needed**: Kalkulasi waktu sholat dengan library
  `adhan` ~1ms (pure math, no I/O). Overhead spawn `Isolate`/`compute()` ~100ms >> calculation
  time. Cukup `async/await` untuk akses SQLite settings.

## UI/UX

Untuk comprehensive UI/UX design principles dan Android TV best practices, lihat [UI/UX Guide](docs/UI_UX_GUIDE.md).

Essential UI/UX guidelines:

- Follow Android TV design guidelines (Leanback library concepts)
- Implement D-Pad navigation untuk semua interactive elements
- Support remote control dengan clear focus indicators
- Gunakan Landscape 16:9 layout (1920x1080 design size, adaptive via ScreenUtil)
- Gunakan `flutter_screenutil` extensions (`.sp`, `.w`, `.h`, `.r`) untuk responsive sizing
- Implement Islamic Glassmorphism theme dengan consistency
- Ensure text readable dari jarak (min 24.sp untuk body text)

## Security & Data Integrity

Core security dan data integrity practices:

- Validate semua user inputs (coordinates, text fields)
- Gunakan SQLite transactions untuk data integrity
- Implement proper error handling dan graceful degradation
- Handle edge cases untuk prayer time calculations
- No sensitive data (karena offline-first, no authentication)
- Prevent SQL injection dengan parameterized queries

## Platform-Specific Considerations

### Android TV Requirements

- **Minimum API Level**: 24 (Android 7.0)
- **Target API Level**: Latest stable
- **TV Support**: LEANBACK launcher + TV banner icon
- **Orientation**: Locked to Landscape
- **Navigation**: D-Pad/Remote control only (no touch)
- **Launcher**: Configured as TV launcher atau boot on startup

### Manifest Configuration

Ensure `AndroidManifest.xml` includes:
- `<uses-feature android:name="android.software.leanback" android:required="false" />` jika APK juga mendukung HP/tablet,
  atau `true` bila distribusi benar-benar TV-only
- `<uses-feature android:name="android.hardware.touchscreen" android:required="false" />`
- `screenOrientation="landscape"` for all activities
- `MAIN` + `LAUNCHER` intent filter untuk instalasi non-TV, dan `MAIN` + `LEANBACK_LAUNCHER`
  untuk Android TV jika produk memang dibagikan ke keduanya

### Screen Timeout / Ambient Mode

- Untuk aplikasi display Android TV, `MainActivity` harus memasang
  `WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON` agar sistem tidak mematikan layar setelah idle.
- Jika gejala user berbunyi "sekitar 10 menit layar mati" atau "kembali ke standby hitam" saat
  app masih di layar utama, prioritaskan diagnosis screen timeout sistem / Ambient Mode sebelum
  menyalahkan state machine Flutter.
- Lihat juga pitfall #9 di bagian `Common Pitfalls & Solutions` untuk root cause dan contoh fix.

---

### Slideshow Pengumuman / Announcement Slideshow (COMPLETED — 2026-05-08)

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

**Technical Patterns & Lessons Learned**:

- **Absolute Cycle Logic**: Slideshow menggunakan jadwal absolut dari `windowStart` (06:00) agar sinkron antar-device.
- **FilePicker v11 Migration**: `FilePicker.platform.pickFiles` dihapus, gunakan static method `FilePicker.pickFiles`. Mocking via `FilePickerPlatform.instance`.
- **FocusableWidget HitTest**: Tombol interaktif di atas layer transparan (Preview) membutuhkan `HitTestBehavior.opaque` agar responsif terhadap remote TV.
- **State Synchronization**: `SlideshowSectionCubit` secara eksplisit memicu `DisplayStateCubit.onSettingsChanged()` setelah operasi file agar UI layar utama langsung ter-update tanpa restart.

---

### Jadwal Imam Sholat Berjamaah (COMPLETED — 2026-05-25)

Fitur tampilan full-screen periodik jadwal imam sholat berjamaah untuk hari ini. Menambahkan
`ImamScheduleState` sebagai State ke-9 pada display state machine. Mendukung maksimal 10 imam,
jadwal 7 hari (Senin–Minggu), dan tampilan khusus hari Jumat dengan pemisahan Khatib dan Imam.
Data bersumber dari tabel SQLite `imams` dan `imam_schedules` dengan foreign key enforcement.
10 phase implementasi, 98 total tests baru.

Prioritas display: `prayer` → `midnight` → `slideshow` (pengumuman) → `imam_schedule` → `wisdom` → `standby`.

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

**Technical Patterns & Lessons Learned**:

- **FK Enforcement via `_onConfigure()`**: Aktifkan `PRAGMA foreign_keys = ON` di method `_onConfigure(Database db)` yang terdaftar ke `openDatabase(onConfigure:...)` agar `ON DELETE SET NULL` benar-benar berlaku saat imam dihapus. Tanpa ini, delete imam tidak men-null-kan `imam_id`/`khatib_id` di jadwal.
- **Jumat Normalization di DataSource**: Aturan "hari Jumat pakai slot `jumat`, bukan `dzuhur`" ditegakkan di `ImamScheduleLocalDataSource.setSchedule()` — konversi `dzuhur`→`jumat` saat `dayOfWeek==5`, tolak `jumat` untuk non-Jumat, dan hapus row konflik legacy. SQLite schema tidak menggunakan trigger tambahan agar solusi tetap sederhana.
- **Cache Jadwal Harian di DisplayStateCubit**: `DisplayStateCubit` menyimpan `_todayImamSchedule` dan `_todayImamScheduleDayOfWeek`. Pada setiap tick, jika `weekday` berubah, jadwal di-reload otomatis — tanpa polling SQLite setiap detik. Pada `onSettingsChanged()`, config dan jadwal hari ini direfresh bersama.
- **Domain Adapter Pattern di Repository**: `ImamRepositoryImpl.update()` mengkonversi `Imam` entity ke `ImamModel` secara eksplisit untuk menghindari runtime cast error (`type 'Imam' is not a subtype of type 'ImamModel'`). Repository bertindak sebagai adapter domain ↔ data layer.
- **`isImamScheduleLocked` Dikecualikan dari `TransitionConfig`**: Field lock hanya mempengaruhi UI admin di halaman Settings (disable/enable editing). Tidak perlu masuk ke evaluator display — evaluator hanya memeriksa 7 field scheduling yang relevan.

Planning doc: `plan/feature-imam-schedule-1.md` (v1.4, status: Completed)

---

**Last Updated**: May 30, 2026
**Version**: 2.2.0
**Project**: Miqotul Khoir TV (MKT)
**Platform**: Android TV
**Related Docs**: [ARCHITECTURE_PATTERNS.md](docs/ARCHITECTURE_PATTERNS.md), [Product_Requirement_Document.md](Product_Requirement_Document.md)
