---
goal: "Setup Theme System — Islamic Glassmorphism Colors, Typography Scale, ThemeData & ScreenUtil Init"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [design, theme, colors, typography, screenutil, material3]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Plan ini mencakup setup seluruh design system foundation: color palette (Islamic Glassmorphism), typography scale (menggunakan `flutter_screenutil`), ThemeData (Material3), TV safe area wrapper, dan inisialisasi `ScreenUtil` di `main.dart`.

Plan ini **tidak membuat reusable widgets** (itu ada di Plan 04). Fokusnya murni design tokens, theme, dan konfigurasi responsive scaling.

**Source Specification**: [spec-design-ui-foundation.md](../spec/spec-design-ui-foundation.md) (SPEC-02 Part A)

## 1. Requirements & Constraints

- **REQ-001**: Seluruh UI harus menggunakan `flutter_screenutil` untuk responsive scaling — tidak ada hardcoded pixel values
- **REQ-002**: Design baseline resolution: 1920×1080 (16:9 landscape)
- **REQ-003**: Theme harus mendukung "Islamic Glassmorphism" aesthetic: Deep Emerald Green primary, Gold/Amber accents
- **REQ-004**: Typography scale harus mencakup minimal 7 text styles: display, heading, title, subtitle, body, caption, overline
- **REQ-005**: TV safe area harus 5% margin dari seluruh edge layar (standard 10-foot UI)
- **REQ-006**: Google Fonts (`Poppins`) sebagai default font family
- **CON-001**: Semua ukuran font menggunakan `.sp` extension dari ScreenUtil
- **CON-002**: Semua width menggunakan `.w`, height menggunakan `.h`, radius menggunakan `.r`
- **CON-003**: Tidak ada hardcoded color values di luar file theme constants — semua akses via `Theme.of(context)` atau constants class
- **GUD-001**: Glassmorphism background blur intensity: range 10-20
- **GUD-002**: Glassmorphism overlay opacity: range 0.05-0.15
- **PAT-001**: Semua color values didefinisikan sebagai `static const` dalam class terpisah
- **PAT-002**: Semua text styles didefinisikan sebagai static methods yang mengembalikan `TextStyle` dengan `.sp` units

## 2. Implementation Steps

### Phase 1: Package Dependencies

- GOAL-001: Menambahkan font dan ScreenUtil packages

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Jalankan `flutter pub add flutter_screenutil` — Responsive scaling framework | ✅ | 2026-02-18 |
| TASK-002 | Jalankan `flutter pub add google_fonts` — Dynamic font loading (Poppins) | ✅ | 2026-02-18 |
| TASK-003 | Jalankan `flutter pub get` dan pastikan dependencies terinstall clean | ✅ | 2026-02-18 |

### Phase 2: Color Palette Constants

