---
goal: "Membuat Halaman Panduan Pengguna MKTV di Landing Page dengan Referensi Penggunaan, Navigasi, Menu Settings, dan Rencana Screenshot"
version: 1.0
date_created: 2026-05-25
last_updated: 2026-05-27
owner: "Gulajava Ministudio"
status: 'In Progress'
tags: [feature, landing-page, documentation, user-guide, support, website]
---

# Introduction

![Status: In Progress](https://img.shields.io/badge/status-In_Progress-yellow)

<!-- markdownlint-disable -->

Plan ini mendefinisikan implementasi halaman panduan pengguna khusus untuk
produk **Miqotul Khoir TV Masjid** pada website statis di folder
`landingpage/`. Panduan ditujukan untuk membantu user Google Play Store,
DKM, dan operator masjid memahami cara masuk ke pengaturan, menavigasi menu,
menjalankan setup awal, serta memahami fungsi setiap kategori settings pada
aplikasi.

Pendekatan yang dipilih adalah membuat halaman baru `landingpage/panduan.html`
yang terhubung dari `landingpage/index.html`. Halaman ini harus konsisten
secara visual dengan landing page yang sudah ada, memakai Bahasa Indonesia
baku yang natural, dan membedakan dengan jelas alur **Android TV + remote**
dan **HP/tablet touchscreen**. Semua konten harus diturunkan dari perilaku UI
aktual pada source code Flutter agar tidak terjadi mismatch dokumentasi.

## 1. Requirements & Constraints

- **REQ-001**: Panduan pengguna harus dibuat sebagai halaman statis terpisah di
  `landingpage/panduan.html`, bukan disisipkan sebagai section panjang di
  `landingpage/index.html`.
- **REQ-002**: `landingpage/index.html` harus menyediakan akses yang jelas ke
  halaman panduan melalui navbar, footer, dan minimal satu titik CTA sekunder
  yang mudah ditemukan user.
- **REQ-003**: Bahasa panduan harus menggunakan Bahasa Indonesia baku yang
  mengalir, natural, dan mudah dimengerti oleh user non-teknis.
- **REQ-004**: Konten panduan harus menjelaskan dua mode penggunaan secara
  terpisah dan eksplisit: **Android TV + remote** dan **HP/tablet
  touchscreen**.
- **REQ-005**: Bagian "Cara Masuk ke Pengaturan" harus sesuai dengan perilaku
  aktual di `lib/presentation/pages/main_display_page.dart`, yaitu:
  `OK/Enter/Select` membuka settings pada Android TV, dan `tap layar` dahulu
  untuk memunculkan ikon settings pada perangkat sentuh.
- **REQ-006**: Bagian "Keamanan / PIN" harus sesuai dengan perilaku aktual di
  `lib/presentation/pages/settings/pin_gate_page.dart`, termasuk kondisi bahwa
  halaman PIN dilewati jika PIN tidak aktif.
- **REQ-007**: Bagian "Setup Awal" harus mendokumentasikan 4 langkah wizard
  sesuai source file:
  `welcome_step.dart`, `identity_step.dart`, `location_step.dart`, dan
  `preview_step.dart`.
- **REQ-008**: Bagian "Navigasi Menu" harus menjelaskan pola split layout
  settings yang ada di
  `lib/presentation/pages/settings/settings_menu_page.dart`, yaitu daftar menu
  di panel kiri dan isi pengaturan di panel kanan.
- **REQ-009**: Panduan harus memuat referensi detail untuk seluruh kategori menu
  settings yang saat ini terdaftar di `SettingsMenuPage`, yaitu 15 kategori.
- **REQ-010**: Setiap kategori settings harus dijelaskan minimal dengan format
  konsisten: fungsi utama, pengaturan penting, kapan digunakan, dampak ke layar
  utama, dan catatan penggunaan perangkat.
- **REQ-011**: Konten kategori settings tidak boleh mengklaim fitur atau field
  yang tidak ada pada source code saat ini.
- **REQ-012**: Halaman panduan harus memiliki struktur yang mudah dipindai,
  minimal mencakup: ringkasan, daftar isi, akses settings, navigasi,
  setup awal, referensi settings, FAQ, dan screenshot pendukung.
- **REQ-013**: Halaman panduan harus dapat dipakai sebagai target link untuk
  balasan support Google Play Store.
- **REQ-014**: Head metadata halaman panduan harus dioptimalkan untuk SEO dasar,
  termasuk title, meta description, canonical yang benar, dan Open Graph yang
  relevan dengan halaman bantuan/panduan.
- **REQ-015**: Halaman panduan harus responsif untuk mobile, tablet, laptop,
  dan desktop besar tanpa build pipeline tambahan.
- **REQ-016**: Semua screenshot di halaman panduan harus memiliki `alt` text,
  `width`, `height`, dan `loading="lazy"` kecuali gambar hero yang dipilih
  untuk eager loading.
- **REQ-017**: Plan implementasi harus mendefinisikan kebutuhan screenshot
  secara eksplisit, termasuk daftar aset yang sudah ada dan aset baru yang
  masih harus dibuat.
- **REQ-018**: Penjelasan menu settings harus menggunakan istilah UI yang sama
  dengan label yang ada di aplikasi sesuai `_categories` di
  `settings_menu_page.dart`, yaitu: "Identitas Masjid",
  "Koreksi Waktu (Ihtiyat)", "Durasi Iqomah", "Pengaturan Dhuha",
  "Durasi Tampilan", "Alarm Tanda Waktu", "Running Text", "Keamanan (PIN)",
  "Informasi Kas", "Kata Mutiara", "Slideshow Pengumuman", "Jadwal Imam",
  "Mode Hemat Daya", "Reset Data", "Tentang Aplikasi".
- **SEC-001**: Screenshot yang menampilkan PIN tidak boleh memperlihatkan PIN
  nyata yang digunakan user produksi.
- **SEC-002**: Screenshot dan copy panduan tidak boleh mengandung data sensitif,
  data kas nyata, atau identitas masjid yang tidak diizinkan untuk dipublikasikan.
- **CON-001**: Implementasi halaman panduan harus tetap berada di stack website
  statis yang sudah dipakai sekarang: HTML + Bootstrap 5.3.8 + CSS/JS ringan.
- **CON-002**: Tidak boleh menambah framework frontend baru, package manager,
  atau build pipeline untuk fitur ini.
- **CON-003**: Perubahan fitur ini hanya menyentuh area `landingpage/` dan aset
  screenshot website; tidak ada perubahan perilaku runtime aplikasi Flutter.
- **CON-004**: Styling harus reuse token visual di
  `landingpage/assets/css/styles.css` agar branding tetap konsisten dengan
  landing page utama.
- **CON-005**: Semua narasi penggunaan harus diturunkan dari source code Flutter
  yang saat ini menjadi source-of-truth, khususnya file halaman utama,
  PIN gate, wizard setup, dan settings sections.
- **CON-006**: Existing screenshot marketing di folder
  `landingpage/assets/img/screenshots/` harus tetap kompatibel dan tidak boleh
  rusak referensinya.
- **GUD-001**: Konten harus dipisah jelas antara materi belajar langkah demi
  langkah (tutorial) dan materi referensi menu (reference-style) walaupun
  berada di satu halaman yang sama.
- **GUD-002**: Gunakan blok callout atau badge yang membedakan konteks
  "Android TV / Remote" dan "Touchscreen" agar user tidak salah mengikuti langkah.
- **GUD-003**: Untuk bagian settings yang panjang, gunakan subsection dan anchor
  link agar user dapat langsung lompat ke menu yang dicari.
- **GUD-004**: FAQ harus fokus pada masalah praktis user umum, bukan penjelasan
  internal teknis aplikasi.
- **PAT-001**: `landingpage/panduan.html` harus memakai pola visual yang sama
  dengan `landingpage/index.html`: navbar sticky, section spacing, warna, dan
  footer konsisten.
- **PAT-002**: Source-of-truth perilaku akses settings berasal dari method
  `_showSettingsIcon()`, `_openSettings()`, dan blok `onKeyEvent` di
  `lib/presentation/pages/main_display_page.dart`.
- **PAT-003**: Source-of-truth struktur menu settings berasal dari list
  `_categories` dan `_sections` di
  `lib/presentation/pages/settings/settings_menu_page.dart`.

### Screenshot Requirement Matrix

| ID      | File yang Dibutuhkan               | Status Awal | Lokasi Target                               | Digunakan Untuk                                     |
| ------- | ---------------------------------- | ----------- | ------------------------------------------- | --------------------------------------------------- |
| IMG-001 | `standby.png`                      | Sudah ada   | `landingpage/assets/img/screenshots/`       | Tampilan layar utama / pembuka panduan              |
| IMG-002 | `guide/home-settings-overlay.png`  | Baru        | `landingpage/assets/img/screenshots/guide/` | Menjelaskan ikon settings setelah layar disentuh    |
| IMG-003 | `settings.png`                     | Sudah ada   | `landingpage/assets/img/screenshots/`       | Gambaran umum struktur menu settings                |
| IMG-004 | `guide/pin-gate.png`               | Baru        | `landingpage/assets/img/screenshots/guide/` | Menjelaskan halaman PIN sebelum settings            |
| IMG-005 | `guide/setup-welcome.png`          | Baru        | `landingpage/assets/img/screenshots/guide/` | Langkah 1 setup wizard                              |
| IMG-006 | `guide/setup-identity.png`         | Baru        | `landingpage/assets/img/screenshots/guide/` | Langkah 2 isi identitas masjid                      |
| IMG-007 | `guide/setup-location.png`         | Baru        | `landingpage/assets/img/screenshots/guide/` | Langkah 3 pilih provinsi dan kota                   |
| IMG-008 | `guide/setup-preview.png`          | Baru        | `landingpage/assets/img/screenshots/guide/` | Langkah 4 konfirmasi dan simpan                     |
| IMG-009 | `guide/settings-identity.png`      | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu Identitas Masjid                     |
| IMG-010 | `guide/settings-ihtiyat.png`       | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu Koreksi Waktu                        |
| IMG-011 | `guide/settings-running-text.png`  | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu Running Text                         |
| IMG-012 | `guide/settings-security.png`      | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu PIN                                  |
| IMG-013 | `guide/settings-treasury.png`      | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu Informasi Kas                        |
| IMG-014 | `guide/settings-wisdom-quote.png`  | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu Kata Mutiara                         |
| IMG-015 | `guide/settings-slideshow.png`     | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu Slideshow Pengumuman                 |
| IMG-016 | `guide/settings-imam-schedule.png` | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu Jadwal Imam                          |
| IMG-017 | `guide/settings-midnight-mode.png` | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu Mode Hemat Daya                      |
| IMG-018 | `guide/settings-reset-data.png`    | Baru        | `landingpage/assets/img/screenshots/guide/` | Referensi menu Reset Data                           |
| IMG-019 | `wisdom.png`                       | Sudah ada   | `landingpage/assets/img/screenshots/`       | Contoh hasil tayang Kata Mutiara di layar utama     |
| IMG-020 | `slideshow.png`                    | Sudah ada   | `landingpage/assets/img/screenshots/`       | Contoh hasil tayang slideshow di layar utama        |
| IMG-021 | `imam-schedule-weekday.png`        | Sudah ada   | `landingpage/assets/img/screenshots/`       | Contoh hasil tayang jadwal imam hari biasa          |
| IMG-022 | `imam-schedule-jumat.png`          | Sudah ada   | `landingpage/assets/img/screenshots/`       | Contoh hasil tayang jadwal imam hari Jumat          |
| IMG-023 | `iqomah.png`                       | Sudah ada   | `landingpage/assets/img/screenshots/`       | Contoh tampilan layar utama saat iqomah berlangsung |
| IMG-024 | `pre-adzan.png`                    | Sudah ada   | `landingpage/assets/img/screenshots/`       | Contoh tampilan layar saat alarm pre-adzan aktif    |

## 2. Implementation Steps

### Implementation Phase 1

- GOAL-001: Menetapkan arsitektur konten, source-of-truth, dan inventaris aset
  untuk halaman panduan pengguna.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                              | Completed | Date       |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-001 | Buat dokumen peta konten internal untuk `landingpage/panduan.html` berdasarkan source-of-truth berikut: `lib/presentation/pages/main_display_page.dart`, `lib/presentation/pages/settings/pin_gate_page.dart`, `lib/presentation/pages/settings/settings_menu_page.dart`, `lib/presentation/pages/setup_wizard/setup_wizard_page.dart`, dan seluruh file di `lib/presentation/pages/settings/sections/`. | ✅         | 2026-05-26 |
| TASK-002 | Verifikasi perilaku akses settings dari `MainDisplayPage`: dokumentasikan tap-anywhere untuk memunculkan ikon settings selama 5 detik (`_showSettingsIcon()`), navigasi ke `PinGatePage` melalui `_openSettings()`, serta shortcut `LogicalKeyboardKey.select`, `enter`, `escape`, dan `mediaPlayPause` pada blok `onKeyEvent`.                                                                          | ✅         | 2026-05-26 |
| TASK-003 | Verifikasi perilaku `PinGatePage`: dokumentasikan kondisi bypass jika PIN tidak aktif dan alur masuk ke `SettingsMenuPage` jika verifikasi PIN berhasil.                                                                                                                                                                                                                                                 | ✅         | 2026-05-26 |
| TASK-004 | Turunkan daftar 15 kategori menu dari `_categories` dan `_sections` di `lib/presentation/pages/settings/settings_menu_page.dart`, lalu jadikan struktur dasar reference section pada panduan.                                                                                                                                                                                                            | ✅         | 2026-05-26 |
| TASK-005 | Definisikan inventory screenshot final menggunakan matrix `IMG-001` s.d. `IMG-024`, termasuk status existing/new, nama file final, dan penempatan per section panduan.                                                                                                                                                                                                                                   | ✅         | 2026-05-26 |
| TASK-006 | Putuskan struktur halaman panduan yang terdiri atas: Hero ringkas, daftar isi, cara masuk ke pengaturan, navigasi dasar, setup awal, referensi menu settings, FAQ, dan CTA/support footer.                                                                                                                                                                                                               | ✅         | 2026-05-26 |

### Implementation Phase 2

- GOAL-002: Membuat shell halaman `panduan.html` dan menghubungkannya dari
  landing page utama.

| Task     | Description                                                                                                                                                                                                                                                                     | Completed | Date       |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-007 | Buat file baru `landingpage/panduan.html` dengan HTML5 document, `lang="id"`, title khusus panduan, meta description, canonical, OG tags, Bootstrap 5.3.8 CDN, Bootstrap Icons CDN, dan referensi ke `landingpage/assets/css/styles.css` serta `landingpage/assets/js/main.js`. | ✅         | 2026-05-26 |
| TASK-008 | Reuse pola navbar dari `landingpage/index.html` (brand, toggler, tombol CTA), namun sesuaikan link internal agar mengarah ke anchor di `panduan.html` seperti `#ringkasan`, `#akses-settings`, `#setup-awal`, `#menu-settings`, dan `#faq`.                                     | ✅         | 2026-05-26 |
| TASK-009 | Tambahkan link `Panduan` pada navbar `landingpage/index.html` tanpa mengganggu link existing (`Kenapa MKTV?`, `Fitur`, `Tampilan`, `Cara Pasang`).                                                                                                                              | ✅         | 2026-05-26 |
| TASK-010 | Tambahkan link `Panduan Pengguna` pada area footer `landingpage/index.html` agar halaman bantuan bisa diakses dari seluruh halaman marketing.                                                                                                                                   | ✅         | 2026-05-26 |
| TASK-011 | Tambahkan satu CTA sekunder pada `landingpage/index.html` yang mengarahkan user ke `panduan.html`, misalnya di section `Cara Pasang & Gunakan` atau CTA akhir, dengan copy yang eksplisit seperti "Lihat Panduan Penggunaan".                                                   | ✅         | 2026-05-26 |
| TASK-012 | Reuse pola footer dari `landingpage/index.html` pada `landingpage/panduan.html` agar branding, kontak support, dan link legal tetap konsisten.                                                                                                                                  | ✅         | 2026-05-26 |

### Implementation Phase 3

- GOAL-003: Menulis materi tutorial utama untuk user baru dan operator.

| Task     | Description                                                                                                                                                                                                                                                                                                  | Completed | Date       |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- | ---------- |
| TASK-013 | Tulis section ringkasan pada `landingpage/panduan.html` yang menjelaskan siapa target panduan ini, perangkat yang didukung, dan hasil yang akan didapat user setelah membaca halaman.                                                                                                                        | ✅         | 2026-05-27 |
| TASK-014 | Tulis section "Cara Masuk ke Pengaturan" dengan dua subalur terpisah: **Android TV / Remote** dan **HP / Tablet Touchscreen**. Wajib merujuk pada perilaku aktual di `main_display_page.dart` dan `pin_gate_page.dart`; jangan menulis instruksi yang tidak sesuai dengan key binding atau gesture yang ada. | ✅         | 2026-05-27 |
| TASK-015 | Tulis section "Cara Navigasi Menu" berdasarkan split layout `SettingsMenuPage`: panel kiri untuk kategori, panel kanan untuk isi, tombol kembali di bawah, serta perbedaan interaksi antara D-Pad dan tap sentuh.                                                                                            | ✅         | 2026-05-27 |
| TASK-016 | Tulis section "Setup Awal Langkah demi Langkah" berdasarkan 4 file wizard: `welcome_step.dart`, `identity_step.dart`, `location_step.dart`, dan `preview_step.dart`. Uraikan urutan isi data, validasi dasar, dan aksi lanjut/kembali/simpan.                                                                | ✅         | 2026-05-27 |
| TASK-017 | Tulis section "Jika PIN Aktif" yang menjelaskan kapan user diminta memasukkan PIN, apa yang terjadi jika PIN salah, dan kondisi ketika settings langsung terbuka tanpa PIN.                                                                                                                                  | ✅         | 2026-05-27 |
| TASK-018 | Tulis section "FAQ / Kendala Umum" yang menjawab minimal masalah berikut: tidak tahu cara membuka settings, ikon settings tidak muncul di perangkat sentuh, lupa PIN, belum paham fungsi menu tertentu, dan ingin reset ke setup awal.                                                                       | ✅         | 2026-05-27 |

### Implementation Phase 4

- GOAL-004: Menulis referensi detail seluruh kategori settings tanpa menyimpang
  dari source code aktual.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                         | Completed | Date       |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-019 | Buat subsection referensi untuk menu `Identitas Masjid`, `Koreksi Waktu (Ihtiyat)`, `Durasi Iqomah`, dan `Pengaturan Dhuha` berdasarkan file `identity_section.dart`, `ihtiyat_section.dart`, `iqomah_section.dart`, dan `dhuha_section.dart`. Jelaskan field penting seperti nama/alamat, offset waktu, durasi iqomah per sholat, dan offset Dhuha setelah Syuruq. | ✅         | 2026-05-27 |
| TASK-020 | Buat subsection referensi untuk menu `Durasi Tampilan`, `Alarm Tanda Waktu`, dan `Running Text` berdasarkan `display_timing_section.dart`, `alert_settings_section.dart`, dan `running_text_section.dart`. Jelaskan parameter durasi, alarm pre-adzan/pre-iqomah, preview running text, dan aksi simpan.                                                            | ✅         | 2026-05-27 |
| TASK-021 | Buat subsection referensi untuk menu `Keamanan (PIN)` dan `Informasi Kas` berdasarkan `security_section.dart` dan `treasury_section.dart`. Jelaskan status PIN aktif/nonaktif, buat/ubah/nonaktifkan PIN, toggle info kas, input saldo/pemasukan/pengeluaran, serta preview nominal.                                                                                | ✅         | 2026-05-27 |
| TASK-022 | Buat subsection referensi untuk menu `Kata Mutiara`, `Slideshow Pengumuman`, dan `Jadwal Imam` berdasarkan `wisdom_quote_section.dart`, `slideshow_section.dart`, dan `imam_schedule_section.dart`. Jelaskan toggle fitur, waktu aktif, interval, slot gambar, preview, CRUD data terkait, serta dampaknya pada layar utama.                                        | ✅         | 2026-05-27 |
| TASK-023 | Buat subsection referensi untuk menu `Mode Hemat Daya`, `Reset Data`, dan `Tentang Aplikasi` berdasarkan `midnight_mode_section.dart`, `reset_section.dart`, dan `about_section.dart`. Jelaskan jadwal mode hemat daya, konsekuensi reset data, dan fungsi informasi aplikasi.                                                                                      | ✅         | 2026-05-27 |
| TASK-024 | Untuk setiap subsection settings, gunakan pola konsisten: fungsi utama, pengaturan penting, kapan digunakan, apa dampaknya di layar utama, dan catatan penggunaan untuk Android TV/touchscreen.                                                                                                                                                                     | ✅         | 2026-05-27 |
| TASK-025 | Tambahkan anchor link per kategori settings agar user dapat lompat langsung dari daftar isi atau daftar menu bantuan ke submenu yang diinginkan.                                                                                                                                                                                                                    | ✅         | 2026-05-27 |

### Implementation Phase 5

- GOAL-005: Menambahkan styling panduan, layout bantuan, dan integrasi
  screenshot pendukung.

| Task     | Description                                                                                                                                                                                                                                                                                                    | Completed | Date       |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-026 | Modifikasi `landingpage/assets/css/styles.css` untuk menambah utility class khusus halaman panduan, minimal untuk: table of contents, callout perangkat, step list, screenshot figure, note/warning box, dan sticky in-page navigation bila diperlukan.                                                        | ✅         | 2026-05-26 |
| TASK-027 | Pastikan kelas CSS baru tetap reuse token warna `--mkt-*` yang sudah ada dan tidak membuat cabang tema visual baru.                                                                                                                                                                                            | ✅         | 2026-05-26 |
| TASK-028 | Tambahkan folder `landingpage/assets/img/screenshots/guide/` untuk aset screenshot panduan yang tidak dipakai oleh halaman marketing utama.                                                                                                                                                                    | ✅         | 2026-05-26 |
| TASK-029 | Update `landingpage/assets/img/screenshots/README.md` agar mencantumkan inventory `IMG-001` s.d. `IMG-024`, aturan naming, rasio 16:9, dan daftar screenshot yang existing vs baru untuk halaman panduan.                                                                                                      | ✅         | 2026-05-26 |
| TASK-030 | Integrasikan screenshot existing (`standby.png`, `settings.png`, `wisdom.png`, `slideshow.png`, `iqomah.png`, `pre-adzan.png`, `imam-schedule-weekday.png`, `imam-schedule-jumat.png`) pada `panduan.html`; screenshot baru di `guide/` tetap didokumentasikan di README dan baru dipasang setelah aset final tersedia. | ✅         | 2026-05-26 |
| TASK-031 | Untuk screenshot yang menunjukkan langkah atau area penting, tentukan apakah akan memakai gambar polos atau varian anotasi terpisah. Jika anotasi dipakai, gunakan nama file berbeda (misalnya `*-annotated.png`) agar aset asli tetap tersedia.                                                               | ✅         | 2026-05-26 |
| TASK-032 | Tambahkan caption deskriptif pada setiap screenshot agar fungsi visualnya jelas, misalnya "Tap layar untuk memunculkan ikon settings" atau "Pilih kota sebelum menekan Selanjutnya".                                                                                                                           | ✅         | 2026-05-26 |

### Implementation Phase 6

- GOAL-006: Melakukan QA konten, validasi konsistensi, dan verifikasi
  keterbacaan lintas perangkat.

| Task     | Description                                                                                                                                                                                                         | Completed | Date       |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-033 | Buka `landingpage/panduan.html` di browser lokal dan verifikasi halaman render tanpa asset 404, tanpa layout rusak, dan tanpa anchor link yang mati.                                                                | ✅         | 2026-05-26 |
| TASK-034 | Verifikasi responsive layout minimal pada viewport 375px, 768px, 1366px, dan 1920px; fokus pada keterbacaan daftar isi, table screenshot, dan subsection menu settings yang panjang.                                | ✅         | 2026-05-26 |
| TASK-035 | Verifikasi seluruh tautan dari `landingpage/index.html` menuju `panduan.html` bekerja pada navbar, footer, dan CTA sekunder.                                                                                        | ✅         | 2026-05-26 |
| TASK-036 | Audit isi panduan terhadap source code aktual: akses settings di `main_display_page.dart`, PIN di `pin_gate_page.dart`, struktur menu di `settings_menu_page.dart`, dan wizard di file `setup_wizard/steps/*.dart`. | ✅         | 2026-05-26 |
| TASK-037 | Audit bahwa seluruh label menu settings yang disebut di panduan identik dengan label yang tampil di aplikasi; jangan ada nama menu lama, typo, atau istilah buatan baru.                                            | ✅         | 2026-05-26 |
| TASK-038 | Audit bahwa screenshot tidak memuat data sensitif, PIN nyata, atau identitas masjid yang tidak boleh dipublikasikan.                                                                                                | ✅         | 2026-05-26 |
| TASK-039 | Audit bahwa `title`, `meta description`, heading hierarchy, alt text gambar, dan copy CTA halaman panduan sesuai untuk kebutuhan bantuan pengguna dan support Google Play.                                          | ✅         | 2026-05-26 |
| TASK-040 | Lakukan final content QA untuk memastikan tone Bahasa Indonesia konsisten: baku, natural, tidak terlalu teknis, dan tidak bertentangan antarbagian.                                                                 | ✅         | 2026-05-26 |

## 3. Alternatives

- **ALT-001**: Menambahkan panduan sebagai section panjang di
  `landingpage/index.html`. Ditolak karena homepage saat ini berfungsi sebagai
  halaman marketing; menambahkan dokumentasi panjang akan membuat halaman utama
  terlalu padat dan sulit dipindai.
- **ALT-002**: Membuat panduan dalam bentuk PDF/manual terpisah di luar landing
  page. Ditolak karena lebih sulit diakses dari Google Play reply, lebih sulit
  diupdate, dan tidak terhubung langsung dengan website produk.
- **ALT-003**: Menambahkan halaman bantuan langsung di aplikasi Flutter.
  Ditolak untuk scope ini karena kebutuhan awal berasal dari user yang mencari
  tutorial publik di web landing page, bukan perubahan runtime aplikasi.
- **ALT-004**: Menulis panduan singkat saja tanpa referensi tiap menu settings.
  Ditolak karena user secara eksplisit meminta penjelasan detail per menu dan
  per fungsi penting.
- **ALT-005**: Mengandalkan screenshot yang sudah ada tanpa mendefinisikan aset
  baru. Ditolak karena screenshot marketing saat ini belum cukup untuk
  menjelaskan PIN gate, wizard setup, dan section settings spesifik.

## 4. Dependencies

- **DEP-001**: `landingpage/index.html` - halaman utama yang akan diberi link ke
  panduan.
- **DEP-002**: `landingpage/assets/css/styles.css` - stylesheet utama yang harus
  direuse dan diperluas untuk layout dokumentasi.
- **DEP-003**: `landingpage/assets/js/main.js` - script ringan existing yang dapat
  dipakai kembali untuk perilaku navbar/anchor.
- **DEP-004**: `lib/presentation/pages/main_display_page.dart` - source-of-truth
  akses settings via remote dan touch.
- **DEP-005**: `lib/presentation/pages/settings/pin_gate_page.dart` -
  source-of-truth alur PIN sebelum masuk settings.
- **DEP-006**: `lib/presentation/pages/settings/settings_menu_page.dart` -
  source-of-truth nama dan urutan kategori settings.
- **DEP-007**: `lib/presentation/pages/setup_wizard/setup_wizard_page.dart` dan
  `lib/presentation/pages/setup_wizard/steps/*.dart` - source-of-truth setup awal.
- **DEP-008**: Semua file di `lib/presentation/pages/settings/sections/` -
  source-of-truth detail fungsi setiap submenu settings.
- **DEP-009**: Existing screenshot di
  `landingpage/assets/img/screenshots/`: `standby.png`, `settings.png`,
  `wisdom.png`, `slideshow.png`, `iqomah.png`, `pre-adzan.png`,
  `imam-schedule-weekday.png`, dan `imam-schedule-jumat.png`.
- **DEP-010**: Screenshot baru di
  `landingpage/assets/img/screenshots/guide/` sesuai matrix `IMG-002` s.d.
  `IMG-018`.
- **DEP-011**: Bootstrap v5.3.8 dan Bootstrap Icons CDN yang sudah dipakai oleh
  landing page existing.
- **DEP-012**: Copy produk dasar dari `README.md`, `Product_Requirement_Document.md`,
  dan halaman landing page existing untuk menjaga konsistensi istilah.

## 5. Files

- **FILE-001**: `landingpage/panduan.html` - **BARU** - halaman panduan pengguna
  utama.
- **FILE-002**: `landingpage/index.html` - **DIMODIFIKASI** - tambah link dan CTA
  ke halaman panduan.
- **FILE-003**: `landingpage/assets/css/styles.css` - **DIMODIFIKASI** - tambah
  styling khusus dokumentasi dan screenshot layout.
- **FILE-004**: `landingpage/assets/js/main.js` - **OPSIONAL DIMODIFIKASI** -
  hanya jika diperlukan untuk active state, anchor helper, atau interaksi TOC.
- **FILE-005**: `landingpage/assets/img/screenshots/README.md` -
  **DIMODIFIKASI** - perluas inventaris screenshot untuk halaman panduan.
- **FILE-006**: `landingpage/assets/img/screenshots/guide/` - **BARU** - folder
  screenshot tambahan khusus panduan.
- **FILE-007**: `landingpage/assets/img/screenshots/guide/home-settings-overlay.png` -
  **BARU** - aset tutorial akses settings via touch.
- **FILE-008**: `landingpage/assets/img/screenshots/guide/pin-gate.png` -
  **BARU** - aset tutorial PIN gate.
- **FILE-009**: `landingpage/assets/img/screenshots/guide/setup-welcome.png` -
  **BARU** - aset wizard langkah 1.
- **FILE-010**: `landingpage/assets/img/screenshots/guide/setup-identity.png` -
  **BARU** - aset wizard langkah 2.
- **FILE-011**: `landingpage/assets/img/screenshots/guide/setup-location.png` -
  **BARU** - aset wizard langkah 3.
- **FILE-012**: `landingpage/assets/img/screenshots/guide/setup-preview.png` -
  **BARU** - aset wizard langkah 4.
- **FILE-013**: `landingpage/assets/img/screenshots/guide/settings-identity.png` -
  **BARU** - aset referensi settings identitas.
- **FILE-014**: `landingpage/assets/img/screenshots/guide/settings-ihtiyat.png` -
  **BARU** - aset referensi settings koreksi waktu.
- **FILE-015**: `landingpage/assets/img/screenshots/guide/settings-running-text.png` -
  **BARU** - aset referensi settings running text.
- **FILE-016**: `landingpage/assets/img/screenshots/guide/settings-security.png` -
  **BARU** - aset referensi settings PIN.
- **FILE-017**: `landingpage/assets/img/screenshots/guide/settings-treasury.png` -
  **BARU** - aset referensi settings kas.
- **FILE-018**: `landingpage/assets/img/screenshots/guide/settings-wisdom-quote.png` -
  **BARU** - aset referensi settings kata mutiara.
- **FILE-019**: `landingpage/assets/img/screenshots/guide/settings-slideshow.png` -
  **BARU** - aset referensi settings slideshow.
- **FILE-020**: `landingpage/assets/img/screenshots/guide/settings-imam-schedule.png` -
  **BARU** - aset referensi settings jadwal imam.
- **FILE-021**: `landingpage/assets/img/screenshots/guide/settings-midnight-mode.png` -
  **BARU** - aset referensi settings mode hemat daya.
- **FILE-022**: `landingpage/assets/img/screenshots/guide/settings-reset-data.png` -
  **BARU** - aset referensi settings reset data.

## 6. Testing

- **TEST-001**: Verifikasi `landingpage/panduan.html` dapat dibuka langsung di
  browser tanpa error fatal.
- **TEST-002**: Verifikasi seluruh link dari `landingpage/index.html` menuju
  `panduan.html` berfungsi.
- **TEST-003**: Verifikasi anchor link internal pada `panduan.html` dapat
  membawa user ke section yang benar.
- **TEST-004**: Verifikasi konten "Cara Masuk ke Pengaturan" sama dengan perilaku
  aktual di `main_display_page.dart` dan `pin_gate_page.dart`.
- **TEST-005**: Verifikasi seluruh label nama menu settings di panduan identik
  dengan `_categories` pada `settings_menu_page.dart`.
- **TEST-006**: Verifikasi panduan setup awal konsisten dengan urutan 4 step
  wizard yang ada di source code.
- **TEST-007**: Verifikasi seluruh screenshot memiliki `alt`, `width`, `height`,
  dan `loading` yang sesuai.
- **TEST-008**: Verifikasi tidak ada asset lokal yang menghasilkan 404.
- **TEST-009**: Verifikasi responsive layout pada viewport 375px, 768px,
  1366px, dan 1920px.
- **TEST-010**: Verifikasi screenshot tidak memuat PIN nyata atau data sensitif.
- **TEST-011**: Verifikasi halaman panduan tetap nyaman dipindai walaupun
  section settings panjang, termasuk pada mobile.
- **TEST-012**: Verifikasi heading hierarchy, title, meta description,
  canonical, dan copy CTA sesuai untuk halaman bantuan pengguna.
- **TEST-013**: Final content QA memastikan Bahasa Indonesia konsisten, baku,
  natural, dan tidak saling bertentangan antarbagian.

## 7. Risks & Assumptions

- **RISK-001**: Dokumentasi dapat cepat usang jika label menu atau perilaku
  settings berubah di aplikasi Flutter. **Mitigasi**: treat source files sebagai
  source-of-truth dan lakukan audit sebelum publish.
- **RISK-002**: Screenshot baru belum tersedia saat halaman panduan selesai
  ditulis. **Mitigasi**: definisikan inventory aset lebih awal dan siapkan
  instruksi pemasangan di README; jangan tampilkan placeholder kosong di halaman
  publik sebelum screenshot final tersedia.
- **RISK-003**: Halaman panduan bisa menjadi terlalu panjang untuk user mobile.
  **Mitigasi**: sediakan daftar isi, anchor link, subsection ringkas, dan
  pengelompokan menu yang jelas.
- **RISK-004**: User bisa bingung membedakan instruksi Android TV vs touchscreen.
  **Mitigasi**: pisahkan langkah per perangkat dengan callout visual yang kuat.
- **RISK-005**: Screenshot yang menampilkan data contoh kas, nama masjid, atau
  PIN dapat dianggap data nyata. **Mitigasi**: gunakan data dummy yang jelas dan
  jangan tampilkan PIN sebenarnya.
- **ASSUMPTION-001**: Package ID Google Play Store tetap sama sehingga halaman
  panduan bisa dipakai sebagai link support publik untuk listing saat ini.
- **ASSUMPTION-002**: Struktur `SettingsMenuPage` saat ini (15 kategori) adalah
  baseline yang akan dipakai saat implementasi panduan.
- **ASSUMPTION-003**: User ingin panduan publik berbasis web, bukan dokumen PDF
  atau in-app help screen, untuk fase ini.
- **ASSUMPTION-004**: Bahasa target utama tetap Bahasa Indonesia dan belum
  membutuhkan versi bilingual.
- **ASSUMPTION-005**: Existing visual theme landing page tetap dipertahankan dan
  tidak ada redesign besar bersamaan dengan fitur panduan.

## 8. Related Specifications / Further Reading

- [feature-landing-page-1.md](feature-landing-page-1.md) - plan landing page
  existing yang menjadi baseline visual dan struktur website.
- [feature-setup-wizard-ui-1.md](feature-setup-wizard-ui-1.md) - referensi plan
  flow setup wizard yang akan didokumentasikan pada panduan.
- [feature-settings-ui-1.md](feature-settings-ui-1.md) - referensi plan UI
  settings yang menjadi sumber daftar menu dan pola navigasi.
- [README.md](../README.md) - referensi istilah produk dan ringkasan fitur.
- [Product_Requirement_Document.md](../Product_Requirement_Document.md) -
  referensi positioning produk dan bahasa produk tingkat tinggi.
- [landingpage/index.html](../landingpage/index.html) - baseline markup landing
  page yang harus tetap konsisten dengan halaman panduan.
- [lib/presentation/pages/main_display_page.dart](../lib/presentation/pages/main_display_page.dart) -
  referensi perilaku akses settings dari layar utama.
- [lib/presentation/pages/settings/settings_menu_page.dart](../lib/presentation/pages/settings/settings_menu_page.dart) -
  referensi nama dan urutan kategori menu settings.
