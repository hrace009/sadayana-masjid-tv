# Product Requirement Document (PRD)

**Project Name:** Miqotul Khoir TV (MKT)
**Platform:** Android TV (Mini PC / STB / Smart TV)
**Technology:** Flutter (Dart)
**Version:** 3.0.0 (Production-Ready Edition)
**Status:** In Development — Core Features Completed
**Last Updated:** 4 Maret 2026
**Target User:** DKM Masjid (Admin) & Jamaah (Viewer)

---

## 1. Executive Summary

Miqotul Khoir TV adalah aplikasi *jam masjid digital* dan papan informasi jadwal sholat berbasis Android TV. Dirancang untuk menggantikan jam jadwal sholat konvensional di masjid atau musala, aplikasi ini menampilkan antarmuka yang indah, mudah dibaca dari jarak jauh, dan kaya akan fitur.

Dirancang dengan prinsip **Offline-First** — cukup masukkan koordinat lokasi satu kali saat pengaturan awal, dan aplikasi ini akan menghitung jadwal sholat secara **presisi abadi** tanpa perlu terhubung ke internet sama sekali. Kompatibel dengan perangkat **TV Android**, **TV Pintar**, dan **Kotak Dekoder**.

## 2. User Personas

### 2.1. Admin DKM (Primary Operator)

* **Characteristics:** Tidak terlalu teknis, menggunakan remote TV standar untuk navigasi.
* **Goals:** Mengatur jadwal sholat agar akurat dengan kalender lokal/masjid tanpa koneksi internet.
* **Needs:** Proses pengaturan awal yang mudah (wizard) tanpa harus mengetik koordinat rumit.

### 2.2. Jamaah (Viewer)

* **Goals:** Mengetahui waktu sholat masuk, waktu iqomah, dan informasi kajian.
* **Needs:** Teks besar, kontras tinggi, dan indikator waktu yang jelas.

---

## 3. Functional Requirements

### 3.1. Prayer Time Calculation (Core - Offline)

Sistem **TIDAK** menggunakan API internet. Perhitungan dilakukan menggunakan *astronomical calculation library* (porting `adhan-dart`) secara lokal.

**Daftar Waktu yang Ditampilkan (Urut):**

1. **Subuh**
2. **Syuruq** (Terbit)
3. **Dhuha**
4. **Dzuhur**
5. **Ashar**
6. **Maghrib**
7. **Isya**

**Logika Kalkulasi:**

* **Input:** Latitude, Longitude, Timezone, Elevation/DPL (dari Settings).
* **Algoritma Utama:** Standar **Kemenag RI** (SIHAT) — Subuh 20°, Isya 18°, Ihtiyat bawaan **+2 menit** setiap waktu sholat (kecuali Syuruq -2 menit).
* **Koreksi Ketinggian (DPL):** Ketinggian tempat di atas permukaan laut (meter) digunakan untuk mengoreksi waktu Syuruq dan Maghrib agar akurat untuk kota dataran tinggi (misal Bandung ~768m). Data elevasi per kota tersimpan di tabel `cities`.
* **Logika Dhuha:** `Waktu Syuruq + Offset Dhuha` (Default: +20 menit, configurable).
* **Manual Correction (Ihtiyat):** Setiap waktu sholat (1-7) memiliki nilai koreksi (+/- menit) yang disimpan di database SQLite.
* **Penanganan Hari Jum'at:** Setiap hari Jumat, waktu Dzuhur secara otomatis berganti label menjadi **"Jum'at"** pada seluruh tampilan UI. Durasi layar mati dan iqomah menggunakan nilai khusus Jum'at yang terpisah dari Dzuhur biasa.
* *Formula Akhir:* `DisplayTime = CalculatedTime + ElevationCorrection + UserCorrectionMinutes`.



### 3.2. State Machine (UI Transition Logic)

Aplikasi memiliki 5 status tampilan otomatis berdasarkan waktu:

