---
goal: "Implementasi Alarm Tanda Waktu (Pre-Adzan & Pre-Iqomah Alert)"
version: 1.0
date_created: 2026-03-17
last_updated: 2026-03-17
owner: "Gulajava Ministudio"
status: "Planned"
tags: [feature, audio, alarm, settings, state-machine, display, notification]
---

## Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

Dokumen ini mendefinisikan rencana implementasi fitur **Alarm Tanda Waktu** untuk aplikasi
Miqotul Khoir TV. Fitur ini membunyikan suara alarm pendek beberapa detik **sebelum masuk
waktu Adzan** dan/atau **sebelum Iqomah selesai** (transisi ke Sholat), sebagai tanda
pengingat bagi jamaah masjid.

Fitur bersifat opsional (default OFF) dengan dua toggle terpisah — satu untuk Pre-Adzan
dan satu untuk Pre-Iqomah — yang dapat dikonfigurasi DKM melalui menu Pengaturan.
Durasi alarm sebelum trigger dapat diatur antara 5 hingga 15 detik.

File audio alarm (`assets/sound/alarm_before_adhan_and_iqamah.mp3`, ~501 KB, ~16 detik)
sudah tersedia di repositori. Audio akan **dihentikan secara programatik** saat transisi
state terjadi (PreAdzan→Adzan dan Iqomah→Sholat) sehingga suara alarm tidak overlap
dengan state berikutnya.

## 1. Requirements & Constraints

- **REQ-001**: Tambahkan dua toggle terpisah: `isPreAdzanAlertEnabled` (default: `false`)
  dan `isPreIqomahAlertEnabled` (default: `false`).
- **REQ-002**: Tambahkan dua konfigurasi durasi: `preAdzanAlertSeconds` (default: `10`,
  range 5–15) dan `preIqomahAlertSeconds` (default: `10`, range 5–15).
- **REQ-003**: Alarm Pre-Adzan berbunyi saat `PreAdzanState.remainingDuration.inSeconds`
  mencapai atau di bawah nilai `preAdzanAlertSeconds` **dan** `isPreAdzanAlertEnabled` true.
- **REQ-004**: Alarm Pre-Iqomah berbunyi saat `IqomahState.remainingDuration.inSeconds`
  mencapai atau di bawah nilai `preIqomahAlertSeconds` **dan** `isPreIqomahAlertEnabled`
  true.
- **REQ-005**: Setiap alarm hanya berbunyi **satu kali per siklus** (tidak berulang tiap
  detik selama dalam threshold window). Flag `_preAdzanAlertFired` dan
  `_preIqomahAlertFired` mencegah trigger berulang.
- **REQ-006**: Audio alarm **dihentikan secara programatik** (`player.stop()`) saat state
  bertransisi keluar dari PreAdzanState (→ AdzanState) dan keluar dari IqomahState
  (→ SholatState). Ini mencegah audio 16 detik overlap dengan state berikutnya.
- **REQ-007**: Flag alarm di-reset saat state bertransisi keluar dari PreAdzan atau Iqomah,
  sehingga setiap waktu sholat memiliki siklus alarm baru.
- **REQ-008**: File audio sudah tersedia di `assets/sound/alarm_before_adhan_and_iqamah.mp3`.
  Tidak perlu download runtime — app tetap 100% offline.
- **REQ-009**: Konfigurasi disimpan di SQLite (tabel `settings`) dan dimuat via
  `TransitionConfig`.
- **REQ-010**: UI Settings menggunakan dua pasang `Switch.adaptive` + `DPadStepper`
  (pattern identik dengan `MidnightModeSection`). DPadStepper bersifat conditional
  visible — hanya tampil jika toggle terkait ON.

- **SEC-001**: Tidak ada data sensitif baru. Konfigurasi menggunakan mekanisme
  penyimpanan yang sudah ada (`SettingsRepository`).
- **SEC-002**: Package `audioplayers` tidak melakukan network call — source audio adalah
  `AssetSource` (bundled). Tidak memerlukan permission internet atau storage eksternal.

- **CON-001**: Logic trigger alarm adalah **side-effect presentasi**, bukan business logic
  domain. Logika ini ditempatkan di `DisplayStateCubit._tick()`, bukan di
  `EvaluateDisplayStateUseCase`.