- GOAL-002: Mendefinisikan seluruh color palette Islamic Glassmorphism sebagai constants

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-004 | Buat file `lib/core/theme/islamic_colors.dart` — Class `IslamicColors` dengan semua colors sebagai `static const Color` | ✅ | 2026-02-18 |
| TASK-005 | Definisikan Primary Colors: `deepEmerald = Color(0xFF0D4A3A)`, `emeraldGreen = Color(0xFF1B6B4A)`, `lightEmerald = Color(0xFF2E8B5A)` (warna utama background dan accents) | ✅ | 2026-02-18 |
| TASK-006 | Definisikan Accent Colors: `goldAmber = Color(0xFFD4A012)`, `lightGold = Color(0xFFE8C547)`, `warmGold = Color(0xFFF5D060)` (warna highlight dan CTA) | ✅ | 2026-02-18 |
| TASK-007 | Definisikan Background Colors: `darkBackground = Color(0xFF0A1A14)`, `surfaceDark = Color(0xFF0F2A1F)`, `surfaceLight = Color(0xFF1A3D2E)` | ✅ | 2026-02-18 |
| TASK-008 | Definisikan Text Colors: `textPrimary = Color(0xFFF5F5F5)`, `textSecondary = Color(0xFFB8C9C0)`, `textMuted = Color(0xFF7A9A8A)` | ✅ | 2026-02-18 |
| TASK-009 | Definisikan Glassmorphism Colors: `glassWhite = Color(0x1AFFFFFF)` (10% opacity), `glassBorder = Color(0x33FFFFFF)` (20% opacity), `glassOverlay = Color(0x0DFFFFFF)` (5% opacity) | ✅ | 2026-02-18 |
| TASK-010 | Definisikan State Colors: `success = Color(0xFF4CAF50)`, `error = Color(0xFFE53935)`, `warning = Color(0xFFFFA726)`, `info = Color(0xFF42A5F5)` | ✅ | 2026-02-18 |
| TASK-011 | Definisikan Prayer State Colors (untuk Display State Machine): `standbyColor = deepEmerald`, `preAdzanColor = Color(0xFF1E6038)`, `adzanColor = goldAmber`, `iqomahColor = Color(0xFFB8860B)`, `sholatColor = deepEmerald` | ✅ | 2026-02-18 |

### Phase 3: Typography Scale

- GOAL-003: Membuat typography scale yang menggunakan ScreenUtil `.sp` untuk semua font sizes

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-012 | Buat file `lib/core/theme/islamic_typography.dart` — Class `IslamicTypography` | ✅ | 2026-02-18 |
| TASK-013 | Implementasi static method `display()` — GoogleFonts.poppins, fontSize: `72.sp`, fontWeight: FontWeight.w700, color: textPrimary. Untuk clock display utama | ✅ | 2026-02-18 |
| TASK-014 | Implementasi static method `heading()` — fontSize: `48.sp`, fontWeight: FontWeight.w600. Untuk judul section utama | ✅ | 2026-02-18 |
| TASK-015 | Implementasi static method `title()` — fontSize: `36.sp`, fontWeight: FontWeight.w600. Untuk judul card/panel | ✅ | 2026-02-18 |
| TASK-016 | Implementasi static method `subtitle()` — fontSize: `28.sp`, fontWeight: FontWeight.w500. Untuk sub-judul | ✅ | 2026-02-18 |
| TASK-017 | Implementasi static method `body()` — fontSize: `24.sp`, fontWeight: FontWeight.w400. Untuk teks konten utama | ✅ | 2026-02-18 |
| TASK-018 | Implementasi static method `caption()` — fontSize: `20.sp`, fontWeight: FontWeight.w400, color: textSecondary. Untuk label kecil | ✅ | 2026-02-18 |
| TASK-019 | Implementasi static method `overline()` — fontSize: `16.sp`, fontWeight: FontWeight.w500, letterSpacing: `2.sp`. Untuk label uppercase | ✅ | 2026-02-18 |
| TASK-020 | Setiap method harus menerima optional named parameters: `Color? color`, `FontWeight? fontWeight` — untuk override default values | ✅ | 2026-02-18 |

### Phase 4: App ThemeData

- GOAL-004: Membuat Material3 ThemeData yang mengintegrasikan color palette dan typography

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-021 | Buat file `lib/core/theme/islamic_theme.dart` — Class `IslamicTheme` | ✅ | 2026-02-18 |
| TASK-022 | Implementasi static method `ThemeData darkTheme()` yang mengembalikan ThemeData dengan: `useMaterial3: true`, `brightness: Brightness.dark`, `scaffoldBackgroundColor: IslamicColors.darkBackground` | ✅ | 2026-02-18 |
| TASK-023 | Setup `ColorScheme.dark()` dengan mapping: `primary → emeraldGreen`, `secondary → goldAmber`, `surface → surfaceDark`, `error → error`, `onPrimary → textPrimary`, `onSecondary → darkBackground`, `onSurface → textPrimary`, `onError → textPrimary` | ✅ | 2026-02-18 |
| TASK-024 | Setup `TextTheme` dengan mapping typography scale ke Material text styles: `displayLarge → display()`, `headlineLarge → heading()`, `titleLarge → title()`, `titleMedium → subtitle()`, `bodyLarge → body()`, `bodySmall → caption()`, `labelSmall → overline()` | ✅ | 2026-02-18 |
| TASK-025 | Setup `AppBarTheme`: backgroundColor transparent, elevation 0, foregroundColor textPrimary | ✅ | 2026-02-18 |
| TASK-026 | Setup `CardTheme`: color surfaceDark, elevation 0, shape RoundedRectangleBorder dengan borderRadius `16.r` | ✅ | 2026-02-18 |

