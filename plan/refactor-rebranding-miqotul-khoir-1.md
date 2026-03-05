---
goal: "Rebranding Sadayana Masjid Display → Miqotul Khoir TV — Update PRD, Dokumen, Source Code, dan Konfigurasi Android"
version: 1.0
date_created: '2026-03-02'
last_updated: '2026-03-02'
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [refactor, rebranding, documentation, prd, android, naming]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Plan ini mencakup **rebranding menyeluruh** aplikasi dari **Sadayana Masjid Display (SMD)** menjadi **Miqotul Khoir TV (MKT)**. Cakupan perubahan meliputi:

1. **Dokumen PRD** — rewrite nama, versi, executive summary, section baru App Store Listing, perubahan standar kalkulasi ke Kemenag RI
2. **Dokumentasi utama** — README, AGENTS, GEMINI, plan/README
3. **Dokumentasi teknis** — 6 file di `docs/`
4. **Spesifikasi** — 6 file di `spec/`
5. **Implementation plans** — ~17 file di `plan/`
6. **Source code** — string literal, class name, comment, dan fallback nama masjid
7. **Konfigurasi Android** — `AndroidManifest.xml` label, `build.gradle.kts` applicationId & namespace, `MainActivity.kt` package, folder Kotlin
8. **Package name migration** — `pubspec.yaml` name + semua import di `lib/` dan `test/`

### Pemetaan Nama

| Item | Lama | Baru |
|------|------|------|
| Nama Lengkap | Sadayana Masjid Display | Miqotul Khoir TV |
| Singkatan | SMD | MKT |
| Versi PRD | 1.2.0 | 2.0.0 |
| Kalkulasi Default | `CalculationMethod.singapore` | Standar Kemenag RI |
| Tagline | *(tidak ada)* | Jam Masjid Digital & Jadwal Sholat |
| App Title (MaterialApp) | `'Sadayana Masjid Display'` | `'Miqotul Khoir TV'` |
| Class Name Root Widget | `SadayanaApp` | `MiqotulKhoirApp` |
| Database File | `sadayana_masjid.db` | `miqotul_khoir.db` |
| Android Label | `Sadayana MasjidTV` | `Miqotul Khoir TV` |
| Default Mosque Name (fallback) | `'Sadayana Masjid'` | `'Masjid Anda'` |
| Package Name (pubspec) | `sadayana_masjid_tv` | `miqotul_khoir_tv` |
| Application ID (Android) | `com.example.sadayana_masjid_tv` | `com.example.miqotul_khoir_tv` |

## 1. Requirements & Constraints

### Requirements

- **REQ-001**: Semua referensi "Sadayana Masjid Display" dan "SMD" di **dokumen** harus diganti ke "Miqotul Khoir TV" dan "MKT"
- **REQ-002**: PRD harus di-update ke versi **2.0.0** dengan section baru **App Store Listing** berisi tagline, deskripsi singkat, dan deskripsi lengkap
- **REQ-003**: Executive Summary PRD harus ditulis ulang sesuai deskripsi baru Miqotul Khoir TV
- **REQ-004**: Standar kalkulasi utama di PRD §3.1 harus diubah dari `CalculationMethod.singapore` menjadi **Standar Kemenag RI** (Subuh 20°, Isya 18°, Ihtiyat +2 menit)
- **REQ-005**: Semua string literal visible-to-user di source code harus diperbarui (title, splash, welcome, fallback mosque name)
- **REQ-006**: Class `SadayanaApp` di `main.dart` harus di-rename ke `MiqotulKhoirApp`
- **REQ-007**: `android:label` di `AndroidManifest.xml` harus diubah ke `Miqotul Khoir TV`
- **REQ-008**: Nama file database harus diubah dari `sadayana_masjid.db` ke `miqotul_khoir.db`
- **REQ-009**: `applicationId` dan `namespace` di `build.gradle.kts` harus diubah ke `com.example.miqotul_khoir_tv`
- **REQ-010**: `package` di `MainActivity.kt` harus disesuaikan dan folder Kotlin harus di-rename
- **REQ-011**: `name` di `pubspec.yaml` harus diubah ke `miqotul_khoir_tv` dan **semua import** `package:sadayana_masjid_tv/` harus di-rename ke `package:miqotul_khoir_tv/`
- **REQ-012**: Semua `owner:` di frontmatter YAML plan/spec harus diubah dari "Sadayana Masjid Display Team" ke "Gulajava Ministudio"
- **REQ-013**: Running Text use case di PRD §3.3 harus diperkaya: kajian, laporan keuangan, pesan hadits
- **REQ-014**: NFR Auto-Start di PRD §4 harus diperkaya: otomatis berjalan setelah listrik padam

