---
title: "UI Foundation & Theme System Specification"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
tags: [design, ui, theme, screenutil, dpad, glassmorphism, android-tv]
---

# Introduction

Spesifikasi ini mendefinisikan fondasi UI/UX untuk aplikasi Miqotul Khoir TV (MKT): theme system (Islamic Glassmorphism), responsive scaling (`flutter_screenutil`), typography, color palette, D-Pad navigation system, layout grid, dan reusable UI components.

Dokumen ini menjadi acuan dasar bagi semua halaman dan widget di aplikasi — setiap spec lain (State Machine, Setup Wizard, Settings) merujuk kesini untuk standar visual.

## 1. Purpose & Scope

### Purpose

Mendefinisikan design system, component contracts, dan interaction patterns yang konsisten di seluruh aplikasi MKT untuk platform Android TV.

### Scope

- Color palette dan color scheme (Islamic Glassmorphism)
- Typography scale menggunakan `flutter_screenutil`
- ScreenUtil configuration dan extensions
- D-Pad navigation system (FocusTraversal)
- TV Safe Area margins
- Layout grid system (header / body / footer)
- Reusable component contracts (GlassmorphismCard, FocusableWidget, dll)
- Screen burn-in prevention strategy
- Animation dan transition standards

### Intended Audience

- AI agents dan developer yang membangun UI widgets
- Designer yang perlu memahami design constraints Android TV

### Assumptions

- Target display: Android TV 16:9 landscape
- Design baseline: 1920×1080 (Full HD)
- Viewing distance: ~3 meter (10 feet — leanback design)
- Primary input: D-Pad remote control (bukan touch)
- `flutter_screenutil` sudah terpasang dan di-init di root app

## 2. Definitions

| Term | Definition |
|------|-----------|
| **Glassmorphism** | UI style menggunakan semi-transparent backgrounds dengan blur effect |
| **D-Pad** | Directional pad pada remote TV (Up, Down, Left, Right, Select, Back) |
| **TV Safe Area** | Area aman di layar TV yang dijamin terlihat (exclude overscan area) |
| **10-foot UI** | Design paradigm untuk UI yang dilihat dari jarak ~3 meter |
| **ScreenUtil** | Library Flutter untuk responsive scaling berdasarkan design baseline |
| **Focus Indicator** | Visual cue yang menunjukkan elemen mana yang aktif/terpilih via D-Pad |
| **Burn-in** | Kerusakan display permanen akibat static image ditampilkan terlalu lama |
| **Leanback** | Design approach Android untuk pengalaman TV "lean back" |

## 3. Requirements, Constraints & Guidelines

### Requirements

- **REQ-001**: Semua sizing (font, width, height, radius, padding, margin) harus menggunakan `flutter_screenutil` extensions — hardcoded pixel values dilarang
- **REQ-002**: Minimum font size adalah `24.sp` untuk body text — teks harus terbaca dari jarak 3 meter
- **REQ-003**: Semua interactive elements harus focusable dan navigable via D-Pad remote
- **REQ-004**: Focus indicator harus memiliki kontras tinggi dan clearly visible (minimum 4px border + glow)
- **REQ-005**: Color palette harus mengikuti Islamic Glassmorphism theme (Deep Emerald Green + Gold/Amber)
- **REQ-006**: Layout harus berfungsi di resolusi 720p, 1080p, 2K, dan 4K tanpa overflow atau cut-off
- **REQ-007**: Screen burn-in prevention harus aktif saat state SHOLAT (blank/dimmed screen)
- **REQ-008**: Semua state transition antar layout harus menggunakan smooth animation (fade/slide)
- **REQ-009**: App harus berjalan pada 60 FPS — tidak ada jank atau frame drop

### Constraints

- **CON-001**: Orientasi layar selalu landscape, tidak mendukung portrait
- **CON-002**: Tidak ada touch interaction — semua navigasi via D-Pad
- **CON-003**: Tap target minimum 48×48 logical pixels (accessibility standard)
- **CON-004**: Maksimal 2 level depth navigasi dari main display
- **CON-005**: Background image/gradient tidak boleh terlalu terang — readability prioritas

### Guidelines