1. **State: STANDBY — Mode Siaga (Default)**
* Menampilkan Jam Besar, Tanggal, 7 Jadwal Sholat, Running Text, dan Background Slider.


2. **State: PRE-ADZAN (Countdown)**
* *Trigger:* H-10 menit (configurable) sebelum waktu sholat masuk.
* *Action:* Jadwal sholat terkait berkedip/highlight + Countdown timer muncul.


3. **State: ADZAN**
* *Trigger:* Waktu == Jadwal Sholat.
* *Action:* Audio Adzan/Beep (Opsional) + Visual "SAATNYA ADZAN [NAMA SHOLAT]".


4. **State: IQOMAH (Waiting)**
* *Trigger:* Setelah durasi Adzan selesai.
* *Action:* Menampilkan Countdown Timer mundur besar (Durasi berbeda tiap sholat, misal Subuh 10m, Maghrib 7m).


5. **State: SHOLAT — Mode Sholat (Screen Off/Dimmed)**
* *Trigger:* Timer Iqomah habis (00:00).
* *Action:* Layar menjadi **Blank Hitam** atau **Jam Redup Kecil** (OLED safe) — agar tidak mengganggu kekhusyukan jamaah.
* *Exit Condition:* Setelah durasi sholat selesai (misal 15 menit), kembali ke **STANDBY**.



### 3.3. Content Management

* **Running Text (Marquee):** Teks berjalan di bagian bawah layar. Dapat diedit melalui menu Settings. Input berupa satu field teks panjang; admin dapat memisahkan segmen informasi menggunakan pemisah seperti spasi atau simbol. Cocok untuk menyampaikan informasi kajian, atau pesan hadits pilihan.
* **Informasi Kas Masjid (Opsional):** Fitur display saldo kas, pemasukan, dan pengeluaran masjid yang dapat diaktifkan/dinonaktifkan dari Settings. Nilai diinput secara manual oleh admin. Ditampilkan di panel kanan layar utama (Standby Layout) saat diaktifkan.
* **Hijri Date:** Kalkulasi lokal (Umm al-Qura approximation) dengan fitur **Manual Adjustment** (H-1 / H+1) untuk sinkronisasi puasa/lebaran.

### 3.4. Settings Menu (Remote Friendly)

Menu pengaturan dilindungi PIN sederhana (optional) dan dinavigasi menggunakan D-Pad Remote Control.

* **Identity Settings:** Edit Nama Masjid & Alamat Singkat.
* **Location Settings:** ⚠️ *Backlog* — Setelah Setup Wizard selesai, admin belum dapat mengubah kota/koordinat tanpa melakukan Reset Data. Fitur "Ubah Lokasi" di Settings menu perlu ditambahkan.
* **Time Corrections (Ihtiyat):** Input DPadStepper untuk koreksi menit tiap waktu sholat (-30 s/d +30 menit).
* **Iqomah Config:** Edit durasi jeda Iqomah per waktu sholat, termasuk durasi khusus Jum'at.
* **Dhuha Settings:** Konfigurasi offset Dhuha dari Syuruq.
* **Display Timing:** Edit durasi Pre-Adzan countdown, durasi Adzan, dan durasi layar mati Sholat.
* **Running Text:** Edit teks berjalan footer.
* **Treasury/Kas Masjid:** Aktifkan fitur kas masjid dan input nilai saldo, pemasukan, pengeluaran.
* **Security:** Atur PIN untuk mengunci akses Settings menu.
* **Reset Data:** Kembalikan seluruh konfigurasi ke pengaturan pabrik.

### 3.5. Initial Setup Flow (First Run Experience)

Flow ini hanya muncul satu kali saat aplikasi baru diinstal (cek `is_first_run` di SQLite).

**Step 1: Welcome & System Check**