### Constraints

- **CON-001**: Perubahan `name:` di `pubspec.yaml` akan memecah **semua import** (~60+ file Dart). Semua harus di-rename secara atomik
- **CON-002**: Perubahan `applicationId` di Gradle menyebabkan Android menganggap ini **aplikasi berbeda** — data SQLite user existing **tidak akan bermigrasi** otomatis
- **CON-003**: Perubahan nama database file (`sadayana_masjid.db` → `miqotul_khoir.db`) juga menyebabkan user existing kehilangan data lama — ini dapat diterima karena aplikasi masih dalam tahap development
- **CON-004**: Folder Kotlin (`android/app/src/main/kotlin/com/example/sadayana_masjid_tv/`) harus di-rename secara fisik ke (`com/example/miqotul_khoir_tv/`)
- **CON-005**: File output test (`.txt` files di root) tidak perlu diubah karena bersifat ephemeral/auto-generated
- **CON-006**: Plan file ini sendiri (`refactor-rebranding-miqotul-khoir-1.md`) tidak perlu diubah ulang
- **CON-007**: Perubahan kode sumber harus diikuti dengan `flutter test --reporter=expanded` untuk memastikan semua test tetap pass

### Guidelines & Patterns

- **GUD-001**: Urutan eksekusi harus mengikuti fase — dokumen dahulu, lalu source code, lalu konfigurasi Android, terakhir package rename
- **GUD-002**: Setiap fase harus diverifikasi sebelum melanjutkan ke fase berikutnya
- **GUD-003**: Perubahan di `pubspec.yaml` dan Gradle merupakan operasi destruktif — harus dikonfirmasi oleh user sebelum dieksekusi
- **PAT-001**: Gunakan find-and-replace yang presisi, bukan regex blind. Pastikan konteks sekitar benar agar tidak salah replace

## 2. Implementation Steps

### Phase 1: Update Dokumen PRD

- GOAL-001: Perbarui seluruh isi `Product_Requirement_Document.md` — nama, versi, executive summary, standar kalkulasi, section baru, dan pengayaan konten

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Update header PRD: Project Name `Sadayana Masjid Display (SMD)` → `Miqotul Khoir TV (MKT)` | ✅ | 2026-03-02 |
| TASK-002 | Update header PRD: Version `1.2.0` → `2.0.0` | ✅ | 2026-03-02 |
| TASK-003 | Rewrite §1 Executive Summary sesuai deskripsi baru Miqotul Khoir TV — mencantumkan keyword: "jam masjid digital", "100% luring", "presisi abadi", target perangkat (TV Android, TV Pintar, Kotak Dekoder) | ✅ | 2026-03-02 |
| TASK-004 | Update §3.1 Logika Kalkulasi: ubah algoritma utama dari `CalculationMethod.singapore (atau parameter Kemenag RI)` menjadi `Standar Kemenag RI (Subuh 20°, Isya 18°, Ihtiyat bawaan +2 menit)` sebagai metode utama | ✅ | 2026-03-02 |
| TASK-005 | Update §3.2 State Machine: tambahkan istilah Indonesia (Mode Siaga, Mode Sholat) dan alasan "agar tidak mengganggu kekhusyukan jamaah" pada state SHOLAT | ✅ | 2026-03-02 |
| TASK-006 | Perkaya §3.3 Content Management — Running Text: tambahkan use case "informasi kajian, laporan keuangan, atau pesan hadits" | ✅ | 2026-03-02 |
| TASK-007 | Perkaya §4 Non-Functional Requirements: update poin Auto-Start menjadi "otomatis berjalan saat TV dinyalakan atau setelah listrik padam" | ✅ | 2026-03-02 |
| TASK-008 | Update §3.5 Step 1: `Logo Sadayana` → `Logo Miqotul Khoir TV` | ✅ | 2026-03-02 |
| TASK-009 | Tambah section baru **§8. App Store Listing** setelah §7, berisi: Judul Aplikasi, Deskripsi Singkat, dan Deskripsi Lengkap sesuai brief user | ✅ | 2026-03-02 |
| TASK-010 | Update §5.1 Theme: tambahkan istilah "Kaca Buram" sebagai alias Glassmorphism | ✅ | 2026-03-02 |

