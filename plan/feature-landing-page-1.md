---
goal: "Membuat Landing Page Produk Miqotul Khoir TV Masjid dengan Bootstrap"
version: 1.0
date_created: 2026-05-12
last_updated: 2026-05-12
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, landing-page, bootstrap, marketing, website]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Plan ini mendefinisikan implementasi landing page statis untuk produk **Miqotul
Khoir TV Masjid** di folder `landingpage/`. Landing page menjelaskan nilai
produk, fitur utama, screenshot aplikasi, dan CTA menuju Google Play Store.

Landing page dibuat sebagai halaman marketing ringan yang dapat dibuka langsung
di browser atau di-deploy sebagai static website tanpa build step. Konten utama
berbahasa Indonesia dan ditujukan untuk DKM/pengurus masjid yang ingin memahami
manfaat aplikasi sebelum memasangnya di Android TV.

## 1. Requirements & Constraints

- **REQ-001**: Landing page harus dibuat sebagai website statis berbasis HTML,
  CSS, dan JavaScript ringan.
- **REQ-002**: Semua file implementasi landing page harus berada di folder
  `landingpage/`.
- **REQ-003**: Gunakan Bootstrap CSS terbaru yang diverifikasi saat planning,
  yaitu **Bootstrap v5.3.8** via CDN resmi.
- **REQ-004**: Konten utama landing page harus berbahasa Indonesia.
- **REQ-005**: CTA utama harus mengarah ke Google Play Store:
  `https://play.google.com/store/apps/details?id=gulajava.mini.miqotul_khoir_tv`.
- **REQ-006**: Landing page harus menampilkan beberapa screenshot aplikasi dari
  aset yang disediakan user.
- **REQ-007**: Landing page harus menjelaskan produk sebagai aplikasi jam masjid
  digital dan papan informasi jadwal sholat untuk Android TV.
- **REQ-008**: Landing page harus menampilkan fitur utama: jadwal sholat offline,
  standar Kemenag SIHAT, koreksi DPL/elevasi, penanganan Jum'at, navigasi D-Pad,
  running text, kas masjid, kata mutiara, mode hemat daya, alarm tanda waktu, dan
  slideshow pengumuman.
- **REQ-009**: Landing page harus menyertakan pesan bahwa aplikasi sudah tersedia
  di Google Play Store.
- **REQ-010**: Landing page harus responsive untuk mobile, tablet, laptop, dan
  desktop besar.
- **REQ-011**: Semua copy UI utama (navbar, hero, section heading, deskripsi,
  CTA, dan footer) harus menggunakan Bahasa Indonesia yang konsisten, kecuali
  istilah produk/teknis yang merupakan nama baku.
- **BRD-001**: Warna visual harus mengikuti konstanta aktual di
  `lib/core/theme/islamic_colors.dart`: `deepTeal #075B5E`,
  `primaryTeal #0E9296`, `lightTeal #1CC0C5`, `goldAmber #D4A012`,
  `lightGold #E8C547`, `darkBackground #041E1E`, `surfaceDark #082E2E`,
  `surfaceLight #0F4343`, `textPrimary #F5F5F5`,
  `textSecondary #B0C9C6`, dan `textMuted #739A95`.
- **BRD-002**: Logo utama menggunakan aset MKTV yang sudah ada di repo:
  `assets/images/mktv_icon_large_transparent.png`.
- **BRD-003**: Custom CSS landing page harus mengekspos warna branding sebagai
  CSS variables di `:root` agar mudah diaudit dan disesuaikan.
- **CON-001**: Tidak menggunakan framework frontend berat seperti React, Vue,
  Angular, Next.js, atau Flutter Web untuk v1.
- **CON-002**: Tidak menambahkan npm dependency atau build pipeline untuk v1.
- **CON-003**: Screenshot tidak diunduh otomatis dari Play Store; user akan
  menyediakan file gambar final.
- **CON-005**: Format screenshot final dikunci ke PNG sesuai keputusan revisi
  implementasi, dan seluruh referensi file mengikuti ekstensi `.png`.
- **CON-004**: Bootstrap dan Bootstrap Icons CDN membutuhkan koneksi internet
  ketika halaman dibuka; constraint ini diterima untuk v1 karena landing page
  ditujukan sebagai website publik.
- **GUD-001**: Desain harus modern, ringan, mudah dibaca, dan cocok untuk target
  DKM/pengurus masjid.
- **GUD-002**: Hindari copywriting yang terlalu teknis; fitur teknis harus
  dijelaskan sebagai manfaat praktis.
- **GUD-003**: Gunakan section pendek dan mudah dipindai, bukan halaman teks
  panjang.
