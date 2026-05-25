---
goal: "Integrasi Fitur Jadwal Imam Sholat Berjamaah ke Landing Page Miqotul Khoir TV"
version: "1.2"
date_created: "2026-05-25"
last_updated: "2026-05-25"
owner: "MKT Dev Team"
status: "Completed"
tags: [feature, landing-page, marketing, imam-schedule, bootstrap, website]
---

# Introduction

<!-- markdownlint-disable -->

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Plan ini mendefinisikan perubahan terstruktur pada landing page statis produk
Miqotul Khoir TV Masjid di folder landingpage/ agar fitur Jadwal Imam Sholat
Berjamaah tampil sebagai bagian dari narasi produk, daftar fitur, dan bukti
visual aplikasi. Tujuan utamanya adalah memastikan pengunjung memahami bahwa
produk tidak hanya menampilkan jadwal sholat, tetapi juga dapat menampilkan
jadwal imam harian secara periodik di layar utama, termasuk dukungan khusus
untuk hari Jumat dengan pemisahan Khatib dan Imam.

Plan ini tidak mencakup implementasi kode aplikasi Flutter karena fitur produk
sudah selesai di layer aplikasi. Scope plan ini terbatas pada representasi
fitur di landing page: SEO copy, hero messaging, feature grid, screenshot
gallery, aset gambar, dan final visual QA sebelum dipublikasikan.

Status implementasi: seluruh perubahan pada landing page sudah selesai
diterapkan per 2026-05-25. Galeri screenshot diperluas dari 6 menjadi 8 item;
kedua aset `imam-schedule-weekday.png` dan `imam-schedule-jumat.png` sudah
tersedia di repo dan sudah dipasang sebagai elemen `<img>` aktual menggantikan
placeholder sementara. Semua task dan verifikasi QA telah lolos.

## 1. Requirements & Constraints

- **REQ-001**: Landing page harus menampilkan fitur Jadwal Imam Sholat
  Berjamaah sebagai kemampuan produk yang sudah tersedia, bukan roadmap atau
  coming soon.
- **REQ-002**: Copy fitur harus menjelaskan manfaat praktis untuk DKM dan
  jamaah, bukan detail internal state machine.
- **REQ-003**: Narasi landing page harus menyebut bahwa jadwal imam yang
  ditampilkan adalah jadwal hari ini dan tampil periodik pada layar utama.
- **REQ-004**: Copy fitur harus menyebut dukungan khusus hari Jumat, yaitu slot
  Dzuhur diganti menjadi Jumat dengan pemisahan Khatib dan Imam.
- **REQ-005**: Landing page harus tetap berbahasa Indonesia secara konsisten.
- **REQ-006**: Integrasi fitur harus mempertahankan struktur landing page saat
  ini: hero, value proposition, feature grid, screenshot gallery, how-it-works,
  dan CTA akhir.
- **REQ-007**: Fitur Jadwal Imam harus muncul minimal di tiga tempat: product
  messaging, daftar fitur, dan bukti visual screenshot.
- **REQ-008**: Screenshot yang ditambahkan untuk fitur Jadwal Imam harus
  menggunakan aset nyata dari aplikasi, bukan mockup ilustratif generik.
- **REQ-009**: Landing page tidak boleh memberi kesan bahwa fitur ini butuh
  internet atau sistem backend terpisah.
- **REQ-010**: Jika screenshot baru belum tersedia saat implementasi, struktur
  HTML harus tetap stabil tanpa merusak grid tampilan aplikasi.
- **REQ-011**: Copy marketing harus tetap sinkron dengan perilaku fitur aktual
  di aplikasi, termasuk dukungan lock jadwal sebagai fitur admin-only dan refresh
  otomatis setelah perubahan data.
- **REQ-012**: Penambahan fitur ini tidak boleh menghapus fitur existing yang
  sudah dipromosikan pada landing page saat ini.