### Phase 2: Update Dokumentasi Utama

- GOAL-002: Perbarui semua referensi nama di `README.md`, `AGENTS.md`, `GEMINI.md`, dan `plan/README.md`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-011 | `README.md` — Update H1 heading: `Sadayana Masjid Display` → `Miqotul Khoir TV` | ✅ | 2026-03-02 |
| TASK-012 | `README.md` — Update deskripsi pembuka sesuai tagline baru | ✅ | 2026-03-02 |
| TASK-013 | `README.md` — Update git clone URL: `sadayana-masjid-tv` → `miqotul-khoir-tv` | ✅ | 2026-03-02 |
| TASK-014 | `README.md` — Update test count dan referensi jika ada | ✅ | 2026-03-02 |
| TASK-015 | `AGENTS.md` L1: `Sadayana Masjid Display Contributor Guide` → `Miqotul Khoir TV Contributor Guide` | ✅ | 2026-03-02 |
| TASK-016 | `AGENTS.md` L3: `Sadayana Masjid Display (SMD)` → `Miqotul Khoir TV (MKT)` di deskripsi | ✅ | 2026-03-02 |
| TASK-017 | `AGENTS.md` L638: `Cubit Pattern untuk SMD` → `Cubit Pattern untuk MKT` | ✅ | 2026-03-02 |
| TASK-018 | `AGENTS.md` L721: Update footer Project name dan singkatan | ✅ | 2026-03-02 |
| TASK-019 | `AGENTS.md` — Update semua referensi `CalculationMethod.singapore` dalam contoh kode (L501, L523) ke standar Kemenag | ✅ | 2026-03-02 |
| TASK-020 | `GEMINI.md` L1: `Sadayana Masjid Display — Gemini Context` → `Miqotul Khoir TV — Gemini Context` | ✅ | 2026-03-02 |
| TASK-021 | `plan/README.md` L1: heading → `Miqotul Khoir TV` | ✅ | 2026-03-02 |
| TASK-022 | `plan/README.md` L7: deskripsi → `Miqotul Khoir TV` | ✅ | 2026-03-02 |

### Phase 3: Update Dokumentasi Teknis (`docs/`)

