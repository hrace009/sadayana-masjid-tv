---
goal: Menambahkan Efek Latar Belakang Siluet Masjid (Glassmorphism)
version: 1.0
date_created: 2026-02-26
last_updated: 2026-05-11
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, design, ui]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Dokumen ini telah mengimplementasikan penambahan gambar siluet masjid sebagai ornamen visual (*overlay*) samar-samar pada latar belakang (*background*) layar utama aplikasi Miqotul Khoir TV. Tujuannya adalah untuk memperkuat nuansa Islami dan kedalaman desain (glassmorphism/layering) tanpa mengurangi keterbacaan teks utama.

Aset gambar yang digunakan telah disediakan (hasil *generate* AI) dan telah berhasil diintegrasikan ke dalam proyek.

## 1. Requirements & Constraints

- **REQ-001**: Menggunakan gambar siluet masjid berlapis (masjid, gunung, burung) sebagai aset lokal.
- **REQ-002**: Gambar harus memiliki transparansi (*opacity* rendah) agar terlihat samar-samar.
- **REQ-003**: Gambar diletakkan di bagian paling bawah layar (menempel pada *bottom edge*).
- **CON-001**: *Contrast Ratio* harus dijaga. Siluet tidak boleh mengaburkan atau mengacaukan teks di atasnya (Jam, Jadwal Sholat, Teks Berjalan).
- **PAT-001**: Harus menerapkan prinsip *Anti Burn-In* untuk layar TV. Mengingat gambar ini cukup besar dan statis, harus ada animasi *parallax* atau pergerakan yang amat lambat (mis. geser horizontal perlahan, mirip dengan mekanisme pergeseran gradien warna yang sudah ada).
- **DIR-001**: Gambar ditempatkan di folder `assets/images/`.

## 2. Implementation Steps

### Implementation Phase 1: Persiapan Aset & Konfigurasi

- GOAL-001: Memastikan aset gambar siluet terdaftar dalam proyek sehingga dapat digunakan oleh _widgets_.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-000 | Menggunakan AI Image Generator untuk membuat aset gambar siluet berlapis (`mosque_silhouette_layered...png`). | ✅ | 2026-02-26 |
| TASK-001 | Memindahkan/Menyalin gambar hasil generate ke `assets/images/mosque_silhouette.png` (buat folder jika belum ada). | ✅ | 2026-02-26 |
| TASK-002 | Mendaftarkan path `assets/images/mosque_silhouette.png` (atau direktori `assets/images/`) pada file `pubspec.yaml` (dibawah section `flutter: assets:`). | ✅ | 2026-02-26 |
| TASK-003 | Menjalankan *flutter pub get* setelah `pubspec.yaml` diubah. | ✅ | 2026-02-26 |

### Implementation Phase 2: Modifikasi Komponen UI Dasar

- GOAL-002: Mengintegrasikan gambar siluet ke dalam *widget* `IslamicBackground` yang sudah ada, lengkap dengan transparansi dan proteksi TV.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-004 | Buka `lib/presentation/widgets/islamic_background.dart`. Sesuaikan *Stack* untuk menyisipkan layer gambar (*Image.asset*) sebelum layer `child` konten. | ✅ | 2026-02-26 |
| TASK-005 | Atur properti `opacity` (menggunakan `Opacity` widget atau properti warna *withAlpha/withValues*) dan `blendMode` jika perlu pada gambar. Nilai opacity disarankan antara 0.1 - 0.2 (10% - 20%). | ✅ | 2026-02-26 |
| TASK-006 | Letakkan gambar di posisi bawah layar menggunakan `Positioned` atau `Align(alignment: Alignment.bottomCenter)`. | ✅ | 2026-02-26 |
| TASK-007 | (Kritis) Modifikasi *state* (*Anti Burn-in Timer*) pada `_IslamicBackgroundState` untuk juga memberikan *micro-movement* pada posisi horizontal (sumbu x) atau alignment dari gambar siluet tersebut, bergerak secara harmonis dengan pergeseran *gradient*. | ✅ | 2026-02-26 |

## 3. Alternatives

- **ALT-001**: Menggunakan `CustomPainter` murni tanpa aset. *Ditolak* karena kompleksitas untuk menghasilkan gambar bernuansa gunung, bulan, dan burung persis seperti referensi terlalu tinggi dibandingkan memuat satu lapisan gambar *overlay*.

## 4. Dependencies

- **DEP-001**: Aset visual PNG transparan (`mosque_silhouette_layered...png`).

## 5. Files

- **FILE-001**: `pubspec.yaml` (menambah asets)
- **FILE-002**: `lib/presentation/widgets/islamic_background.dart` (implementasi layer gambar & animasi)

## 6. Testing

- **TEST-001**: Uji *Widget Test* pada `IslamicBackground` untuk memastikan lapisan `Image` berhasil dimuat (*pumpWidget*).
- **TEST-002**: Verifikasi manual (*Visual Regression*) pada emulator/TV bahwa keterbacaan (*readability*) teks tidak terganggu.
- **TEST-003**: Verifikasi *Timer* pergeseran gambar dapat jalan tanpa menyebabkan *memory leak*.

## 7. Risks & Assumptions

- **RISK-001**: Potensi lonjakan penggunaan RAM karena ukuran aset gambar jika layar target (*resolution*) terlalu besar (TV 4K). Mitigasi: Pastikan gambar PNG sudah ter-*compress* dengan baik.
- **ASSUMPTION-001**: Background aplikasi akan selalu bernuansa transenden (gelap Emerald) sehingga gambar siluet hitam transparan akan selalu berpadu dengan baik (*glassmorphism blending*).

## 8. Related Specifications / Further Reading

- `docs/UI_UX_GUIDE.md` (Panduan tema Islamic Glassmorphism)

## 9. Completion Summary

Dokumen ini telah selesai diimplementasikan. Berikut adalah referensi implementasi aktual:

### Implementation Evidence

| Component | Location | Notes |
|-----------|----------|-------|
| **Asset Image** | `assets/images/mosque_silhouette.png` | Layered silhouette (masjid, gunung, burung) |
| **Pubspec Registration** | `pubspec.yaml:83` | `assets/images/` registered |
| **Background Widget** | `lib/presentation/widgets/islamic_background.dart:106-128` | Layer 3: Mosque Silhouette |
| **Anti Burn-in Timer** | `lib/presentation/widgets/islamic_background.dart:52-68` | `_burnInTimer` + `_shiftGradient()` |
| **Parallax Movement** | `lib/presentation/widgets/islamic_background.dart:109-111` | `Transform.translate(offset: Offset(offset * 1000, 0))` |
| **Color Filter Matrix** | `lib/presentation/widgets/islamic_background.dart:114-119` | Alpha ~0.15 (15% opacity) |

### Technical Details

- **Opacity**: ~15% menggunakan `ColorFilter.matrix` — putih dihilangkan, hitam/abu menjadi siluet tipis 15%
- **Anti Burn-in**: Parallax micro-movement selaras dengan gradient shift setiap 60 detik (±0.5% alignment offset)
- **Layer Order**: LinearGradient → RadialGradient → Mosque Silhouette → Content child
- **Coverage**: Full screen (`BoxFit.cover`) dengan alignment bottom-center

### Testing Status

| Test | Status |
|------|--------|
| Widget Test (`IslamicBackground` dengan Image layer) | ✅ Integrated |
| Visual Regression (readability check) | ✅ Manual verified |
| Memory Leak (timer disposal) | ✅ `dispose()` + `_burnInTimer?.cancel()` |

### Completion Date

- **2026-05-11**: Status updated dari `Planned` → `Completed`
