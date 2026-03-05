---
goal: "Implementasi Settings UI — Menu Pages, DPadStepper, PinInput, Ihtiyat/Iqomah/Display Controls"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-21
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, settings, ui, menu, stepper, pin-input, dpad, presentation]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Plan ini mencakup implementasi seluruh **UI layer** untuk settings dan content management: PIN gate screen, settings menu utama, sub-pages untuk setiap category (Ihtiyat, Iqomah, Dhuha, Display Timing, Running Text, Security), serta custom widgets `DPadStepper` (increment/decrement control) dan `PinInputWidget`. Semua UI menggunakan design system dari Plan 03-04 dan memanggil `SettingsCubit` (Plan 11).

**Source Specification**: [spec-process-settings.md](../spec/spec-process-settings.md) (SPEC-06 Part B)

## 1. Requirements & Constraints

- **REQ-001**: Settings menu hanya bisa diakses setelah melewati PIN gate (jika PIN enabled)
- **REQ-002**: Setiap setting value diubah menggunakan `DPadStepper` (up/down arrow) — bukan text input
- **REQ-003**: PIN input menggunakan 6 digit numeric input via D-Pad
- **REQ-004**: Settings menu terorganisir dalam categories: Ihtiyat, Iqomah, Dhuha, Display Timing, Running Text, Security (PIN)
- **REQ-005**: Setiap perubahan auto-save (visual feedback: brief checkmark/green flash)
- **REQ-006**: Semua interactions harus D-Pad navigable
- **CON-001**: Semua dimensi menggunakan ScreenUtil
- **CON-002**: D-Pad sebagai primary interaction
- **GUD-001**: DPadStepper: up/right = increment, down/left = decrement, long-press = fast repeat
- **GUD-002**: Settings menu scroll via D-Pad focus navigation
- **GUD-003**: PIN input digits shown as dots (masked) kecuali digit terakhir yang sedang diketik
- **PAT-001**: `BlocBuilder` pattern untuk reactive UI
- **PAT-002**: Category-based navigation (list → detail)

## 2. Implementation Steps

### Phase 1: DPadStepper Custom Widget

- GOAL-001: Membuat widget numeric stepper yang di-navigate via D-Pad

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat file `lib/presentation/widgets/dpad_stepper.dart` | ✅ | 2026-02-21 |
| TASK-002 | Implementasi `DPadStepper` sebagai `StatefulWidget`. Parameters: `int value` (required), `int minValue`, `int maxValue`, `int step` (default: 1), `ValueChanged<int> onChanged` (required), `String? label`, `String? suffix` (e.g., "menit", "detik"), `bool autofocus` | ✅ | 2026-02-21 |
| TASK-003 | Layout: `Row` → minus button (`−`), value display (formatted), plus button (`+`). Wrap seluruh row dalam `FocusableWidget`. D-Pad up/right = increment, D-Pad down/left = decrement | ✅ | 2026-02-21 |
| TASK-004 | Implementasi long-press acceleration: setelah 500ms hold, increment/decrement setiap 100ms. Gunakan `Timer.periodic` — cancel on key up | ✅ | 2026-02-21 |
| TASK-005 | Visual feedback: value flash animation (scale up briefly) saat berubah | ✅ | 2026-02-21 |

### Phase 2: PinInputWidget Custom Widget

- GOAL-002: Membuat PIN input widget dengan 6 digit masked display

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-006 | Buat file `lib/presentation/widgets/pin_input_widget.dart` | ✅ | 2026-02-21 |
| TASK-007 | Implementasi `PinInputWidget` sebagai `StatefulWidget`. Parameters: `int pinLength` (default: 6), `ValueChanged<String> onCompleted`, `bool showError` (flash red on error) | ✅ | 2026-02-21 |
| TASK-008 | Layout: `Row` of digit boxes (GlassmorphismCard per digit). Filled digits shown as `●`, empty shown as `−`. Current digit box has golden border focus indicator | ✅ | 2026-02-21 |
| TASK-009 | D-Pad input: 0-9 digit keys → fill current box and advance. Backspace/left → delete last digit. D-Pad navigation between digits | ✅ | 2026-02-21 |
| TASK-010 | Saat semua 6 digit terisi → panggil `onCompleted(pin)` | ✅ | 2026-02-21 |
| TASK-011 | Error animation: shake + red flash effect saat PIN salah | ✅ | 2026-02-21 |