* **UI:** Logo Miqotul Khoir TV + Teks "Selamat Datang".
* **Action:** Sistem mengecek Waktu & Tanggal Android TV.
* **Prompt:** Jika waktu sistem salah, muncul peringatan.

**Step 2: Identitas Masjid**

* **UI:** Form Input Nama Masjid & Alamat Singkat via On-screen Keyboard.

**Step 3: Lokasi Masjid (Critical)**

* **Pilih Kota (Implemented)**
* *Data Source:* Table SQLite `cities` (Pre-populated, 514 kota/kabupaten, 34 provinsi).
* *UI:* Cascading Dropdown Provinsi → Kota/Kabupaten.
* *Action:* Mengisi otomatis `latitude`, `longitude`, dan `elevation` ke state wizard.


* **Koordinat Manual (Advanced)** — ⚠️ *Backlog, belum diimplementasi*
* *UI:* Input Field Latitude & Longitude (untuk masjid di lokasi yang tidak ada di daftar kota).
* *Prioritas:* Medium — kota yang belum terdaftar bisa disiasati sementara dengan memilih kota terdekat.


**Step 4: Konfirmasi Jadwal**

* **UI:** Preview Jadwal Sholat.
* **Action:** Simpan konfigurasi final ke SQLite.

---

## 4. Non-Functional Requirements

1. **Offline Capability:** Aplikasi berfungsi 100% tanpa internet setelah instalasi.
2. **Auto-Start:** Aplikasi dikonfigurasi sebagai *Launcher* atau *Boot on Startup* — otomatis berjalan saat TV dinyalakan atau setelah listrik padam.
3. **Display Ratio:** Dioptimalkan untuk resolusi 16:9 (Landscape) - 1920x1080 (FHD).
4. **Performance:** 60 FPS rendering.
5. **Data Integrity:** Menggunakan SQLite Transaction untuk mencegah korupsi data saat mati listrik mendadak.
6. **Anti-Sleep (Wakelock):** ⚠️ *Gap Implementasi* — Library `wakelock_plus` disebutkan sebagai dependency wajib namun belum ditambahkan ke `pubspec.yaml`. Tanpa wakelock, Android TV berpotensi masuk mode sleep saat tidak ada interaksi, yang akan mematikan tujuan utama aplikasi sebagai jam masjid 24 jam. **Wajib ditambahkan sebelum rilis.**

---

## 5. UI/UX Guidelines

### 5.1. Theme: "Modern Islamic Glassmorphism" (Kaca Buram)

* **Primary Color:** Deep Emerald Green (`#004D40`).
* **Accent Color:** Gold / Amber (`#FFD700`).
* **Background:** Image Masjid dengan Dark Overlay.

### 5.2. Typography

* **Clock:** Digital Font / Monospace Bold.
* **Text:** Sans-Serif (Montserrat / Roboto).

### 5.3. Layout Structure

* **Header:** Logo, Nama Masjid, Tanggal.
* **Body:** Jam Besar (Kiri), Info/Countdown (Kanan).
* **Footer:** 7 Kotak Jadwal Sholat (Bawah), Running Text (Paling Bawah).

---

## 6. Technical Architecture

### 6.1. Tech Stack

* **Framework:** Flutter (Latest Stable).
* **Database:** SQLite (via `sqflite`).
* **Architecture:** Clean Architecture (Feature-based).

### 6.2. Key Libraries (Dart Packages)

1. **Logic:**
   * `adhan`: Kalkulasi astronomi waktu sholat.
   * `hijri`: Konversi tanggal Hijriah.
   * `crypto`: SHA-256 hashing untuk PIN Settings.

2. **Storage:**
   * `sqflite`: Database SQL lokal.
   * `path`: Helper untuk path database.

3. **System:**
   * `wakelock_plus`: Mencegah layar TV masuk mode sleep. ⚠️ **Belum ditambahkan ke `pubspec.yaml` — wajib ditambahkan sebelum rilis.**
   * `intl`: Formatting tanggal & angka (`id_ID` locale, format Rupiah).