- GOAL-003: Perbarui semua referensi nama di 6 file dokumentasi teknis

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-023 | `docs/ARCHITECTURE_PATTERNS.md` L1: heading → `Miqotul Khoir TV` | ✅ | 2026-03-02 |
| TASK-024 | `docs/ARCHITECTURE_PATTERNS.md` L5: deskripsi `SMD` → `MKT`, `Sadayana Masjid Display` → `Miqotul Khoir TV` | ✅ | 2026-03-02 |
| TASK-025 | `docs/ARCHITECTURE_PATTERNS.md` L14, L1326: `Cubit Pattern untuk SMD` → `Cubit Pattern untuk MKT` | ✅ | 2026-03-02 |
| TASK-026 | `docs/ARCHITECTURE_PATTERNS.md` L520: `sadayana_masjid.db` → `miqotul_khoir.db` dalam contoh kode | ✅ | 2026-03-02 |
| TASK-027 | `docs/ARCHITECTURE_PATTERNS.md` L1541, L1549: update singkatan dan nama project | ✅ | 2026-03-02 |
| TASK-028 | `docs/DEVELOPMENT_WORKFLOW.md` L1, L3: heading dan deskripsi → `Miqotul Khoir TV (MKT)` | ✅ | 2026-03-02 |
| TASK-029 | `docs/DEVELOPMENT_WORKFLOW.md` L275, L278: update path adb dan nama database file | ✅ | 2026-03-02 |
| TASK-030 | `docs/DEVELOPMENT_WORKFLOW.md` L445: update kalimat penutup | ✅ | 2026-03-02 |
| TASK-031 | `docs/EXECUTION_WORKFLOW.md` L8: `Sadayana Masjid Display (SMD)` → `Miqotul Khoir TV (MKT)` | ✅ | 2026-03-02 |
| TASK-032 | `docs/SPECIFICATION_OVERVIEW.md` L1, L4: heading dan singkatan → `Miqotul Khoir TV`, `MKT` | ✅ | 2026-03-02 |
| TASK-033 | `docs/TESTING_GUIDE.md` L1, L3, L820: heading, deskripsi, dan penutup → `Miqotul Khoir TV` | ✅ | 2026-03-02 |
| TASK-034 | `docs/UI_UX_GUIDE.md` L1, L3, L33, L1034: heading, deskripsi, contoh kode title, dan penutup → `Miqotul Khoir TV` | ✅ | 2026-03-02 |

### Phase 4: Update Spesifikasi (`spec/`)

- GOAL-004: Perbarui referensi nama di 6 file spesifikasi teknis

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-035 | `spec/spec-design-ui-foundation.md` — Update `owner:` frontmatter, deskripsi (L12), class name `SadayanaMasjidApp` → `MiqotulKhoirApp` (L103, L426), title string (L111) | ✅ | 2026-03-02 |
| TASK-036 | `spec/spec-process-prayer-time.md` — Update `owner:` frontmatter, deskripsi (L12), dan REQ-006 `CalculationMethod.singapore` → standar Kemenag (L58) | ✅ | 2026-03-02 |
| TASK-037 | `spec/spec-process-settings.md` — Update `owner:` frontmatter, deskripsi (L12, L20) | ✅ | 2026-03-02 |
| TASK-038 | `spec/spec-process-setup-wizard.md` — Update `owner:` frontmatter, deskripsi (L12), welcome string (L96) | ✅ | 2026-03-02 |
| TASK-039 | `spec/spec-process-state-machine.md` — Update `owner:` frontmatter, deskripsi (L12) | ✅ | 2026-03-02 |
| TASK-040 | `spec/spec-schema-database.md` — Update `owner:` frontmatter, deskripsi (L12, L20), database name (L317) | ✅ | 2026-03-02 |

### Phase 5: Update Implementation Plans (`plan/`)

- GOAL-005: Perbarui field `owner:` di semua frontmatter plan files dan referensi nama di body text

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-041 | Update `owner:` field di YAML frontmatter dari `"Sadayana Masjid Display Team"` → `"Gulajava Ministudio"` di 16 plan files: `design-theme-system-1.md`, `design-ui-components-1.md`, `feature-data-layer-1.md`, `feature-display-state-machine-1.md`, `feature-elevation-correction-1.md`, `feature-kemenag-prayer-method-1.md`, `feature-prayer-calculation-1.md`, `feature-prayer-cubit-1.md`, `feature-settings-logic-1.md`, `feature-settings-ui-1.md`, `feature-setup-wizard-logic-1.md`, `feature-setup-wizard-ui-1.md`, `feature-state-evaluation-1.md`, `infrastructure-database-1.md`, `feature-main-display-ui-1.md`, `feature-mosque-silhouette-1.md` | ✅ | 2026-03-02 |
| TASK-042 | `plan/feature-setup-wizard-ui-1.md` L67: update string `"Sadayana Masjid Display"` → `"Miqotul Khoir TV"` dalam TASK-008 description | ✅ | 2026-03-02 |
| TASK-043 | `plan/feature-mosque-silhouette-1.md` L13: update `Sadayana Masjid TV` → `Miqotul Khoir TV` dalam deskripsi | ✅ | 2026-03-02 |
| TASK-044 | `plan/infrastructure-database-1.md` L15: update `Sadayana Masjid Display` → `Miqotul Khoir TV` dalam deskripsi | ✅ | 2026-03-02 |
| TASK-045 | `plan/infrastructure-database-1.md` L63, L65: update referensi `sadayana_masjid.db` → `miqotul_khoir.db` dalam task description | ✅ | 2026-03-02 |
| TASK-046 | `plan/refactor-theme-color-teal-1.md` L15: update `Sadayana Masjid TV` → `Miqotul Khoir TV` dalam deskripsi | ✅ | 2026-03-02 |