- **SEC-001**: Tidak ada klaim yang menyiratkan sinkronisasi cloud, dashboard
  web, atau pengelolaan jarak jauh karena fitur aktual bekerja offline-first.
- **SEC-002**: Aset screenshot yang dipublikasikan tidak boleh menampilkan data
  sensitif non-demo.
- **CON-001**: Landing page tetap berupa website statis berbasis HTML, CSS, dan
  JavaScript ringan tanpa build pipeline baru.
- **CON-002**: Implementasi visual harus memanfaatkan komponen existing sejauh
  mungkin, terutama `.card-mkt`, `.section-mkt`, `.section-mkt-alt`, dan
  `.screenshot-container`.
- **CON-003**: Bootstrap 5.3.8 CDN dan Bootstrap Icons 1.13.1 tetap dipakai,
  tanpa mengganti stack frontend landing page.
- **CON-004**: Struktur screenshot saat ini sudah menggunakan enam gambar aktif;
  integrasi fitur baru harus mempertimbangkan apakah grid diperluas atau satu
  gambar existing diganti, tetapi keputusan akhir harus eksplisit.
- **CON-005**: Plan ini hanya mencakup landing page di folder landingpage/ dan
  tidak mengubah halaman aplikasi Flutter.
- **GUD-001**: Copy harus menonjolkan manfaat operasional masjid: jamaah tahu
  imam hari ini, pengurus mudah mengatur rotasi, dan jadwal Jumat lebih jelas.
- **GUD-002**: Detail teknis seperti `ImamScheduleState`, `DisplayStateCubit`,
  atau prioritas evaluator tidak ditampilkan di landing page; detail tersebut
  hanya menjadi dasar akurasi copy internal tim.
- **GUD-003**: Posisi feature card Jadwal Imam sebaiknya berdekatan dengan kartu
  Penanganan Sholat Jum'at agar konteks penggunaannya mudah dipahami.
- **GUD-004**: Jika screenshot weekday dan Jumat sama-sama tersedia, keduanya
  sebaiknya ditampilkan untuk memperjelas value fitur.
- **GUD-005**: Jangan menambahkan section baru di navbar kecuali benar-benar
  diperlukan; prioritaskan integrasi ke section yang sudah ada untuk menjaga
  halaman tetap ringkas.
- **PAT-001**: Ikuti gaya copy pada landing page existing: headline singkat,
  manfaat praktis, dan paragraf pendek yang mudah dipindai.
- **PAT-002**: Ikuti pola caption screenshot existing: satu kalimat singkat yang
  menjelaskan konteks layar dan manfaatnya.
- **PAT-003**: Ikuti pola feature card existing di `landingpage/index.html`:
  ikon Bootstrap, heading pendek, dan deskripsi sekitar 1–2 kalimat.
- **PAT-004**: Ikuti naming convention aset screenshot existing di folder
  `landingpage/assets/img/screenshots/` yang memakai nama file lowercase dengan
  pemisah hyphen bila diperlukan.

## 2. Implementation Steps

### Implementation Phase 1

- **GOAL-001**: Menyelaraskan positioning produk dan SEO copy landing page agar
  fitur Jadwal Imam masuk ke narasi utama produk.

| Task     | Description                                                                                                                                                                                                                      | Status | Date       |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ---------- |
| TASK-001 | Di `landingpage/index.html`, perbarui `<title>`, meta description, Open Graph description, Twitter description, dan meta keywords agar manfaat produk mencakup jadwal imam berjamaah selain jadwal sholat offline.               | ✅      | 2026-05-25 |
| TASK-002 | Di section hero `#beranda` pada `landingpage/index.html`, revisi paragraf lead agar secara eksplisit menyebut kemampuan menampilkan jadwal imam harian dan informasi ibadah berjamaah di Android TV.                             | ✅      | 2026-05-25 |
| TASK-003 | Audit badge hero existing dan tentukan apakah perlu menambah satu badge baru terkait “Jadwal Imam Harian” atau cukup memperkuat subheadline tanpa badge tambahan. Keputusan ini harus eksplisit agar implementasi tidak melebar. | ✅      | 2026-05-25 |