4. **State Management:**
   * `flutter_bloc`: Cubit pattern untuk semua state management.
   * `equatable`: Value equality untuk state classes.

5. **UI:**
   * `google_fonts`: Font Poppins (dynamic loading).
   * `marquee`: Running text scrolling horizontal.
   * `flutter_screenutil`: Responsive scaling (design size 1920×1080).


### 6.3. Database Schema (SQLite)

Schema ini mencerminkan struktur aktual implementasi (versi database: **v6**). Perubahan dari PRD sebelumnya ditandai dengan komentar `-- NEW`.

**Table `settings` (Singleton — selalu tepat 1 baris, `CHECK id = 1`)**

```sql
CREATE TABLE settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  is_first_run INTEGER NOT NULL DEFAULT 1,       -- Boolean (0/1)

  -- Identity
  mosque_name TEXT NOT NULL DEFAULT '',
  mosque_address TEXT NOT NULL DEFAULT '',

  -- Location
  city_name TEXT NOT NULL DEFAULT '',
  province_name TEXT NOT NULL DEFAULT '',        -- NEW (v2)
  latitude REAL NOT NULL DEFAULT -6.9175,
  longitude REAL NOT NULL DEFAULT 107.6191,
  timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',

  -- Calculation Method
  calculation_method TEXT NOT NULL DEFAULT 'kemenag', -- NEW; nilai: 'kemenag'

  -- Time Corrections / Ihtiyat (Minutes)
  offset_subuh INTEGER NOT NULL DEFAULT 0,
  offset_syuruq INTEGER NOT NULL DEFAULT 0,
  offset_dhuha INTEGER NOT NULL DEFAULT 0,
  offset_dzuhur INTEGER NOT NULL DEFAULT 0,
  offset_ashar INTEGER NOT NULL DEFAULT 0,
  offset_maghrib INTEGER NOT NULL DEFAULT 0,
  offset_isya INTEGER NOT NULL DEFAULT 0,

  -- Dhuha offset from Syuruq (Minutes)
  dhuha_offset_minutes INTEGER NOT NULL DEFAULT 20, -- NEW

  -- Hijri Date Adjustment (Days)
  hijri_adjustment INTEGER NOT NULL DEFAULT 0,

  -- Iqomah Delays (Minutes)
  iqomah_subuh INTEGER NOT NULL DEFAULT 10,
  iqomah_dzuhur INTEGER NOT NULL DEFAULT 10,
  iqomah_ashar INTEGER NOT NULL DEFAULT 10,
  iqomah_maghrib INTEGER NOT NULL DEFAULT 7,
  iqomah_isya INTEGER NOT NULL DEFAULT 10,
  iqomah_jumat INTEGER NOT NULL DEFAULT 10,         -- NEW (v5) — khusus hari Jum'at

  -- Display Timing
  pre_adzan_minutes INTEGER NOT NULL DEFAULT 10,    -- NEW
  sholat_duration_minutes INTEGER NOT NULL DEFAULT 15, -- NEW
  sholat_jumat_duration_minutes INTEGER NOT NULL DEFAULT 45, -- NEW (v5)
  adzan_duration_seconds INTEGER NOT NULL DEFAULT 180,       -- NEW

  -- Running Text Content
  running_text TEXT NOT NULL DEFAULT 'Selamat datang di masjid kami',

  -- PIN Protection (empty string = disabled)
  settings_pin_hash TEXT NOT NULL DEFAULT '',       -- NEW; SHA-256 hash

  -- Informasi Kas Masjid (fitur opsional, default OFF)
  is_treasury_enabled INTEGER NOT NULL DEFAULT 0,   -- NEW (v6) — Boolean (0/1)
  treasury_balance INTEGER NOT NULL DEFAULT 0,      -- NEW (v6) — Rupiah
  treasury_income INTEGER NOT NULL DEFAULT 0,       -- NEW (v6) — Rupiah
  treasury_expense INTEGER NOT NULL DEFAULT 0,      -- NEW (v6) — Rupiah

  -- Timestamps
  created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')), -- NEW
  updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')), -- NEW

  -- Elevation (meter DPL — Di atas Permukaan Laut)
  elevation INTEGER NOT NULL DEFAULT 0              -- NEW (v3)
);
```