### Phase 3: PIN Gate Screen

- GOAL-003: Halaman verifikasi PIN sebelum masuk settings

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-012 | Buat file `lib/presentation/pages/settings/pin_gate_page.dart` | ✅ | 2026-02-21 |
| TASK-013 | Implementasi `PinGatePage`. Layout: `IslamicBackground` + `TVSafeArea` → center content: lock icon, title "Masukkan PIN", `PinInputWidget`. Jika PIN disabled → langsung navigate ke settings menu | ✅ | 2026-02-21 |
| TASK-014 | On PIN entered → call `settingsCubit.verifyPin(pin)` → jika true, navigate ke SettingsMenuPage → jika false, show error animation dan reset input | ✅ | 2026-02-21 |
| TASK-015 | Tombol "Kembali" (FocusableWidget) → navigate back ke display | ✅ | 2026-02-21 |

### Phase 4: Settings Menu Page

- GOAL-004: Halaman menu utama yang menampilkan categories

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-016 | Buat file `lib/presentation/pages/settings/settings_menu_page.dart` | ✅ | 2026-02-21 |
| TASK-017 | Implementasi `SettingsMenuPage`. Layout: `IslamicBackground` + `TVSafeArea` → left side: vertical menu list (categories), right side: selected category content. Gunakan `Row` split layout | ✅ | 2026-02-21 |
| TASK-018 | Menu categories (FocusableWidget per item): "Koreksi Waktu (Ihtiyat)", "Durasi Iqomah", "Pengaturan Dhuha", "Durasi Tampilan", "Running Text", "Keamanan (PIN)". Auto-focus pada first item | ✅ | 2026-02-21 |
| TASK-019 | Saat category dipilih via D-Pad → tampilkan sub-page content di right panel. Gunakan `IndexedStack` atau conditional rendering | ✅ | 2026-02-21 |

### Phase 5: Ihtiyat Settings Sub-page

- GOAL-005: Control panel untuk Ihtiyat (koreksi waktu) 7 waktu sholat

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-020 | Buat file `lib/presentation/pages/settings/sections/ihtiyat_section.dart` | ✅ | 2026-02-21 |
| TASK-021 | Implementasi `IhtiyatSection`. Layout: title "Koreksi Waktu (Ihtiyat)", deskripsi singkat, `Column` of 7 `DPadStepper` widgets — satu per waktu sholat (Subuh, Syuruq, Dhuha, Dzuhur, Ashar, Maghrib, Isya). Label: nama sholat, suffix: "menit", range: -30 to +30 | ✅ | 2026-02-21 |
| TASK-022 | Setiap stepper `onChanged` → panggil `settingsCubit.updateIhtiyatOffset(prayerName, value)` | ✅ | 2026-02-21 |

### Phase 6: Iqomah Settings Sub-page

- GOAL-006: Control panel untuk durasi iqomah per sholat wajib

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-023 | Buat file `lib/presentation/pages/settings/sections/iqomah_section.dart` | ✅ | 2026-02-21 |
| TASK-024 | Implementasi `IqomahSection`. Layout: title "Durasi Iqomah", `Column` of 5 `DPadStepper` widgets — Subuh (default 15), Dzuhur (10), Ashar (10), Maghrib (5), Isya (10). Range: 1-30 menit, suffix: "menit" | ✅ | 2026-02-21 |
| TASK-025 | Setiap stepper `onChanged` → panggil `settingsCubit.updateIqomahDuration(prayerName, value)` | ✅ | 2026-02-21 |

### Phase 7: Dhuha & Display Timing Sub-pages