- **GUD-004**: Gunakan image loading lazy untuk screenshot.
- **GUD-005**: Semua gambar harus memiliki `alt` text yang deskriptif.
- **PAT-001**: Struktur file dibuat sederhana: `index.html`,
  `assets/css/styles.css`, `assets/js/main.js`, dan `assets/img/`.

## 2. Implementation Steps

### Implementation Phase 1

- **GOAL-001**: Menyiapkan struktur landing page statis.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat folder `landingpage/assets/css/`, `landingpage/assets/js/`, `landingpage/assets/img/`, dan `landingpage/assets/img/screenshots/`. | ✅ | 2026-05-12 |
| TASK-002 | Buat `landingpage/index.html` dengan HTML5 document, `lang="id"`, meta charset, meta viewport, title SEO, meta description, Bootstrap 5.3.8 CDN CSS (`https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css`), Bootstrap Icons 1.13.1 CDN (`https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css`), custom stylesheet, dan Bootstrap 5.3.8 bundle JS (`https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js`). | ✅ | 2026-05-12 |
| TASK-003 | Buat `landingpage/assets/css/styles.css` untuk custom theme warna Miqotul Khoir TV dan responsive polish. | ✅ | 2026-05-12 |
| TASK-004 | Di `landingpage/assets/css/styles.css`, definisikan CSS variables `--mkt-deep-teal`, `--mkt-primary-teal`, `--mkt-light-teal`, `--mkt-gold`, `--mkt-light-gold`, `--mkt-dark-bg`, `--mkt-surface-dark`, `--mkt-surface-light`, `--mkt-text-primary`, `--mkt-text-secondary`, dan `--mkt-text-muted` sesuai nilai di BRD-001. | ✅ | 2026-05-12 |
| TASK-005 | Buat `landingpage/assets/js/main.js` untuk interaksi ringan: navbar scroll state, smooth anchor behavior, dan fallback kecil tanpa framework. | ✅ | 2026-05-12 |
| TASK-006 | Salin logo dari `assets/images/mktv_icon_large_transparent.png` ke `landingpage/assets/img/logo-mktv.png`. | ✅ | 2026-05-12 |

### Implementation Phase 2

- **GOAL-002**: Membuat struktur konten dan copywriting marketing landing page.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | Implementasikan navbar sticky dengan logo, nama produk, anchor link ke section utama, dan tombol "Download di Google Play". | ✅ | 2026-05-12 |
| TASK-008 | Implementasikan hero section dengan headline "Miqotul Khoir TV Masjid", subheadline aplikasi jam masjid digital untuk Android TV, badge "100% Offline", badge "Kemenag SIHAT", dan CTA Google Play. | ✅ | 2026-05-12 |
| TASK-009 | Implementasikan hero visual menggunakan mockup TV/browser frame yang menampilkan screenshot utama jika tersedia, atau placeholder branded jika screenshot belum tersedia. | ✅ | 2026-05-12 |
| TASK-010 | Implementasikan section "Kenapa Miqotul Khoir TV?" berisi 3 manfaat utama: akurat tanpa internet, mudah untuk DKM, dan nyaman dibaca jamaah dari jarak jauh. | ✅ | 2026-05-12 |
| TASK-011 | Implementasikan section fitur utama dalam card/grid: jadwal sholat offline, koreksi DPL, Jum'at, D-Pad, running text, alarm, kas masjid, kata mutiara, mode hemat daya, dan slideshow pengumuman. | ✅ | 2026-05-12 |
| TASK-012 | Implementasikan section "Tampilan Aplikasi" sebagai Bootstrap responsive grid (`row row-cols-1 row-cols-md-2 row-cols-xl-3 g-4`) untuk screenshot dari `landingpage/assets/img/screenshots/`; jangan gunakan carousel pada v1 agar semua screenshot dapat dipindai langsung. | ✅ | 2026-05-12 |
| TASK-013 | Implementasikan section "Cara Kerja" berisi 3 langkah: pasang di Android TV, setup identitas dan lokasi masjid, lalu aplikasi tampil otomatis setiap hari. | ✅ | 2026-05-12 |
| TASK-014 | Implementasikan CTA akhir berisi ringkasan manfaat dan tombol menuju Google Play Store. | ✅ | 2026-05-12 |
| TASK-015 | Implementasikan footer berisi nama developer, email support `gulajava.mini@gmail.com`, link privacy policy `https://gulajavaministudio.github.io`, dan link Google Play. | ✅ | 2026-05-12 |
| TASK-015A | Lakukan audit copywriting akhir untuk memastikan semua copy UI utama konsisten berbahasa Indonesia sesuai REQ-004 dan REQ-011. | ✅ | 2026-05-12 |

### Implementation Phase 3

