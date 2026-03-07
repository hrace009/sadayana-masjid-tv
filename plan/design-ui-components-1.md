---
goal: "Implementasi UI Components — GlassmorphismCard, FocusableWidget, IslamicBackground, RunningText"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-19
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [design, ui-components, glassmorphism, focus, dpad, widget, reusable]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Plan ini mencakup implementasi reusable UI components yang digunakan di seluruh aplikasi: `GlassmorphismCard` (container dengan blur effect), `FocusableWidget` (wrapper D-Pad focus untuk Android TV), `IslamicBackground` (animated background), dan `RunningTextWidget` (marquee text). Semua widget ini menggunakan design system dari Plan 03.

**Source Specification**: [spec-design-ui-foundation.md](../spec/spec-design-ui-foundation.md) (SPEC-02 Part B)

## 1. Requirements & Constraints

- **REQ-001**: `GlassmorphismCard` harus memiliki backdrop blur effect, semi-transparent background, dan subtle border
- **REQ-002**: `FocusableWidget` harus merespons D-Pad navigation (up/down/left/right/select) dan menampilkan visual focus indicator
- **REQ-003**: Semua interactive elements harus memiliki minimum focus area 48×48 logical pixels (accessibility)
- **REQ-004**: `RunningTextWidget` harus scroll horizontal terus-menerus tanpa user interaction
- **REQ-005**: `IslamicBackground` harus memiliki geometric pattern atau gradient yang subtle, anti screen burn-in
- **REQ-006**: Animasi harus smooth 60fps — tidak boleh ada janky animations
- **CON-001**: Semua dimensi menggunakan ScreenUtil extensions (`.w`, `.h`, `.sp`, `.r`)
- **CON-002**: Warna harus diambil dari `IslamicColors` constants, bukan hardcoded
- **CON-003**: Const constructors harus digunakan dimana memungkinkan
- **GUD-001**: Focus indicator: golden glow/border (goldAmber) dengan smooth animation (200ms)
- **GUD-002**: Glassmorphism blur intensity: sigma 10-20
- **GUD-003**: Screen burn-in prevention: subtle position shift pada static elements setiap 60 detik
- **PAT-001**: Widget harus stateless jika tidak memerlukan internal state
- **PAT-002**: Composition over inheritance — gunakan wrapper pattern bukan extend

## 2. Implementation Steps

### Phase 1: Package Dependencies

- GOAL-001: Menambahkan package untuk marquee text widget

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Jalankan `flutter pub add marquee` — Horizontal scrolling text widget | ✅ | 2026-02-18 |
| TASK-002 | Jalankan `flutter pub get` | ✅ | 2026-02-18 |

### Phase 2: GlassmorphismCard Widget

- GOAL-002: Membuat reusable glassmorphism container dengan blur, transparency, dan border effects

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-003 | Buat file `lib/presentation/widgets/glassmorphism_card.dart` | ✅ | 2026-02-18 |
| TASK-004 | Implementasi `GlassmorphismCard` sebagai `StatelessWidget` dengan parameter: `Widget child` (required), `double blurIntensity = 15`, `Color backgroundColor = IslamicColors.glassWhite`, `Color borderColor = IslamicColors.glassBorder`, `double borderRadius = 16`, `EdgeInsetsGeometry? padding` (default: `EdgeInsets.all(16.w)` di build method), `EdgeInsetsGeometry? margin`, `bool isFocused = false` | ✅ | 2026-02-18 |
| TASK-005 | Build method: `Container` (margin) → `ClipRRect` (borderRadius.r) → `BackdropFilter` (sigmaX/sigmaY = blurIntensity) → `Container` dengan `decoration: BoxDecoration(color, borderRadius, border: Border.all(borderColor, 1.w), boxShadow: isFocused ? [...] : null)` dan `padding: padding ?? EdgeInsets.all(16.w)`. Child langsung di-pass sebagai child inner Container. | ✅ | 2026-02-18 |
| TASK-006 | Parameter `bool isFocused = false` (sudah termasuk di TASK-004) menambahkan golden glow `BoxShadow` ke decoration ketika true: `BoxShadow(color: IslamicColors.goldAmber.withValues(alpha: 0.3), blurRadius: 12.r, spreadRadius: 2.r)`. Saat `isFocused = false`, `boxShadow: null`. | ✅ | 2026-02-18 |

### Phase 3: FocusableWidget