### Implementation Phase 2

- **GOAL-002**: Menambahkan representasi fitur Jadwal Imam ke daftar fitur utama
  tanpa merusak struktur visual landing page yang sudah ada.

| Task     | Description                                                                                                                                                                                                 | Status | Date       |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ---------- |
| TASK-004 | Di section `#fitur` pada `landingpage/index.html`, tambahkan satu feature card baru berjudul “Jadwal Imam Sholat Berjamaah” menggunakan komponen `.card-mkt` dan ikon Bootstrap yang relevan.               | ✅      | 2026-05-25 |
| TASK-005 | Tempatkan feature card baru di posisi yang berdekatan dengan card “Penanganan Sholat Jum'at” agar alur pemahaman pengguna runtut: jadwal sholat → Jumat → jadwal imam.                                      | ✅      | 2026-05-25 |
| TASK-006 | Tulis deskripsi feature card yang menjelaskan tiga manfaat inti: menampilkan imam hari ini, dukungan khusus Jumat dengan Khatib dan Imam terpisah, dan membantu jamaah mengetahui petugas sholat berjamaah. | ✅      | 2026-05-25 |
| TASK-007 | Audit ulang seluruh feature grid setelah penambahan card baru untuk memastikan jumlah kolom dan ritme visual tetap seimbang pada breakpoint mobile, tablet, desktop, dan layar besar.                       | ✅      | 2026-05-25 |

### Implementation Phase 3

- **GOAL-003**: Menambahkan bukti visual fitur Jadwal Imam pada galeri screenshot
  dan mendefinisikan kebutuhan aset gambar yang diperlukan.

| Task     | Description                                                                                                                                                                                                                                   | Status | Date       |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ---------- |
| TASK-008 | Di `landingpage/assets/img/screenshots/README.md`, tambahkan daftar aset screenshot baru yang dibutuhkan untuk fitur imam, minimal `imam-schedule-weekday.png` dan `imam-schedule-jumat.png`, lengkap dengan deskripsi konteks masing-masing. | ✅      | 2026-05-25 |
| TASK-009 | Di section `#tampilan` pada `landingpage/index.html`, tambahkan screenshot fitur Jadwal Imam hari biasa dengan caption yang menegaskan tampilan imam sholat hari ini pada layar utama.                                                        | ✅      | 2026-05-25 |
| TASK-010 | Di section `#tampilan` pada `landingpage/index.html`, tambahkan screenshot fitur Jadwal Imam hari Jumat dengan caption yang menegaskan pemisahan Khatib dan Imam untuk sholat Jumat.                                                          | ✅      | 2026-05-25 |
| TASK-011 | Tentukan strategi grid screenshot final: memperluas galeri dari 6 menjadi 8 item tanpa carousel. Jangan mengganti screenshot existing karena setiap gambar existing masih mewakili fitur utama lain yang relevan.                             | ✅      | 2026-05-25 |
| TASK-012 | Jika salah satu screenshot imam belum tersedia, siapkan fallback sementara berbasis struktur `.screenshot-container` agar grid tetap stabil dan file path tidak menghasilkan 404 saat review internal.                                        | ✅      | 2026-05-25 |

### Implementation Phase 4

- **GOAL-004**: Menyelaraskan copy pendukung dan CTA agar fitur Jadwal Imam tidak
  terasa sebagai tambahan yang terisolasi.

