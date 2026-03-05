---
goal: Implement Main Display UI and State Layouts
version: 1.0
date_created: 2026-02-24
last_updated: 2026-02-24
status: 'Completed'
tags: [feature, ui, display, state-machine]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Implementation plan ini bertujuan untuk membangun antarmuka pengguna (UI) dari **Main Display**, yang merupakan tampilan utama digital signage masjid. Tampilan ini beroperasi secara dinamis merespons 5 state dari `DisplayStateCubit` sesuai dengan spesifikasi State Machine (SPEC-04) dan UI Foundation (SPEC-02).

## 1. Requirements & Constraints

- **REQ-001**: Main Display harus memiliki layout utama (`MainDisplayPage`) yang menjadi container untuk 5 state berbeda.
- **REQ-002**: Komponen Header (Logo, Nama Masjid, Tanggal Hijriah/Masehi) dan Footer (Running Text, Marquee) selalu tampil pada state `STANDBY`, `PRE_ADZAN`, dan `IQOMAH`.
- **REQ-003**: Harus ada 5 Layout terpisah: `StandbyLayout`, `PreAdzanLayout`, `AdzanLayout`, `IqomahLayout`, dan `SholatLayout`.
- **REQ-004**: Transisi antar state harus halus menggunakan `AnimatedSwitcher` dengan fade transition (durasi 300-500ms).
- **REQ-005**: `SholatLayout` harus menggelapkan layar (dimmed/blank) untuk *burn-in prevention*, namun tetap menampilkan **sekilas jam kecil** redup di tengah layar.
- **REQ-006**: Widget Jam Digital harus berjalan real-time dan berukuran besar (`clockLarge` / 180.sp).
- **REQ-007**: Widget 7 Prayer Cards (Subuh hingga Isya) responsif dengan indikator "waktu sholat berikutnya".
- **REQ-008**: Terdapat mekanisme untuk menekan tombol "Menu/Settings" di remote D-Pad, yang akan membuka `SettingsPage` (dibangun pada Plan 12).
- **CON-001**: Seluruh padding dan layout harus membungkus di dalam `TVSafeArea`.
- **CON-002**: Ukuran UI merujuk eksklusif pada konfigurasi `flutter_screenutil` (ekstensi `.sp`, `.w`, `.h`, `.r`).

## 2. Implementation Steps

### Implementation Phase 1: Main Display Container & Basis UI

- GOAL-001: Membangun struktur kerangka utama halaman Main Display yang terintegrasi dengan `DisplayStateCubit`.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat `lib/presentation/pages/main_display_page.dart` yang me-listen `DisplayStateCubit` dan menggunakan `AnimatedSwitcher`. | ✅ | 2026-02-24 |
| TASK-002 | Buat `lib/presentation/widgets/header_widget.dart` dengan UI Logo, Nama Masjid, dan Tanggal. | ✅ | 2026-02-24 |
| TASK-003 | Buat `lib/presentation/widgets/digital_clock_widget.dart` untuk menampilkan jam dan detik real-time. | ✅ | 2026-02-24 |
| TASK-004 | Buat `lib/presentation/widgets/prayer_cards_row.dart` untuk menampilkan 7 waktu sholat secara horizontal. | ✅ | 2026-02-24 |
| TASK-005 | Integrasi `IslamicBackground` dan pembungkus `TVSafeArea` di `MainDisplayPage`. | ✅ | 2026-02-24 |
| TASK-006 | Update `SplashPage` untuk melakukan navigasi ke `MainDisplayPage` jika setup wizard selesai. | ✅ | 2026-02-24 |

### Implementation Phase 2: Standby & Pre-Adzan Layouts

- GOAL-002: Mengimplementasikan tampilan saat mode Standby normal dan mode penghitung mundur Pre-Adzan.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | Buat `lib/presentation/pages/main_display/layouts/standby_layout.dart` menyusun Header, Body (Jam Besar di kiri, Info di kanan), Prayer Cards, dan Running Text di Footer. | ✅ | 2026-02-24 |
| TASK-008 | Buat komponen `lib/presentation/widgets/countdown_timer_widget.dart` untuk penghitung mundur waktu. | ✅ | 2026-02-24 |
| TASK-009 | Buat `lib/presentation/pages/main_display/layouts/pre_adzan_layout.dart` yang memberikan penekanan UI lebih pada The Next Prayer dan *Countdown*. | ✅ | 2026-02-24 |

### Implementation Phase 3: Adzan, Iqomah, & Sholat Layouts

