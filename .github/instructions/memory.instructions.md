---
applyTo: "**"
---

# Memory - Preferensi Pengguna

## Komunikasi

- **Bahasa**: Komunikasi harus menggunakan bahasa Indonesia yang jelas dan baku
- **Gaya**: Formal namun tetap ramah dan profesional
- **Format**: Gunakan struktur yang rapi dengan bullet points dan code blocks sesuai kebutuhan

## Penjelasan dan Dokumentasi

- **Kejelasan**: Penjelasan harus jelas, terstruktur, dan mudah dipahami
- **Struktur**: Gunakan format bertingkat dengan heading, subheading, dan poin-poin yang logis
- **Dokumentasi**: Semua dokumentasi yang dibuat harus jelas, komprehensif, dan mudah dimengerti
- **Detail**: Berikan konteks yang cukup tanpa terlalu bertele-tele
- **Contoh**: Sertakan contoh praktis jika diperlukan untuk memperjelas konsep

## Gaya Komunikasi User

- Menggunakan bahasa Indonesia formal tapi santai
- Suka detail teknis dan penjelasan komprehensif
- Meminta dokumentasi yang lengkap dan terstruktur
- Memperhatikan kualitas kode dan testing standards

## Workflow & Metodologi

- **SDLC Strict Adherence**: User mengikuti alur SDLC yang ketat dan terstruktur
- **Sequential Development**: Harus mengikuti urutan: PRD → Spec → Plan → Code
- **No Skip Phases**: Tidak boleh melompat fase, setiap tahap harus selesai sebelum lanjut
- **Documentation First**: Dokumentasi lengkap dan terstruktur harus ada sebelum mulai coding
- **Custom Agents Usage**: User menggunakan custom GitHub Copilot Agents sesuai dengan fase development:
  - `@ProductManagerPRD` untuk Requirements (PRD)
  - `@SpecificationArchitect` untuk Technical Specification
  - `@PlannerArchitect` untuk Implementation Planning
  - `@BeastModeDev` atau `@MiniBeast` untuk Coding/Implementation
  - `@QATestArchitect` untuk Testing
  - `@DocumentationWriter` untuk User Documentation
- **New Session per Phase**: User prefer memulai sesi chat baru saat berpindah fase untuk menjaga fokus konteks
- **Verification Mindset**: Setiap output harus diverifikasi terhadap PRD dan Spec sebelum lanjut
- **Phase Completion Pattern**: Setelah fase selesai, user meminta pemisahan planning untuk fase berikutnya ke dokumen terpisah untuk review tim

## Format Markdown

- **Markdown Lint**: Semua file markdown harus mengikuti aturan markdown lint
- **Konsistensi**: Pastikan format heading, list, dan struktur konsisten
- **Standar**: Ikuti best practices markdown untuk readability dan maintainability
- **Validasi**: Pastikan markdown yang dibuat lolos validasi lint checker
- **Elemen**: Gunakan elemen markdown seperti heading, subheading, bullet points, code blocks sesuai kebutuhan
- **Pemformatan**: Gunakan pemformatan teks seperti bold, italic, dan inline code untuk menekankan poin penting
- **Tabel**: Gunakan tabel untuk menyajikan data terstruktur jika diperlukan
- **Blok Kode**: Gunakan blok kode untuk menyajikan contoh kode dengan penyorotan sintaks yang sesuai

## Implementation Progress

### Plan 01 — Database Infrastructure ✅ COMPLETED (2026-02-18)

Infrastruktur database SQLite sudah selesai diimplementasi:

- **`DatabaseHelper`** singleton di `lib/data/datasources/database_helper.dart`
  - Schema DDL: `settings` table (30+ columns, singleton row `CHECK id = 1`) + `cities` table
  - Default settings row di-insert otomatis saat `onCreate`
  - `_seedCities()` via `rootBundle.loadString('assets/data/cities.json')` + batch insert
  - `_onUpgrade()` dengan pattern `if (oldVersion < N)` untuk future migrations
  - Testing hooks: `initForTesting()`, `resetForTesting()`, `createTablesForTesting()`, `insertDefaultSettingsForTesting()`
- **`assets/data/cities.json`** — 514 kota/kabupaten, 34 provinsi, sorted by province→city (Title Case)
- **`test/data/datasources/database_helper_test.dart`** — 6 unit tests, semua PASSED
  - Menggunakan `sqflite_common_ffi` dengan `inMemoryDatabasePath` untuk isolated testing
