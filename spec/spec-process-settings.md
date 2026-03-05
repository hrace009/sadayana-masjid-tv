---
title: "Settings & Content Management Specification"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
tags: [process, settings, content, running-text, pin, configuration]
---

# Introduction

Spesifikasi ini mendefinisikan Settings Menu dan Content Management untuk aplikasi Miqotul Khoir TV. Modul ini memungkinkan admin DKM mengkonfigurasi ulang aplikasi setelah Setup Wizard selesai — termasuk koreksi waktu sholat (Ihtiyat), tampilan, running text, timing, dan proteksi PIN.

Settings menu diakses dari Main Display melalui tombol "Menu/Settings" pada remote control.

## 1. Purpose & Scope

### Purpose

Menyediakan antarmuka admin untuk mengelola seluruh konfigurasi aplikasi MKT setelah setup awal.

### Scope

- Settings menu structure dan navigation tree
- PIN protection (opsional) — input via D-Pad
- Location settings (edit lokasi, ganti kota)
- Time corrections (Ihtiyat) — per waktu sholat
- Iqomah timing config per waktu sholat
- Display settings (nama masjid, alamat, running text)
- Timing config (pre-adzan, adzan duration, sholat duration)
- Cubit state management (`SettingsCubit`)

### Out of Scope

- First-run wizard (ditangani oleh SPEC-05)
- Prayer time calculation logic (ditangani oleh SPEC-03)
- State machine logic (ditangani oleh SPEC-04)

## 2. Definitions

| Term | Definition |
|------|-----------|
| **Ihtiyat** | Koreksi waktu sholat (±menit) untuk menyesuaikan dengan kebiasaan lokal |
| **PIN** | Personal Identification Number untuk proteksi akses settings |
| **Running Text** | Teks berjalan (marquee) yang ditampilkan di footer main display |
| **D-Pad Entry** | Input PIN menggunakan D-Pad remote (Up/Down mengganti digit) |

## 3. Requirements, Constraints & Guidelines

### Requirements

- **REQ-001**: Settings menu diakses via tombol "Menu" atau "Settings" pada remote control
- **REQ-002**: PIN protection opsional — jika diaktifkan, admin harus memasukkan PIN sebelum masuk settings
- **REQ-003**: PIN input menggunakan D-Pad (Up/Down untuk digit, Left/Right untuk posisi)
- **REQ-004**: PIN disimpan sebagai hash (SHA-256), bukan plaintext
- **REQ-005**: Settings menu memiliki navigasi hierarchical (menu utama → submenu)
- **REQ-006**: Setiap perubahan setting langsung di-save ke database (auto-save)
- **REQ-007**: Setelah location, ihtiyat, atau iqomah berubah, prayer times harus di-recalculate
- **REQ-008**: Time corrections (Ihtiyat) menggunakan slider atau stepper dengan range -10 s/d +10 menit
- **REQ-009**: Iqomah duration per waktu sholat, range 1 s/d 30 menit
- **REQ-010**: Running text mendukung teks hingga 500 karakter
- **REQ-011**: Saat membuka settings dari Main Display, state machine harus di-pause

### Constraints

- **CON-001**: Seluruh navigasi settings via D-Pad (no touch)
- **CON-002**: PIN maksimal 6 digit (0-9)
- **CON-003**: Auto-save — tidak ada tombol "Save" eksplisit
- **CON-004**: Settings page harus bisa kembali ke Main Display via tombol "Back" di remote

## 4. Interfaces & Data Contracts

### 4.1. Menu Structure

```
Settings Menu (Root)
├── 🕌 Identitas Masjid
│   ├── Nama Masjid [TextField]
│   └── Alamat Masjid [TextField]
├── 📍 Lokasi
│   ├── Kota Saat Ini [Display only]
│   ├── Latitude / Longitude [Display only]
│   ├── Ganti Kota [CityPicker] → reuse SPEC-05 Step 3
│   └── Timezone [Dropdown: WIB/WITA/WIT]
├── ⏰ Koreksi Waktu (Ihtiyat)
│   ├── Subuh    [Stepper: -10 to +10 menit]
│   ├── Syuruq   [Stepper: -10 to +10 menit]
│   ├── Dhuha    [Stepper: -10 to +10 menit]
│   ├── Dzuhur   [Stepper: -10 to +10 menit]
│   ├── Ashar    [Stepper: -10 to +10 menit]
│   ├── Maghrib  [Stepper: -10 to +10 menit]
│   └── Isya     [Stepper: -10 to +10 menit]
├── 🕐 Durasi Iqomah
│   ├── Subuh    [Stepper: 1-30 menit]
│   ├── Dzuhur   [Stepper: 1-30 menit]
│   ├── Ashar    [Stepper: 1-30 menit]
│   ├── Maghrib  [Stepper: 1-30 menit]
│   └── Isya     [Stepper: 1-30 menit]
├── 🕌 Dhuha
│   └── Offset dari Syuruq [Stepper: 10-45 menit]
├── 📺 Tampilan
│   ├── Running Text [TextField]
│   ├── Hijri Adjustment [Stepper: -2 to +2 hari]
│   ├── Pre-Adzan [Stepper: 5-30 menit]
│   ├── Durasi Adzan [Stepper: 60-600 detik]
│   └── Durasi Sholat [Stepper: 5-60 menit]
├── 🔒 Keamanan
│   ├── Status PIN [Toggle: Aktif/Nonaktif]
│   ├── Ubah PIN [PIN input dialog]
│   └── Hapus PIN [Confirmation dialog]
└── ℹ️ Tentang Aplikasi
    ├── Versi Aplikasi
    └── Developer Info
```