- GOAL-003: Mengimplementasikan tampilan mode Adzan, penghitung mundur Iqomah, dan layar gelap untuk mode Sholat.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-010 | Buat `lib/presentation/pages/main_display/layouts/adzan_layout.dart` untuk tampilan visual Adzan Full Screen. | ✅ | 2026-02-24 |
| TASK-011 | Buat `lib/presentation/pages/main_display/layouts/iqomah_layout.dart` menampilkan timer Iqomah yang besar ("Menuju Sholat Berjamaah"). | ✅ | 2026-02-24 |
| TASK-012 | Buat `lib/presentation/pages/main_display/layouts/sholat_layout.dart` yang sangat gelap/blank screen demi mencegah burn-in OLED, dengan sisipan jam ukuran kecil. | ✅ | 2026-02-24 |

### Implementation Phase 4: Integrasi Settings / D-Pad Remote

- GOAL-004: Memastikan respons dari remote kontrol Android TV (Tombol Menu) dapat mengakses Settings.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-013 | Tambahkan custom listener `FocusableActionDetector` / `KeyboardListener` di `MainDisplayPage` untuk menangkap input D-Pad/tombol Menu. | ✅ | 2026-02-24 |
| TASK-014 | Implementasi rute `Navigator.push` dari `MainDisplayPage` ke `SettingsPage`. | ✅ | 2026-02-24 |

## 3. Alternatives

- **ALT-001**: Menggunakan satu layout statis dan menyembunyikan/menampilkan widget dengan `Visibility`. *Tidak dipilih* karena kode UI akan membengkak, solid principles terlanggar, dan transisi animasi menjadi lebih sulit diatur dibanding membuat class Layout terpisah.

## 4. Dependencies

- **DEP-001**: Membutuhkan `DisplayStateCubit` dari Plan 08 yang sudah selesai.
- **DEP-002**: Membutuhkan `SettingsPage` dari Plan 12 yang sudah selesai.
- **DEP-003**: Desain `IslamicTheme`, `ScreenUtil`, `GlassmorphismCard`, `RunningTextWidget` dari Plan 03 dan Plan 04 yang sudah selesai.

## 5. Files

- **FILE-001**: `lib/presentation/pages/main_display_page.dart` (NEW)
- **FILE-002**: `lib/presentation/pages/splash_page.dart` (MODIFIED)
- **FILE-003**: `lib/presentation/widgets/header_widget.dart` (NEW)
- **FILE-004**: `lib/presentation/widgets/digital_clock_widget.dart` (NEW)
- **FILE-005**: `lib/presentation/widgets/prayer_cards_row.dart` (NEW)
- **FILE-006**: `lib/presentation/widgets/countdown_timer_widget.dart` (NEW)
- **FILE-007**: `lib/presentation/pages/main_display/layouts/standby_layout.dart` (NEW)
- **FILE-008**: `lib/presentation/pages/main_display/layouts/pre_adzan_layout.dart` (NEW)
- **FILE-009**: `lib/presentation/pages/main_display/layouts/adzan_layout.dart` (NEW)
- **FILE-010**: `lib/presentation/pages/main_display/layouts/iqomah_layout.dart` (NEW)
- **FILE-011**: `lib/presentation/pages/main_display/layouts/sholat_layout.dart` (NEW)

## 6. Testing

- **TEST-001**: Widget Test untuk `MainDisplayPage` memastikan integrasi `AnimatedSwitcher` dengan state cubit sukses berjalan.
- **TEST-002**: Widget Test untuk memastikan rendering 5 Layouts secara bergantian bebas dari exception overflow.
- **TEST-003**: Widget Test memastikan penekanan tombol remote (misalnya `LogicalKeyboardKey.select` atau `escape` / setting) dapat mentrigger rute navigasi.
- **TEST-004**: Menulis test terpisah untuk komponen re-usable `PrayerCardsRow` dan `CountdownTimerWidget` memastikan formatter string waktu berjalan dengan benar.

## 7. Risks & Assumptions

- **RISK-001**: Penambahan *AnimatedSwitcher* untuk state layout yang kompleks dapat menyebabkan *jank* (penurunan framerate) di perangkat Android TV *low-end*. Pemecahan layar dalam widget statis (`const`) sebisa mungkin dilakukan.
- **ASSUMPTION-001**: Seluruh package timing dan core cubit sudah matang dan teruji, sehingga tidak ada *flaky bugs* waktu pergantian state.

## 8. Related Specifications / Further Reading

- [SPEC-02: UI Foundation Specification](../spec/spec-design-ui-foundation.md)
- [SPEC-04: Display State Machine Specification](../spec/spec-process-state-machine.md)