- GOAL-003: Membuat D-Pad-aware focus wrapper untuk seluruh interactive elements

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | Buat file `lib/presentation/widgets/focusable_widget.dart` | ✅ | 2026-02-18 |
| TASK-008 | Implementasi `FocusableWidget` sebagai `StatefulWidget` dengan parameter: `Widget Function(bool isFocused) builder` (required), `VoidCallback? onSelect` (D-Pad center/Enter press), `FocusNode? focusNode`, `bool autofocus = false`, `Duration focusAnimationDuration = const Duration(milliseconds: 200)` | ✅ | 2026-02-18 |
| TASK-009 | Dalam `_FocusableWidgetState`: Buat internal `_focusNode` jika tidak disediakan via constructor. Dispose `_focusNode` di `dispose()` jika internal | ✅ | 2026-02-18 |
| TASK-010 | State `_isFocused` (bool) disimpan di `_FocusableWidgetState`. `Focus.onFocusChange` memanggil `setState(() => _isFocused = hasFocus)`. Build: `Focus` → `AnimatedScale(scale: _isFocused ? 1.02 : 1.0, duration: focusAnimationDuration)` → `ConstrainedBox(minWidth: 48, minHeight: 48)` → `widget.builder(_isFocused)` | ✅ | 2026-02-18 |
| TASK-011 | Handle `KeyEvent` di `Focus.onKeyEvent`: detect `LogicalKeyboardKey.select`, `LogicalKeyboardKey.enter`, `LogicalKeyboardKey.gameButtonA` → panggil `onSelect()`. Return `KeyEventResult.handled` jika processed, `KeyEventResult.ignored` jika tidak | ✅ | 2026-02-18 |
| TASK-012 | Pastikan minimum size constraint (48×48 logical pixels) via `ConstrainedBox` | ✅ | 2026-02-18 |

### Phase 4: IslamicBackground Widget

- GOAL-004: Membuat animated background widget dengan Islamic-inspired design dan anti burn-in

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-013 | Buat file `lib/presentation/widgets/islamic_background.dart` | ✅ | 2026-02-18 |
| TASK-014 | Implementasi `IslamicBackground` sebagai `StatefulWidget` dengan dua layer gradient di dalam `Stack(fit: StackFit.expand)`: Layer 1: `LinearGradient(begin: Alignment(-1.0+offset, -1.0+offset), end: Alignment(1.0+offset, 1.0+offset), colors: [darkBackground, surfaceDark])`, Layer 2: `RadialGradient(center: Alignment(offset, offset), radius: 1.2, colors: [emeraldGreen.withValues(alpha: 0.1), transparent])`. Layer 3: `SizedBox.expand` untuk child. | ✅ | 2026-02-18 |
| TASK-015 | Anti screen burn-in: `_burnInTimer = Timer.periodic(Duration(seconds: 60), (_) => _shiftGradient())`. `_shiftGradient()` mengubah `_alignmentOffset += _shiftDirection * 0.005` (shift 0.5% per 60 detik). Saat `_alignmentOffset.abs() >= 0.02` (batas ±2%), `_shiftDirection` dibalik. Offset diapply ke begin/end kedua layer. Timer di-cancel di `dispose()`. | ✅ | 2026-02-18 |
| TASK-016 | Widget menerima `Widget child` dan menampilkannya di atas background menggunakan `Stack` | ✅ | 2026-02-18 |

### Phase 5: RunningTextWidget

- GOAL-005: Membuat widget ticker text yang scroll horizontal terus-menerus

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-017 | Buat file `lib/presentation/widgets/running_text_widget.dart` | ✅ | 2026-02-18 |
| TASK-018 | Implementasi `RunningTextWidget` sebagai `StatelessWidget` dengan parameter: `String text` (required), `TextStyle? textStyle` (default: `IslamicTypography.body()` di build), `double scrollSpeed = 50.0`, `double? blankSpace` (default: `100.w` di build), `Duration pauseDuration = Duration.zero`, `bool showBackground = true`, `double height = 48` (di-scale via `.h` di build) | ✅ | 2026-02-18 |
| TASK-019 | Build method: Guard awal — jika `text.isEmpty`, return `const SizedBox.shrink()`. Jika tidak: buat `marqueeWidget = SizedBox(height: height.h, child: Marquee(text, style, scrollAxis, crossAxisAlignment, blankSpace: blankSpace ?? 100.w, velocity: scrollSpeed, pauseAfterRound: pauseDuration, accelerationDuration: 1s, decelerationDuration: 500ms))`. | ✅ | 2026-02-18 |
| TASK-020 | Jika `showBackground = true`: wrap `marqueeWidget` dengan `GlassmorphismCard(padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h))`. Jika false: return `marqueeWidget` langsung. | ✅ | 2026-02-18 |