- **GOAL-003**: Menyiapkan aset screenshot dan fallback visual.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-016 | Buat `landingpage/assets/img/screenshots/README.md` yang menjelaskan screenshot user-provided dan daftar nama file yang direkomendasikan: `standby.png`, `pre-adzan.png`, `iqomah.png`, `settings.png`, `wisdom.png`, dan `slideshow.png`. | ✅ | 2026-05-12 |
| TASK-017 | Jika screenshot belum tersedia, tampilkan placeholder visual yang jelas dan tidak merusak layout. | ✅ | 2026-05-12 |
| TASK-018 | Pastikan semua screenshot dirender dalam container 16:9 dengan `object-fit: contain` agar UI aplikasi tidak terpotong. | ✅ | 2026-05-12 |
| TASK-019 | Tambahkan `loading="lazy"` dan `alt` deskriptif pada semua screenshot. | ✅ | 2026-05-12 |

### Implementation Phase 4

- **GOAL-004**: Verifikasi visual, aksesibilitas, dan kesiapan deploy.

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-020 | Buka `landingpage/index.html` di browser lokal dan pastikan halaman render tanpa error. | ✅ | 2026-05-12 |
| TASK-021 | Verifikasi layout responsive pada viewport 375px, 768px, 1366px, dan 1920px. | ✅ | 2026-05-12 |
| TASK-022 | Verifikasi semua CTA membuka link Google Play yang benar. | ✅ | 2026-05-12 |
| TASK-023 | Verifikasi link privacy policy membuka `https://gulajavaministudio.github.io`. | ✅ | 2026-05-12 |
| TASK-024 | Verifikasi tidak ada asset 404 dari file lokal yang dirujuk. | ✅ | 2026-05-12 |
| TASK-025 | Verifikasi kontras teks terhadap background hijau gelap cukup terbaca. | ✅ | 2026-05-12 |
| TASK-026 | Verifikasi title, meta description, heading hierarchy, dan alt text untuk SEO dasar. | ✅ | 2026-05-12 |

## 3. Alternatives

- **ALT-001**: Bootstrap + Vite. Ditolak untuk v1 karena menambah build pipeline
  dan dependency npm yang belum diperlukan untuk landing page sederhana.
- **ALT-002**: Mengunduh screenshot otomatis dari Google Play Store. Ditolak
  karena user memilih screenshot disediakan manual dan screenshot publik Play
  Store dapat berubah.
- **ALT-003**: Membuat landing page dengan Flutter Web. Ditolak karena scope
  lebih berat untuk halaman marketing statis dan tidak diperlukan untuk v1.
- **ALT-004**: Menggunakan Tailwind CSS. Ditolak karena user meminta Bootstrap
  CSS terbaru.
- **ALT-005**: Membuat multi-page website. Ditolak untuk v1 karena kebutuhan
  utama adalah satu landing page produk yang mudah direview dan dideploy.

## 4. Dependencies

- **DEP-001**: Bootstrap v5.3.8 via jsDelivr CDN:
  `https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css`
  dan
  `https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js`.
- **DEP-002**: Bootstrap Icons v1.13.1 via jsDelivr CDN:
  `https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css`.
- **DEP-003**: Logo lokal `assets/images/mktv_icon_large_transparent.png`.
- **DEP-004**: Screenshot user-provided di
  `landingpage/assets/img/screenshots/` dengan file final:
  `standby.png`, `pre-adzan.png`, `iqomah.png`, `settings.png`,
  `wisdom.png`, dan `slideshow.png`.
- **DEP-005**: Konten produk dari `README.md`,
  `Product_Requirement_Document.md`, dan listing Google Play Store.
- **DEP-006**: Browser modern yang mendukung CSS variables, responsive layout,
  dan Bootstrap 5.

## 5. Files

- **FILE-001**: `landingpage/index.html` — halaman utama landing page.
- **FILE-002**: `landingpage/assets/css/styles.css` — custom theme, responsive
  polish, dan visual branding.
- **FILE-003**: `landingpage/assets/js/main.js` — interaksi ringan untuk navbar
  dan smooth scroll.
- **FILE-004**: `landingpage/assets/img/logo-mktv.png` — logo produk untuk
  landing page.
- **FILE-005**: `landingpage/assets/img/screenshots/` — folder screenshot
  aplikasi dari user.
- **FILE-006**: `landingpage/assets/img/screenshots/README.md` — instruksi aset
  screenshot.

## 6. Testing

- **TEST-001**: Buka `landingpage/index.html` di browser dan pastikan halaman
  render tanpa error visual mayor.
- **TEST-002**: Verifikasi responsive layout pada viewport 375px, 768px, 1366px,
  dan 1920px.
- **TEST-003**: Verifikasi responsive grid screenshot tidak overflow dan tetap
  mempertahankan area gambar 16:9.
- **TEST-004**: Verifikasi seluruh tombol CTA mengarah ke Google Play Store
  dengan package ID `gulajava.mini.miqotul_khoir_tv`.