**Table `cities` (Pre-populated untuk Setup Wizard City Picker)**

```sql
CREATE TABLE cities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  province_name TEXT NOT NULL,
  city_name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  elevation INTEGER NOT NULL DEFAULT 0  -- NEW (v3) — meter DPL
);

CREATE INDEX idx_cities_province ON cities(province_name);
CREATE INDEX idx_cities_name ON cities(city_name);
```

**Data Seed Cities:** 514 kota/kabupaten, 34 provinsi Indonesia, disimpan di `assets/data/cities.json`.

**Versi Migration History:**

| Versi | Perubahan |
|-------|-----------|
| v1 | Schema awal |
| v2 | Tambah kolom `province_name` di `settings` |
| v3 | Tambah kolom `elevation` di `settings` dan `cities` |
| v4 | Isi data elevasi di `cities` dari JSON asset |
| v5 | Tambah `iqomah_jumat` dan `sholat_jumat_duration_minutes` |
| v6 | Tambah 4 kolom `is_treasury_enabled`, `treasury_balance`, `treasury_income`, `treasury_expense` |

---

## 7. Roadmap & Status Implementasi

### 7.1. Phases yang Sudah Selesai ✅

| Phase | Deskripsi | Plan File |
|-------|-----------|-----------|
| Phase 1 — Database | SQLite schema, seed 514 kota, migration v1-v6 | `infrastructure-database-1.md` |
| Phase 2 — Data Layer | Entities, Repositories, Models, Data Sources | `feature-data-layer-1.md` |
| Phase 3 — Theme System | IslamicColors, Typography, Material3 Theme, TVSafeArea | `design-theme-system-1.md` |
| Phase 4 — UI Components | GlassmorphismCard, DPadStepper, PinInput, widgets | `design-ui-components-1.md` |
| Phase 5 — Prayer Time | `CalculatePrayerTimesUseCase`, Kemenag SIHAT, DPL | `feature-prayer-calculation-1.md` |
| Phase 6 — Prayer Cubit | `PrayerTimeCubit`, daily refresh, state management | `feature-prayer-cubit-1.md` |
| Phase 7 — State Evaluation | `EvaluateDisplayStateUseCase`, 5-state logic | `feature-state-evaluation-1.md` |
| Phase 8 — Display State Machine | `DisplayStateCubit`, timer, state transitions | `feature-display-state-machine-1.md` |
| Phase 9 — Setup Wizard Logic | `SetupWizardCubit`, first-run flow | `feature-setup-wizard-logic-1.md` |
| Phase 10 — Setup Wizard UI | Welcome, Identity, Location, Preview steps | `feature-setup-wizard-ui-1.md` |
| Phase 11 — Settings Logic | `SettingsCubit`, auto-save debounce, PIN lifecycle | `feature-settings-logic-1.md` |
| Phase 12 — Settings UI | PinGatePage, SettingsMenuPage, semua sections | `feature-settings-ui-1.md` |
| Phase 13 — Main Display UI | 5 layout states, AnimatedSwitcher, D-Pad menu | `feature-main-display-ui-1.md` |
| **Extra** — Kemenag Method Fix | Ganti MUIS → SIHAT, fix ihtiyat bawaan | `feature-kemenag-prayer-method-1.md` |
| **Extra** — Elevation/DPL | Koreksi ketinggian untuk akurasi Maghrib/Syuruq | `feature-elevation-correction-1.md` |
| **Extra** — Jum'at Handling | Label dinamis, durasi layar & iqomah khusus Jum'at | `feature-jumat-prayer-1.md` |
| **Extra** — Treasury/Kas | Informasi saldo kas masjid di layar utama | `feature-treasury-info-1.md` |
| **Extra** — Rebranding | SMD → Miqotul Khoir TV, seluruh dokumen & kode | `refactor-rebranding-miqotul-khoir-1.md` |