| Task     | Description                                                                                                                                                                                   | Status | Date       |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ---------- |
| TASK-013 | Di section `#kenapa` pada `landingpage/index.html`, evaluasi apakah salah satu benefit card perlu diperluas copy-nya agar menyinggung keterbacaan informasi imam oleh jamaah dari jarak jauh. | ✅      | 2026-05-25 |
| TASK-014 | Di section `#cara-kerja`, revisi langkah ke-3 agar tidak hanya menyebut jadwal sholat otomatis, tetapi juga rotasi tampilan informasi ibadah seperti jadwal imam bila fitur diaktifkan admin. | ✅      | 2026-05-25 |
| TASK-015 | Di section CTA akhir, perbarui paragraf ringkasan agar value proposition produk mencakup jadwal imam dan informasi berjamaah, tanpa membuat kalimat terlalu panjang atau teknis.              | ✅      | 2026-05-25 |

### Implementation Phase 5

- **GOAL-005**: Menjaga konsistensi visual, aksesibilitas, dan akurasi pesan
  setelah fitur Jadwal Imam masuk ke landing page.

| Task     | Description                                                                                                                                                                                                                                       | Status | Date       |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | ---------- |
| TASK-016 | Verifikasi seluruh copy baru di `landingpage/index.html` konsisten dengan perilaku fitur aktual pada `plan/feature-imam-schedule-1.md`, terutama soal tampilan periodik, dukungan Jumat, sifat offline, dan konteks admin-only untuk lock jadwal. | ✅      | 2026-05-25 |
| TASK-017 | Verifikasi penambahan screenshot imam tidak menyebabkan tinggi figure tidak seragam, horizontal overflow, atau ritme grid yang terasa timpang pada viewport 375px, 768px, 1366px, dan 1920px.                                                     | ✅      | 2026-05-25 |
| TASK-018 | Verifikasi seluruh screenshot imam baru memiliki `alt`, `width`, `height`, dan `loading="lazy"` yang konsisten dengan pola screenshot existing.                                                                                                   | ✅      | 2026-05-25 |
| TASK-019 | Verifikasi tidak ada klaim marketing yang bertentangan dengan fitur aktual, misalnya sinkronisasi cloud, dashboard web, atau penjadwalan multi-cabang yang tidak ada di produk.                                                                   | ✅      | 2026-05-25 |
| TASK-020 | Final visual QA di browser lokal untuk memastikan landing page tetap terasa ringkas, tidak terlalu padat, dan fitur imam tampil sebagai nilai tambah yang jelas namun tidak mendominasi seluruh halaman.                                          | ✅      | 2026-05-25 |

## 3. Alternatives

- **ALT-001**: Hanya menambah satu feature card tanpa screenshot baru. Ditolak
  karena fitur Jadwal Imam sangat visual dan akan terasa lemah bila tidak
  didukung bukti tampilan nyata.
- **ALT-002**: Mengganti salah satu screenshot existing dengan screenshot Jadwal
  Imam. Ditolak karena akan mengurangi representasi fitur lain yang juga sudah
  penting untuk komunikasi marketing produk.
- **ALT-003**: Menambahkan section navbar baru khusus “Jadwal Imam”. Ditolak
  untuk v1 integrasi karena informasi masih bisa dimasukkan ke struktur existing
  tanpa menambah kompleksitas navigasi.
- **ALT-004**: Menjelaskan Jadwal Imam dengan istilah teknis internal seperti
  state machine atau cache refresh. Ditolak karena landing page ditujukan untuk
  audiens DKM dan pengurus masjid, bukan pembaca teknis internal.
- **ALT-005**: Menunggu implementasi code selesai lalu baru menyiapkan plan.
  Ditolak karena user secara eksplisit meminta dokumen planning terlebih dahulu
  untuk dibaca dan direview sebelum coding dimulai.

## 4. Dependencies

- **DEP-001**: Struktur landing page existing di `landingpage/index.html`.
- **DEP-002**: Styling existing di `landingpage/assets/css/styles.css`.
- **DEP-003**: Konvensi aset screenshot di
  `landingpage/assets/img/screenshots/README.md`.