- **CON-002**: `AudioAlertService` berperan sebagai *port* (abstraksi domain) —
  interface didefinisikan di `lib/domain/services/` dan implementasi di
  `lib/data/services/`. Ini menjaga compliance DIP (Dependency Inversion Principle).
- **CON-003**: DB migration ke version 9 menggunakan pattern `ALTER TABLE` yang konsisten
  dengan migration sebelumnya (v2–v8).
- **CON-004**: `audioplayers` menggunakan `AssetSource('sound/alarm_before_adhan_and_iqamah.mp3')`
  — prefix `assets/` adalah default package, sehingga path yang dispesifikasikan
  dimulai dari subdirektori `sound/`.
- **CON-005**: `player.stop()` bersifat async namun efeknya hampir instan (<50ms).
  Tidak perlu blocking `await` di dalam `_tick()` yang berjalan setiap detik.
- **CON-006**: `AudioAlertServiceImpl` perlu di-`dispose()` saat `DisplayStateCubit`
  di-close, untuk mencegah memory leak `AudioPlayer`.

- **GUD-001**: Ikuti pattern fitur Midnight Mode untuk integrasi Settings (entity →
  model → data source → cubit → UI section).
- **GUD-002**: **D-Pad Toggle Pattern** — Toggle ON/OFF menggunakan
  `FocusableWidget(onSelect: ...)`. `Switch.adaptive` di dalam boks toggle bersifat
  visual-only (`onChanged: null`). Pattern identik dengan `MidnightModeSection`.
- **GUD-003**: **D-Pad Stepper Disable Pattern** — `DPadStepper` untuk detik alarm
  dibungkus `ExcludeFocus` + `IgnorePointer` + `Opacity` saat toggle OFF.
- **GUD-004**: Section baru **"Alarm Tanda Waktu"** disisipkan di posisi ke-6 pada
  `SettingsMenuPage`, setelah "Durasi Tampilan" dan sebelum "Running Text".

- **PAT-001**: Flag guard pattern — `_preAdzanAlertFired` dan `_preIqomahAlertFired`
  sebagai field `bool` di `DisplayStateCubit`, diset `true` saat playAlert dipanggil
  dan di-reset saat state bertransisi keluar dari state bersangkutan.
- **PAT-002**: Stop-before-reset pattern — panggil `stopAlert()` **sebelum** reset
  flag, agar audio dihentikan bahkan jika timeline sangat singkat.

## 2. Implementation Steps

### Phase 1 — Domain Layer: Settings Entity, TransitionConfig & AudioAlertService Interface

- GOAL-001: Memperluas model domain dengan 4 field alarm baru dan mendefinisikan
  abstraksi `AudioAlertService` sebagai port di domain layer.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Tambahkan 4 field baru ke `Settings` entity (`lib/domain/entities/settings.dart`): `isPreAdzanAlertEnabled` (bool, default `false`), `isPreIqomahAlertEnabled` (bool, default `false`), `preAdzanAlertSeconds` (int, default `10`), `preIqomahAlertSeconds` (int, default `10`). Update constructor defaults, `copyWith()`, dan `props`. | | |
| TASK-002 | Tambahkan 4 field baru ke `TransitionConfig` (`lib/domain/entities/transition_config.dart`): `isPreAdzanAlertEnabled`, `isPreIqomahAlertEnabled`, `preAdzanAlertSeconds`, `preIqomahAlertSeconds`. Update constructor, `fromSettings()` factory, dan `props`. | | |
| TASK-003 | Buat file baru `lib/domain/services/audio_alert_service.dart` — abstract class `AudioAlertService` dengan 3 method: `Future<void> playAlert()`, `Future<void> stopAlert()`, `Future<void> dispose()`. Zero infrastructure import (domain-pure). | | |

### Phase 2 — Data Layer: Database Migration, SettingsModel & AudioAlertServiceImpl

- GOAL-002: Memperluas schema SQLite, model data, dan membuat implementasi konkret
  `AudioAlertService` menggunakan package `audioplayers`.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-004 | Naikkan `_databaseVersion` dari `8` ke `9` di `DatabaseHelper` (`lib/data/datasources/database_helper.dart`). | | |
