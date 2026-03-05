---
goal: "Implementasi Setup Wizard UI — 4 Step Pages, City Picker, Prayer Preview, Step Indicator"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-20
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, setup-wizard, ui, pages, city-picker, dpad, presentation]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Plan ini mencakup implementasi seluruh **UI layer** untuk setup wizard: 4 halaman step (Welcome, Identity, Location/City Picker, Preview), step indicator widget, integrasi dengan `SetupWizardCubit` (Plan 09), dan D-Pad navigation di setiap halaman. Semua widget menggunakan design system dari Plan 03-04.

**Source Specification**: [spec-process-setup-wizard.md](../spec/spec-process-setup-wizard.md) (SPEC-05 Part B)

## 1. Requirements & Constraints

- **REQ-001**: Wizard page harus full-screen dengan `IslamicBackground` dan `TVSafeArea`
- **REQ-002**: Step indicator menampilkan progress visual (step 1/4, 2/4, dst)
- **REQ-003**: Semua interactive elements harus focusable via D-Pad
- **REQ-004**: Welcome page menampilkan logo, nama app, dan tombol "Mulai" (auto-focused)
- **REQ-005**: Identity page memiliki text field untuk nama masjid dan alamat
- **REQ-006**: Location page memiliki province picker → city picker (cascading dropdown)
- **REQ-007**: Preview page menampilkan ringkasan data dan contoh waktu sholat hari ini
- **REQ-008**: Navigasi: tombol "Selanjutnya" dan "Kembali" di setiap page (kecuali Welcome hanya "Mulai")
- **CON-001**: Semua dimensi menggunakan ScreenUtil extensions
- **CON-002**: D-Pad remote control sebagai primary interaction
- **CON-003**: Warna dan typography dari `IslamicColors` dan `IslamicTypography`
- **GUD-001**: Text fields harus accessible via D-Pad dan menampilkan on-screen keyboard saat selected
- **GUD-002**: City picker harus searchable dan support scrolling via D-Pad
- **GUD-003**: Preview page harus menampilkan prayer times preview menggunakan `CalculatePrayerTimesUseCase` (Placeholder in this plan)
- **PAT-001**: `BlocBuilder` untuk reactive UI updates dari `SetupWizardCubit`
- **PAT-002**: `BlocProvider` untuk provide Cubit ke widget tree

## 2. Implementation Steps

### Phase 1: Setup Wizard Page (Root)

- GOAL-001: Membuat container page yang orchestrates step navigation dan provides Cubit

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat file `lib/presentation/pages/setup_wizard/setup_wizard_page.dart` | ✅ | 2026-02-20 |
| TASK-002 | Implementasi `SetupWizardPage` sebagai `StatelessWidget`. Provides `BlocProvider<SetupWizardCubit>`. Body: `BlocConsumer` yang listen ke state changes: jika `SetupWizardCompleted` → navigate ke home page | ✅ | 2026-02-20 |
| TASK-003 | Build body berdasarkan `state.currentStep`: `IndexedStack` atau `switch` yang menampilkan step page yang sesuai. Wrap dengan `IslamicBackground` dan `TVSafeArea` | ✅ | 2026-02-20 |
| TASK-004 | Tampilkan `StepIndicatorWidget` di top area yang menunjukkan current step dan total steps | ✅ | 2026-02-20 |

### Phase 2: Step Indicator Widget

- GOAL-002: Membuat visual step indicator

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-005 | Buat file `lib/presentation/widgets/step_indicator_widget.dart` | ✅ | 2026-02-20 |
| TASK-006 | Implementasi `StepIndicatorWidget` sebagai `StatelessWidget`. Parameters: `int currentStep`, `int totalSteps`, `List<String> stepLabels`. Tampilkan horizontal row of circles/dots yang menunjukkan: completed (filled gold), current (outlined gold with glow), upcoming (dim outline). Connected by lines between dots | ✅ | 2026-02-20 |

### Phase 3: Welcome Step Page

- GOAL-003: Halaman selamat datang dengan branding dan tombol mulai

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | Buat file `lib/presentation/pages/setup_wizard/steps/welcome_step.dart` | ✅ | 2026-02-20 |
| TASK-008 | Implementasi `WelcomeStep`. Layout: `Column` centered — App icon/logo (placeholder atau generated), title "Miqotul Khoir TV" (`IslamicTypography.heading()`), subtitle "Sistem Digital Signage Masjid" (`IslamicTypography.subtitle()`), deskripsi singkat (`IslamicTypography.body()`), tombol "Mulai Setup" (FocusableWidget + GlassmorphismCard) | ✅ | 2026-02-20 |
| TASK-009 | Tombol "Mulai Setup" harus `autofocus: true` dan memanggil `context.read<SetupWizardCubit>().goToNextStep()` saat pressed | ✅ | 2026-02-20 |

### Phase 4: Identity Step Page