### Phase 6: Testing

- GOAL-006: Widget tests untuk semua reusable components

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-021 | Buat file `test/presentation/widgets/glassmorphism_card_test.dart` | ✅ | 2026-02-18 |
| TASK-022 | TEST: `GlassmorphismCard` renders child widget correctly | ✅ | 2026-02-18 |
| TASK-023 | TEST: `GlassmorphismCard` displays golden glow shadow when `isFocused = true` | ✅ | 2026-02-18 |
| TASK-024 | TEST: `GlassmorphismCard` uses default blur intensity and border radius when not specified | ✅ | 2026-02-18 |
| TASK-025 | Buat file `test/presentation/widgets/focusable_widget_test.dart` | ✅ | 2026-02-18 |
| TASK-026 | TEST: `FocusableWidget` calls `builder(false)` when not focused, `builder(true)` when focused | ✅ | 2026-02-18 |
| TASK-027 | TEST: `FocusableWidget` calls `onSelect` when Enter key pressed while focused | ✅ | 2026-02-18 |
| TASK-028 | TEST: `FocusableWidget` disposes internal FocusNode correctly | ✅ | 2026-02-18 |
| TASK-029 | Buat file `test/presentation/widgets/running_text_widget_test.dart` | ✅ | 2026-02-18 |
| TASK-030 | TEST: `RunningTextWidget` renders Marquee when text is not empty | ✅ | 2026-02-18 |
| TASK-031 | TEST: `RunningTextWidget` renders `SizedBox.shrink()` when text is empty | ✅ | 2026-02-18 |
| TASK-032 | Jalankan `flutter test test/presentation/widgets/ --reporter=expanded` dan pastikan semua pass | ✅ | 2026-02-18 |

## 3. Alternatives

- **ALT-001**: Menggunakan `glassmorphism` package — Ditolak karena custom implementation memberikan kontrol penuh atas blur intensity dan border styling sesuai design system
- **ALT-002**: Menggunakan default Flutter `Focus` widget tanpa wrapper — Ditolak karena berulang kali menulis focus logic di setiap widget tidak DRY, dan butuh konsistensi visual focus indicator
- **ALT-003**: Menggunakan `AnimatedContainer` untuk glassmorphism — Ditolak karena `BackdropFilter` memberikan real blur effect, bukan simulasi

## 5. Android TV D-Pad + Keyboard Patterns (Proven)

### PATTERN-001 — TextField dengan D-Pad Navigation

Untuk setiap `TextField` yang harus bisa diakses via D-pad remote:

```dart
// FocusNode di level State:
final FocusNode _fieldFocusNode = FocusNode(skipTraversal: true);
//   ^ skipTraversal: true = D-pad tidak auto-landing di sini
//     tapi requestFocus() programatik tetap berfungsi

// Builder:
FocusableWidget(
  onSelect: () {
    // WAJIB defer ke postFrameCallback — jika synchronous,
    // IME tidak ter-trigger karena key event belum selesai diproses.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fieldFocusNode.requestFocus();
    });
  },
  builder: (isFocused) {
    return AnimatedContainer(
      // ...
      child: TextField(
        focusNode: _fieldFocusNode,
        // JANGAN bungkus TextField dengan ExcludeFocus()
        // karena akan memblokir requestFocus() programatik!
      ),
    );
  },
)
```

**Aturan kritis**:
- `FocusNode(skipTraversal: true)` sudah cukup mencegah D-pad traversal otomatis
- `ExcludeFocus()` tanpa `excluding: false` → `descendantsAreFocusable = false` → `requestFocus()` diam-diam diabaikan
- `addPostFrameCallback` wajib untuk membuka IME dari dalam key-event handler

### PATTERN-002 — Widget Non-TextField yang Butuh Soft Keyboard

Contoh: `PinInputWidget` yang menampilkan digit boxes kustom tapi butuh keyboard virtual.

```dart
// Hidden TextField sebagai IME connection:
Offstage(
  child: TextField(
    focusNode: _hiddenFocusNode,
    controller: _hiddenController,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
  ),
)
// FocusableWidget memanggil _hiddenFocusNode.requestFocus() via postFrameCallback
// Controller listener meneruskan digit ke business logic
```

