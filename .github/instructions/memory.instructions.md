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
  - `@BeastModeDev`, `@GodModeDev`, atau `@MiniBeast` untuk Coding/Implementation
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

### Plan 12 dan seterusnya — SELESAI (2026-03-16)

Fitur yang sudah selesai di luar urutan Plan 01–11:

- **Kata Mutiara Islam (Wisdom Quote)** — 14 phases, 257 total tests ✅. State ke-6 pada display state machine.
  Lihat `AGENTS.md` section "Kata Mutiara Islam / Wisdom Quote" untuk detail file.
- **Mode Hemat Daya Tengah Malam (Midnight Mode)** — 7 phases, 306 total tests ✅. State ke-7 pada display state machine.
  Lihat `AGENTS.md` section "Mode Hemat Daya Tengah Malam / Midnight Mode" untuk detail file.

> Catatan: Settings UI (Plan 12) dan Main Display UI (Plan 13) juga sudah selesai sejak 2026-02-20.
> Lihat `AGENTS.md` tabel "Completed Features" untuk daftar lengkap.

### Plan 14 — Slideshow Pengumuman ✅ COMPLETED (2026-05-08)

Fitur pengumuman berbasis gambar selesai diimplementasi:

- **State Management**: `SlideshowAnnouncementState` terintegrasi di `DisplayStateCubit`.
- **Infrastructure**: Table `slideshow_images`, migration v10, logic siklus absolut.
- **Features**: 3 slot gambar, manajemen file lokal (path_provider), sinkronisasi state instan.
- **Testing**: Unit tests repo & cubit passing.

## Flutter UI Patterns — Deprecated APIs (2026-03-16)

### Pattern: Switch.adaptive — activeColor Deprecated

`activeColor` deprecated sejak Flutter v3.31.0. Penggantinya adalah dua property terpisah.

```dart
// ❌ SALAH — deprecated
Switch.adaptive(
  value: isEnabled,
  onChanged: null,
  activeColor: IslamicColors.goldAmber,
)

// ✅ BENAR — Flutter v3.31+
Switch.adaptive(
  value: isEnabled,
  onChanged: null,
  activeThumbColor: IslamicColors.goldAmber,           // warna lingkaran thumb saat ON
  activeTrackColor: IslamicColors.goldAmber.withValues(alpha: 0.5), // warna track saat ON
)
```

**File yang sudah diperbaiki**: `midnight_mode_section.dart`, `wisdom_quote_section.dart`,
`treasury_section.dart`.

### Pattern: Color.withOpacity() Deprecated (Dart 3.6 / Flutter 3.27+)

`Color.withOpacity(x)` deprecated. Gunakan `Color.withValues(alpha: x)` sebagai gantinya.

```dart
// ❌ SALAH
color.withOpacity(0.5)

// ✅ BENAR
color.withValues(alpha: 0.5)
```

---

## Android TV — FocusableWidget Interaction Pattern (2026-05-08)

### Bug: Tombol Tutup Preview Tidak Responsif (Remote/Klik)

Pada halaman `SlideshowPreviewPage`, tombol "Tutup Preview" yang menggunakan `FocusableWidget` sering
gagal menerima event klik/select jika berada di atas layer `Stack` yang memiliki `BackdropFilter`
atau layer transparan lainnya.

**Fix**: Gunakan `HitTestBehavior.opaque` pada `GestureDetector` internal `FocusableWidget`.

```dart
// lib/presentation/widgets/focusable_widget.dart

GestureDetector(
  behavior: HitTestBehavior.opaque, // <--- WAJIB untuk tombol di layer transparan
  onTap: () {
    _focusNode.requestFocus();
    if (widget.onSelect != null) widget.onSelect!();
  },
  child: ...,
)
```

**Prinsip**: Android TV remote (D-Pad Center) sering memetakan ke tap event. Jika behavior
default (`deferToChild`) digunakan, dan child-nya tidak memiliki area visual solid yang luas,
tap event seringkali "tembus" ke layer di bawahnya.