| TASK-005 | Tambahkan migration block `if (oldVersion < 9)` di `_onUpgrade()` dengan 4 `ALTER TABLE settings ADD COLUMN`: `is_pre_adzan_alert_enabled INTEGER NOT NULL DEFAULT 0`, `is_pre_iqomah_alert_enabled INTEGER NOT NULL DEFAULT 0`, `pre_adzan_alert_seconds INTEGER NOT NULL DEFAULT 10`, `pre_iqomah_alert_seconds INTEGER NOT NULL DEFAULT 10`. | | |
| TASK-006 | Tambahkan 4 kolom yang sama di DDL `_createTables()` (blok `CREATE TABLE settings`) untuk fresh install. | | |
| TASK-007 | Update `SettingsModel` (`lib/data/models/settings_model.dart`): tambah 4 field baru di `fromMap()` (snake_case → camelCase, int→bool untuk flag) dan `toMap()` (camelCase → snake_case, bool→int). | | |
| TASK-008 | Update unit test `SettingsModel` (`test/data/models/settings_model_test.dart`): tambah assertion untuk 4 field baru di test `fromMap` default, `fromMap` custom, `toMap`, dan round-trip. | | |
| TASK-009 | Buat file baru `lib/data/services/audio_alert_service_impl.dart` — class `AudioAlertServiceImpl implements AudioAlertService`. Gunakan `AudioPlayer` dari package `audioplayers`. `playAlert()` memanggil `player.play(AssetSource('sound/alarm_before_adhan_and_iqamah.mp3'))`. `stopAlert()` memanggil `player.stop()`. `dispose()` memanggil `player.dispose()`. | | |
| TASK-010 | Tambahkan dependency `audioplayers` ke `pubspec.yaml` (section `dependencies`). Gunakan versi stabil terbaru yang kompatibel dengan Flutter 3.x (misal `audioplayers: ^6.1.0`). | | |
| TASK-011 | Daftarkan `assets/sound/` di `pubspec.yaml` section `flutter.assets` agar `AudioPlayer` dapat mengakses file melalui `AssetSource`. | | |

### Phase 3 — Presentation Layer: SettingsCubit Update

- GOAL-003: Menambahkan 4 method update ke `SettingsCubit` untuk mendukung
  perubahan konfigurasi alarm dari UI Settings.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-012 | Tambahkan 4 method ke `SettingsCubit` (`lib/presentation/cubits/settings/settings_cubit.dart`): `void updatePreAdzanAlertEnabled(bool value)`, `void updatePreIqomahAlertEnabled(bool value)`, `void updatePreAdzanAlertSeconds(int seconds)`, `void updatePreIqomahAlertSeconds(int seconds)`. Ikuti pola method update yang sudah ada (auto-save debounce). | | |
| TASK-013 | Update unit test `SettingsCubit` (`test/presentation/cubits/settings/settings_cubit_test.dart`): tambah 4 test case untuk method update baru — verifikasi state diperbarui dengan benar dan auto-save dipicu. | | |

### Phase 4 — Presentation Layer: DisplayStateCubit Update

- GOAL-004: Mengintegrasikan `AudioAlertService` ke dalam `DisplayStateCubit` —
  menambahkan logic trigger alarm saat threshold tercapai dan logic stop saat transisi
  state terjadi.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-014 | Tambahkan `AudioAlertService` sebagai parameter wajib di constructor `DisplayStateCubit` (`lib/presentation/cubits/display_state/display_state_cubit.dart`). Simpan sebagai field `final AudioAlertService _audioAlertService`. | | |