### PATTERN-003 — Tombol FocusableWidget di Column (Teks Rata Tengah)

```dart
IntrinsicHeight(              // mencegah FocusableWidget meregang vertikal
  child: FocusableWidget(
    builder: (isFocused) {
      return AnimatedContainer(
        alignment: Alignment.center,  // teks rata tengah H & V
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        // ...
        child: Text('Label'),
      );
    },
  ),
)
```

### PATTERN-004 — Dialog dengan FocusableWidget Buttons

Gunakan `Dialog` (bukan `AlertDialog`) saat menempatkan `FocusableWidget` sebagai tombol aksi. `AlertDialog.actions` menggunakan `OverflowBar` yang mengganggu layout `FocusableWidget`.

```dart
showDialog(
  builder: (_) => Dialog(
    child: Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ... content ...
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FocusableWidget(autofocus: true, /* Batal */, ...),
              FocusableWidget(/* Konfirmasi */, ...),
            ],
          ),
        ],
      ),
    ),
  ),
)
```

### PATTERN-005 — Multiline TextField: Tombol Done bukan Enter

```dart
TextField(
  maxLines: 2,
  textInputAction: TextInputAction.done,  // override default newline
  onSubmitted: (_) => focusNode.unfocus(),
)
```

## 4. Dependencies

- **DEP-001**: `marquee` (^2.3.0) — Horizontal auto-scrolling text widget
- **DEP-002**: Plan 03 Theme System — `IslamicColors`, `IslamicTypography`, ScreenUtil initialization
- **DEP-003**: Flutter SDK `dart:ui` — `BackdropFilter`, `ImageFilter.blur()` untuk glassmorphism

## 5. Files

- **FILE-001**: `lib/presentation/widgets/glassmorphism_card.dart` — [NEW] Glassmorphism container widget
- **FILE-002**: `lib/presentation/widgets/focusable_widget.dart` — [NEW] D-Pad focus wrapper widget
- **FILE-003**: `lib/presentation/widgets/islamic_background.dart` — [NEW] Animated background widget
- **FILE-004**: `lib/presentation/widgets/running_text_widget.dart` — [NEW] Marquee text widget
- **FILE-005**: `pubspec.yaml` — [MODIFY] Add marquee dependency
- **FILE-006**: `test/presentation/widgets/glassmorphism_card_test.dart` — [NEW] Widget tests
- **FILE-007**: `test/presentation/widgets/focusable_widget_test.dart` — [NEW] Focus tests
- **FILE-008**: `test/presentation/widgets/running_text_widget_test.dart` — [NEW] Running text tests

## 6. Testing

- **TEST-001**: `GlassmorphismCard` renders child widget
- **TEST-002**: `GlassmorphismCard` shows golden glow when focused
- **TEST-003**: `GlassmorphismCard` uses default blur/border values
- **TEST-004**: `FocusableWidget` toggles focus state correctly
- **TEST-005**: `FocusableWidget` handles D-Pad select key
- **TEST-006**: `FocusableWidget` disposes FocusNode
- **TEST-007**: `RunningTextWidget` renders/hides based on text content

**Test Command**: `flutter test test/presentation/widgets/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: `BackdropFilter` bisa expensive pada low-end Android TV — Mitigasi: provide parameter untuk disable blur jika performa rendah
- **RISK-002**: D-Pad focus navigation mungkin tidak smooth di complex widget trees — Mitigasi: test extensif dengan Android TV emulator, setup `FocusTraversalGroup`
- **RISK-003**: `marquee` package mungkin tidak kompatibel dengan Flutter versi terbaru — Mitigasi: check pub.dev compatibility, siapkan custom implementation sebagai fallback
- **ASSUMPTION-001**: Plan 03 (Theme System) sudah selesai — `IslamicColors`, `IslamicTypography` tersedia
- **ASSUMPTION-002**: Android TV remote mengirimkan standard keyboard events yang bisa di-handle oleh Flutter `Focus` widget
- **ASSUMPTION-003**: `BackdropFilter` bekerja pada Android TV platform

## 8. Related Specifications / Further Reading

- [SPEC-02: UI Foundation](../spec/spec-design-ui-foundation.md) — Source specification §6-7
- [UI/UX Guide](../docs/UI_UX_GUIDE.md) — 10-foot UI principles, D-Pad design
- Plan 03: `design-theme-system-1.md` — Prerequisite (colors, typography, theme)
- Plan 10, 12: Setup Wizard UI & Settings UI — Consumer utama widgets ini