### Phase 6: Update Source Code — String Literal, Class Name, Comment

- GOAL-006: Perbarui semua string yang terlihat user, nama class, dan komentar di source code Dart

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-047 | `lib/main.dart` L25: Update comment `Sadayana Masjid Display` → `Miqotul Khoir TV` | ✅ | 2026-03-02 |
| TASK-048 | `lib/main.dart` L94: `runApp(const SadayanaApp())` → `runApp(const MiqotulKhoirApp())` | ✅ | 2026-03-02 |
| TASK-049 | `lib/main.dart` L101-102: Rename class `SadayanaApp` → `MiqotulKhoirApp` dan constructor | ✅ | 2026-03-02 |
| TASK-050 | `lib/main.dart` L161: `title: 'Sadayana Masjid Display'` → `title: 'Miqotul Khoir TV'` | ✅ | 2026-03-02 |
| TASK-051 | `lib/core/theme/islamic_theme.dart` L7: Update comment `Sadayana Masjid Display` → `Miqotul Khoir TV` | ✅ | 2026-03-02 |
| TASK-052 | `lib/presentation/pages/splash_page.dart` L105: `'Sadayana Masjid Display'` → `'Miqotul Khoir TV'` | ✅ | 2026-03-02 |
| TASK-053 | `lib/presentation/pages/setup_wizard/steps/welcome_step.dart` L49: `'Sadayana Masjid Display'` → `'Miqotul Khoir TV'` | ✅ | 2026-03-02 |
| TASK-054 | `lib/presentation/pages/main_display/layouts/standby_layout.dart` L31: Fallback `'Sadayana Masjid'` → `'Masjid Anda'` | ✅ | 2026-03-02 |
| TASK-055 | `lib/presentation/pages/main_display/layouts/pre_adzan_layout.dart` L29: `mosqueName: 'Sadayana Masjid'` → `mosqueName: 'Masjid Anda'` | ✅ | 2026-03-02 |
| TASK-056 | `lib/presentation/widgets/header_widget.dart` L72: Fallback `'Sadayana Masjid'` → `'Masjid Anda'` | ✅ | 2026-03-02 |
| TASK-057 | `lib/data/datasources/database_helper.dart` L20: `'sadayana_masjid.db'` → `'miqotul_khoir.db'` | ✅ | 2026-03-02 |

### Phase 7: Update Test Files — String Assertions

- GOAL-007: Perbarui test yang memvalidasi string lama agar sesuai dengan nama baru

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-058 | `test/widget_test.dart` L21: `SadayanaApp()` → `MiqotulKhoirApp()` | ✅ | 2026-03-02 |
| TASK-059 | `test/widget_test.dart` L26: `'Sadayana Masjid Display'` → `'Miqotul Khoir TV'` assertion | ✅ | 2026-03-02 |
| TASK-060 | `test/widget_test.dart` L11: Update import jika masih merujuk class lama | ✅ | 2026-03-02 |
| TASK-061 | Scan semua file test untuk referensi string `'Sadayana'` dan update sesuai konteks | ✅ | 2026-03-02 |

### Phase 8: Update Konfigurasi Android