### 7.2. Backlog (Belum Diimplementasi)

| Prioritas | Item | Keterangan |
|-----------|------|------------|
| 🔴 **Kritikal** | `wakelock_plus` | Tambah ke `pubspec.yaml` dan aktifkan di `main.dart` |
| 🟠 **Sedang** | Location Settings di Settings menu | Agar admin bisa ganti kota/koordinat post-setup tanpa full reset |
| 🟠 **Sedang** | Setup Wizard: Input Koordinat Manual | Tab alternatif untuk masjid di luar daftar 514 kota |
| 🟡 **Rendah** | Mosque Silhouette Background | Overlay siluet masjid pada latar belakang glassmorphism |

---

## 8. Fitur Tambahan (Melebihi Scope PRD Awal)

Fitur-fitur berikut diimplementasikan selama pengembangan sebagai peningkatan di luar scope PRD versi 2.0.0. Semua fitur ini sudah production-ready dan sudah terintegrasi penuh.

### 8.1. Koreksi Ketinggian Tempat (DPL/Elevasi)

**Latar Belakang:** Analisis perbandingan selama 31 hari menemukan selisih sistematis pada waktu Syuruq (+5.3 menit) dan Maghrib (-5.3 menit) untuk kota dataran tinggi (Bandung ~768m DPL), yang bersumber dari tidak adanya koreksi ketinggian tempat.

**Implementasi:**

* Field `elevation` (meter DPL) ditambahkan ke tabel `settings` dan `cities`.
* Data elevasi untuk 514 kota tersimpan di `assets/data/cities.json`.
* Library `adhan` menerima parameter `highLatitudeRule` dan parameter elevasi saat kalkulasi.
* Saat Setup Wizard memilih kota, nilai `elevation` otomatis terisi dari data `cities`.

### 8.2. Penanganan Khusus Sholat Jum'at

**Latar Belakang:** Durasi Sholat Jum'at (mencakup khutbah ~25-30 menit + sholat 2 rakaat) jauh lebih panjang dari Dzuhur biasa. Menggunakan durasi layar mati yang sama menyebabkan layar menyala di tengah khutbah.

**Implementasi:**

* Setiap hari Jumat, label waktu Dzuhur secara otomatis berubah menjadi **"Jum'at"** di seluruh UI (kartu sholat, state adzan, iqomah, sholat). Deteksi dilakukan di satu titik tunggal (`CalculatePrayerTimesUseCase`).
* `iqomahJumat` (default 10 menit): durasi countdown iqomah khusus Jum'at, terpisah dari `iqomahDzuhur`.
* `sholatJumatDurationMinutes` (default 45 menit): durasi layar mati khusus Jum'at, menggantikan `sholatDurationMinutes` (default 15 menit).
* Kedua nilai ini dapat dikonfigurasi admin melalui Settings menu.

### 8.3. Informasi Kas Masjid (Treasury Info)

**Latar Belakang:** Masjid memiliki kebutuhan transparansi keuangan kepada jamaah. Fitur ini memungkinkan admin menampilkan kondisi kas masjid di layar utama tanpa perlu papan pengumuman terpisah.

**Implementasi:**

* Toggle `isTreasuryEnabled` di Settings untuk mengaktifkan/menonaktifkan fitur.
* Admin menginput `treasuryBalance` (saldo), `treasuryIncome` (pemasukan), `treasuryExpense` (pengeluaran) via Settings menu.
* `TreasuryInfoWidget` menampilkan data tersebut di panel kanan Standby Layout dalam format Rupiah (`Rp 12.500.000`).
* Data disimpan lokal di SQLite, tidak ada network call.