| TASK-015 | Tambahkan dua field flag di `DisplayStateCubit`: `bool _preAdzanAlertFired = false` dan `bool _preIqomahAlertFired = false`. | | |
| TASK-016 | Tambahkan method private `void _checkAlertStop(DisplayState previous, DisplayState next)`. Method ini: (a) jika `previous is PreAdzanState` dan `next is! PreAdzanState` → panggil `_audioAlertService.stopAlert()`, reset `_preAdzanAlertFired = false`; (b) jika `previous is IqomahState` dan `next is! IqomahState` → panggil `_audioAlertService.stopAlert()`, reset `_preIqomahAlertFired = false`. | | |
| TASK-017 | Tambahkan method private `void _checkAlertTrigger(DisplayState newState)`. Method ini: (a) jika `newState is PreAdzanState` dan `remaining.inSeconds <= config.preAdzanAlertSeconds` dan `!_preAdzanAlertFired` dan `config.isPreAdzanAlertEnabled` → panggil `_audioAlertService.playAlert()`, set `_preAdzanAlertFired = true`; (b) kondisi simetris untuk `IqomahState` dan `_preIqomahAlertFired`. | | |
| TASK-018 | Update method `_tick()` di `DisplayStateCubit`: simpan `previous = state` sebelum evaluasi, setelah mendapat `newState` panggil `_checkAlertStop(previous, newState)`, lalu `emit(newState)`, lalu `_checkAlertTrigger(newState)`. | | |
| TASK-019 | Override method `close()` di `DisplayStateCubit`: panggil `_audioAlertService.stopAlert()` dan `_audioAlertService.dispose()` sebelum `super.close()`. | | |
| TASK-020 | Update unit test `DisplayStateCubit` (`test/presentation/cubits/display_state/display_state_cubit_test.dart`): tambah mock `MockAudioAlertService` via `mocktail`. Skenario test: (a) alert Pre-Adzan dipanggil saat `remaining <= threshold` dan toggle ON; (b) alert tidak dipanggil saat toggle OFF; (c) alert tidak dipanggil ganda (fired flag); (d) `stopAlert()` dipanggil saat transisi PreAdzan→Adzan; (e) kondisi simetris untuk Pre-Iqomah; (f) `dispose()` dipanggil saat cubit close. | | |

### Phase 5 — Presentation Layer: Settings UI Section

- GOAL-005: Membuat widget section baru "Alarm Tanda Waktu" dan mengintegrasikannya
  ke `SettingsMenuPage`.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-021 | Buat file baru `lib/presentation/pages/settings/sections/alert_settings_section.dart` — class `AlertSettingsSection extends StatelessWidget`. Berisi: dua blok toggle (`FocusableWidget` + `Switch.adaptive` visual-only) masing-masing diikuti satu `DPadStepper` (5–15 detik, step 1, conditional `ExcludeFocus`/`IgnorePointer`/`Opacity`). Ikuti struktur dan style `MidnightModeSection` sebagai referensi. | | |
| TASK-022 | Update `SettingsMenuPage` (`lib/presentation/pages/settings/settings_menu_page.dart`): tambahkan `'Alarm Tanda Waktu'` ke list `_categories` di posisi ke-6 (setelah "Durasi Tampilan"), dan `AlertSettingsSection()` ke list `_sections` di posisi yang sama. Import file section baru. | | |
| TASK-023 | Buat widget test `test/presentation/pages/settings/sections/alert_settings_section_test.dart`. Skenario: (a) kedua toggle OFF saat default; (b) tap toggle Pre-Adzan → memanggil `updatePreAdzanAlertEnabled(true)`; (c) tap toggle Pre-Iqomah → memanggil `updatePreIqomahAlertEnabled(true)`; (d) DPadStepper tersembunyi saat toggle OFF; (e) DPadStepper muncul dan aktif saat toggle ON; (f) DPadStepper memanggil `updatePreAdzanAlertSeconds` / `updatePreIqomahAlertSeconds` dengan nilai yang benar. | | |

### Phase 6 — Wiring & DI: main.dart

- GOAL-006: Mengintegrasikan `AudioAlertServiceImpl` ke dalam dependency injection
  di `main.dart` dan meneruskannya ke `DisplayStateCubit`.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-024 | Update `main.dart`: import `AudioAlertServiceImpl` dari `lib/data/services/audio_alert_service_impl.dart`. Instansiasi `final audioAlertService = AudioAlertServiceImpl()` di dalam `builder` function `ScreenUtilInit`, bersamaan dengan use case dan cubit lainnya. | | |
| TASK-025 | Update instantiasi `DisplayStateCubit` di `main.dart`: tambahkan parameter `audioAlertService: audioAlertService` pada constructor call. | | |

## 3. Alternatives

- **ALT-001**: Menyimpan logika trigger alarm di `EvaluateDisplayStateUseCase` sebagai
  bagian dari domain. Ditolak karena alarm adalah *side-effect presentasi* (memutar
  suara), bukan business policy. Mencampur audio trigger di domain layer akan melanggar
  DIP dan membuat use case tidak murni.
- **ALT-002**: Menggunakan package `just_audio` sebagai audio player. Lebih powerful
  tetapi memerlukan dependency tambahan (`audio_session`) dan lebih kompleks untuk
  use case sesederhana "play satu file pendek + stop". `audioplayers` lebih ringan dan
  cukup.