### 4.2. Settings Menu Item Widget

```dart
/// presentation/widgets/settings_menu_item.dart
class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;      // Current value preview
  final VoidCallback onSelect;
  final bool showArrow;        // true → has submenu
}
```

### 4.3. Stepper Widget (D-Pad Compatible)

```dart
/// presentation/widgets/dpad_stepper.dart
class DPadStepper extends StatelessWidget {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final int step;              // default: 1
  final String suffix;         // "menit", "detik", "hari"
  final ValueChanged<int> onChanged;

  // D-Pad: Left = decrement, Right = increment
  // D-Pad: Up/Down = navigate to other steppers
}
```

### 4.4. PIN Input Widget

```dart
/// presentation/widgets/pin_input.dart
class PinInput extends StatelessWidget {
  final int maxLength;         // default: 6
  final ValueChanged<String> onCompleted;
  final VoidCallback onCancel;

  // D-Pad: Up = digit +1, Down = digit -1
  // D-Pad: Right = next digit, Left = previous digit
  // D-Pad: Select/Enter = confirm current digit, Center = submit
}
```

### 4.5. Cubit States

```dart
/// presentation/cubits/settings/settings_state.dart
abstract class SettingsState extends Equatable {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final Settings settings;
  final SettingsPage currentPage; // Which page/section is active
}

class SettingsPinRequired extends SettingsState {}

class SettingsPinVerified extends SettingsState {}

class SettingsPinFailed extends SettingsState {
  final int attemptsRemaining; // Optional: limit attempts
}

class SettingsError extends SettingsState {
  final String message;
}
```

### 4.6. Cubit

```dart
/// presentation/cubits/settings/settings_cubit.dart
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _settingsRepository;
  final PrayerTimeCubit _prayerTimeCubit;

  SettingsCubit({
    required SettingsRepository settingsRepository,
    required PrayerTimeCubit prayerTimeCubit,
  });

  /// Load current settings dari database
  Future<void> loadSettings();

  /// Check apakah PIN required
  Future<void> checkPinRequired();

  /// Verify PIN input
  Future<void> verifyPin(String inputPin);

  /// Update single field
  Future<void> updateField(String fieldName, dynamic value);

  /// Update multiple fields atomically
  Future<void> updateFields(Map<String, dynamic> updates);

  /// Trigger prayer time recalculation (after location/ihtiyat changes)
  void _notifyPrayerTimeRecalculation();

  /// Set new PIN
  Future<void> setPin(String newPin);

  /// Remove PIN (disable protection)
  Future<void> removePin();

  /// Navigate to submenu
  void navigateTo(SettingsPage page);

  /// Go back to parent menu
  void goBack();
}
```

### 4.7. Settings Page Enum

```dart
enum SettingsPage {
  root,           // Main settings menu
  identity,       // Nama & alamat masjid
  location,       // Lokasi & timezone
  timeCorrection, // Ihtiyat per waktu sholat
  iqomahDuration, // Iqomah per waktu sholat
  dhuhaOffset,    // Dhuha offset dari Syuruq
  display,        // Running text, hijri, timing
  security,       // PIN management
  about,          // App info
}
```

### 4.8. File Structure

```
lib/
├── presentation/
│   ├── cubits/
│   │   └── settings/
│   │       ├── settings_cubit.dart
│   │       └── settings_state.dart
│   ├── pages/
│   │   └── settings/
│   │       ├── settings_page.dart          # Root menu
│   │       ├── identity_settings_page.dart
│   │       ├── location_settings_page.dart
│   │       ├── time_correction_page.dart
│   │       ├── iqomah_duration_page.dart
│   │       ├── dhuha_settings_page.dart
│   │       ├── display_settings_page.dart
│   │       ├── security_settings_page.dart
│   │       └── about_page.dart
│   └── widgets/
│       ├── settings_menu_item.dart
│       ├── dpad_stepper.dart
│       └── pin_input.dart
```

## 5. Acceptance Criteria

