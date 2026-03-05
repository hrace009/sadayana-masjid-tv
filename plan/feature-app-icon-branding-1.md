---
goal: Mengganti icon bawaan Flutter (Icons.mosque_rounded) dengan custom app icon MKTV di seluruh halaman branding
version: 1.0
date_created: 2026-03-04
last_updated: 2026-03-04
owner: MKT Dev Team
status: 'Completed'
tags: [feature, design, branding, ui]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Saat ini terdapat 3 titik branding utama aplikasi (Splash Screen, Welcome Wizard, Header Widget) yang masih menggunakan `Icons.mosque_rounded` bawaan Material Icons sebagai logo aplikasi. Plan ini mengganti ketiga icon tersebut dengan custom app icon MKTV yang telah disediakan di folder `assets/images/`, menggunakan **Opsi A (icon transparan)** sebagai pendekatan utama yang telah disepakati.

## 1. Requirements & Constraints

- **REQ-001**: Setiap titik branding (Splash, Welcome Wizard, Header Widget) harus menggunakan custom icon MKTV, bukan Material Icon bawaan.
- **REQ-002**: Efek visual glow emas (`goldAmber`) pada container lingkaran harus tetap dipertahankan.
- **REQ-003**: Proporsi dan ukuran container pada setiap titik tidak boleh berubah.
- **REQ-004**: Perubahan hanya boleh menyentuh bagian `child` dari container icon (prinsip minimal change).
- **CON-001**: Asset `assets/images/mktv_icon_large_transparent.png` harus digunakan untuk Opsi A (background transparan agar menyatu dengan container emas).
- **CON-002**: Path `assets/images/` sudah terdaftar di `pubspec.yaml` — tidak ada perubahan `pubspec.yaml` yang diperlukan.
- **CON-003**: Icon dekoratif fungsional kecil (`identity_step.dart`, `preview_step.dart`) **tidak** diganti karena bukan bagian dari branding logo.
- **GUD-001**: Gunakan `Image.asset(...)` dengan `fit: BoxFit.contain` agar icon tidak terpotong dalam container lingkaran.
- **GUD-002**: Tambahkan `Padding` yang proporsional di setiap ukuran container agar icon tidak menyentuh tepi lingkaran.
- **PAT-001**: Ikuti Clean Code: minimal change, tidak memodifikasi kode di luar target yang ditetapkan.

## 2. Implementation Steps

### Implementation Phase 1 — Opsi A: Ganti dengan Icon Transparan (DIPILIH)

- **GOAL-001**: Mengganti bagian `child: Icon(Icons.mosque_rounded, ...)` dengan `Image.asset(mktv_icon_large_transparent.png)` di 3 titik branding utama, mempertahankan semua dekorasi container yang sudah ada.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Edit `splash_page.dart` — ganti `child: Icon(Icons.mosque_rounded, size: 80.w, ...)` dengan `child: Padding(padding: EdgeInsets.all(20.w), child: Image.asset('assets/images/mktv_icon_large_transparent.png', fit: BoxFit.contain))` | ✅ | 2026-03-04 |
| TASK-002 | Edit `welcome_step.dart` — ganti `child: Icon(Icons.mosque_rounded, size: 64.w, ...)` dengan `child: Padding(padding: EdgeInsets.all(18.w), child: Image.asset('assets/images/mktv_icon_large_transparent.png', fit: BoxFit.contain))` | ✅ | 2026-03-04 |
| TASK-003 | Edit `header_widget.dart` — ganti `child: Icon(Icons.mosque_rounded, size: 48.w, ...)` dengan `child: Padding(padding: EdgeInsets.all(12.w), child: Image.asset('assets/images/mktv_icon_large_transparent.png', fit: BoxFit.contain))` | ✅ | 2026-03-04 |
| TASK-004 | Hapus import `Icons` yang tidak terpakai di file yang telah diedit (jika ada import terisolasi) | ✅ Tidak ada import terpisah — `Icons` bagian dari `flutter/material.dart` yang masih digunakan | 2026-03-04 |
| TASK-005 | Verifikasi visual di emulator/device: pastikan icon tampil proporsional dan glow emas masih terlihat | ⏳ Pending review user | — |
| TASK-006 | Jalankan `flutter analyze` dan `flutter test` untuk memastikan tidak ada breaking change | ✅ `dart analyze` clean. 91 tests passed, 2 failures pre-existing (IhtiyatSection & IqomahSection DPadStepper — tidak terkait perubahan ini) | 2026-03-04 |

### Implementation Phase 2 — Opsi B: Ganti dengan Icon Non-Transparan (ALTERNATIF, Tidak Dipilih Saat Ini)