- **ALT-003**: Membiarkan audio berbunyi sampai selesai (tidak di-stop saat transisi).
  Ditolak karena audio 16 detik yang masih berbunyi saat layar sudah menampilkan
  "WAKTU ADZAN" atau "SHOLAT BERJAMAAH" akan membingungkan jamaah.
- **ALT-004**: Menggunakan satu toggle saja untuk mengontrol keduanya (Pre-Adzan dan
  Pre-Iqomah sekaligus). Ditolak sesuai permintaan user — DKM mungkin hanya ingin
  alarm sebelum adzan saja atau sebelum iqomah saja.
- **ALT-005**: Durasi alert di-hardcode ke 10 detik. Ditolak sesuai permintaan user —
  dikonfigurasi 5–15 detik via `DPadStepper`.

## 4. Dependencies

- **DEP-001**: `audioplayers: ^6.1.0` — Flutter plugin untuk memutar audio dari
  bundled asset. Mendukung Android (termasuk Android TV). Tidak memerlukan network
  atau permission storage eksternal.
- **DEP-002**: `assets/sound/alarm_before_adhan_and_iqamah.mp3` — File audio alarm
  (~501 KB, ~16 detik) yang sudah tersedia di repositori. Perlu didaftarkan di
  `pubspec.yaml` section `flutter.assets`.
- **DEP-003**: Semua dependency yang sudah ada (Equatable, sqflite, flutter_bloc,
  mocktail) tetap digunakan tanpa perubahan versi.

## 5. Files

- **FILE-001**: `lib/domain/entities/settings.dart` — Tambah 4 field alarm (ubah).
- **FILE-002**: `lib/domain/entities/transition_config.dart` — Tambah 4 field alarm
  + update `fromSettings()` (ubah).
- **FILE-003**: `lib/domain/services/audio_alert_service.dart` — Abstract interface
  `AudioAlertService` (baru).
- **FILE-004**: `lib/data/datasources/database_helper.dart` — Migration v9, DDL
  update (ubah).
- **FILE-005**: `lib/data/models/settings_model.dart` — `fromMap`/`toMap` 4 field
  baru (ubah).
- **FILE-006**: `lib/data/services/audio_alert_service_impl.dart` — Implementasi
  konkret menggunakan `audioplayers` (baru).
- **FILE-007**: `lib/presentation/cubits/settings/settings_cubit.dart` — 4 update
  methods baru (ubah).
- **FILE-008**: `lib/presentation/cubits/display_state/display_state_cubit.dart` —
  Inject `AudioAlertService`, flag, `_checkAlertStop`, `_checkAlertTrigger`,
  update `_tick()`, update `close()` (ubah).
- **FILE-009**: `lib/presentation/pages/settings/sections/alert_settings_section.dart`
  — Widget section Settings UI (baru).
- **FILE-010**: `lib/presentation/pages/settings/settings_menu_page.dart` — Tambah
  menu entry + section di posisi ke-6 (ubah).
- **FILE-011**: `lib/main.dart` — Instansiasi `AudioAlertServiceImpl`, inject ke
  `DisplayStateCubit` (ubah).
- **FILE-012**: `pubspec.yaml` — Tambah `audioplayers`, tambah `assets/sound/` (ubah).
- **FILE-013**: `test/data/models/settings_model_test.dart` — Update assertions untuk
  4 field baru (ubah).
- **FILE-014**: `test/presentation/cubits/settings/settings_cubit_test.dart` — Tambah
  4 test case update method baru (ubah).
- **FILE-015**: `test/presentation/cubits/display_state/display_state_cubit_test.dart`
  — Tambah mock + 6 skenario test alarm (ubah).
- **FILE-016**: `test/presentation/pages/settings/sections/alert_settings_section_test.dart`
  — 6 widget test scenario (baru).

## 6. Testing

- **TEST-001**: `SettingsModel` — verifikasi `fromMap` membaca 4 field baru dengan
  nilai default yang benar (int `0` → bool `false`, nilai default `10`).
- **TEST-002**: `SettingsModel` — verifikasi `toMap` menghasilkan snake_case key yang
  benar dengan konversi bool→int.
- **TEST-003**: `SettingsCubit` — verifikasi `updatePreAdzanAlertEnabled(true)` mengubah
  state dengan benar dan auto-save dipicu.
- **TEST-004**: `SettingsCubit` — verifikasi `updatePreAdzanAlertSeconds(5)` memvalidasi
  range dan memperbarui state.