- **GUD-001**: Gunakan `Theme.of(context)` untuk akses warna — jangan hardcode hex values di widget
- **GUD-002**: Extract widget classes untuk reusability — jangan gunakan helper methods untuk UI
- **GUD-003**: Gunakan `const` constructors di mana memungkinkan
- **GUD-004**: Body text menggunakan `Montserrat` atau `Roboto`, clock menggunakan monospace bold
- **GUD-005**: Animasi transition: durasi 300-500ms, curve `Curves.easeInOut`
- **GUD-006**: Setiap widget yang menerima focus harus menampilkan visual feedback dalam < 100ms

### Patterns

- **PAT-001**: ScreenUtil Init — Wrap `MaterialApp` dengan `ScreenUtilInit(designSize: Size(1920, 1080))`
- **PAT-002**: Focus Builder — Gunakan `Focus` + `Builder` atau custom `FocusableActionDetector` untuk D-Pad
- **PAT-003**: AnimatedSwitcher — Untuk transisi antar state-based layouts

## 4. Interfaces & Data Contracts

### 4.1. ScreenUtil Configuration

```dart
/// main.dart — Root app setup
class MiqotulKhoirApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Miqotul Khoir TV',
          theme: IslamicTheme.darkTheme,
          home: child,
        );
      },
      child: const MainDisplayPage(),
    );
  }
}
```

### 4.2. Color Palette — Islamic Glassmorphism

```dart
/// core/theme/islamic_colors.dart
abstract class IslamicColors {
  // Primary — Deep Emerald Green
  static const Color deepEmeraldPrimary = Color(0xFF004D40);
  static const Color emeraldSecondary = Color(0xFF00695C);
  static const Color emeraldLight = Color(0xFF00897B);
  static const Color emeraldSurface = Color(0xFF1B5E20);

  // Accent — Gold / Amber
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color amberWarm = Color(0xFFFFAB00);
  static const Color goldLight = Color(0xFFFFE082);

  // Neutral
  static const Color backgroundDark = Color(0xFF0D1B2A);
  static const Color surfaceDark = Color(0xFF1B2838);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70% white
  static const Color textMuted = Color(0x80FFFFFF);      // 50% white

  // Glass
  static const Color glassBackground = Color(0x33FFFFFF);     // 20% white
  static const Color glassBackgroundDark = Color(0x1AFFFFFF); // 10% white
  static const Color glassBorder = Color(0x4DFFFFFF);         // 30% white

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);
}
```

### 4.3. Typography Scale

```dart
/// core/theme/islamic_typography.dart
abstract class IslamicTypography {
  // Clock — Monospace Bold
  static TextStyle get clockLarge => TextStyle(
    fontSize: 180.sp,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    color: IslamicColors.textPrimary,
  );

  static TextStyle get clockMedium => TextStyle(
    fontSize: 128.sp,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    color: IslamicColors.textPrimary,
  );

  // Countdown
  static TextStyle get countdownLarge => TextStyle(
    fontSize: 120.sp,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    color: IslamicColors.textPrimary,
  );

  static TextStyle get countdownMedium => TextStyle(
    fontSize: 96.sp,
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    color: IslamicColors.textPrimary,
  );

  // Heading
  static TextStyle get headingLarge => TextStyle(
    fontSize: 48.sp,
    fontWeight: FontWeight.bold,
    color: IslamicColors.goldAccent,
  );

  static TextStyle get headingMedium => TextStyle(
    fontSize: 36.sp,
    fontWeight: FontWeight.bold,
    color: IslamicColors.textPrimary,
  );

  // Body
  static TextStyle get bodyLarge => TextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeight.w500,
    color: IslamicColors.textPrimary,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.normal,
    color: IslamicColors.textPrimary,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.normal,
    color: IslamicColors.textSecondary,
  );

  // Label
  static TextStyle get label => TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
    color: IslamicColors.textPrimary,
  );

  // Running Text
  static TextStyle get marquee => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w500,
    color: IslamicColors.goldAccent,
  );
}
```

### 4.4. TV Safe Area

```dart
/// core/theme/tv_safe_area.dart
abstract class TVSafeArea {
  /// Horizontal margin: 5% of 1920 = 96px
  static EdgeInsets get padding => EdgeInsets.symmetric(
    horizontal: 96.w,
    vertical: 54.h, // 5% of 1080
  );

  /// Reduced padding for content-heavy layouts
  static EdgeInsets get paddingCompact => EdgeInsets.symmetric(
    horizontal: 48.w,
    vertical: 32.h,
  );
}
```