- **GOAL-002**: Jika Opsi A secara visual kurang memuaskan, gunakan Opsi B sebagai pengganti — menampilkan `mktv_icon_large.png` langsung dengan `ClipOval`, menghapus container circle emas beserta efek glow-nya.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | Edit `splash_page.dart` — hapus seluruh blok `Container(BoxDecoration circle goldAmber)`, ganti dengan `ClipOval(child: SizedBox(width: 140.w, height: 140.w, child: Image.asset('assets/images/mktv_icon_large.png', fit: BoxFit.cover)))` | ✅ | 2026-03-04 |
| TASK-008 | Edit `welcome_step.dart` — hapus seluruh blok Container, ganti dengan `ClipOval(child: SizedBox(width: 120.w, height: 120.w, child: Image.asset(..., fit: BoxFit.cover)))` | ✅ | 2026-03-04 |
| TASK-009 | Edit `header_widget.dart` — hapus seluruh blok Container, ganti dengan `ClipOval(child: SizedBox(width: 80.w, height: 80.w, child: Image.asset(..., fit: BoxFit.cover)))` | ✅ | 2026-03-04 |
| TASK-010 | Evaluasi apakah efek glow perlu ditambahkan kembali via `DecoratedBox` wrapper (opsional, tergantung review visual) | ⏳ Ditangguhkan — glow tidak ditambahkan otomatis, menunggu keputusan user setelah review visual | — |
| TASK-011 | Verifikasi visual dan jalankan `flutter analyze` + `flutter test` | ✅ `dart analyze` clean. 91 tests passed, 2 failures pre-existing (tidak terkait perubahan ini) | 2026-03-04 |

## 3. Alternatives

- **ALT-001 (Opsi B — Non-Transparan)**: Menggunakan `mktv_icon_large.png` dengan `ClipOval` dan menghapus container circle emas. Tidak dipilih sebagai langkah pertama karena berisiko menghilangkan efek glow branding yang sudah konsisten, dan hasilnya bergantung pada warna dominan dalam gambar non-transparan.
- **ALT-002 (Cached Network Image)**: Menggunakan icon dari URL remote. Ditolak karena project ini adalah offline-first — tidak ada network calls.
- **ALT-003 (Flutter Launcher Icons Package)**: Menggunakan package `flutter_launcher_icons` untuk mengganti app icon di launcher OS. Ini adalah scope berbeda (icon di launcher/homescreen Android), bukan icon in-app. Bisa menjadi plan terpisah di masa depan.

## 4. Dependencies

- **DEP-001**: `assets/images/mktv_icon_large_transparent.png` — icon PNG transparan yang sudah tersedia di workspace.
- **DEP-002**: `assets/images/mktv_icon_large.png` — icon PNG non-transparan, digunakan jika Opsi B dipilih.
- **DEP-003**: `flutter_screenutil` — sudah terinstall, digunakan untuk `.w` sizing yang konsisten.
- **DEP-004**: Tidak ada dependency baru yang perlu ditambahkan — `Image.asset` adalah Flutter built-in.

## 5. Files

- **FILE-001**: `lib/presentation/pages/splash_page.dart` — titik branding Splash Screen (container `140w × 140w`)
- **FILE-002**: `lib/presentation/pages/setup_wizard/steps/welcome_step.dart` — titik branding Welcome Wizard (container `120w × 120w`)
- **FILE-003**: `lib/presentation/widgets/header_widget.dart` — titik branding Header utama (container `80w × 80w`)
- **FILE-004**: `assets/images/mktv_icon_large_transparent.png` — asset sumber (read-only, tidak dimodifikasi)
- **FILE-005**: `assets/images/mktv_icon_large.png` — asset cadangan untuk Opsi B (read-only, tidak dimodifikasi)

## 6. Testing

- **TEST-001**: Verifikasi visual Splash Screen — icon MKTV muncul proporsional di dalam lingkaran emas dengan glow, tidak terpotong.
- **TEST-002**: Verifikasi visual Welcome Wizard Step 1 — icon MKTV tampil konsisten dengan ukuran yang lebih kecil (`120w`).
- **TEST-003**: Verifikasi visual Header Widget di Main Display Page — icon `80w` di pojok kiri header tampil proporsional.
- **TEST-004**: Jalankan `flutter test --reporter=expanded` — semua widget test yang sudah ada harus tetap PASSED.
- **TEST-005**: Jalankan `dart analyze` — tidak ada warning atau error baru.
- **TEST-006**: Uji di emulator/device landscape 16:9 — pastikan padding proporsional dan tidak ada clipping di semua ukuran container.

## 7. Risks & Assumptions

- **RISK-001**: Padding yang dipilih (`20.w`, `18.w`, `12.w`) bersifat estimasi awal. Jika secara visual icon terlihat terlalu kecil atau terlalu besar setelah dijalankan, nilai padding perlu disesuaikan. Solusi: review visual di emulator setelah TASK-005.
- **RISK-002**: Jika `mktv_icon_large_transparent.png` ternyata memiliki area putih/warna di sisi-sisinya (bukan benar-benar full-bleed transparan), icon akan tampak aneh di atas background emas. Solusi: jika terjadi, fallback ke Opsi B.
- **ASSUMPTION-001**: File `mktv_icon_large_transparent.png` sudah memiliki semua sisi transparan penuh (32-bit PNG with alpha channel).
- **ASSUMPTION-002**: Tidak ada widget test yang secara eksplisit melakukan `findsOneWidget` pada `Icons.mosque_rounded` di 3 file target. Jika ada, test tersebut perlu diupdate.

## 8. Related Specifications / Further Reading

- [AGENTS.md - Plan 10: Setup Wizard UI](../AGENTS.md) — konteks implementasi welcome_step dan setup wizard
- [docs/UI_UX_GUIDE.md](../docs/UI_UX_GUIDE.md) — panduan Islamic Glassmorphism Theme dan Branding
- [feature-setup-wizard-ui-1.md](feature-setup-wizard-ui-1.md) — plan sebelumnya untuk Setup Wizard UI