- **Dependencies**: `sqflite`, `path` (prod) + `sqflite_common_ffi` (dev)

### Plan 10 — Setup Wizard UI ✅ COMPLETED (2026-02-20)

Implementasi UI Setup Wizard (4 langkah) selesai:

- **Pages**: Welcome, Identity, Location (City Picker), Preview
- **Components**: `StepIndicatorWidget`, `SplashPage` (routing logic)
- **Features**: D-Pad navigation support, data persistence via `SetupWizardCubit` (Plan 09), 1920x1080 responsive design
- **Testing**: Widget tests passing for all steps (layout, interaction, overflow prevention)

### Plan 11 — Settings Logic ✅ COMPLETED (2026-02-20)

- **`SettingsCubit`** di `lib/presentation/cubits/settings/settings_cubit.dart`
- **Features**: auto-save debounce, PIN management, update logic
- **Testing**: Comprehensive unit tests passing

### Plan 12 dan seterusnya — BELUM DIMULAI

Fase berikutnya: Settings UI, Main Display UI, dan fitur lainnya.

## Known Bugs & Fixes

### Bug: DropdownButton Blank saat Back Navigation (LocationStep) — Fixed 2026-03-05

**Root Cause**: `_syncWithCubit()` membuat dummy `City(id: 0)` untuk pre-fill dropdown.
`City` memakai `Equatable` yang menyertakan `id` di `props`, sehingga dummy tidak cocok
dengan item real dari DB → Flutter assertion error → widget blank.

**Fix**: Hapus dummy object. Cukup set `_selectedProvince` (String), lalu pass
`preselectCityName` sebagai parameter ke `_loadCities()`. Preselect objek real dilakukan
dalam satu `setState` bersamaan dengan pengisian `_cities` list.

**Pattern generik**: Jangan gunakan dummy Equatable object sebagai `DropdownButton.value`
sebelum `items` tersedia. Selalu preselect setelah data real dimuat.

---

## Android TV — D-Pad & Soft Keyboard Patterns (2026-03-06)

### Pattern: TextField yang Bisa Dibuka via D-Pad

```dart
// FocusNode pada TextField dengan skipTraversal: true
final _fieldFocusNode = FocusNode(skipTraversal: true);
// ^ D-pad tidak auto-landing di sini, tapi requestFocus() programatik tetap jalan

FocusableWidget(
  onSelect: () {
    // WAJIB addPostFrameCallback — requestFocus() synchronous di dalam key-event handler
    // tidak trigger IME karena event belum selesai diproses Flutter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fieldFocusNode.requestFocus();
    });
  },
  builder: (isFocused) => TextField(focusNode: _fieldFocusNode),
)
```

**JANGAN** bungkus `TextField` dengan `ExcludeFocus()` (tanpa `excluding: false`) — defaultnya `excluding: true` → `requestFocus()` diam-diam diabaikan.

### Pattern: Soft Keyboard untuk Widget Non-TextField (misal PIN input)

Tambah hidden `Offstage(TextField)` sebagai IME connection:

```dart
Offstage(
  child: TextField(
    focusNode: _hiddenFocusNode, // skipTraversal: true
    controller: _hiddenController,
    keyboardType: TextInputType.number,
  ),
)
// FocusableWidget.onSelect → addPostFrameCallback(() => _hiddenFocusNode.requestFocus())
// Controller listener meneruskan digit ke business logic
```

### Pattern: Teks Tombol FocusableWidget Tidak Rata Tengah

`FocusableWidget` memiliki `ConstrainedBox(minHeight: 48)` — bila di dalam `Column`, widget meregang dan teks naik ke atas.

**Fix**: `AnimatedContainer(alignment: Alignment.center)` + bungkus dengan `IntrinsicHeight`.

### Pattern: Dialog dengan FocusableWidget Buttons

`AlertDialog.actions` memakai `OverflowBar` → layout `FocusableWidget` rusak.

**Fix**: Gunakan `Dialog` biasa + layout `Column`/`Row` custom.

### Pattern: Multi-Resolusi (1920×1080 vs 1280×720)

`SingleChildScrollView(physics: NeverScrollableScrollPhysics)` memotong konten — tidak scroll, tidak shrink.

**Fix**: `LayoutBuilder` + `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.topCenter)`.

### Pattern: Multiline TextField — Tombol Done bukan Enter

`maxLines > 1` otomatis set `TextInputAction.newline`.

**Fix**: `textInputAction: TextInputAction.done` + `onSubmitted: (_) => focusNode.unfocus()`.