---

## Flutter Library Patterns — FilePicker v11 Migration (2026-05-08)

### Breaking Change: FilePicker.platform.pickFiles Dihapus

Pada `file_picker` v11.0.0+, akses ke instance `platform` secara langsung sudah dibatasi/dihapus
untuk static methods.

```dart
// ❌ SALAH (v10-)
FilePicker.platform.pickFiles(...)

// ✅ BENAR (v11+)
FilePicker.pickFiles(...)
```

**Testing**: Untuk melakukan mocking, gunakan `FilePickerPlatform.instance`.

```dart
// test/presentation/cubits/slideshow_section/slideshow_section_cubit_test.dart

class MockFilePicker extends Mock with MockPlatformInterfaceMixin implements FilePickerPlatform {}

setUp(() {
  mockPicker = MockFilePicker();
  FilePickerPlatform.instance = mockPicker; // <--- Inject mock di sini
});
```

---

## Android TV — DPadStepper Layout Constraint (2026-03-17)

### Bug: DPadStepper dalam Row — D-Pad Kanan Tidak Pindah Fokus

`DPadStepper` mengonsumsi `ArrowRight` (increment) dan `ArrowLeft` (decrement) dengan
`KeyEventResult.handled`. Ketika dua `DPadStepper` ditempatkan dalam `Row`, event Right
tidak pernah sampai ke Flutter focus traversal → fokus stuck di stepper pertama.

```dart
// ❌ SALAH — D-Pad kanan hanya increment Jam, tidak bisa ke Menit
Row(
  children: [
    Expanded(child: DPadStepper(label: 'Jam', ...)),
    SizedBox(width: 16.w),
    Expanded(child: DPadStepper(label: 'Menit', ...)),
  ],
)

// ✅ BENAR — D-Pad bawah dari Jam pindah ke Menit secara natural
DPadStepper(label: 'Jam', ...),
SizedBox(height: 12.h),
DPadStepper(label: 'Menit', ...),
```

**Prinsip**: `DPadStepper` dirancang untuk layout **vertikal saja**. ArrowUp/Down sengaja
TIDAK dikonsumsi agar Flutter focus traversal bisa berpindah antar-stepper. Selalu gunakan
`Column` untuk pair Jam+Menit, bukan `Row`.

**File yang sudah diperbaiki**: `midnight_mode_section.dart`, `wisdom_quote_section.dart`.

---

## Flutter Testing Patterns (2026-03-10)

### Pattern: DateFormat Locale di Widget Test

`DateFormat('...', 'id_ID')` di dalam widget membutuhkan locale data saat test.
Tanpa inisialisasi, test akan throw `LocaleDataException`.

**Fix**: Tambah `setUpAll` di test file yang merender widget tersebut:

```dart
import 'package:intl/date_symbol_data_local.dart';

setUpAll(() async {
  await initializeDateFormatting('id_ID', null);
});
```

**Kapan berlaku**: Semua widget test yang merender `WisdomQuoteLayout` atau widget lain
yang memanggil `DateFormat` dengan locale non-default.

### Pattern: Mocktail Stub — Semua Named Arg Harus Disebutkan

Jika sebuah method dipanggil dengan optional named parameter yang bernilai **non-null**,
stub `when()` harus mengikutsertakan parameter tersebut. Jika tidak, stub tidak cocok
(≠ recorded call) → `MissingStubError`.

```dart
// ❌ SALAH — evaluate() dipanggil dengan activeQuotes: const []
// tapi stub tidak menyebutkan activeQuotes → stub miss, return null
when(() => mockEvaluate.evaluate(...)).thenReturn(StandbyState());

// ✅ BENAR — sebutkan semua named params yang digunakan, atau pakai any(named:)
when(() => mockEvaluate.evaluate(
  config: any(named: 'config'),
  currentTime: any(named: 'currentTime'),
  prayerTimes: any(named: 'prayerTimes'),
  hijriDate: any(named: 'hijriDate'),
  activeQuotes: any(named: 'activeQuotes'),  // ← WAJIB jika cubit memanggilnya
)).thenReturn(StandbyState());
```