### Phase 5: TV Safe Area Wrapper

- GOAL-005: Membuat widget wrapper yang memberikan 5% safe area margin standar android TV

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-027 | Buat file `lib/core/theme/tv_safe_area.dart` — StatelessWidget `TVSafeArea` | ✅ | 2026-02-18 |
| TASK-028 | Implementasi `TVSafeArea` yang membungkus `child` dengan `Padding` 5% dari screen width (horizontal) dan 5% dari screen height (vertical) dihitung via `MediaQuery.of(context).size` | ✅ | 2026-02-18 |
| TASK-029 | Tambahkan optional parameter `bool ignoreSafeArea = false` untuk bypass jika diperlukan (misal fullscreen background) | ✅ | 2026-02-18 |

### Phase 6: ScreenUtil Initialization

- GOAL-006: Mengintegrasikan ScreenUtil initialization ke `main.dart` dan setup MaterialApp

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-030 | Update `lib/main.dart` — Wrap `MaterialApp` dengan `ScreenUtilInit` widget. Set `designSize: const Size(1920, 1080)`, `minTextAdapt: true`, `splitScreenMode: false` | ✅ | 2026-02-18 |
| TASK-031 | Set `theme: IslamicTheme.darkTheme()` di `MaterialApp` | ✅ | 2026-02-18 |
| TASK-032 | Pastikan `WidgetsFlutterBinding.ensureInitialized()` dipanggil sebelum `runApp()` | ✅ | 2026-02-18 |

### Phase 7: Testing

- GOAL-007: Unit tests untuk memvalidasi color constants, typography scale, dan theme configuration

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-033 | Buat file `test/core/theme/islamic_colors_test.dart` | ✅ | 2026-02-18 |
| TASK-034 | TEST: Semua primary, accent, background, text, glass, state, dan prayer state colors terdefinisi dan bukan null | ✅ | 2026-02-18 |
| TASK-035 | TEST: Glass colors memiliki opacity yang benar (glassWhite ~10%, glassBorder ~20%, glassOverlay ~5%) | ✅ | 2026-02-18 |
| TASK-036 | Buat file `test/core/theme/islamic_typography_test.dart` | ✅ | 2026-02-18 |
| TASK-037 | TEST: Semua 7 typography methods mengembalikan TextStyle yang valid dengan menggunakan Poppins font family | ✅ | 2026-02-18 |
| TASK-038 | TEST: Typography methods menerima optional `color` dan `fontWeight` overrides | ✅ | 2026-02-18 |
| TASK-039 | Buat file `test/core/theme/islamic_theme_test.dart` | ✅ | 2026-02-18 |
| TASK-040 | TEST: `darkTheme()` memiliki `useMaterial3: true`, `brightness: Brightness.dark`, correct primary/secondary colors | ✅ | 2026-02-18 |
| TASK-041 | Jalankan `flutter test test/core/theme/ --reporter=expanded` dan pastikan semua pass | ✅ | 2026-02-18 |

## 3. Alternatives