- GOAL-004: Halaman input nama dan alamat masjid

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-010 | Buat file `lib/presentation/pages/setup_wizard/steps/identity_step.dart` | ✅ | 2026-02-20 |
| TASK-011 | Implementasi `IdentityStep`. Layout: `Column` centered — Title "Identitas Masjid", Description text. Form fields: `TextFormField` untuk Nama Masjid (validation: required, min length 3) dan Alamat Masjid (validation: required). Connect to `SetupWizardCubit` via `onChanged`. Tombol Back & Next | ✅ | 2026-02-20 |
| TASK-012 | TextField `onChanged` → memanggil `cubit.updateMosqueName()` / `cubit.updateMosqueAddress()` | ✅ | 2026-02-20 |
| TASK-013 | Tombol "Selanjutnya" dan "Kembali" — menggunakan `FocusableWidget`, di-layout sebagai `Row` di bottom | ✅ | 2026-02-20 |

### Phase 5: Location Step Page (City Picker)

- GOAL-005: Halaman pemilihan lokasi dengan cascading province → city picker

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-014 | Buat file `lib/presentation/pages/setup_wizard/steps/location_step.dart` | ✅ | 2026-02-20 |
| TASK-015 | Implementasi `LocationStep` sebagai `StatefulWidget` (manages local picker state). Layout: title "Lokasi Masjid", province dropdown (searchable list), city dropdown (filtered by selected province), selected city info display (nama, koordinat) | ✅ | 2026-02-20 |
| TASK-016 | Province picker: load provinces dari `CityRepository.getProvinces()`. Tampilkan sebagai scrollable `ListView` dalam `GlassmorphismCard` dengan `FocusableWidget` per item | ✅ | 2026-02-20 |
| TASK-017 | City picker: saat province dipilih, load cities via `CityRepository.getCitiesByProvince()`. Tampilkan sebagai scrollable `ListView` | ✅ | 2026-02-20 |
| TASK-018 | Saat city dipilih → panggil `cubit.selectCity(city)`, tampilkan koordinat dan tombol konfirmasi | ✅ | 2026-02-20 |
| TASK-019 | Tambahkan search/filter TextField di atas city list — filter `CityRepository.searchCities()` | ✅ | 2026-02-20 |
| TASK-020 | Tombol "Selanjutnya" dan "Kembali" di bottom | ✅ | 2026-02-20 |

### Phase 6: Preview Step Page

- GOAL-006: Halaman preview yang menampilkan ringkasan data dan contoh jadwal sholat

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-021 | Buat file `lib/presentation/pages/setup_wizard/steps/preview_step.dart` | ✅ | 2026-02-20 |
| TASK-022 | Implementasi `PreviewStep`. Layout: title "Preview Pengaturan", `GlassmorphismCard` dengan ringkasan: Nama Masjid, Alamat, Kota, Koordinat, Metode Kalkulasi | ✅ | 2026-02-20 |
| TASK-023 | Tampilkan preview waktu sholat hari ini: gunakan `CalculatePrayerTimesUseCase.execute()` dengan data dari wizard. Tampilkan 7 waktu sholat dalam tabel/list | ✅ | 2026-02-20 |
| TASK-024 | Tombol "Simpan & Mulai" (primary, gold accent) dan "Kembali" (secondary) | ✅ | 2026-02-20 |
| TASK-025 | Loading indicator saat menyimpan (state: `SetupWizardCompleting`) | ✅ | 2026-02-20 |

### Phase 7: First-Run Check & Route Integration

- GOAL-007: Menambahkan check first-run di app startup dan routing ke wizard

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-026 | Update `lib/main.dart` atau buat `lib/presentation/pages/splash_page.dart`: check `settingsRepository.isFirstRun()` → jika true, navigate ke `SetupWizardPage` → jika false, navigate ke main display page | ✅ | 2026-02-20 |
| TASK-027 | Pastikan setelah wizard selesai (`SetupWizardCompleted`), app navigate ke home dan wizard tidak muncul lagi | ✅ | 2026-02-20 |

### Phase 8: Widget Tests

- GOAL-008: Widget tests untuk setup wizard pages

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-028 | Buat file `test/presentation/pages/setup_wizard/setup_wizard_page_test.dart` | ✅ | 2026-02-20 |
| TASK-029 | TEST: SetupWizardPage renders WelcomeStep initially (step 0) | ✅ | 2026-02-20 |
| TASK-030 | TEST: Step indicator shows correct progress (1/4 initially) | ✅ | 2026-02-20 |
| TASK-031 | TEST: "Mulai Setup" button navigates to Identity step | ✅ | 2026-02-20 |
| TASK-032 | TEST: Identity step shows text fields for mosque name and address | ✅ | 2026-02-20 |
| TASK-033 | TEST: Location step shows province and city picker lists | ✅ | 2026-02-20 |
| TASK-034 | TEST: Preview step shows summary data and prayer times preview | ✅ | 2026-02-20 |
| TASK-035 | TEST: "Simpan & Mulai" triggers completion flow | ✅ | 2026-02-20 |
| TASK-036 | Jalankan `flutter test test/presentation/pages/setup_wizard/ --reporter=expanded` | ✅ | 2026-02-20 |