### 4.5. Layout Grid System

```
┌─────────────────────────────────────────────────────┐
│  TV Safe Area Padding (96.w horizontal, 54.h vert)  │
│  ┌───────────────────────────────────────────────┐  │
│  │  HEADER: Logo | Nama Masjid | Tanggal         │  │
│  ├───────────────────────────────────────────────┤  │
│  │                                               │  │
│  │  BODY: Main Content (Expanded)                │  │
│  │  ┌──────────────┐  ┌──────────────────────┐   │  │
│  │  │  Jam Besar   │  │  Info / Countdown    │   │  │
│  │  │  (Left)      │  │  (Right)             │   │  │
│  │  └──────────────┘  └──────────────────────┘   │  │
│  │                                               │  │
│  ├───────────────────────────────────────────────┤  │
│  │  PRAYER CARDS: 7 cards (Subuh → Isya)         │  │
│  ├───────────────────────────────────────────────┤  │
│  │  FOOTER: Running Text (Marquee, 60.h)         │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

### 4.6. GlassmorphismCard Component

```dart
/// presentation/widgets/glassmorphism_card.dart
class GlassmorphismCard extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;
  final Color backgroundColor;   // default: IslamicColors.glassBackground
  final Color borderColor;       // default: IslamicColors.glassBorder
  final double borderRadius;     // default: 16.r
  final double blurAmount;       // default: 10.0
  final EdgeInsets? padding;     // default: EdgeInsets.all(24.r)

  // ... constructor & build
}
```

### 4.7. FocusableWidget Component

```dart
/// presentation/widgets/focusable_widget.dart
class FocusableWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSelect;              // D-Pad center button
  final bool autofocus;
  final FocusNode? focusNode;
  final Color focusBorderColor;              // default: IslamicColors.goldAccent
  final double focusBorderWidth;             // default: 4.0
  final Color focusGlowColor;               // default: goldAccent.withOpacity(0.5)
  final double focusGlowBlurRadius;          // default: 20.0
  final Duration animationDuration;          // default: 200ms

  // When focused: shows gold border + glow + optional scale
  // When unfocused: transparent border, no glow
}
```

### 4.8. File Structure

```
lib/
├── core/
│   └── theme/
│       ├── islamic_colors.dart              # Color palette constants
│       ├── islamic_typography.dart           # Typography scale with .sp
│       ├── islamic_theme.dart               # ThemeData configuration
│       └── tv_safe_area.dart                # Safe area padding
├── presentation/
│   └── widgets/
│       ├── glassmorphism_card.dart           # Semi-transparent card
│       ├── focusable_widget.dart             # D-Pad focusable wrapper
│       ├── islamic_background.dart           # Background gradient/pattern
│       └── running_text_widget.dart          # Marquee text
```

## 5. Acceptance Criteria

- **AC-001**: Given ScreenUtilInit with designSize (1920, 1080), When running on 720p device, Then all UI elements scale proportionally without overflow
- **AC-002**: Given ScreenUtilInit with designSize (1920, 1080), When running on 4K device, Then all UI elements scale proportionally without blurriness
- **AC-003**: Given any interactive element on screen, When D-Pad arrow keys are pressed, Then focus moves logically between elements
- **AC-004**: Given an element receives focus, When rendered, Then it shows gold border (4px) + glow effect within 100ms
- **AC-005**: Given main display layout, When rendered, Then content stays within TV Safe Area margins (96.w horizontal, 54.h vertical)
- **AC-006**: Given body text on screen, When measured, Then font size is ≥ 24.sp (readable from 3 meters)
- **AC-007**: Given GlassmorphismCard, When rendered, Then it shows semi-transparent background with blur effect
- **AC-008**: Given any state transition, When layout changes, Then AnimatedSwitcher provides fade transition (300-500ms)
- **AC-009**: Given SHOLAT state, When activated, Then screen goes blank/dimmed for burn-in prevention
- **AC-010**: Given the app running, When profiled, Then frame rendering maintains 60 FPS average

## 6. Test Automation Strategy

### Test Levels

| Level | Scope | Framework |
|-------|-------|-----------|
| **Widget** | Individual components (GlassmorphismCard, FocusableWidget) | `flutter_test` |
| **Widget** | Layout structure (header/body/footer positioning) | `flutter_test` |
| **Widget** | Focus traversal (D-Pad navigation order) | `flutter_test` |

### Required Tests

- **TEST-001**: `GlassmorphismCard` renders with correct background opacity and border
- **TEST-002**: `FocusableWidget` shows focus indicator when focused, hides when unfocused
- **TEST-003**: D-Pad key simulation moves focus in expected order between widgets
- **TEST-004**: TV Safe Area padding is correctly applied on all layout pages
- **TEST-005**: Typography scale values match specification (clockLarge = 180.sp, bodySmall = 24.sp, etc.)
- **TEST-006**: Color palette values match specification hex codes

### Important Note

> Widget tests yang menggunakan ScreenUtil perlu di-wrap dengan `ScreenUtilInit` pada test setup.

## 7. Rationale & Context

### Mengapa flutter_screenutil?

Android TV memiliki berbagai resolusi (720p, 1080p, 4K). Tanpa responsive scaling:
- Widget overflow di resolusi rendah
- Widget terlalu kecil di resolusi tinggi
- Font size tidak konsisten antar device

`flutter_screenutil` memberikan scaling otomatis berdasarkan design baseline 1920×1080.

### Mengapa Islamic Glassmorphism?

- Deep Emerald Green: warna dominan dalam estetika Islam (simbolisme surga)
- Gold/Amber accent: elegan, kontras tinggi terhadap hijau tua
- Glassmorphism effect: modern, premium, sesuai trend digital signage

### Mengapa D-Pad First, Bukan Touch?

Android TV tidak memiliki touchscreen. Semua interaksi menggunakan remote control. Ini mempengaruhi:
- Minimum tap target size (48×48)
- Visible focus indicators (gold border + glow)
- Linear focus traversal (bukan random tap)

## 8. Dependencies & External Integrations

### Third-Party Packages

- **DEP-001**: `flutter_screenutil` — Responsive scaling library
- **DEP-002**: `google_fonts` — Font asset (Montserrat, Roboto)
- **DEP-003**: `marquee` — Running text widget

### Platform Dependencies

- **PLT-001**: Android TV (API level ≥ 21) — Target platform
- **PLT-002**: Flutter SDK (stable channel) — Framework

## 9. Examples & Edge Cases

### Edge Case: ScreenUtil Belum Diinisialisasi

```dart
// ❌ WRONG — ScreenUtil extensions di luar ScreenUtilInit tree
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Hello', style: TextStyle(fontSize: 24.sp)); // CRASH
  }
}