- **DEP-004**: Dokumen fitur produk di `plan/feature-imam-schedule-1.md` sebagai
  sumber kebenaran perilaku fitur yang dipromosikan.
- **DEP-005**: Bootstrap v5.3.8 dan Bootstrap Icons v1.13.1 yang sudah dipakai
  landing page saat ini.
- **DEP-006**: Aset screenshot nyata fitur imam dari aplikasi, minimal satu
  tampilan hari biasa dan satu tampilan hari Jumat. Tersedia di repo sejak
  2026-05-25 dan sudah dipasang sebagai `<img>` aktual di `landingpage/index.html`.

## 5. Files

- **FILE-001**: `landingpage/index.html` — update SEO, hero, feature grid,
  screenshot gallery, how-it-works, dan CTA.
- **FILE-002**: `landingpage/assets/css/styles.css` — hanya jika dibutuhkan
  penyesuaian minor untuk ritme grid screenshot atau spacing setelah penambahan
  konten baru.
- **FILE-003**: `landingpage/assets/img/screenshots/README.md` — update daftar
  screenshot yang dibutuhkan untuk fitur Jadwal Imam.
- **FILE-004**: `landingpage/assets/img/screenshots/imam-schedule-weekday.png`
  — screenshot tampilan Jadwal Imam hari biasa.
- **FILE-005**: `landingpage/assets/img/screenshots/imam-schedule-jumat.png`
  — screenshot tampilan Jadwal Imam hari Jumat.
- **FILE-006**: `plan/feature-imam-schedule-1.md` — referensi perilaku fitur,
  bukan target implementasi.

## 6. Testing

- **TEST-001**: Verifikasi title, meta description, Open Graph description, dan
  Twitter description sudah menyebut kemampuan produk yang mencakup jadwal imam
  berjamaah.
- **TEST-002**: Verifikasi hero copy tetap ringkas, terbaca, dan tidak overflow
  pada mobile maupun desktop setelah manfaat Jadwal Imam ditambahkan.
- **TEST-003**: Verifikasi feature card “Jadwal Imam Sholat Berjamaah” tampil di
  section fitur dengan urutan yang logis dan gaya visual konsisten.
- **TEST-004**: Verifikasi deskripsi feature card tidak bertentangan dengan
  behavior aktual fitur di aplikasi.
- **TEST-005**: Verifikasi screenshot `imam-schedule-weekday.png` tampil dengan
  caption, `alt`, `width`, `height`, dan `loading="lazy"` yang benar.
- **TEST-006**: Verifikasi screenshot `imam-schedule-jumat.png` tampil dengan
  caption yang menjelaskan Khatib dan Imam terpisah.
- **TEST-007**: Verifikasi grid screenshot tetap rapi pada viewport 375px,
  768px, 1366px, dan 1920px setelah galeri diperluas menjadi delapan item.
- **TEST-008**: Verifikasi tidak ada asset 404 untuk screenshot imam baru.
- **TEST-009**: Verifikasi CTA dan how-it-works copy yang diperbarui masih
  terasa alami, tidak terlalu teknis, dan tidak menimbulkan klaim berlebihan.
- **TEST-010**: Final manual review memastikan fitur Jadwal Imam terlihat jelas
  sebagai nilai tambah produk tetapi tidak menggeser fokus utama landing page
  sebagai aplikasi jadwal sholat untuk Android TV.

## 6A. Current Implementation Sync Report (2026-05-25)

- **QA-001 (SEO Sync)**: Title, meta description, Open Graph, Twitter card,
  dan keywords di `landingpage/index.html` sudah diperbarui agar mencakup
  jadwal imam berjamaah.
- **QA-002 (Hero Decision)**: Hero copy sudah diperkuat untuk menyebut jadwal
  imam harian dan informasi berjamaah. Tidak ada badge hero baru yang
  ditambahkan agar area hero tetap ringkas.