- **ALT-001**: Menggunakan Tailwind-style utility classes — Ditolak karena Flutter tidak memiliki ecosystem ini, dan `flutter_screenutil` sudah menjadi standar de-facto
- **ALT-002**: Hardcode font sizes tanpa ScreenUtil — Ditolak karena tidak responsive di berbagai resolusi Android TV (720p, 1080p, 4K)
- **ALT-003**: Bundling font files locally (assets/fonts/) — Ditolak untuk saat ini karena `google_fonts` menangani caching secara otomatis; bisa di-migrate ke local fonts di production jika diperlukan untuk offline reliability
- **ALT-004**: Menggunakan light theme — Ditolak karena dark theme lebih sesuai untuk digital signage masjid, mengurangi light pollution, dan mengurangi screen burn-in

## 4. Dependencies

- **DEP-001**: `flutter_screenutil` (^5.9.0) — Responsive scaling, provides `.sp`, `.w`, `.h`, `.r` extensions
- **DEP-002**: `google_fonts` (^6.1.0) — Dynamic font loading, provides GoogleFonts.poppins()
- **DEP-003**: Flutter SDK `material` package — MaterialApp, ThemeData, ColorScheme
- **DEP-004**: `MediaQuery` — Screen dimensions untuk TV Safe Area calculations

## 5. Files

- **FILE-001**: `lib/core/theme/islamic_colors.dart` — [NEW] Color palette constants
- **FILE-002**: `lib/core/theme/islamic_typography.dart` — [NEW] Typography scale with ScreenUtil
- **FILE-003**: `lib/core/theme/islamic_theme.dart` — [NEW] Material3 ThemeData
- **FILE-004**: `lib/core/theme/tv_safe_area.dart` — [NEW] TV safe area wrapper widget
- **FILE-005**: `lib/main.dart` — [MODIFY] ScreenUtil init, theme assignment
- **FILE-006**: `pubspec.yaml` — [MODIFY] Add flutter_screenutil, google_fonts
- **FILE-007**: `test/core/theme/islamic_colors_test.dart` — [NEW] Color constants tests
- **FILE-008**: `test/core/theme/islamic_typography_test.dart` — [NEW] Typography tests
- **FILE-009**: `test/core/theme/islamic_theme_test.dart` — [NEW] Theme tests

## 6. Testing

- **TEST-001**: All color constants are defined (non-null) and have expected opacity for glass variants
- **TEST-002**: All 7 typography methods return valid TextStyle with Poppins font
- **TEST-003**: Typography optional parameters (color, fontWeight) override defaults correctly
- **TEST-004**: `darkTheme()` has `useMaterial3: true`, `Brightness.dark`, correct ColorScheme
- **TEST-005**: TextTheme mapping in `darkTheme()` uses correct typography methods

**Test Command**: `flutter test test/core/theme/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: `google_fonts` requires internet connection for first font download — Mitigasi: pre-cache font di app startup, atau fallback ke system font
- **RISK-002**: ScreenUtil design size (1920×1080) mungkin tidak optimal untuk semua Android TV resolutions — Mitigasi: `minTextAdapt: true` menangani adaptasi otomatis
- **RISK-003**: TV safe area 5% mungkin terlalu banyak/kurang di beberapa TV — Mitigasi: parametrize percentage, adjustable di settings
- **ASSUMPTION-001**: Android TV yang ditarget mendukung resolusi minimal 720p
- **ASSUMPTION-002**: `flutter_screenutil` bekerja dengan baik di Android TV environment
- **ASSUMPTION-003**: `google_fonts` package dapat mengakses font file yang sudah di-cache secara offline

## 8. Related Specifications / Further Reading

- [SPEC-02: UI Foundation](../spec/spec-design-ui-foundation.md) — Source specification
- [UI/UX Guide](../docs/UI_UX_GUIDE.md) — Islamic Glassmorphism design principles
- Plan 04: `design-ui-components-1.md` — Next plan yang membangun reusable widgets di atas theme ini
- [Material Design 3](https://m3.material.io/) — Material3 theming reference