- **TEST-005**: `DisplayStateCubit` — saat `PreAdzanState.remainingDuration` ≤
  `preAdzanAlertSeconds` dan toggle ON → `playAlert()` dipanggil tepat sekali.
- **TEST-006**: `DisplayStateCubit` — saat toggle OFF → `playAlert()` tidak pernah
  dipanggil.
- **TEST-007**: `DisplayStateCubit` — `playAlert()` tidak dipanggil dua kali untuk
  siklus yang sama (flag guard berfungsi).
- **TEST-008**: `DisplayStateCubit` — saat transisi PreAdzanState → AdzanState →
  `stopAlert()` dipanggil dan flag di-reset.
- **TEST-009**: `DisplayStateCubit` — skenario simetris untuk Pre-Iqomah (TEST-005
  hingga TEST-008).
- **TEST-010**: `DisplayStateCubit` — `dispose()` dipanggil pada `AudioAlertService`
  saat cubit di-close.
- **TEST-011**: `AlertSettingsSection` widget — kedua toggle OFF saat default, DPadStepper
  tersembunyi.
- **TEST-012**: `AlertSettingsSection` widget — tap toggle Pre-Adzan ON →
  `updatePreAdzanAlertEnabled(true)` dipanggil, DPadStepper muncul.
- **TEST-013**: `AlertSettingsSection` widget — tap toggle Pre-Iqomah ON →
  `updatePreIqomahAlertEnabled(true)` dipanggil, DPadStepper muncul.

## 7. Risks & Assumptions

- **RISK-001**: Android TV tertentu mungkin tidak merender audio via HDMI secara
  otomatis jika volume sistem nol. Mitigasi: ini berada di luar kontrol aplikasi —
  user bertanggung jawab mengatur volume TV.
- **RISK-002**: `audioplayers` v6.x mungkin membutuhkan Android `minSdkVersion` yang
  lebih tinggi dari yang dikonfigurasi saat ini. Perlu diverifikasi di
  `android/app/build.gradle.kts` setelah dependency ditambahkan ke `pubspec.yaml`.
- **RISK-003**: Audio yang di-stop sangat cepat (< 1 detik setelah trigger, misal
  jika `preAdzanAlertSeconds = 0` — namun minimum 5 detik sesuai REQ-002) akan
  terkesan "putus-putus". Mitigrasi: minimum 5 detik cukup untuk pengguna mendengar
  bunyi alarm dengan jelas sebelum transisi.
- **RISK-004**: `_tick()` berjalan asinkron dan `playAlert()`/`stopAlert()` bersifat
  `async`. Pemanggilan tanpa `await` di dalam `_tick()` adalah by design —
  audio playback tidak perlu blocking timer. Perlu dipastikan tidak ada race condition
  jika `_tick()` dipanggil berulang sangat cepat saat test.

- **ASSUMPTION-001**: File audio `alarm_before_adhan_and_iqamah.mp3` sudah berada di
  `assets/sound/` dan tidak perlu diubah atau dikonversi format.
- **ASSUMPTION-002**: Satu instance `AudioPlayer` yang sama digunakan untuk kedua
  jenis alarm (Pre-Adzan dan Pre-Iqomah). Tidak perlu dua instance terpisah karena
  keduanya tidak akan pernah overlap (Pre-Adzan dan Iqomah tidak terjadi bersamaan).
- **ASSUMPTION-003**: `audioplayers` kompatibel dengan Android API level yang sudah
  dikonfigurasi di project ini.
- **ASSUMPTION-004**: Implementasi `stopAlert()` pada `AudioAlertServiceImpl` aman
  dipanggil meskipun tidak ada audio yang sedang diputar (tidak akan throw exception).

## 8. Related Specifications / Further Reading

- [feature-midnight-mode-1.md](feature-midnight-mode-1.md) — Referensi pattern
  implementasi fitur opsional dengan toggle + settings (struktur serupa).
- [feature-wisdom-quote-1.md](feature-wisdom-quote-1.md) — Referensi pattern
  D-Pad toggle dan conditional DPadStepper.
- [audioplayers Documentation](https://github.com/bluefireteam/audioplayers/blob/main/getting_started.md)
  — Dokumentasi resmi package yang digunakan.
- [spec-process-state-machine.md](../spec/spec-process-state-machine.md) — Spesifikasi
  display state machine yang mendasari logika trigger alarm.