- **QA-003 (Feature Card Sync)**: Feature card “Jadwal Imam Sholat
  Berjamaah” sudah ditambahkan berdekatan dengan card “Penanganan Sholat
  Jum'at” sesuai konteks penggunaan.
- **QA-004 (Gallery Strategy)**: Galeri screenshot diperluas dari 6 menjadi 8
  item tanpa mengganti screenshot existing.
- **QA-005 (Screenshots Live)**: Kedua slot screenshot imam di
  `landingpage/index.html` sudah menggunakan elemen `<img>` aktual yang
  mengarah ke `imam-schedule-weekday.png` dan `imam-schedule-jumat.png`.
  Placeholder sementara sudah dihapus.
- **QA-006 (README Sync)**: `landingpage/assets/img/screenshots/README.md`
  sudah diperbarui dengan kebutuhan aset `imam-schedule-weekday.png` dan
  `imam-schedule-jumat.png`.
- **QA-007 (Validation)**: Dokumen markdown yang diedit dan file HTML landing
  page lolos pengecekan error lokal; browser snapshot lokal juga mengonfirmasi
  copy baru, card fitur imam, dan galeri 8 item tampil di section yang benar.
- **QA-008 (All Tasks Closed)**: REQ-008, TASK-009, TASK-010, TASK-018,
  TEST-005, TEST-006, dan TEST-008 sudah ditutup. Kedua screenshot PNG tersedia
  di repo dan elemen `<img>` aktual sudah dipasang di landing page. Tidak ada
  pekerjaan yang tersisa.

## 7. Risks & Assumptions

- **RISK-001**: Screenshot fitur imam belum tersedia saat implementasi landing
  page dimulai. Mitigasi: tetapkan nama file final dari awal dan siapkan fallback
  layout yang tidak merusak grid saat review internal.
- **RISK-001 Status**: **Resolved** — kedua aset screenshot final sudah
  tersedia di repo dan dipasang sebagai `<img>` aktual di landing page.
- **RISK-002**: Copy marketing terlalu teknis dan sulit dipahami audiens DKM.
  Mitigasi: seluruh copy harus ditulis ulang dalam bahasa manfaat operasional.
- **RISK-003**: Penambahan dua screenshot baru membuat galeri terasa terlalu
  padat. Mitigasi: pertahankan grid Bootstrap existing dan evaluasi spacing serta
  ritme visual sebelum publish.
- **RISK-003 Status**: **Resolved** — galeri 8 item terkonfirmasi stabil
  pada review browser lokal, memanfaatkan grid existing dan `.screenshot-container`.
  Screenshot imam tampil selaras dengan 6 item existing.
- **RISK-004**: Klaim fitur lock jadwal bisa disalahpahami sebagai keamanan akun.
  Mitigasi: jelaskan hanya sebagai proteksi perubahan jadwal oleh admin, bukan
  sistem autentikasi kompleks.
- **ASSUMPTION-001**: Landing page existing tetap menjadi baseline visual dan
  tidak memerlukan redesign total untuk menampung fitur baru.
- **ASSUMPTION-002**: User menginginkan integrasi Jadwal Imam sebagai bagian dari
  halaman existing, bukan microsite atau halaman terpisah.
- **ASSUMPTION-003**: Dua screenshot imam adalah jumlah minimal yang cukup untuk
  menjelaskan perbedaan hari biasa dan hari Jumat.
- **ASSUMPTION-004**: Fitur Jadwal Imam yang dipromosikan di landing page sudah
  stabil di aplikasi dan tidak lagi bersifat eksperimental.

## 8. Related Specifications / Further Reading

- [plan/feature-imam-schedule-1.md](feature-imam-schedule-1.md)
- [plan/feature-landing-page-1.md](feature-landing-page-1.md)
- [landingpage/index.html](../landingpage/index.html)
- [landingpage/assets/img/screenshots/README.md](../landingpage/assets/img/screenshots/README.md)