// ✅ CORRECT — Pastikan widget berada di dalam ScreenUtilInit builder
class MiqotulKhoirApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      builder: (context, child) => MaterialApp(home: child),
      child: SplashScreen(), // Now 24.sp works
    );
  }
}
```

### Edge Case: Focus Lost Saat Layout Berubah

```dart
// ✅ Restore focus setelah state transition
class StateAwareLayout extends StatefulWidget {
  @override
  State<StateAwareLayout> createState() => _StateAwareLayoutState();
}

class _StateAwareLayoutState extends State<StateAwareLayout> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true, // Reclaim focus saat layout rebuild
      child: /* layout content */,
    );
  }
}
```

## 10. Validation Criteria

- [ ] Semua warna sesuai dengan hex values di spec
- [ ] Semua typography size menggunakan `.sp` extension
- [ ] GlassmorphismCard dapat di-customkan (width, height, color, border)
- [ ] FocusableWidget menampilkan gold indicator saat focused
- [ ] Layout tidak overflow di 720p dan tidak terlalu kecil di 4K
- [ ] D-Pad navigation berfungsi di semua interactive elements
- [ ] Running text berjalan smooth tanpa lag

## 11. Related Specifications / Further Reading

- [PRD §5 — UI/UX Guidelines](file:///d:/AndroidProject/LatihanFlutter/sadayana_masjid_tv/Product_Requirement_Document.md) — Original design direction
- [UI/UX Guide](file:///d:/AndroidProject/LatihanFlutter/sadayana_masjid_tv/docs/UI_UX_GUIDE.md) — Detailed implementation guide with code examples
- SPEC-04: Display State Machine — 5 different UI layouts per state
- SPEC-05: Setup Wizard — Wizard UI components and navigation
- SPEC-06: Settings & Content — Settings menu UI with D-Pad