- **TEST-005**: Verifikasi footer privacy policy mengarah ke
  `https://gulajavaministudio.github.io`.
- **TEST-006**: Verifikasi semua aset lokal yang dirujuk tersedia dan tidak
  menghasilkan 404.
- **TEST-007**: Verifikasi semua gambar memiliki `alt` text yang deskriptif.
- **TEST-008**: Verifikasi heading hierarchy hanya memiliki satu `h1` utama dan
  section berikutnya memakai `h2`/`h3` secara terstruktur.
- **TEST-009**: Verifikasi kontras teks pada background gelap dan card teal
  tetap nyaman dibaca.
- **TEST-010**: Verifikasi halaman tetap usable saat screenshot belum tersedia
  dengan fallback placeholder.
- **TEST-011**: Verifikasi seluruh copy UI utama (navbar, hero, heading section,
  deskripsi, CTA, footer) konsisten berbahasa Indonesia sesuai REQ-004 dan
  REQ-011.
- **TEST-012**: Final quick visual QA memastikan screenshot section tetap rapi
  pada desktop dan mobile breakpoint, tidak terjadi horizontal overflow, serta
  tinggi seluruh kartu screenshot konsisten.

## 6A. Final QA Report (2026-05-12)

- **QA-001 (Asset Readiness)**: Keenam screenshot final PNG terverifikasi
  tersedia di folder `landingpage/assets/img/screenshots/`.
- **QA-002 (Screenshot Activation)**: Semua placeholder pada section tampilan
  berhasil diganti menjadi elemen `<img>` aktual dengan `alt`, `width`,
  `height`, dan `loading="lazy"` (hero memakai `loading="eager"`).
- **QA-003 (Visual Consistency Fix)**: Ditemukan rasio file screenshot campuran
  (mayoritas 16:10, sebagian 16:9) yang menyebabkan tinggi kartu tidak seragam.
  Mitigasi implementasi: semua gambar screenshot grid dibungkus
  `.screenshot-container` berasio tetap 16:9 dengan `object-fit: contain`.
- **QA-004 (Layout Stability)**: Setelah mitigasi, tinggi seluruh figure pada
  screenshot grid menjadi konsisten dan tidak ditemukan overflow horizontal.
- **QA-005 (Responsiveness Validation)**: Struktur responsif tervalidasi melalui
  kombinasi kelas Bootstrap grid (`row-cols-1`, `row-cols-md-2`,
  `row-cols-xl-3`) dan media query custom di stylesheet.

## 7. Risks & Assumptions

- **RISK-001**: Screenshot belum tersedia saat implementasi. Mitigasi: siapkan
  placeholder dan README aset screenshot.
- **RISK-001 Status**: **Closed** — screenshot final PNG sudah tersedia dan
  telah terpasang di halaman.
- **RISK-002**: Bootstrap CDN membutuhkan internet saat membuka landing page.
  Mitigasi: untuk v1 diterima karena ini website publik; jika perlu offline
  preview penuh, Bootstrap dapat di-vendor pada plan terpisah.
- **RISK-003**: README lokal belum mencantumkan semua fitur terbaru secara penuh,
  misalnya slideshow pengumuman. Mitigasi: copy fitur diselaraskan dengan kode
  aktual dan listing Google Play.
- **RISK-004**: Screenshot dengan rasio berbeda dapat terlihat terlalu kecil
  atau kosong di frame 16:9. Mitigasi: gunakan `object-fit: contain` dan
  background frame gelap.
- **RISK-004 Status**: **Mitigated** — diterapkan wrapper
  `.screenshot-container` rasio 16:9 agar tinggi kartu seragam meskipun rasio
  file sumber berbeda.
- **ASSUMPTION-001**: User akan menyediakan screenshot final sebelum landing
  page dipublikasikan.
- **ASSUMPTION-002**: Landing page dipakai untuk publik Indonesia, sehingga
  bahasa utama adalah Bahasa Indonesia.
- **ASSUMPTION-003**: Implementasi v1 tidak membutuhkan form kontak, analytics,
  CMS, atau backend.
- **ASSUMPTION-004**: Link Google Play Store yang digunakan tetap:
  `https://play.google.com/store/apps/details?id=gulajava.mini.miqotul_khoir_tv`.

## 8. Related Specifications / Further Reading

- [README.md](../README.md)
- [Product Requirement Document](../Product_Requirement_Document.md)
- [Google Play Store - Miqotul Khoir TV Masjid](https://play.google.com/store/apps/details?id=gulajava.mini.miqotul_khoir_tv)
- [Bootstrap v5.3.8 Documentation](https://getbootstrap.com/)
- [UI/UX Guide](../docs/UI_UX_GUIDE.md)