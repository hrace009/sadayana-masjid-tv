---
goal: "Implementasi Fitur Kata Mutiara Islam — Tampilan Full-Screen Periodik dengan Ayat Al-Quran dan Hadits"
version: "1.0"
date_created: "2026-03-09"
last_updated: "2026-03-10"
phase_completed: "Phase 14"
owner: "MKT Dev Team"
status: "Completed"
tags: [feature, state-machine, android-tv, settings, display, sqlite, migration]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)
![Phase 1: Done](https://img.shields.io/badge/Phase%201-Done-brightgreen)
![Phase 2: Done](https://img.shields.io/badge/Phase%202-Done-brightgreen)
![Phase 3: Done](https://img.shields.io/badge/Phase%203-Done-brightgreen)
![Phase 4: Done](https://img.shields.io/badge/Phase%204-Done-brightgreen)
![Phase 5: Done](https://img.shields.io/badge/Phase%205-Done-brightgreen)
![Phase 6: Done](https://img.shields.io/badge/Phase%206-Done-brightgreen)
![Phase 7: Done](https://img.shields.io/badge/Phase%207-Done-brightgreen)
![Phase 8: Done](https://img.shields.io/badge/Phase%208-Done-brightgreen)
![Phase 9: Done](https://img.shields.io/badge/Phase%209-Done-brightgreen)
![Phase 10: Done](https://img.shields.io/badge/Phase%2010-Done-brightgreen)
![Phase 11: Done](https://img.shields.io/badge/Phase%2011-Done-brightgreen)
![Phase 12: Done](https://img.shields.io/badge/Phase%2012-Done-brightgreen)
![Phase 13: Done](https://img.shields.io/badge/Phase%2013-Done-brightgreen)
![Phase 14: Done](https://img.shields.io/badge/Phase%2014-Done-brightgreen)

Fitur **Kata Mutiara Islam** menambahkan sebuah tampilan full-screen tambahan (State ke-6) pada mesin tampilan
utama (_display state machine_) aplikasi Miqotul Khoir TV. Secara periodik — sesuai interval yang dikonfigurasi
admin — layar standby digantikan sementara oleh satu kartu konten besar yang menampilkan ayat Al-Quran atau
hadits terpilih beserta terjemahan dan referensinya.

Fitur ini **bukan overlay** di atas `StandbyLayout`, melainkan `DisplayState` baru (`WisdomQuoteState`) yang
dikelola sepenuhnya oleh `EvaluateDisplayStateUseCase` dan ditampilkan melalui `AnimatedSwitcher` 500 ms yang
sudah ada.

Konten bersumber dari katalog **11 item hardcoded** (5 ayat Al-Quran + 6 Hadits) yang tersimpan sebagai JSON
asset. Admin dapat memilih item mana saja yang aktif, mengatur interval dan durasi tampil, serta memilih mode
urut atau acak deterministik. Tersedia pula tombol **Preview** untuk melihat pratinjau item yang dipilih
sebelum diterapkan.

## Sketsa Layout

### WisdomQuoteLayout (Full-Screen)

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│  [JAM DIGITAL 00:00]        SELASA, 9 MARET 2026        [8 SYA'BAN 1447 H]         │  ← Header (clone StandbyLayout)
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│                          ┌─────────────────────┐                                   │
│                          │  🕌  Ayat Al-Quran   │  ← badge label (type)            │
│                          └─────────────────────┘                                   │
│                                                                                     │
│                "Karena sesungguhnya bersama kesulitan                               │
│                       ada kemudahan."                                               │  ← translationText (large)
│                                                                                     │
│                      QS. Al-Insyirah [94]: 6                                       │  ← reference (small, 2-line ok)
│                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│  ████████████████████░░░░░░░░░░  (progress bar)         3 / 7   Masjid Al-Ikhlas  │  ← Footer
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### WisdomPreviewPage (Modal Full-Screen)

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                    [ PREVIEW KATA MUTIARA — 3 item dipilih ]                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│       ◄ PREV                [WisdomQuoteLayout ditampilkan ulang]        NEXT ►     │
│                                                                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                           ●  ○  ○     (dot indicator)                              │
│                                                                                     │
│                       [ Tutup Preview (FocusableWidget) ]                          │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Requirements & Constraints

### Functional Requirements

- **REQ-001**: Tampilkan satu item Kata Mutiara setiap siklus periodik berdasarkan `wisdomIntervalMinutes`
  + `wisdomDurationMinutes`.
- **REQ-002**: Fitur dapat diaktifkan/dinonaktifkan admin via toggle di halaman Settings.
- **REQ-003**: Interval kemunculan dikonfigurasi 5–30 menit (default: 15 menit).
- **REQ-004**: Durasi tampil per item dikonfigurasi 1–10 menit (default: 3 menit).
- **REQ-005**: Admin dapat membatasi jam aktif fitur (jam mulai dan jam selesai).
- **REQ-006**: Katalog 11 item hardcoded (5 Al-Quran + 6 Hadits) — tidak dapat diedit oleh admin.
- **REQ-007**: Admin memilih item yang ditampilkan via checklist multi-select; minimum 1 item harus dicentang
  agar fitur bekerja.
- **REQ-008**: Mode tampil urut (default) atau acak deterministik (seed = tanggal hari ini).
- **REQ-009**: Tombol Preview di Settings membuka halaman pratinjau fullscreen dengan navigasi D-Pad dan
  auto-slide 5 detik.
- **REQ-010**: Tampilan hanya menampilkan teks terjemahan dan referensi (tanpa teks Arab).
- **REQ-011**: State sholat (preAdzan, adzan, iqomah, sholat) selalu lebih prioritas daripada Kata Mutiara —
  dievaluasi lebih dahulu dalam `EvaluateDisplayStateUseCase`.

### Security Requirements

- **SEC-001**: Data katalog bersumber dari asset bundled — tidak ada parse dari input user, mencegah injection.
- **SEC-002**: Penyimpanan `wisdomSelectedIds` sebagai JSON string di SQLite menggunakan parameterized query
  yang sudah ada.

### Constraints

- **CON-001**: Tidak ada teks Arab — hanya terjemahan Bahasa Indonesia + referensi.
- **CON-002**: Tidak ada konten custom dari admin — katalog tetap hardcoded sebagai JSON asset.
- **CON-003**: Offline-first — tidak ada network calls sama sekali.
- **CON-004**: Platform target: Android TV 1920×1080 (utama) dan 1280×720 (fallback), navigasi D-Pad.
- **CON-005**: Tidak ada filter per tipe (Quran vs Hadits) — satu list terpadu dengan label tipe.

### Guidelines

- **GUD-001**: Tambahkan `wisdomQuote` sebagai State ke-6 di `DisplayStateType` (bukan sub-mode overlay).
- **GUD-002**: Guard kondisi wajib: jika `activeQuotes.isEmpty` → skip wisdom check → fallback ke
  `StandbyState`.
- **GUD-003**: Gunakan `LayoutBuilder` + `FittedBox(fit: BoxFit.scaleDown)` untuk kompatibilitas
  multi-resolusi.
- **GUD-004**: Semua elemen interaktif wajib accessible via D-Pad menggunakan `FocusableWidget`.

### Patterns to Follow

- **PAT-001**: Ikuti pola migrasi database `if (oldVersion < N)` di `DatabaseHelper._onUpgrade()`.
- **PAT-002**: Ikuti pola `_debounceSave()` untuk input bertipe stepper di `SettingsCubit`.
- **PAT-003**: Ikuti pola `TreasurySection` untuk struktur Settings UI (toggle + conditional fields).
- **PAT-004**: Ikuti pola header clock+tanggal dari `StandbyLayout` untuk `WisdomQuoteLayout`.
- **PAT-005**: Gunakan `RepositoryProvider<WisdomQuoteRepository>` di `main.dart` untuk dependency injection.

---

## 2. Implementation Steps

### Phase 1 — Katalog Asset & Domain Entities Baru

- **GOAL-001**: Mendefinisikan kontrak domain (entity + repository interface) dan menyiapkan file aset katalog
  11 item. Fase ini murni domain layer — zero infrastructure imports.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat `assets/data/wisdom_quotes.json` dengan 11 item (struktur JSON lengkap lihat Section 8) | ✅ | 2026-03-09 |
| TASK-002 | Verifikasi `assets/data/` sudah terdaftar di `pubspec.yaml` (sudah ada via `- assets/data/`, tidak perlu tambahan) | ✅ | 2026-03-09 |
| TASK-003 | Buat `lib/domain/entities/wisdom_quote.dart` — immutable `WisdomQuote` entity: `id` (String), `type` (String: `"quran"` / `"hadith"`), `label` (String: label tampilan), `translationText` (String), `reference` (String). Extends `Equatable`, `props: [id]`. | ✅ | 2026-03-09 |
| TASK-004 | Buat `lib/domain/repositories/wisdom_quote_repository.dart` — abstract interface: `Future<List<WisdomQuote>> getAll()`, `Future<List<WisdomQuote>> getByIds(List<String> ids)`. Zero infrastructure imports. | ✅ | 2026-03-09 |

### Phase 2 — Database Migration v7

- **GOAL-002**: Menambahkan 9 kolom baru ke tabel `settings` untuk menyimpan konfigurasi fitur Kata Mutiara.
  Menggunakan pola migrasi `if (oldVersion < N)` yang sudah ada.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-005 | Di `lib/data/datasources/database_helper.dart`: naikkan `_databaseVersion` dari `6` ke `7`. | ✅ | 2026-03-09 |
| TASK-006 | Tambah migration block `if (oldVersion < 7)` di `_onUpgrade()` dengan 9 pernyataan `ALTER TABLE settings ADD COLUMN`: `is_wisdom_enabled INTEGER NOT NULL DEFAULT 0`, `wisdom_interval_minutes INTEGER NOT NULL DEFAULT 15`, `wisdom_duration_minutes INTEGER NOT NULL DEFAULT 3`, `wisdom_start_hour INTEGER NOT NULL DEFAULT 6`, `wisdom_start_minute INTEGER NOT NULL DEFAULT 0`, `wisdom_end_hour INTEGER NOT NULL DEFAULT 21`, `wisdom_end_minute INTEGER NOT NULL DEFAULT 0`, `wisdom_selected_ids TEXT NOT NULL DEFAULT '[]'`, `wisdom_shuffle INTEGER NOT NULL DEFAULT 0`. | ✅ | 2026-03-09 |
| TASK-007 | Update DDL di `_createTables()` — tambahkan 9 definisi kolom yang sama ke CREATE TABLE statement `settings` agar fresh install juga mendapatkan skema lengkap. | ✅ | 2026-03-09 |

### Phase 3 — Domain Layer Update

- **GOAL-003**: Memperbarui semua domain entities dan use case yang terdampak untuk mengakomodasi
  `WisdomQuoteState` sebagai State ke-6.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-008 | Update `lib/domain/entities/settings.dart` — tambah 9 field baru ke constructor, default values (`isWisdomEnabled: false`, `wisdomIntervalMinutes: 15`, `wisdomDurationMinutes: 3`, `wisdomStartHour: 6`, `wisdomStartMinute: 0`, `wisdomEndHour: 21`, `wisdomEndMinute: 0`, `wisdomSelectedIds: const []`, `wisdomShuffle: false`), `copyWith()`, dan `props` list. | ✅ | 2026-03-09 |
| TASK-009 | Update `lib/domain/entities/transition_config.dart` — tambah 7 field wisdom: `isWisdomEnabled`, `wisdomIntervalMinutes`, `wisdomDurationMinutes`, `wisdomStartHour`, `wisdomStartMinute`, `wisdomEndHour`, `wisdomEndMinute`, `wisdomShuffle`. Update factory `TransitionConfig.fromSettings(Settings s)` untuk memetakan setiap field baru. | ✅ | 2026-03-09 |
| TASK-010 | Update `lib/domain/entities/display_state_type.dart` — tambah nilai `wisdomQuote` ke enum `DisplayStateType`. | ✅ | 2026-03-09 |
| TASK-011 | Update `lib/domain/entities/display_state.dart` — tambah `final class WisdomQuoteState extends DisplayState` dengan field: `WisdomQuote currentQuote`, `int currentIndex` (0-based), `int totalItems`, `DateTime currentTime`, `int totalDurationSeconds`, `int remainingSeconds`. Override `type` return `DisplayStateType.wisdomQuote`. | ✅ | 2026-03-09 |
| TASK-012 | Update signature `evaluate()` di `lib/domain/usecases/evaluate_display_state_use_case.dart` — tambah named parameter `List<WisdomQuote>? activeQuotes`. | ✅ | 2026-03-09 |
| TASK-013 | Implementasikan wisdom window check logic di `evaluate_display_state_use_case.dart` **setelah** loop prayer windows dan **sebelum** `return StandbyState()`: (1) Guard: `config.isWisdomEnabled && activeQuotes != null && activeQuotes.isNotEmpty`; (2) Hitung `minutesSinceStart`, `cycleLength`, `positionInCycle`, `slotIndex`; (3) Jika `positionInCycle < config.wisdomDurationMinutes`: hitung index item (urut: `slotIndex % count`, acak: gunakan `Random(seed)` dengan `seed = year*10000 + month*100 + day`); (4) Return `WisdomQuoteState(...)`. | ✅ | 2026-03-09 |

### Phase 4 — Data Layer

- **GOAL-004**: Menyediakan implementasi konkret untuk membaca katalog dari JSON asset dan menyimpan settings
  baru ke SQLite.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-014 | Update `lib/data/models/settings_model.dart` — tambah mapping `fromMap` untuk 9 kolom baru (dengan fallback `?? default_value`) dan tambah entry `toMap` untuk 9 field tersebut. | ✅ | 2026-03-09 |
| TASK-015 | Buat `lib/data/models/wisdom_quote_model.dart` — factory `WisdomQuoteModel.fromJson(Map<String, dynamic> json)` dan method `WisdomQuote toEntity()`. | ✅ | 2026-03-09 |
| TASK-016 | Buat `lib/data/datasources/wisdom_quote_local_data_source.dart` — class `WisdomQuoteLocalDataSource` dengan method `Future<List<WisdomQuote>> getAll()` (load `assets/data/wisdom_quotes.json` via `rootBundle.loadString`, parse JSON list, map ke entity) dan `Future<List<WisdomQuote>> getByIds(List<String> ids)` (filter dari `getAll()`). | ✅ | 2026-03-09 |
| TASK-017 | Buat `lib/data/repositories/wisdom_quote_repository_impl.dart` — `WisdomQuoteRepositoryImpl` mengimplementasikan `WisdomQuoteRepository`, delegasi ke `WisdomQuoteLocalDataSource`. | ✅ | 2026-03-09 |

### Phase 5 — Settings Cubit Logic

- **GOAL-005**: Menambahkan 9 method update baru ke `SettingsCubit` untuk setiap field konfigurasi
  Kata Mutiara. Toggle dan boolean menggunakan `_saveField()`, stepper menggunakan `_debounceSave()`.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-018 | Tambah `updateWisdomEnabled(bool value)` di `settings_cubit.dart` — gunakan `_saveField()` (save langsung tanpa debounce). | ✅ | 2026-03-09 |
| TASK-019 | Tambah `updateWisdomIntervalMinutes(int value)` — gunakan `_debounceSave()`. | ✅ | 2026-03-09 |
| TASK-020 | Tambah `updateWisdomDurationMinutes(int value)` — gunakan `_debounceSave()`. | ✅ | 2026-03-09 |
| TASK-021 | Tambah `updateWisdomStartHour(int value)` — gunakan `_debounceSave()`. | ✅ | 2026-03-09 |
| TASK-022 | Tambah `updateWisdomStartMinute(int value)` — gunakan `_debounceSave()`. | ✅ | 2026-03-09 |
| TASK-023 | Tambah `updateWisdomEndHour(int value)` — gunakan `_debounceSave()`. | ✅ | 2026-03-09 |
| TASK-024 | Tambah `updateWisdomEndMinute(int value)` — gunakan `_debounceSave()`. | ✅ | 2026-03-09 |
| TASK-025 | Tambah `updateWisdomSelectedIds(List<String> ids)` — encode ke JSON string (`jsonEncode(ids)`), simpan via `_debounceSave()`. | ✅ | 2026-03-09 |
| TASK-026 | Tambah `updateWisdomShuffle(bool value)` — gunakan `_saveField()` (save langsung). | ✅ | 2026-03-09 |

### Phase 6 — DisplayStateCubit Update

- **GOAL-006**: Menghubungkan `DisplayStateCubit` dengan `WisdomQuoteRepository` sehingga daftar item yang
  aktif dapat dimuat dan diteruskan ke `EvaluateDisplayStateUseCase` setiap tick.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-027 | Update constructor `DisplayStateCubit` di `display_state_cubit.dart` — tambah required parameter `WisdomQuoteRepository wisdomQuoteRepository`. | ✅ | 2026-03-09 |
| TASK-028 | Tambah field `List<WisdomQuote> _activeQuotes = const []` di `DisplayStateCubit`. Di method `_loadConfig()`: setelah settings dimuat, panggil `_activeQuotes = await wisdomQuoteRepository.getByIds(settings.wisdomSelectedIds)`. | ✅ | 2026-03-09 |
| TASK-029 | Update pemanggilan `_evaluateUseCase.evaluate(...)` di method `_tick()` — tambah argument `activeQuotes: _activeQuotes`. | ✅ | 2026-03-09 |

### Phase 7 — WisdomQuoteLayout

- **GOAL-007**: Membuat widget layout full-screen baru yang menampilkan satu item Kata Mutiara sesuai
  desain Islamic Glassmorphism. Kompatibel dengan 1920×1080 dan 1280×720.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-030 | Buat file `lib/presentation/pages/main_display/layouts/wisdom_quote_layout.dart` — `StatelessWidget` menerima parameter `WisdomQuoteState state`. | ✅ | 2026-03-09 |
| TASK-031 | Implementasi **header** (clone dari `StandbyLayout`): jam digital kiri, tanggal Masehi tengah, tanggal Hijriyah kanan. Gunakan `BlocBuilder<SettingsCubit>` untuk nama masjid (`state.currentTime` untuk jam). | ✅ | 2026-03-09 |
| TASK-032 | Implementasi **body** (area tengah): (1) `GlassmorphismCard` centered; (2) Badge oval tipe (`"🕌 Ayat Al-Quran"` / `"📖 Hadits"`) dengan warna berbeda (teal untuk Quran, amber untuk Hadits); (3) Teks terjemahan center-aligned, font `IslamicTypography.headline2` (atau `.h2.sp`); (4) Referensi center-aligned, font `IslamicTypography.caption`, `maxLines: 2`, `overflow: TextOverflow.ellipsis`. | ✅ | 2026-03-09 |
| TASK-033 | Implementasi **footer** (row bawah): progress bar horizontal (`LinearProgressIndicator`, value = `1 - remainingSeconds / totalDurationSeconds`), counter posisi `"${state.currentIndex + 1} / ${state.totalItems}"`, nama masjid kanan. | ✅ | 2026-03-09 |
| TASK-034 | Wrap seluruh layout dengan `IslamicBackground` + dark overlay, serta `LayoutBuilder` + `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center)` untuk multi-resolusi. | ✅ | 2026-03-09 |

### Phase 8 — MainDisplayPage Integration

- **GOAL-008**: Mendaftarkan `WisdomQuoteState` ke switch statement di `MainDisplayPage` sehingga
  `AnimatedSwitcher` yang sudah ada secara otomatis menangani transisi fade ke/dari tampilan Kata Mutiara.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-035 | Di `lib/presentation/pages/main_display_page.dart`: tambah import untuk `wisdom_quote_layout.dart`. | ✅ | 2026-03-09 |
| TASK-036 | Tambah case `DisplayStateType.wisdomQuote:` ke switch statement `_buildLayout()` — return `WisdomQuoteLayout(state: displayState as WisdomQuoteState)`. | ✅ | 2026-03-09 |

### Phase 9 — ChecklistItemWidget

- **GOAL-009**: Membuat widget reusable untuk item checklist di Settings UI yang support D-Pad focus dan
  menampilkan badge tipe, teks preview, dan status centang.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-037 | Buat `lib/presentation/widgets/checklist_item_widget.dart` — `StatelessWidget` dengan parameter: `String id`, `String type` (`"quran"` / `"hadith"`), `String label`, `String translationText`, `bool isChecked`, `ValueChanged<bool> onChanged`. | ✅ | 2026-03-09 |
| TASK-038 | Implementasi layout: `FocusableWidget` wrapping `Row` — (1) Badge oval type (color-coded: teal Quran, amber Hadits); (2) Kolom dengan teks preview translationText max 1 baris (`overflow: ellipsis`); (3) `Checkbox` / icon centang di kanan. `onSelect` memanggil `onChanged(!isChecked)`. | ✅ | 2026-03-09 |

### Phase 10 — WisdomPreviewPage

- **GOAL-010**: Membuat halaman pratinjau fullscreen yang memungkinkan admin melihat item yang telah dipilih
  sebelum diterapkan. Mendukung navigasi D-Pad dan auto-slide otomatis.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-039 | Buat `lib/presentation/pages/wisdom_preview_page.dart` — `StatefulWidget` dengan parameter: `List<WisdomQuote> quotes`. | ✅ | 2026-03-09 |
| TASK-040 | State: `int _currentIndex = 0`, `Timer? _autoSlideTimer`. Inisialisasi timer periodic 5 detik di `initState()` → advance `_currentIndex`. Override `dispose()` → `_autoSlideTimer?.cancel()`. | ✅ | 2026-03-09 |
| TASK-041 | Handle D-Pad navigasi: wrap root container dengan `Focus` + `onKeyEvent`; panggil `_goNext()` saat `LogicalKeyboardKey.arrowRight`, `_goPrevious()` saat `LogicalKeyboardKey.arrowLeft`. Reset timer saat navigasi manual (`_resetAutoSlideTimer()`). Ingat pola `mounted` check sebelum `setState`. | ✅ | 2026-03-09 |
| TASK-042 | Layout: gunakan `Stack` — (1) Di bawah: `WisdomQuoteLayout` dengan `WisdomQuoteState` simulasi (buat helper factory atau mock state khusus preview); (2) Di atas: header overlay `"PREVIEW — X item dipilih"`. | ✅ | 2026-03-09 |
| TASK-043 | Footer overlay: dot indicator (`Row` lingkaran kecil, filled = item aktif) + tombol `FocusableWidget` "Tutup Preview" → `Navigator.pop(context)`. | ✅ | 2026-03-09 |

### Phase 11 — WisdomQuoteSection (Settings UI)

- **GOAL-011**: Membuat section Settings lengkap untuk konfigurasi fitur Kata Mutiara, mengikuti pola
  `TreasurySection` dan `DisplayTimingSection`. Semua fields disabled saat toggle off.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-044 | Buat `lib/presentation/pages/settings/sections/wisdom_quote_section.dart` — `StatefulWidget`, load katalog di `initState()` via `context.read<WisdomQuoteRepository>().getAll()` dan simpan di `List<WisdomQuote> _allQuotes`. | ✅ | 2026-03-10 |
| TASK-045 | Implementasi **header** section: ikon bintang/mutiara + judul "Kata Mutiara Islam" + deskripsi singkat fitur. Gunakan pattern `GlassmorphismCard` seperti section lainnya. | ✅ | 2026-03-10 |
| TASK-046 | Implementasi **toggle aktif**: `FocusableWidget` + `Switch.adaptive` → `settingsCubit.updateWisdomEnabled(value)`. Saat nonaktif, wrapper `ExcludeFocus` + `Opacity(opacity: 0.4)` diterapkan ke seluruh area konfigurasi di bawahnya. | ✅ | 2026-03-10 |
| TASK-047 | Implementasi **DPadStepper interval**: label "Tampil Setiap", range 5–30, satuan "menit", default 15 → `updateWisdomIntervalMinutes()`. | ✅ | 2026-03-10 |
| TASK-048 | Implementasi **DPadStepper durasi**: label "Lama Tampil", range 1–10, satuan "menit", default 3 → `updateWisdomDurationMinutes()`. | ✅ | 2026-03-10 |
| TASK-049 | Implementasi **pengaturan jam aktif** (4 DPadStepper dalam 2 row): "Dari Jam" (0–23) + "Menit" (0–59) → `updateWisdomStartHour` / `updateWisdomStartMinute`; "Sampai Jam" (0–23) + "Menit" (0–59) → `updateWisdomEndHour` / `updateWisdomEndMinute`. | ✅ | 2026-03-10 |
| TASK-050 | Implementasi **mode urut/acak**: dua `FocusableWidget` tombol style radio — "Urut" dan "Acak". Tombol aktif bergaris emas, nonaktif redup. Tap masing-masing memanggil `updateWisdomShuffle(false)` / `updateWisdomShuffle(true)`. | ✅ | 2026-03-10 |
| TASK-051 | Implementasi **daftar checklist** — render 11 `ChecklistItemWidget` dari `_allQuotes`. Tap item → toggle keberadaan `id` di `selectedIds` list → panggil `updateWisdomSelectedIds(newList)`. | ✅ | 2026-03-10 |
| TASK-052 | Tampilkan **counter terpilih** di atas daftar: `"${selectedCount} item dipilih"` (menggunakan teks kecil / caption). Update reaktif saat checklist berubah. | ✅ | 2026-03-10 |
| TASK-053 | Implementasi **tombol Preview** (`FocusableWidget`): disabled (opacity 0.4, `FocusableWidget.onSelect: null`) saat `selectedCount == 0`; aktif → `Navigator.push(WisdomPreviewPage(quotes: selectedQuotes))`. | ✅ | 2026-03-10 |

### Phase 12 — SettingsMenuPage Registration

- **GOAL-012**: Mendaftarkan `WisdomQuoteSection` ke panel settings sehingga dapat diakses dari menu
  kategori sebelah kiri.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-054 | Di `lib/presentation/pages/settings/settings_menu_page.dart`: tambah import `wisdom_quote_section.dart`. | ✅ | 2026-03-10 |
| TASK-055 | Tambah entri `"Kata Mutiara"` ke list `_categories` (posisi sebelum "Reset Data"). | ✅ | 2026-03-10 |
| TASK-056 | Tambah `WisdomQuoteSection()` ke list `_sections` pada indeks yang sama dengan entri kategori di atas. | ✅ | 2026-03-10 |

### Phase 13 — Dependency Injection (main.dart)

- **GOAL-013**: Menghubungkan semua layer dengan menyediakan `WisdomQuoteRepository` melalui
  `RepositoryProvider` dan menyuntikkannya ke `DisplayStateCubit`.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-057 | Di `lib/main.dart`: tambah import untuk `wisdom_quote_local_data_source.dart` dan `wisdom_quote_repository_impl.dart`. Istansiasi: `final wisdomDataSource = WisdomQuoteLocalDataSource(); final wisdomQuoteRepository = WisdomQuoteRepositoryImpl(wisdomDataSource);`. | ✅ | 2026-03-10 |
| TASK-058 | Tambah `RepositoryProvider<WisdomQuoteRepository>.value(value: wisdomQuoteRepository)` ke `MultiRepositoryProvider`. | ✅ | 2026-03-10 |
| TASK-059 | Update instansiasi `DisplayStateCubit` — tambah argumen `wisdomQuoteRepository: context.read<WisdomQuoteRepository>()`. | ✅ | 2026-03-10 |

### Phase 14 — Unit & Widget Tests

- **GOAL-014**: Memastikan semua komponen baru dan yang dimodifikasi terlindungi oleh test suite.
  Jalankan seluruh suite test dengan `flutter test --reporter=expanded`.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-060 | Update `test/data/models/settings_model_test.dart` — tambah test cases untuk 9 field baru: fromMap dengan defaults, fromMap custom, toMap, round-trip. | ✅ | 2026-03-10 |
| TASK-061 | Update `test/presentation/cubits/settings/settings_cubit_test.dart` — tambah test untuk `updateWisdomEnabled`, `updateWisdomIntervalMinutes`, `updateWisdomSelectedIds` (termasuk encode/decode JSON), `updateWisdomShuffle`. | ✅ | 2026-03-10 |
| TASK-062 | Update `test/domain/usecases/evaluate_display_state_use_case_test.dart` — tambah test: wisdom window aktif (return `WisdomQuoteState`), wisdom window tidak aktif (return `StandbyState`), `activeQuotes.isEmpty` (return `StandbyState`), wisdom tidak tampil saat ada state sholat. | ✅ | 2026-03-10 |
| TASK-063 | Buat `test/data/models/wisdom_quote_model_test.dart` — test `fromJson()`, `toEntity()`, round-trip. | ✅ | 2026-03-10 |
| TASK-064 | Buat `test/data/repositories/wisdom_quote_repository_impl_test.dart` — test `getAll()` mengembalikan 11 item, `getByIds()` memfilter dengan benar, `getByIds([])` mengembalikan list kosong. | ✅ | 2026-03-10 |
| TASK-065 | Update `test/presentation/cubits/display_state/display_state_cubit_test.dart` — tambah test: tick saat dalam wisdom window → emit `WisdomQuoteState` dengan item yang tepat. | ✅ | 2026-03-10 |
| TASK-066 | Buat `test/presentation/pages/main_display/layouts/wisdom_quote_layout_test.dart` — test render: badge label muncul, teks terjemahan muncul, referensi muncul, progress bar ada. | ✅ | 2026-03-10 |
| TASK-067 | Buat `test/presentation/widgets/checklist_item_widget_test.dart` — test render, tap toggle memanggil `onChanged`, badge tipe tampil dengan warna sesuai. | ✅ | 2026-03-10 |
| TASK-068 | Buat `test/presentation/pages/wisdom_preview_page_test.dart` — test: render item pertama, navigasi next via tombol, tombol Tutup memanggil `Navigator.pop`. | ✅ | 2026-03-10 |
| TASK-069 | Buat `test/presentation/pages/settings/sections/wisdom_quote_section_test.dart` — test: toggle disable menyembunyikan fields (ExcludeFocus), checklist semua item muncul, tombol preview disable saat 0 item. | ✅ | 2026-03-10 |

---

## 3. Alternatives

- **ALT-001**: **Overlay di atas StandbyLayout** — Ditolak karena `StandbyLayout` adalah `StatelessWidget`,
  manajemen timer akan tersebar, tidak memanfaatkan `AnimatedSwitcher` yang sudah ada, dan pemulihan
  setelah power-off akan tidak dapat diprediksi.
- **ALT-002**: **Sub-state di dalam `StandbyState`** — Ditolak karena melanggar prinsip sealed class; akan
  membutuhkan nested switch dan memperumit logika evaluasi pure function.
- **ALT-003**: **Custom cubit terpisah `WisdomQuoteCubit`** — Ditolak untuk menjaga sederhana; logika
  penjadwalan cukup berada di `EvaluateDisplayStateUseCase` yang sudah memiliki akses ke `DateTime.now()` dan
  config.
- **ALT-004**: **Teks Arab dimasukkan** — Ditolak oleh keputusan desain user: teks Arab membutuhkan font
  tambahan, rendering RTL khusus, dan ukuran layar yang lebih terbatas.
- **ALT-005**: **Konten custom (admin bisa tambah item)** — Ditolak oleh keputusan desain user; meningkatkan
  kompleksitas UI + validasi secara signifikan tanpa kebutuhan nyata (katalog 11 item sudah mencukupi).

---

## 4. Dependencies

- **DEP-001**: `flutter_bloc` (sudah ada) — `BlocBuilder`, `context.read<>()` untuk WisdomQuoteSection.
- **DEP-002**: `sqflite` (sudah ada) — migrasi database v7.
- **DEP-003**: `equatable` (sudah ada) — `WisdomQuote` entity.
- **DEP-004**: `flutter_screenutil` (sudah ada) — `.sp`, `.w`, `.h` di `WisdomQuoteLayout`.
- **DEP-005**: `google_fonts` (sudah ada) — tipografi di layout baru.
- **DEP-006**: **Tidak ada dependency baru** — semua kebutuhan terpenuhi oleh package yang sudah ada di
  `pubspec.yaml`.

---

## 5. Files

### File Baru

- **FILE-001**: `assets/data/wisdom_quotes.json` — Katalog 11 item Kata Mutiara (bundle asset).
- **FILE-002**: `lib/domain/entities/wisdom_quote.dart` — Domain entity.
- **FILE-003**: `lib/domain/repositories/wisdom_quote_repository.dart` — Abstract repository interface.
- **FILE-004**: `lib/data/models/wisdom_quote_model.dart` — Data model (JSON ↔ entity).
- **FILE-005**: `lib/data/datasources/wisdom_quote_local_data_source.dart` — Loader JSON asset.
- **FILE-006**: `lib/data/repositories/wisdom_quote_repository_impl.dart` — Implementasi konkret.
- **FILE-007**: `lib/presentation/pages/main_display/layouts/wisdom_quote_layout.dart` — Layout full-screen.
- **FILE-008**: `lib/presentation/pages/wisdom_preview_page.dart` — Halaman pratinjau.
- **FILE-009**: `lib/presentation/pages/settings/sections/wisdom_quote_section.dart` — Section settings UI.
- **FILE-010**: `lib/presentation/widgets/checklist_item_widget.dart` — Widget checklist reusable.
- **FILE-011**: `test/data/models/wisdom_quote_model_test.dart`
- **FILE-012**: `test/data/repositories/wisdom_quote_repository_impl_test.dart`
- **FILE-013**: `test/presentation/pages/main_display/layouts/wisdom_quote_layout_test.dart`
- **FILE-014**: `test/presentation/pages/wisdom_preview_page_test.dart`
- **FILE-015**: `test/presentation/pages/settings/sections/wisdom_quote_section_test.dart`
- **FILE-016**: `test/presentation/widgets/checklist_item_widget_test.dart`

### File Dimodifikasi

- **FILE-017**: `lib/data/datasources/database_helper.dart` — Versi naik ke 7, migration v7, DDL baru.
- **FILE-018**: `lib/data/models/settings_model.dart` — fromMap/toMap 9 field baru.
- **FILE-019**: `lib/domain/entities/settings.dart` — 9 field baru.
- **FILE-020**: `lib/domain/entities/transition_config.dart` — 7 field wisdom baru.
- **FILE-021**: `lib/domain/entities/display_state_type.dart` — Tambah `wisdomQuote`.
- **FILE-022**: `lib/domain/entities/display_state.dart` — Tambah `WisdomQuoteState`.
- **FILE-023**: `lib/domain/usecases/evaluate_display_state_use_case.dart` — Parameter + logika baru.
- **FILE-024**: `lib/presentation/cubits/settings/settings_cubit.dart` — 9 method baru.
- **FILE-025**: `lib/presentation/cubits/display_state/display_state_cubit.dart` — Inject repo, load quotes.
- **FILE-026**: `lib/presentation/pages/main_display_page.dart` — Tambah case wisdomQuote.
- **FILE-027**: `lib/presentation/pages/settings/settings_menu_page.dart` — Tambah kategori + section.
- **FILE-028**: `lib/main.dart` — Instansiasi dan inject WisdomQuoteRepository.
- **FILE-029**: `test/data/models/settings_model_test.dart` — Update untuk 9 field baru.
- **FILE-030**: `test/presentation/cubits/settings/settings_cubit_test.dart` — Update test wisdom methods.
- **FILE-031**: `test/domain/usecases/evaluate_display_state_use_case_test.dart` — Test wisdom window.
- **FILE-032**: `test/presentation/cubits/display_state/display_state_cubit_test.dart` — Update test.

---

## 6. Testing

- **TEST-001**: `WisdomQuoteModel` — `fromJson` semua 11 item dari aset JSON tanpa throw, `toEntity()` menghasilkan `WisdomQuote` dengan field yang benar.
- **TEST-002**: `WisdomQuoteRepositoryImpl` — `getAll()` mengembalikan tepat 11 item; `getByIds(['quran_001', 'hadith_006'])` mengembalikan 2 item yang tepat; `getByIds([])` mengembalikan list kosong.
- **TEST-003**: `EvaluateDisplayStateUseCase` (wisdom) — Saat `DateTime` berada dalam wisdom window + `isWisdomEnabled = true` + `activeQuotes` non-empty → return `WisdomQuoteState`; Saat `positionInCycle >= wisdomDuration` → return `StandbyState`; Saat `activeQuotes.isEmpty` → return `StandbyState`; Saat ada prayer window overlap → prayer window menang (return state sholat, bukan wisdom).
- **TEST-004**: `EvaluateDisplayStateUseCase` (ordering) — Mode urut: item pertama di slot 0, item kedua di slot 1; Mode acak: seed yang sama menghasilkan urutan yang sama; seed berbeda (hari berbeda) menghasilkan urutan berbeda.
- **TEST-005**: `SettingsModel` — `fromMap` dengan semua 9 default values; `fromMap` dengan custom values; `toMap` menghasilkan map dengan key yang benar; round-trip konsisten.
- **TEST-006**: `SettingsCubit` — `updateWisdomEnabled(true)` memperbarui state; `updateWisdomSelectedIds(['quran_001'])` menyimpan JSON encoded; `updateWisdomShuffle(true)` merefleksikan di state.
- **TEST-007**: `DisplayStateCubit` — Saat `_tick()` dipanggil dalam wisdom window dengan `_activeQuotes` non-empty → emit `WisdomQuoteState`.
- **TEST-008**: `WisdomQuoteLayout` — Widget render tanpa overflow; badge label tampil dengan tipe yang benar; teks terjemahan tampil; referensi tampil (max 2 baris); progress bar ada.
- **TEST-009**: `ChecklistItemWidget` — Render dengan `isChecked: true` menampilkan ikon centang; tap memanggil `onChanged` dengan nilai toggle; badge tipe tampil.
- **TEST-010**: `WisdomPreviewPage` — Render item pertama dari list; tap tombol "Tutup" memanggil `Navigator.pop`.
- **TEST-011**: `WisdomQuoteSection` — Toggle disabled menyebabkan DPadStepper masuk `ExcludeFocus`; tombol Preview disable saat `selectedCount == 0`; semua 11 item checklist tampil setelah future selesai.

---

## 7. Risks & Assumptions

- **RISK-001**: **Referensi hadits_006 terlalu panjang** — `"HR. Tirmidzi No. 1924 & Abu Dawud No. 4941 (Hasan Shahih)"` lebih panjang dari item lain. Mitigasi: set `maxLines: 2` dan `overflow: TextOverflow.ellipsis` di widget referensi, dengan `fontSize` sekitar 22–24.sp.
- **RISK-002**: **Wisdom window overlap dengan prayer window** — Ditangani di `EvaluateDisplayStateUseCase` dengan mengevaluasi prayer windows lebih dahulu; wisdom check hanya di fallback path.
- **RISK-003**: **Migrasi database v7 pada device yang sudah install v6** — Selama admin tidak uninstall app, `_onUpgrade()` akan dipanggil otomatis dengan `ALTER TABLE`. Perlu di-test pada emulator yang sudah memiliki DB v6.
- **RISK-004**: **`WisdomPreviewPage` menggunakan `WisdomQuoteState` simulasi** — State ini dipakai untuk render ulang `WisdomQuoteLayout` di preview. State simulasi harus memiliki nilai `remainingSeconds` dan `totalDurationSeconds` yang valid (contoh: full duration) untuk menghindari division by zero di progress bar.
- **RISK-005**: **Checklist `WisdomQuoteSection` async load** — Load katalog di `initState()` bersifat async; widget perlu menampilkan loading indicator singkat atau render kosong sampai data tersedia.

- **ASSUMPTION-001**: Folder `assets/data/` sudah terdaftar di `pubspec.yaml` — terverifikasi dari `cities.json` yang berfungsi. File `wisdom_quotes.json` di folder yang sama otomatis ter-bundle.
- **ASSUMPTION-002**: `WisdomQuoteLocalDataSource` tidak memerlukan `DatabaseHelper` — data bersumber dari JSON asset via `rootBundle`, bukan SQLite.
- **ASSUMPTION-003**: `wisdomSelectedIds` di `Settings` entity berupa `List<String>` (Dart), namun disimpan di SQLite sebagai JSON string via `jsonEncode` / `jsonDecode` di `SettingsModel`.
- **ASSUMPTION-004**: `Settings.wisdomSelectedIds` default `const <String>[]` — artinya fitur tidak akan menampilkan apapun meski enabled, sampai admin memilih item.

---

## 8. Related Specifications / Further Reading

### Katalog Lengkap wisdom_quotes.json

```json
[
  {
    "id": "quran_001",
    "type": "quran",
    "label": "Ayat Al-Quran",
    "translation_text": "Karena sesungguhnya bersama kesulitan ada kemudahan.",
    "reference": "QS. Al-Insyirah [94]: 6"
  },
  {
    "id": "quran_002",
    "type": "quran",
    "label": "Ayat Al-Quran",
    "translation_text": "Allah tidak membebani seseorang melainkan sesuai dengan kesanggupannya.",
    "reference": "QS. Al-Baqarah [2]: 286"
  },
  {
    "id": "quran_003",
    "type": "quran",
    "label": "Ayat Al-Quran",
    "translation_text": "Janganlah kamu berputus asa dari rahmat Allah. Sesungguhnya Allah mengampuni dosa-dosa semuanya.",
    "reference": "QS. Az-Zumar [39]: 53"
  },
  {
    "id": "quran_004",
    "type": "quran",
    "label": "Ayat Al-Quran",
    "translation_text": "Hai orang-orang yang beriman, mintalah pertolongan kepada Allah dengan sabar dan sholat. Sesungguhnya Allah beserta orang-orang yang sabar.",
    "reference": "QS. Al-Baqarah [2]: 153"
  },
  {
    "id": "quran_005",
    "type": "quran",
    "label": "Ayat Al-Quran",
    "translation_text": "Ingatlah kepada-Ku, maka Aku pun akan ingat kepadamu. Bersyukurlah kepada-Ku, dan janganlah kamu mengingkari nikmat-Ku.",
    "reference": "QS. Al-Baqarah [2]: 152"
  },
  {
    "id": "hadith_001",
    "type": "hadith",
    "label": "Hadits",
    "translation_text": "Sesungguhnya setiap amal itu tergantung pada niatnya, dan setiap orang hanya mendapatkan apa yang ia niatkan.",
    "reference": "HR. Bukhari No. 1"
  },
  {
    "id": "hadith_002",
    "type": "hadith",
    "label": "Hadits",
    "translation_text": "Sebaik-baik manusia adalah yang paling bermanfaat bagi manusia lainnya.",
    "reference": "HR. Ahmad (Hasan)"
  },
  {
    "id": "hadith_003",
    "type": "hadith",
    "label": "Hadits",
    "translation_text": "Menuntut ilmu adalah kewajiban bagi setiap Muslim.",
    "reference": "HR. Ibnu Majah No. 224 (Hasan)"
  },
  {
    "id": "hadith_004",
    "type": "hadith",
    "label": "Hadits",
    "translation_text": "Berbuat baiklah kepada kedua orang tuamu, sesungguhnya surga ada di bawah telapak kaki ibumu.",
    "reference": "HR. Tirmidzi No. 1956 (Shahih)"
  },
  {
    "id": "hadith_005",
    "type": "hadith",
    "label": "Hadits",
    "translation_text": "Tidak termasuk golongan kami orang yang tidak menyayangi yang lebih muda dan tidak menghormati yang lebih tua.",
    "reference": "HR. Bukhari No. 6018"
  },
  {
    "id": "hadith_006",
    "type": "hadith",
    "label": "Hadits",
    "translation_text": "Orang-orang yang penyayang akan disayangi oleh Allah Yang Maha Penyayang. Sayangilah siapa saja yang ada di bumi, niscaya Yang ada di langit akan menyayangi kalian.",
    "reference": "HR. Tirmidzi No. 1924 & Abu Dawud No. 4941 (Hasan Shahih)"
  }
]
```

### Algoritma Penjadwalan (Pseudocode)

```
Input: now (DateTime), config (TransitionConfig), activeQuotes (List<WisdomQuote>)

GUARD:
  if !config.isWisdomEnabled → skip
  if activeQuotes.isEmpty → skip
  
JAM AKTIF CHECK:
  startMinutes = config.wisdomStartHour * 60 + config.wisdomStartMinute
  endMinutes   = config.wisdomEndHour * 60 + config.wisdomEndMinute
  nowMinutes   = now.hour * 60 + now.minute
  if nowMinutes < startMinutes OR nowMinutes >= endMinutes → skip

SIKLUS:
  minutesSinceStart = nowMinutes - startMinutes
  cycleLength       = config.wisdomIntervalMinutes + config.wisdomDurationMinutes
  positionInCycle   = minutesSinceStart % cycleLength
  slotIndex         = minutesSinceStart ~/ cycleLength

WINDOW CHECK:
  if positionInCycle >= config.wisdomDurationMinutes → skip (dalam interval jeda)

INDEX ITEM:
  count = activeQuotes.length
  if config.wisdomShuffle:
    seed     = now.year * 10000 + now.month * 100 + now.day
    rng      = Random(seed)
    indices  = List.generate(count, (i) => i)..shuffle(rng)
    rawIndex = indices[slotIndex % count]
  else:
    rawIndex = slotIndex % count

RETURN WisdomQuoteState:
  currentQuote         = activeQuotes[rawIndex]
  currentIndex         = rawIndex  (0-based)
  totalItems           = count
  currentTime          = now
  totalDurationSeconds = config.wisdomDurationMinutes * 60
  remainingSeconds     = (config.wisdomDurationMinutes - positionInCycle) * 60 - now.second
```

### Referensi Dokumen

- [spec/spec-process-state-machine.md](../spec/spec-process-state-machine.md)
- [spec/spec-schema-database.md](../spec/spec-schema-database.md)
- [spec/spec-process-settings.md](../spec/spec-process-settings.md)
- [plan/feature-treasury-info-1.md](feature-treasury-info-1.md) — referensi pola toggle settings
- [plan/feature-main-display-ui-1.md](feature-main-display-ui-1.md) — referensi layout standby

---