- GOAL-008: Perbarui Android app label, applicationId, namespace, dan folder package Kotlin

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-062 | `android/app/src/main/AndroidManifest.xml` L17: `android:label="Sadayana MasjidTV"` → `android:label="Miqotul Khoir TV"` | ✅ | 2026-03-02 |
| TASK-063 | `android/app/build.gradle.kts` L9: `namespace = "com.example.sadayana_masjid_tv"` → `namespace = "com.example.miqotul_khoir_tv"` | ✅ | 2026-03-02 |
| TASK-064 | `android/app/build.gradle.kts` L24: `applicationId = "com.example.sadayana_masjid_tv"` → `applicationId = "com.example.miqotul_khoir_tv"` | ✅ | 2026-03-02 |
| TASK-065 | Rename folder `android/app/src/main/kotlin/com/example/sadayana_masjid_tv/` → `android/app/src/main/kotlin/com/example/miqotul_khoir_tv/` | ✅ | 2026-03-02 |
| TASK-066 | `android/app/src/main/kotlin/.../MainActivity.kt` L1: `package com.example.sadayana_masjid_tv` → `package com.example.miqotul_khoir_tv` | ✅ | 2026-03-02 |

### Phase 9: Package Name Migration (`pubspec.yaml` + All Imports)

- GOAL-009: Rename package name di `pubspec.yaml` dan update semua import statement di `lib/` dan `test/`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-067 | `pubspec.yaml` L1: `name: sadayana_masjid_tv` → `name: miqotul_khoir_tv` | ✅ | 2026-03-02 |
| TASK-068 | `pubspec.yaml` L2: `description: "A new Flutter project."` → `description: "Miqotul Khoir TV — Jam Masjid Digital & Jadwal Sholat untuk Android TV. 100% Luring."` | ✅ | 2026-03-02 |
| TASK-069 | Global find-and-replace di semua file `lib/**/*.dart`: `package:sadayana_masjid_tv/` → `package:miqotul_khoir_tv/` (estimasi ~60+ file) | ✅ | 2026-03-02 |
| TASK-070 | Global find-and-replace di semua file `test/**/*.dart`: `package:sadayana_masjid_tv/` → `package:miqotul_khoir_tv/` (estimasi ~20+ file) | ✅ | 2026-03-02 |
| TASK-071 | Jalankan `flutter pub get` untuk memastikan package resolve dengan nama baru | ✅ | 2026-03-02 |
| TASK-072 | Jalankan `dart analyze` untuk memastikan tidak ada broken import | ✅ | 2026-03-02 |

### Phase 10: Update `.github/instructions/` Memory File

- GOAL-010: Update referensi nama proyek di instruction files dan memory file

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-073 | `.github/instructions/memory.instructions.md` — Update semua referensi nama proyek dari Sadayana/SMD ke Miqotul Khoir TV/MKT | ✅ | 2026-03-02 |

### Phase 11: Verifikasi Akhir

- GOAL-011: Verifikasi menyeluruh bahwa semua perubahan konsisten dan aplikasi berjalan normal

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-074 | Jalankan `flutter test --reporter=expanded` — semua test harus **PASS** | ✅ | 2026-03-02 |
| TASK-075 | Jalankan `dart analyze` — tidak boleh ada error | ✅ | 2026-03-02 |
| TASK-076 | Jalankan `dart format .` — pastikan format konsisten | ✅ | 2026-03-02 |
| TASK-077 | Grep workspace untuk sisa referensi `Sadayana` — harus **0 match** (kecuali file `.txt` output test lama dan plan ini sendiri) | ✅ | 2026-03-02 |
| TASK-078 | Grep workspace untuk sisa referensi `SMD` yang bermakna singkatan proyek — harus **0 match** (kecuali historical plan/spec yang sudah completed) | ✅ | 2026-03-02 |
| TASK-079 | Build APK: `flutter build apk` — pastikan build sukses dengan package name baru | ⚠️ | 2026-03-02 |

## 3. Alternatives

- **ALT-001**: Hanya mengganti nama di dokumen tanpa rename package/applicationId — **Ditolak** karena inkonsistensi antara branding dan teknikal, serta menyulitkan publishing ke Play Store nanti
- **ALT-002**: Menggunakan `rename` CLI tool (pub package `rename`) untuk otomasi package rename — **Dipertimbangkan**, namun tool ini bisa menyebabkan perubahan tak terduga. Lebih aman dilakukan manual dengan verifikasi per fase
- **ALT-003**: Mempertahankan nama database file `sadayana_masjid.db` untuk backward compatibility — **Ditolak** karena aplikasi masih dalam development, belum ada user production. Clean rename lebih konsisten
- **ALT-004**: Menambahkan migration logic untuk rename database file dari `sadayana_masjid.db` ke `miqotul_khoir.db` — **Opsional**, hanya diperlukan jika ada user yang sudah menginstall versi development. Dapat ditambahkan sebagai enhancement terpisah