---

## 9. App Store Listing

Berikut adalah materi listing resmi aplikasi Miqotul Khoir TV untuk publikasi di Google Play Store.

### 9.1. Judul Aplikasi

**Miqotul Khoir TV - Jam Masjid Digital & Jadwal Sholat**

### 9.2. Deskripsi Singkat

Solusi papan informasi digital dan jam sholat akurat untuk TV Android Masjid Anda. 100% Luring, tanpa perlu sambungan internet!

### 9.3. Deskripsi Lengkap

**Ubah TV Biasa Menjadi Pusat Informasi Masjid yang Elegan dan Akurat**

Miqotul Khoir TV hadir sebagai solusi modern untuk menggantikan jam jadwal sholat konvensional di masjid atau musala. Dirancang khusus untuk perangkat TV Android, TV Pintar, dan Kotak Dekoder, aplikasi ini menampilkan antarmuka yang indah, mudah dibaca dari jarak jauh, dan kaya akan fitur.

Kelebihan utama Miqotul Khoir TV adalah arsitekturnya yang **100% Luring**. Cukup masukkan titik koordinat lokasi satu kali saat pengaturan awal, dan aplikasi ini akan menghitung jadwal sholat secara presisi abadi tanpa perlu terhubung ke internet sama sekali!

**Fitur Unggulan:**

- **Kalkulasi Waktu Sholat Akurat (Luring):** Menghitung jadwal 7 waktu (Subuh, Syuruq, Dhuha, Dzuhur, Ashar, Maghrib, Isya) berdasarkan algoritma astronomi dengan standar Kemenag RI, langsung dari dalam perangkat. Termasuk koreksi ketinggian tempat (DPL) untuk kota dataran tinggi.
- **Penanganan Sholat Jum'at:** Setiap hari Jumat, waktu Dzuhur otomatis berganti label "Jum'at" dengan durasi layar mati dan iqomah yang berbeda, mencakup waktu khutbah sebelum sholat.
- **Penyesuaian Waktu Manual (Ihtiyat):** Pengurus masjid dapat menyesuaikan (menambah atau mengurangi menit) setiap waktu sholat secara manual agar sinkron dengan jam lokal masjid. Termasuk koreksi tanggal Hijriah.
- **Tampilan Modern bergaya Kaca Buram (Glassmorphism):** Desain antarmuka premium, elegan, dan menyejukkan mata dengan tema hijau gelap, memastikan kenyamanan jamaah saat membaca informasi di layar besar.
- **Peralihan Layar Cerdas:**
  - *Mode Siaga:* Menampilkan jam digital besar dan jadwal lengkap.
  - *Adzan & Iqomah:* Hitung mundur iqomah yang jelas dan besar.
  - *Mode Sholat:* Layar otomatis menjadi gelap selama durasi sholat agar tidak mengganggu kekhusyukan jamaah.
- **Informasi Kas Masjid:** Tampilkan saldo, pemasukan, dan pengeluaran kas masjid secara transparan di layar utama (fitur opsional, dapat diaktifkan dari Settings).
- **Teks Berjalan:** Sampaikan informasi kajian atau pesan hadits melalui teks berjalan di bagian bawah layar yang mudah disunting.
- **Ramah Pengendali Jarak Jauh:** Proses pengaturan sangat mudah dinavigasi hanya dengan tombol arah pada pengendali jarak jauh standar TV Anda.
- **Menyala Otomatis:** Aplikasi dapat otomatis berjalan saat TV dinyalakan atau setelah listrik padam.

Jadikan Miqotul Khoir TV sebagai pelita informasi di masjid Anda. Unduh sekarang dan hadirkan ketepatan waktu dalam kebaikan!