---
goal: Refactor palet warna primary dari Deep Emerald Green ke Teal (#248277)
version: '1.0'
date_created: '2026-02-25'
last_updated: '2026-02-25'
owner: Gulajava Ministudio
status: 'Completed'
tags: [refactor, design, theme, color]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Mengubah seluruh hierarki warna primary pada aplikasi **Miqotul Khoir TV** dari palet **Deep Emerald Green** ke palet **Teal** berbasis `#248277`. Perubahan menggunakan pendekatan **Full Palette Replacement** — semua nama variabel di-rename agar tetap *intent-revealing* (Clean Code) dan semua nilai hex diperbarui secara konsisten. Tidak ada perubahan pada logika UI, state machine, atau struktur widget.

## 1. Requirements & Constraints

- **REQ-001**: Warna `deepTeal` harus menggunakan hex **`#036666`** (user-specified).
- **REQ-002**: Warna `primaryTeal` harus menggunakan hex **`#248277`** (user-specified, base color).
- **REQ-003**: Warna `lightTeal` harus menggunakan hex **`#3AA898`** (user-approved, light variant).
- **REQ-004**: Background dan surface colors harus diturunkan secara harmonis dari `deepTeal` (#036666) agar menciptakan kedalaman visual yang tepat di layar TV 16:9.
- **REQ-005**: Warna Gold/Amber, Glassmorphism, dan State colors (success, error, warning, info) TIDAK BOLEH berubah.
- **CON-001**: Tidak ada perubahan pada logika bisnis, Cubit, Use Case, atau struktur widget.
- **CON-002**: Semua unit test yang terdampak harus diperbarui agar tetap passing setelah rename dan perubahan hex.
- **GUD-001**: Semua kode harus mematuhi konvensi proyek — tidak ada hardcoded color values di luar `islamic_colors.dart`.
- **PAT-001**: Ikuti pola Clean Code — nama variabel harus *intent-revealing* (rename `deepEmerald` → `deepTeal`, dst).
- **PAT-002**: Jalankan `flutter test --reporter=expanded` setelah implementasi selesai untuk verifikasi.

## 2. Implementation Steps

### Implementation Phase 1: Update Definisi Konstanta Warna

- GOAL-001: Perbarui semua konstanta warna di `islamic_colors.dart` — rename dan update nilai hex.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Rename `deepEmerald` → `deepTeal`, update hex dari `0xFF0D4A3A` → `0xFF036666`, update komentar doc | ✅ | 2026-02-25 |
| TASK-002 | Rename `emeraldGreen` → `primaryTeal`, update hex dari `0xFF1B6B4A` → `0xFF248277`, update komentar doc | ✅ | 2026-02-25 |
| TASK-003 | Rename `lightEmerald` → `lightTeal`, update hex dari `0xFF2E8B5A` → `0xFF3AA898`, update komentar doc | ✅ | 2026-02-25 |
| TASK-004 | Update `darkBackground` hex dari `0xFF0A1A14` → `0xFF041E1E` | ✅ | 2026-02-25 |
| TASK-005 | Update `surfaceDark` hex dari `0xFF0F2A1F` → `0xFF082E2E` | ✅ | 2026-02-25 |
| TASK-006 | Update `surfaceLight` hex dari `0xFF1A3D2E` → `0xFF0F4343` | ✅ | 2026-02-25 |
| TASK-007 | Update `textSecondary` hex dari `0xFFB8C9C0` → `0xFFB0C9C6` | ✅ | 2026-02-25 |
| TASK-008 | Update `textMuted` hex dari `0xFF7A9A8A` → `0xFF739A95` | ✅ | 2026-02-25 |
| TASK-009 | Update `standbyColor` — ubah referensi dari `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-010 | Update `preAdzanColor` hex dari `0xFF1E6038` → `0xFF14706E` | ✅ | 2026-02-25 |
| TASK-011 | Update `sholatColor` — ubah referensi dari `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |

### Implementation Phase 2: Update Referensi di Source Files

- GOAL-002: Ganti semua referensi nama konstanta lama dengan nama baru di seluruh source files.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-012 | `islamic_theme.dart` L37: `emeraldGreen` → `primaryTeal`. L46: `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-013 | `islamic_background.dart` L98: `emeraldGreen` → `primaryTeal` | ✅ | 2026-02-25 |
| TASK-014 | `step_indicator_widget.dart` L92: `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-015 | `header_widget.dart` L55: `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-016 | `splash_page.dart` L65, L88: `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-017 | `welcome_step.dart` L42, L104: `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-018 | `identity_step.dart` L220: `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-019 | `location_step.dart` L364: `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-020 | `preview_step.dart` L261: `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-021 | `adzan_layout.dart` L19: `deepEmerald` → `deepTeal` | ✅ | 2026-02-25 |
| TASK-022 | `security_section.dart` L129, L133, L143: `emeraldGreen` → `primaryTeal` | ✅ | 2026-02-25 |
| TASK-023 | `running_text_section.dart` L144, L145: `emeraldGreen` → `primaryTeal` | ✅ | 2026-02-25 |

### Implementation Phase 3: Update Unit Tests

- GOAL-003: Sesuaikan unit test agar nama konstanta dan expected hex values menggunakan nilai baru.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-024 | `islamic_colors_test.dart` — Rename test group & descripsi: `deepEmerald` → `deepTeal`, `emeraldGreen` → `primaryTeal`, `lightEmerald` → `lightTeal` | ✅ | 2026-02-25 |
| TASK-025 | `islamic_colors_test.dart` — Update expected hex values: `0xFF0D4A3A` → `0xFF036666`, `0xFF1B6B4A` → `0xFF248277`, `0xFF2E8B5A` → `0xFF3AA898` | ✅ | 2026-02-25 |
| TASK-026 | `islamic_colors_test.dart` — Update assertion L99-100: `standbyColor equals deepEmerald` → `standbyColor equals deepTeal` | ✅ | 2026-02-25 |
| TASK-027 | `islamic_colors_test.dart` — Update assertion L107-108: `sholatColor equals deepEmerald` → `sholatColor equals deepTeal` | ✅ | 2026-02-25 |
| TASK-028 | `islamic_theme_test.dart` — Update test description L76 & assertion L79: `emeraldGreen` → `primaryTeal` | ✅ | 2026-02-25 |

### Implementation Phase 4: Verifikasi

- GOAL-004: Pastikan semua test passing dan tidak ada referensi nama konstanta lama yang tersisa.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-029 | Jalankan `flutter test test/core/theme/islamic_colors_test.dart --reporter=expanded` — semua 15 test harus pass | ✅ | 2026-02-25 |
| TASK-030 | Jalankan `flutter test test/core/theme/islamic_theme_test.dart --reporter=expanded` — semua 17 test harus pass | ✅ | 2026-02-25 |
| TASK-031 | Jalankan `dart analyze lib/core/theme/` — 0 errors, 0 warnings | ✅ | 2026-02-25 |
| TASK-032 | Jalankan `flutter test --reporter=expanded` (full test suite) — 0 failing tests | ✅ | 2026-02-25 |

## 3. Alternatives

- **ALT-001**: **Partial Accent Replacement** — Mempertahankan background emerald yang sangat gelap, hanya mengganti accent/element UI ke `#248277`. Ditolak karena tidak menghasilkan palet yang cukup harmonis; warna background lama akan clash dengan primary teal baru.
- **ALT-002**: **Tambah konstanta baru tanpa rename** — Tambah `deepTeal`, `primaryTeal`, `lightTeal` sebagai konstanta baru dan deprecate yang lama. Ditolak karena melanggar prinsip Clean Code (ISP/SRP) dan menyisakan dead code.

## 4. Dependencies

- **DEP-001**: Tidak ada dependency package baru — perubahan murni pada nilai konstanta yang sudah ada.
- **DEP-002**: `flutter_screenutil` — tidak terdampak.
- **DEP-003**: `adhan` — tidak terdampak.

## 5. Files

- **FILE-001**: `lib/core/theme/islamic_colors.dart` — File utama, source of truth seluruh konstanta warna
- **FILE-002**: `lib/core/theme/islamic_theme.dart` — ThemeData mapping, 2 referensi
- **FILE-003**: `lib/presentation/widgets/islamic_background.dart` — 1 referensi
- **FILE-004**: `lib/presentation/widgets/step_indicator_widget.dart` — 1 referensi
- **FILE-005**: `lib/presentation/widgets/header_widget.dart` — 1 referensi
- **FILE-006**: `lib/presentation/pages/splash_page.dart` — 2 referensi
- **FILE-007**: `lib/presentation/pages/setup_wizard/steps/welcome_step.dart` — 2 referensi
- **FILE-008**: `lib/presentation/pages/setup_wizard/steps/identity_step.dart` — 1 referensi
- **FILE-009**: `lib/presentation/pages/setup_wizard/steps/location_step.dart` — 1 referensi
- **FILE-010**: `lib/presentation/pages/setup_wizard/steps/preview_step.dart` — 1 referensi
- **FILE-011**: `lib/presentation/pages/main_display/layouts/adzan_layout.dart` — 1 referensi
- **FILE-012**: `lib/presentation/pages/settings/sections/security_section.dart` — 3 referensi
- **FILE-013**: `lib/presentation/pages/settings/sections/running_text_section.dart` — 2 referensi
- **FILE-014**: `test/core/theme/islamic_colors_test.dart` — 15 unit tests, 5 tests butuh update
- **FILE-015**: `test/core/theme/islamic_theme_test.dart` — 17 widget tests, 1 test butuh update

## 6. Testing

- **TEST-001**: `IslamicColors — Primary Colors` group — validasi `deepTeal`, `primaryTeal`, `lightTeal` terdefinisi dan nilai hex benar.
- **TEST-002**: `IslamicColors — Prayer State Colors` group — validasi `standbyColor` === `deepTeal` dan `sholatColor` === `deepTeal`.
- **TEST-003**: `IslamicTheme.darkTheme() — ColorScheme` group — validasi `primary` === `primaryTeal`.
- **TEST-004**: Full test suite `flutter test --reporter=expanded` untuk memastikan tidak ada regresi di widget tests lain.

## 7. Risks & Assumptions

- **RISK-001**: Warna `surfaceLight` (#0F4343) lebih terang dari `deepTeal` (#036666) — perlu verifikasi kontras pada dropdown dan nested container agar tetap terbaca di layar TV yang terang.
- **RISK-002**: `preAdzanColor` (#14706E) sangat dekat dengan `deepTeal` (#036666) secara visual — jika perbedaannya terlalu halus di TV asli, nilainya perlu disesuaikan.
- **ASSUMPTION-001**: Semua widget yang menggunakan warna primary tidak hardcode hex di luar `IslamicColors` — terbukti benar berdasarkan hasil `grep_search` yang dilakukan.
- **ASSUMPTION-002**: Tidak ada file lain di luar scope `lib/` dan `test/` yang perlu diperbarui untuk keperluan runtime (build scripts, CI, dsb).

## 8. Related Specifications / Further Reading

- [spec-design-ui-foundation.md](../spec/spec-design-ui-foundation.md)
- [design-theme-system-1.md](./design-theme-system-1.md) — Plan asal yang mendefinisikan palet Emerald
- [UI_UX_GUIDE.md](../docs/UI_UX_GUIDE.md)