## 4. Dependencies

- **DEP-001**: Plan Kemenag Prayer Method (`feature-kemenag-prayer-method-1.md`) untuk perubahan standar kalkulasi — sudah ada ✅
- **DEP-002**: Semua plan 01–12 harus sudah completed — sudah completed ✅
- **DEP-003**: Tool `dart format`, `dart analyze`, `flutter test` harus tersedia di environment

## 5. Files

### Dokumen (akan diubah kontennya)

- **FILE-001**: `Product_Requirement_Document.md` — [MODIFY] Rewrite header, summary, kalkulasi, section baru
- **FILE-002**: `README.md` — [MODIFY] Heading, deskripsi, git URL
- **FILE-003**: `AGENTS.md` — [MODIFY] Heading, deskripsi, singkatan, contoh kode, footer
- **FILE-004**: `GEMINI.md` — [MODIFY] Heading
- **FILE-005**: `plan/README.md` — [MODIFY] Heading, deskripsi
- **FILE-006**: `docs/ARCHITECTURE_PATTERNS.md` — [MODIFY] Heading, deskripsi, contoh kode, footer
- **FILE-007**: `docs/DEVELOPMENT_WORKFLOW.md` — [MODIFY] Heading, deskripsi, path adb
- **FILE-008**: `docs/EXECUTION_WORKFLOW.md` — [MODIFY] Deskripsi
- **FILE-009**: `docs/SPECIFICATION_OVERVIEW.md` — [MODIFY] Heading, singkatan
- **FILE-010**: `docs/TESTING_GUIDE.md` — [MODIFY] Heading, deskripsi, penutup
- **FILE-011**: `docs/UI_UX_GUIDE.md` — [MODIFY] Heading, deskripsi, contoh kode
- **FILE-012**: `spec/spec-design-ui-foundation.md` — [MODIFY] Owner, deskripsi, class name, title string
- **FILE-013**: `spec/spec-process-prayer-time.md` — [MODIFY] Owner, deskripsi, REQ kalkulasi
- **FILE-014**: `spec/spec-process-settings.md` — [MODIFY] Owner, deskripsi
- **FILE-015**: `spec/spec-process-setup-wizard.md` — [MODIFY] Owner, deskripsi, welcome string
- **FILE-016**: `spec/spec-process-state-machine.md` — [MODIFY] Owner, deskripsi
- **FILE-017**: `spec/spec-schema-database.md` — [MODIFY] Owner, deskripsi, DB name
- **FILE-018**: 16 plan files di `plan/` — [MODIFY] Owner field di frontmatter + body text references

### Source Code (akan diubah)

- **FILE-019**: `lib/main.dart` — [MODIFY] Comment, class name, title string
- **FILE-020**: `lib/core/theme/islamic_theme.dart` — [MODIFY] Comment
- **FILE-021**: `lib/presentation/pages/splash_page.dart` — [MODIFY] Title string
- **FILE-022**: `lib/presentation/pages/setup_wizard/steps/welcome_step.dart` — [MODIFY] Title string
- **FILE-023**: `lib/presentation/pages/main_display/layouts/standby_layout.dart` — [MODIFY] Fallback name
- **FILE-024**: `lib/presentation/pages/main_display/layouts/pre_adzan_layout.dart` — [MODIFY] Fallback name
- **FILE-025**: `lib/presentation/widgets/header_widget.dart` — [MODIFY] Fallback name
- **FILE-026**: `lib/data/datasources/database_helper.dart` — [MODIFY] Database filename

### Konfigurasi Android (akan diubah)