- GOAL-007: Control panels untuk Dhuha offset dan display timing settings

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-026 | Buat file `lib/presentation/pages/settings/sections/dhuha_section.dart` — DPadStepper untuk `dhuhaOffsetMinutes` (range: 10-30, default: 15, suffix: "menit setelah Syuruq") | ✅ | 2026-02-21 |
| TASK-027 | Buat file `lib/presentation/pages/settings/sections/display_timing_section.dart` — Layout: title "Durasi Tampilan", 3 DPadSteppers: `preAdzanMinutes` (5-30 menit), `adzanDurationSeconds` (60-600 detik), `sholatDurationMinutes` (10-45 menit). Plus `hijriAdjustment` (-2 to 2 hari) | ✅ | 2026-02-21 |

### Phase 8: Running Text Sub-page

- GOAL-008: Text input untuk running text (ticker)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-028 | Buat file `lib/presentation/pages/settings/sections/running_text_section.dart` | ✅ | 2026-02-21 |
| TASK-029 | Implementasi `RunningTextSection`. Layout: title "Running Text", `TextField` (multiline, maxLength: 500), preview `RunningTextWidget` yang menampilkan text live saat diketik | ✅ | 2026-02-21 |
| TASK-030 | TextField `onChanged` debounced → panggil `settingsCubit.updateRunningText(text)` | ✅ | 2026-02-21 |

### Phase 9: Security (PIN) Sub-page

- GOAL-009: PIN management UI — enable, change, disable

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-031 | Buat file `lib/presentation/pages/settings/sections/security_section.dart` | ✅ | 2026-02-21 |
| TASK-032 | Implementasi `SecuritySection`. Layout: title "Keamanan", PIN status indicator (enabled/disabled), tombol "Atur PIN Baru" / "Ubah PIN" / "Hapus PIN" | ✅ | 2026-02-21 |
| TASK-033 | "Atur PIN Baru": tampilkan `PinInputWidget` → set PIN via `settingsCubit.setPin()` | ✅ | 2026-02-21 |
| TASK-034 | "Ubah PIN": verify old PIN dulu → tampilkan new PIN input | ✅ | 2026-02-21 |
| TASK-035 | "Hapus PIN": verify current PIN → call `settingsCubit.removePin()` | ✅ | 2026-02-21 |

### Phase 10: Widget Tests

- GOAL-010: Widget tests untuk settings UI components

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-036 | Buat file `test/presentation/widgets/dpad_stepper_test.dart` | ✅ | 2026-02-21 |
| TASK-037 | TEST: DPadStepper renders value, label, and suffix correctly | ✅ | 2026-02-21 |
| TASK-038 | TEST: Increment/decrement changes value within min/max bounds | ✅ | 2026-02-21 |
| TASK-039 | TEST: Value does not exceed max or go below min | ✅ | 2026-02-21 |
| TASK-040 | Buat file `test/presentation/widgets/pin_input_widget_test.dart` | ✅ | 2026-02-21 |
| TASK-041 | TEST: PinInputWidget renders correct number of digit boxes | ✅ | 2026-02-21 |
| TASK-042 | TEST: Digit input fills boxes and calls `onCompleted` when full | ✅ | 2026-02-21 |
| TASK-043 | Buat file `test/presentation/pages/settings/settings_menu_page_test.dart` | ✅ | 2026-02-21 |
| TASK-044 | TEST: Settings menu renders all 6 categories | ✅ | 2026-02-21 |
| TASK-045 | TEST: Ihtiyat section shows 7 DPadSteppers | ✅ | 2026-02-21 |
| TASK-046 | TEST: Iqomah section shows 5 DPadSteppers | ✅ | 2026-02-21 |
| TASK-047 | TEST: PIN gate verifies PIN before showing settings | ✅ | 2026-02-21 |
| TASK-048 | Jalankan `flutter test test/presentation/ --reporter=expanded` | ✅ | 2026-02-21 |

## 3. Alternatives