- **AC-001**: Given PIN is disabled, When "Menu" is pressed on remote, Then settings menu opens directly
- **AC-002**: Given PIN is enabled, When "Menu" is pressed, Then PIN input is shown
- **AC-003**: Given correct PIN entered, When submitted, Then settings menu opens
- **AC-004**: Given wrong PIN entered, When submitted, Then error message is shown
- **AC-005**: Given Ihtiyat Subuh changed from 0 to +2, When change is applied, Then prayer times are recalculated with new offset
- **AC-006**: Given Iqomah Maghrib changed from 7 to 10 minutes, When next Maghrib occurs, Then Iqomah countdown is 10 minutes
- **AC-007**: Given Running Text changed to "Selamat Hari Raya", When returning to Main Display, Then marquee shows new text
- **AC-008**: Given any setting is changed, When change is applied, Then it is immediately saved to database (auto-save)
- **AC-009**: Given settings menu is open, When "Back" button is pressed at root, Then return to Main Display
- **AC-010**: Given D-Pad stepper for Ihtiyat, When Left is pressed at -10, Then value stays at -10 (min bound)
- **AC-011**: Given D-Pad stepper for Iqomah, When Right is pressed at 30, Then value stays at 30 (max bound)
- **AC-012**: Given D-Pad PIN input with 6 digits entered, When Enter is pressed, Then PIN is hashed and verified

## 6. Test Automation Strategy

### Required Tests

- **TEST-001**: `SettingsCubit.loadSettings()` emits `SettingsLoaded` with current data
- **TEST-002**: `SettingsCubit.updateField()` updates single field in database
- **TEST-003**: `SettingsCubit.updateField()` triggers prayer time recalculation for relevant fields
- **TEST-004**: `SettingsCubit.verifyPin()` returns success for correct PIN
- **TEST-005**: `SettingsCubit.verifyPin()` returns failure for wrong PIN
- **TEST-006**: `SettingsCubit.setPin()` hashes and saves PIN
- **TEST-007**: `SettingsCubit.removePin()` clears PIN hash
- **TEST-008**: `DPadStepper` respects min/max bounds
- **TEST-009**: `PinInput` accepts exactly 6 digits
- **TEST-010**: `SettingsCubit.navigateTo()` changes current page

## 7. Rationale & Context

### Mengapa Auto-Save?

- Digital signage → admin jarang berinteraksi → kemungkinan lupa "Save" tinggi
- Auto-save mengurangi risiko konfigurasi hilang karena power loss saat di settings
- Setiap field di-save individual → transaction scope kecil = aman

### Mengapa PIN via D-Pad?

- Android TV tidak selalu memiliki keyboard
- Remote control D-Pad tersedia secara universal
- Up/Down untuk ganti digit → intuitif untuk input numerik

### Mengapa Stepper, Bukan Slider?

- D-Pad kurang cocok untuk slider (perlu drag gesture)
- Stepper dengan Left/Right increment → natural untuk remote control
- Value range kecil (-10 to +10) → stepper lebih presisi

## 8. Dependencies & External Integrations

### Internal Dependencies

- **INT-001**: SPEC-01 `SettingsRepository` — CRUD operations
- **INT-002**: SPEC-03 `PrayerTimeCubit` — Trigger recalculation
- **INT-003**: SPEC-05 Setup Wizard — Reuse city picker component di location settings
- **INT-004**: SPEC-02 UI Foundation — FocusableWidget, GlassmorphismCard, D-Pad nav

### Third-Party Packages

- **DEP-001**: `crypto` — SHA-256 hashing untuk PIN

## 9. Examples & Edge Cases

### Edge Case: Admin Lupa PIN

```dart
// Saat ini tidak ada recovery mechanism
// Opsi untuk future: factory reset via adb command
// Untuk MVP: informasikan admin bahwa app data bisa di-clear dari Android Settings
```

### Edge Case: Timezone Berubah

```dart
// Saat timezone berubah (WIB → WITA):
// 1. Update settings.timezone
// 2. Trigger prayer time recalculation
// 3. State machine akan re-evaluate berdasarkan waktu baru
```

### Edge Case: Settings Dibuka Saat State PRE_ADZAN

```dart
// State machine harus di-pause saat settings dibuka
// Setelah settings ditutup, state machine re-evaluate dari waktu saat ini
// Jika waktu adzan sudah lewat saat kembali → state machine langsung ke state yang sesuai
```

## 10. Validation Criteria

- [ ] Settings menu dapat diakses dari Main Display
- [ ] PIN protection berfungsi (enable, verify, disable)
- [ ] Ihtiyat changes trigger prayer time recalculation
- [ ] Iqomah duration changes persisted dan digunakan oleh state machine
- [ ] Running text berubah setelah update
- [ ] All stepper bounds respected (min/max)
- [ ] D-Pad navigation berfungsi di semua settings pages
- [ ] Auto-save bekerja — perubahan langsung tersimpan
- [ ] Back navigation kembali ke parent menu / main display

## 11. Related Specifications / Further Reading

- [PRD §3.4 — Settings Menu](file:///d:/AndroidProject/LatihanFlutter/sadayana_masjid_tv/Product_Requirement_Document.md)
- [PRD §3.3 — Running Text](file:///d:/AndroidProject/LatihanFlutter/sadayana_masjid_tv/Product_Requirement_Document.md)
- SPEC-01: Database Schema — `settings` table structure
- SPEC-02: UI Foundation — D-Pad components, Glassmorphism theme
- SPEC-03: Prayer Time — Recalculation after setting changes
- SPEC-04: State Machine — Pause/resume saat settings dibuka
- SPEC-05: Setup Wizard — Reusable city picker component