- **FILE-027**: `android/app/src/main/AndroidManifest.xml` — [MODIFY] App label
- **FILE-028**: `android/app/build.gradle.kts` — [MODIFY] namespace, applicationId
- **FILE-029**: `android/app/src/main/kotlin/com/example/sadayana_masjid_tv/MainActivity.kt` — [MODIFY+MOVE] Package declaration + folder rename

### Package Infrastructure (akan diubah)

- **FILE-030**: `pubspec.yaml` — [MODIFY] name, description
- **FILE-031**: ~60+ file `lib/**/*.dart` — [MODIFY] Import statements
- **FILE-032**: ~20+ file `test/**/*.dart` — [MODIFY] Import statements

### Instruction Files

- **FILE-033**: `.github/instructions/memory.instructions.md` — [MODIFY] Referensi nama proyek

## 6. Testing

- **TEST-001**: `flutter test --reporter=expanded` — Semua 160+ test harus PASS setelah semua fase selesai
- **TEST-002**: `dart analyze` — 0 error, 0 warning (kecuali info/hint yang sudah ada sebelumnya)
- **TEST-003**: `dart format . --set-exit-if-changed` — Semua file terformat konsisten
- **TEST-004**: Grep validation: `grep -r "Sadayana" --include="*.dart" --include="*.md"` harus menghasilkan 0 match di file aktif (bukan output test lama)
- **TEST-005**: `flutter build apk` — Build APK sukses dengan package name baru
- **TEST-006**: Manual: Verifikasi splash screen menampilkan "Miqotul Khoir TV"
- **TEST-007**: Manual: Verifikasi Welcome Step wizard menampilkan "Miqotul Khoir TV"
- **TEST-008**: Manual: Verifikasi header fallback menampilkan "Masjid Anda" jika belum setup

## 7. Risks & Assumptions

### Risks

- **RISK-001**: **Package rename memecah semua import** — Jika `pubspec.yaml` name diubah tanpa update semua import, aplikasi tidak akan compile. **Mitigasi**: Gunakan find-and-replace global yang atomik dan verifikasi dengan `dart analyze`
- **RISK-002**: **ApplicationId berubah = aplikasi baru di Android** — User yang sudah install versi development harus uninstall manual. **Mitigasi**: Aplikasi masih development, belum ada user production
- **RISK-003**: **Database file rename kehilangan data existing** — Data lama di `sadayana_masjid.db` tidak akan terbaca jika file direname ke `miqotul_khoir.db`. **Mitigasi**: Aplikasi masih development. Opsional: tambahkan migration logic di `DatabaseHelper` untuk rename file jika ditemukan
- **RISK-004**: **Folder Kotlin rename bisa gagal di Windows** — File locking atau path issues saat rename folder. **Mitigasi**: Pastikan tidak ada process yang lock folder, gunakan terminal command
- **RISK-005**: **Test output `.txt` files masih berisi referensi lama** — File ini auto-generated dan tidak perlu di-maintain. **Mitigasi**: Abaikan, beri catatan di `CON-005`

### Assumptions

- **ASSUMPTION-001**: Aplikasi masih dalam tahap development — tidak ada user production yang akan terdampak oleh perubahan applicationId
- **ASSUMPTION-002**: Semua test yang ada saat ini sudah PASS sebelum dimulai rebranding
- **ASSUMPTION-003**: Plan Kemenag prayer method (`feature-kemenag-prayer-method-1.md`) sudah atau akan dieksekusi secara terpisah dari rebranding ini — konten PRD cukup mengubah deskripsi standar kalkulasi
- **ASSUMPTION-004**: Git repository remote URL (GitHub) belum perlu diganti pada fase ini — cukup update referensi di README

## 8. Related Specifications / Further Reading

- [PRD — Product Requirement Document](../Product_Requirement_Document.md) — Target utama perubahan
- [Plan: Kemenag Prayer Method](../plan/feature-kemenag-prayer-method-1.md) — Terkait perubahan standar kalkulasi
- [Spec Overview](../docs/SPECIFICATION_OVERVIEW.md) — Index semua spesifikasi teknis
- [AGENTS.md](../AGENTS.md) — Contributor guide dengan referensi nama proyek