- **ALT-001**: Menggunakan Flutter built-in `Slider` untuk value adjustment — Ditolak karena slider sulit dioperasikan via D-Pad remote control
- **ALT-002**: Dedicated settings page per category (full page navigation) — Ditolak karena split-panel (menu left + content right) lebih efisien untuk TV landscape layout
- **ALT-003**: Number pad overlay untuk PIN input — Ditolak karena custom digit boxes lebih visual dan familiar untuk TV interface

## 4. Dependencies

- **DEP-001**: Plan 11 `SettingsCubit` — Business logic
- **DEP-002**: Plan 03-04 Theme + UI Components — Design system
- **DEP-003**: Plan 04 `RunningTextWidget` — Preview running text
- **DEP-004**: Plan 04 `FocusableWidget` — D-Pad focus handling
- **DEP-005**: Plan 04 `GlassmorphismCard` — Card containers

## 5. Files

- **FILE-001**: `lib/presentation/widgets/dpad_stepper.dart` — [NEW] DPad stepper widget
- **FILE-002**: `lib/presentation/widgets/pin_input_widget.dart` — [NEW] PIN input widget
- **FILE-003**: `lib/presentation/pages/settings/pin_gate_page.dart` — [NEW] PIN gate screen
- **FILE-004**: `lib/presentation/pages/settings/settings_menu_page.dart` — [NEW] Main settings menu
- **FILE-005**: `lib/presentation/pages/settings/sections/ihtiyat_section.dart` — [NEW] Ihtiyat controls
- **FILE-006**: `lib/presentation/pages/settings/sections/iqomah_section.dart` — [NEW] Iqomah controls
- **FILE-007**: `lib/presentation/pages/settings/sections/dhuha_section.dart` — [NEW] Dhuha controls
- **FILE-008**: `lib/presentation/pages/settings/sections/display_timing_section.dart` — [NEW] Display timing
- **FILE-009**: `lib/presentation/pages/settings/sections/running_text_section.dart` — [NEW] Running text
- **FILE-010**: `lib/presentation/pages/settings/sections/security_section.dart` — [NEW] PIN management
- **FILE-011**: `test/presentation/widgets/dpad_stepper_test.dart` — [NEW] Tests
- **FILE-012**: `test/presentation/widgets/pin_input_widget_test.dart` — [NEW] Tests
- **FILE-013**: `test/presentation/pages/settings/settings_menu_page_test.dart` — [NEW] Tests

## 6. Testing

- **TEST-001**: DPadStepper renders and increments/decrements within bounds
- **TEST-002**: PinInputWidget captures 6 digits and calls onCompleted
- **TEST-003**: PIN gate screen blocks access and verifies PIN
- **TEST-004**: All 6 menu categories render in settings menu
- **TEST-005**: Ihtiyat section has 7 stepper controls
- **TEST-006**: Iqomah section has 5 stepper controls
- **TEST-007**: Settings changes trigger auto-save visual feedback

**Test Command**: `flutter test test/presentation/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: DPadStepper long-press detection mungkin berbeda di setiap Android TV remote — Mitigasi: test dengan multiple remotes, fallback ke single press
- **RISK-002**: PIN input via D-Pad number keys mungkin tidak universal di semua remotes — Mitigasi: provide fallback numeric selector (on-screen number pad)
- **RISK-003**: Split-panel layout mungkin tidak ideal di resolusi 720p — Mitigasi: responsive breakpoint, full-page fallback di resolusi rendah
- **ASSUMPTION-001**: Plan 03-04, 11 sudah selesai
- **ASSUMPTION-002**: Android TV remotes mengirimkan standard key events yang detectable oleh Flutter
- **ASSUMPTION-003**: On-screen keyboard tersedia di Android TV untuk running text input

## 8. Related Specifications / Further Reading

- [SPEC-06: Settings & Content Management](../spec/spec-process-settings.md) — Source specification §5-6
- [UI/UX Guide](../docs/UI_UX_GUIDE.md) — D-Pad design patterns, TV layout
- Plan 11: `feature-settings-logic-1.md` — Prerequisite (SettingsCubit)
- Plan 03-04: Theme + UI Components — Prerequisite (design system)