**Root cause**: Mocktail merekam SEMUA argumen call (termasuk optional yang di-pass).
Stub yang tidak menyebut argumen tersebut memiliki matcher berbeda → tidak match.

### Pattern: IndexedStack + Offstage + ListView Lazy

`IndexedStack` menyimpan semua children di-tree, tapi yang tidak aktif dibungkus
`Offstage(offstage: true)`. `ListView` di dalamnya **tidak membangun children** karena
offstage = tidak dirender → `find.byType(SomeWidget)` akan menemukan 0 hasil.

**Fix di widget test**: Navigasi ke section terlebih dahulu sebelum melakukan assertion:

```dart
// ❌ SALAH — Iqomah section bukan default, ListView-nya tidak build
expect(find.byType(DPadStepper), findsNWidgets(6));

// ✅ BENAR — tap label menu untuk navigate ke section, baru assert
await tester.tap(find.text('Durasi Iqomah').first);
await tester.pumpAndSettle();
expect(find.byType(DPadStepper), findsNWidgets(6));
```

**Berlaku untuk**: `SettingsMenuPage` (IndexedStack categories) dan halaman serupa.

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

---

## Android TV — Performance Optimization Patterns (2026-03-10)

Ditemukan saat optimasi `RunningTextWidget` di device Android TV Android 11.

### Pattern: BackdropFilter + Animated Widget = GPU Jank

`BackdropFilter(ImageFilter.blur)` memaksa GPU re-capture seluruh layer di belakangnya di
**setiap frame**. Dikombinasikan dengan continuous animation (Marquee), menyebabkan severe
GPU jank di device low-end.

**Fix**:

```dart
// ❌ JANGAN — BackdropFilter pada widget yang terus beranimasi
ClipRRect(
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Marquee(text: longRunningText), // animasi konstan
  ),
)

// ✅ BENAR — Hapus BackdropFilter, gunakan solid semi-transparent
RunningTextWidget(showBackground: false)

// ✅ BENAR — Atau isolasi layer dengan RepaintBoundary
RepaintBoundary(child: RunningTextWidget(...))
```

**Real Case**: `RunningTextWidget` di `StandbyLayout` — GPU jank di Android TV Android 11.

### Pattern: BlocBuilder buildWhen — Kurangi CPU Rebuild

`DisplayStateCubit` tick setiap detik. `StandbyLayout` (jam, jadwal sholat) hanya perlu
update per menit — bukan per detik.

```dart
BlocBuilder<DisplayStateCubit, DisplayState>(
  buildWhen: (prev, next) {
    if (next is StandbyState && prev is StandbyState) {
      return next.currentTime.minute != prev.currentTime.minute;
    }
    return true; // Adzan, Iqomah countdown tetap rebuild per detik
  },
  builder: (context, state) { ... },
)
```

### Pattern: Self-Contained Timer di StatefulWidget

Jam digital yang update setiap detik: jangan terima `currentTime` dari parent/cubit.
Letakkan `Timer.periodic` di dalam widget sendiri → mencegah parent rebuild 60x/menit.

```dart
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

### Pattern: Cache DateFormat Locale

`DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date)` mahal jika dipanggil setiap detik.
Simpan hasil di `StatefulWidget` state, update hanya saat hari berganti:

```dart
void _updateDateIfNeeded(DateTime now) {
  if (now.day != _cachedDay) {
    _masehiDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    _cachedDay = now.day;
  }
}
```

### Pattern: adhan Prayer Calculation — No Isolate Needed

`adhan` library ~1ms (pure math, no I/O). Overhead `compute()`/`Isolate` ~100ms >> waktu kalkulasi.
Jangan pakai `compute()` — cukup `async/await` biasa untuk akses SQLite settings.
