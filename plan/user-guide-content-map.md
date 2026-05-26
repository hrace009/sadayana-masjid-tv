---
title: "Peta Konten Panduan Pengguna MKTV"
type: "content-map"
parent_plan: "feature-user-guide-landing-page-1.md"
version: 1.0
date_created: 2026-05-26
last_updated: 2026-05-26
status: "Phase 1 Complete"
---

# Peta Konten Panduan Pengguna MKTV

<!-- markdownlint-disable -->

Dokumen ini adalah output dari **Implementation Phase 1** (`GOAL-001`) sesuai
`feature-user-guide-landing-page-1.md`. Berisi arsitektur konten, hasil
verifikasi source-of-truth Flutter, inventaris screenshot, dan struktur final
halaman `landingpage/panduan.html`.

---

## 1. Hasil Verifikasi Source-of-Truth

### 1.1 Cara Masuk ke Pengaturan (TASK-002)

**Source file**: `lib/presentation/pages/main_display_page.dart`

#### Alur HP/Tablet Touchscreen

| Langkah | Aksi                                      | Kode Aktual                                                                               |
| ------- | ----------------------------------------- | ----------------------------------------------------------------------------------------- |
| 1       | Tap di mana saja pada layar utama         | `GestureDetector(behavior: HitTestBehavior.translucent, onTap: _showSettingsIcon)`        |
| 2       | Ikon ⚙ muncul di layar selama **5 detik** | `Timer(const Duration(seconds: 5), () => setState(() => _isSettingsIconVisible = false))` |
| 3       | Tap ikon ⚙ sebelum 5 detik habis          | `_openSettings()` → navigate ke `PinGatePage`                                             |
| 4       | Jika tidak ditap, ikon hilang otomatis    | Auto-hide via timer                                                                       |

**Catatan panduan**: Jika ikon tidak muncul, pastikan tidak sedang dalam mode
adzan atau iqomah — pada state tersebut `isSettingsVisible` tidak dilewatkan ke
layout.

#### Alur Android TV / Remote

| Langkah | Tombol Remote                       | Kode Aktual                                             |
| ------- | ----------------------------------- | ------------------------------------------------------- |
| 1       | Tekan **OK / Select**               | `LogicalKeyboardKey.select` → `_openSettings()`         |
| 1       | Tekan **Enter** (keyboard)          | `LogicalKeyboardKey.enter` → `_openSettings()`          |
| 1       | Tekan **Escape** (back/menu remote) | `LogicalKeyboardKey.escape` → `_openSettings()`         |
| 1       | Tekan **Play/Pause** (media remote) | `LogicalKeyboardKey.mediaPlayPause` → `_openSettings()` |

**Perbedaan penting**: Di Android TV, tidak perlu tap dua langkah. Menekan
tombol apapun di atas **langsung membuka** settings tanpa melalui ikon
intermediate.

---

### 1.2 Perilaku PinGatePage (TASK-003)

**Source file**: `lib/presentation/pages/settings/pin_gate_page.dart`

| Kondisi                | Perilaku                            | Kode Aktual                                                                          |
| ---------------------- | ----------------------------------- | ------------------------------------------------------------------------------------ |
| PIN tidak aktif        | Halaman PIN **dilewati** otomatis   | `if (!settingsCubit.isPinEnabled) { _navigateToMenu(); }` via `addPostFrameCallback` |
| PIN aktif, input benar | Masuk ke `SettingsMenuPage`         | `_navigateToMenu()` → `pushReplacement`                                              |
| PIN aktif, input salah | Tampil pesan error selama **600ms** | `setState(() => _showError = true)` + reset setelah 600ms                            |
| Tombol Kembali         | Kembali ke layar utama              | `Navigator.of(context).pop()`                                                        |

**Catatan panduan**: Setelah keluar dari settings, `DisplayStateCubit.onSettingsChanged()`
dipanggil otomatis untuk memastikan jadwal sholat dan konfigurasi ter-refresh.

---

### 1.3 Daftar 15 Kategori Menu Settings (TASK-004)

**Source file**: `lib/presentation/pages/settings/settings_menu_page.dart`

Daftar ini adalah basis dari section referensi di halaman panduan. Urutan
harus **identik** dengan urutan di `_categories`.

| No  | Label Menu (di `_categories`) | Widget Section           | Anchor ID panduan.html       |
| --- | ----------------------------- | ------------------------ | ---------------------------- |
| 01  | Identitas Masjid              | `IdentitySection()`      | `#menu-identitas-masjid`     |
| 02  | Koreksi Waktu (Ihtiyat)       | `IhtiyatSection()`       | `#menu-koreksi-waktu`        |
| 03  | Durasi Iqomah                 | `IqomahSection()`        | `#menu-durasi-iqomah`        |
| 04  | Pengaturan Dhuha              | `DhuhaSection()`         | `#menu-pengaturan-dhuha`     |
| 05  | Durasi Tampilan               | `DisplayTimingSection()` | `#menu-durasi-tampilan`      |
| 06  | Alarm Tanda Waktu             | `AlertSettingsSection()` | `#menu-alarm-tanda-waktu`    |
| 07  | Running Text                  | `RunningTextSection()`   | `#menu-running-text`         |
| 08  | Keamanan (PIN)                | `SecuritySection()`      | `#menu-keamanan-pin`         |
| 09  | Informasi Kas                 | `TreasurySection()`      | `#menu-informasi-kas`        |
| 10  | Kata Mutiara                  | `WisdomQuoteSection()`   | `#menu-kata-mutiara`         |
| 11  | Slideshow Pengumuman          | `SlideshowSection()`     | `#menu-slideshow-pengumuman` |
| 12  | Jadwal Imam                   | `ImamScheduleSection()`  | `#menu-jadwal-imam`          |
| 13  | Mode Hemat Daya               | `MidnightModeSection()`  | `#menu-mode-hemat-daya`      |
| 14  | Reset Data                    | `ResetSection()`         | `#menu-reset-data`           |
| 15  | Tentang Aplikasi              | `AboutSection()`         | `#menu-tentang-aplikasi`     |

**Layout menu settings** (dari `SettingsMenuPage.build()`):
- Panel **kiri** (lebar `400.w`): daftar kategori, dipisah border kanan, tombol
  "Tutup Pengaturan" di bawah
- Panel **kanan**: konten section yang dipilih (`IndexedStack`)
- Navigasi D-Pad: Arrow Up/Down untuk berpindah kategori di panel kiri
- Navigasi touchscreen: tap pada nama kategori di panel kiri

---

### 1.4 Alur Setup Wizard (TASK-001 — wizard section)

**Source files**:
- `lib/presentation/pages/setup_wizard/steps/welcome_step.dart`
- `lib/presentation/pages/setup_wizard/steps/identity_step.dart`
- `lib/presentation/pages/setup_wizard/steps/location_step.dart`
- `lib/presentation/pages/setup_wizard/steps/preview_step.dart`

| Step | Nama Step            | Konten                                                                                                                               | Tombol Aksi                      |
| ---- | -------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------- |
| 1/4  | Welcome              | Branding MKTV + penjelasan singkat aplikasi                                                                                          | "Mulai" → next step              |
| 2/4  | Identitas Masjid     | Field **"Nama Masjid"** (hint: "Contoh: Masjid Raya Bandung") + Field **"Alamat Lengkap"** (hint: "Contoh: Jl. Asia Afrika No. 123") | Kembali / Selanjutnya            |
| 3/4  | Lokasi               | Dropdown **Provinsi** (34 pilihan) → Dropdown **Kota/Kabupaten** (cascading dari provinsi terpilih)                                  | Kembali / Selanjutnya            |
| 4/4  | Konfirmasi (Preview) | Ringkasan: Nama Masjid, Alamat, Kota/Kabupaten + preview jadwal sholat kalkulasi                                                     | Kembali / **"Simpan & Selesai"** |

**Catatan panduan**:
- Step 3: dropdown kota hanya akan muncul setelah provinsi dipilih
- Step 4: tombol "Simpan & Selesai" menyimpan ke SQLite dan menutup wizard

---

## 2. Inventaris Screenshot Final (TASK-005)

### 2.1 Screenshot yang Sudah Ada (8 file)

Lokasi: `landingpage/assets/img/screenshots/`

| ID      | File                        | Digunakan di Section                                     |
| ------- | --------------------------- | -------------------------------------------------------- |
| IMG-001 | `standby.png`               | Hero panduan + intro tampilan layar utama                |
| IMG-003 | `settings.png`              | Gambaran umum struktur menu settings                     |
| IMG-019 | `wisdom.png`                | Referensi hasil tayang Kata Mutiara                      |
| IMG-020 | `slideshow.png`             | Referensi hasil tayang Slideshow Pengumuman              |
| IMG-021 | `imam-schedule-weekday.png` | Referensi Jadwal Imam hari biasa                         |
| IMG-022 | `imam-schedule-jumat.png`   | Referensi Jadwal Imam hari Jumat                         |
| IMG-023 | `iqomah.png`                | Referensi tampilan iqomah (konteks Durasi Iqomah)        |
| IMG-024 | `pre-adzan.png`             | Referensi tampilan pre-adzan (konteks Alarm Tanda Waktu) |

### 2.2 Screenshot Baru yang Dibutuhkan (16 file)

Lokasi target: `landingpage/assets/img/screenshots/guide/`
Semua belum ada, harus dibuat menggunakan perangkat nyata atau emulator.

| ID      | File                         | Digunakan di Section                   | Cara Ambil                                      |
| ------- | ---------------------------- | -------------------------------------- | ----------------------------------------------- |
| IMG-002 | `home-settings-overlay.png`  | Cara Masuk ke Pengaturan (touchscreen) | Tap layar → screenshot saat ikon ⚙ muncul       |
| IMG-004 | `pin-gate.png`               | Cara Masuk ke Pengaturan (PIN)         | Screenshot halaman PIN dengan PIN dummy "••••"  |
| IMG-005 | `setup-welcome.png`          | Setup Awal step 1                      | Screenshot `WelcomeStep`                        |
| IMG-006 | `setup-identity.png`         | Setup Awal step 2                      | Screenshot `IdentityStep` dengan data dummy     |
| IMG-007 | `setup-location.png`         | Setup Awal step 3                      | Screenshot `LocationStep` saat dropdown terbuka |
| IMG-008 | `setup-preview.png`          | Setup Awal step 4                      | Screenshot `PreviewStep` sebelum simpan         |
| IMG-009 | `settings-identity.png`      | Referensi menu Identitas Masjid        | Screenshot `IdentitySection`                    |
| IMG-010 | `settings-ihtiyat.png`       | Referensi menu Koreksi Waktu           | Screenshot `IhtiyatSection`                     |
| IMG-011 | `settings-running-text.png`  | Referensi menu Running Text            | Screenshot `RunningTextSection`                 |
| IMG-012 | `settings-security.png`      | Referensi menu Keamanan (PIN)          | Screenshot `SecuritySection` — TANPA PIN nyata  |
| IMG-013 | `settings-treasury.png`      | Referensi menu Informasi Kas           | Screenshot `TreasurySection` — data kas dummy   |
| IMG-014 | `settings-wisdom-quote.png`  | Referensi menu Kata Mutiara            | Screenshot `WisdomQuoteSection`                 |
| IMG-015 | `settings-slideshow.png`     | Referensi menu Slideshow Pengumuman    | Screenshot `SlideshowSection`                   |
| IMG-016 | `settings-imam-schedule.png` | Referensi menu Jadwal Imam             | Screenshot `ImamScheduleSection`                |
| IMG-017 | `settings-midnight-mode.png` | Referensi menu Mode Hemat Daya         | Screenshot `MidnightModeSection`                |
| IMG-018 | `settings-reset-data.png`    | Referensi menu Reset Data              | Screenshot `ResetSection`                       |

**Aturan keamanan screenshot** (SEC-001, SEC-002):
- Screenshot PIN: tampilkan karakter `•` (tersensor), jangan PIN angka nyata
- Screenshot kas: gunakan nominal dummy (Rp 0 atau Rp 100.000)
- Screenshot identitas: gunakan nama "Masjid Contoh" / "Jl. Contoh No. 1"

---

## 3. Struktur Final Halaman panduan.html (TASK-006)

### 3.1 Daftar Isi (anchor links)

```
#ringkasan          → Ringkasan & Panduan Ini untuk Siapa
#akses-settings     → Cara Masuk ke Pengaturan
#navigasi-menu      → Cara Navigasi Menu Pengaturan
#setup-awal         → Setup Awal Langkah demi Langkah
#keamanan-pin       → Jika PIN Aktif
#menu-settings      → Referensi Menu Pengaturan
  #menu-identitas-masjid
  #menu-koreksi-waktu
  #menu-durasi-iqomah
  #menu-pengaturan-dhuha
  #menu-durasi-tampilan
  #menu-alarm-tanda-waktu
  #menu-running-text
  #menu-keamanan-pin
  #menu-informasi-kas
  #menu-kata-mutiara
  #menu-slideshow-pengumuman
  #menu-jadwal-imam
  #menu-mode-hemat-daya
  #menu-reset-data
  #menu-tentang-aplikasi
#faq               → Pertanyaan Umum & Kendala
#support           → Bantuan & Kontak
```

### 3.2 Peta Section → Konten → Screenshot

| Section                          | Konten Utama                                                                  | Screenshot di `panduan.html`       |
| -------------------------------- | ----------------------------------------------------------------------------- | ---------------------------------- |
| **Hero / Ringkasan**             | Intro singkat, target pembaca (DKM, operator masjid), perangkat yang didukung | IMG-001 (`standby.png`)            |
| **Cara Masuk ke Pengaturan**     | Dua callout: Android TV (4 tombol) dan Touchscreen (2 langkah tap)            | IMG-003; IMG-002 future            |
| **Keamanan PIN**                 | Kapan PIN diminta, bypass jika PIN nonaktif, PIN salah → error 600ms          | IMG-004 future                     |
| **Cara Navigasi Menu**           | Split layout: panel kiri kategori, panel kanan isi; D-Pad vs tap              | IMG-003                            |
| **Setup Awal**                   | 4 langkah wizard: Welcome → Identitas → Lokasi → Konfirmasi                   | IMG-005..IMG-008 future            |
| **Ref: Identitas Masjid**        | Nama masjid, alamat, dampak ke header layar utama                             | IMG-009 future                     |
| **Ref: Koreksi Waktu (Ihtiyat)** | Offset +/- per waktu sholat, satuan menit                                     | IMG-010 future                     |
| **Ref: Durasi Iqomah**           | Durasi per waktu sholat, hitungan mundur iqomah                               | IMG-023                            |
| **Ref: Pengaturan Dhuha**        | Toggle Dhuha, offset menit setelah Syuruq                                     | *(teks saja)*                      |
| **Ref: Durasi Tampilan**         | Durasi pre-adzan, durasi adzan, durasi iqomah tampil                          | *(teks saja)*                      |
| **Ref: Alarm Tanda Waktu**       | Toggle pre-adzan/pre-iqomah, countdown detik (5–15)                           | IMG-024                            |
| **Ref: Running Text**            | Teks berjalan di footer, edit teks, preview                                   | IMG-011 future                     |
| **Ref: Keamanan (PIN)**          | Status PIN, buat/ubah/nonaktifkan PIN                                         | IMG-012 future                     |
| **Ref: Informasi Kas**           | Toggle tampil kas, saldo, pemasukan, pengeluaran                              | IMG-013 future                     |
| **Ref: Kata Mutiara**            | Toggle, daftar checklist hadits/quran, interval, durasi                       | IMG-019; IMG-014 future            |
| **Ref: Slideshow Pengumuman**    | Toggle, 3 slot gambar, jam aktif, interval                                    | IMG-020; IMG-015 future            |
| **Ref: Jadwal Imam**             | CRUD jadwal per hari, hari Jumat (khatib + imam)                              | IMG-021, IMG-022; IMG-016 future   |
| **Ref: Mode Hemat Daya**         | Toggle, jam mulai/selesai, tampilan hitam tengah malam                        | IMG-017 future                     |
| **Ref: Reset Data**              | Konsekuensi reset, data yang dihapus, konfirmasi                              | IMG-018 future                     |
| **Ref: Tentang Aplikasi**        | Versi app, info developer                                                     | *(teks saja)*                      |
| **FAQ**                          | 5+ pertanyaan umum operator masjid                                            | *(teks saja)*                      |
| **CTA / Support**                | Link Play Store, tombol kontak, footer konsisten                              | *(brand logo)*                     |

### 3.3 Template Konten per Kategori Settings

Sesuai REQ-010 dan TASK-024, setiap kategori settings menggunakan format:

```
### [Nama Menu]

**Fungsi Utama**: [apa yang dilakukan menu ini]

**Pengaturan Penting**:
- [field/toggle 1]: [penjelasan]
- [field/toggle 2]: [penjelasan]

**Kapan Digunakan**: [konteks penggunaan]

**Dampak ke Layar Utama**: [apa yang berubah di layar setelah disimpan]

> 📺 **Android TV**: [catatan navigasi remote]
> 📱 **Touchscreen**: [catatan navigasi sentuh jika berbeda]
```

---

## 4. Komponen CSS Baru yang Dibutuhkan (preview untuk Phase 5)

Komponen ini akan dibuat di `landingpage/assets/css/styles.css` pada Phase 5
namun sudah diidentifikasi sejak Phase 1:

| Class                  | Fungsi                                             |
| ---------------------- | -------------------------------------------------- |
| `.guide-toc`           | Table of Contents sticky / scroll-spy              |
| `.guide-callout-tv`    | Callout blok "📺 Android TV / Remote"               |
| `.guide-callout-touch` | Callout blok "📱 HP / Tablet Touchscreen"           |
| `.guide-step`          | Numbered step list horizontal                      |
| `.guide-screenshot`    | `<figure>` wrapper untuk screenshot dengan caption |
| `.guide-settings-card` | Card per kategori settings di section referensi    |
| `.guide-note`          | Box informasi atau peringatan                      |

---

## 5. Dependensi yang Dikonfirmasi

| Dep     | File                                                      | Status                                                                            |
| ------- | --------------------------------------------------------- | --------------------------------------------------------------------------------- |
| DEP-001 | `landingpage/index.html`                                  | Ada ✓                                                                             |
| DEP-002 | `landingpage/assets/css/styles.css`                       | Ada ✓                                                                             |
| DEP-003 | `landingpage/assets/js/main.js`                           | Ada ✓                                                                             |
| DEP-004 | `lib/presentation/pages/main_display_page.dart`           | Diverifikasi ✓                                                                    |
| DEP-005 | `lib/presentation/pages/settings/pin_gate_page.dart`      | Diverifikasi ✓                                                                    |
| DEP-006 | `lib/presentation/pages/settings/settings_menu_page.dart` | Diverifikasi ✓                                                                    |
| DEP-007 | `lib/presentation/pages/setup_wizard/steps/*.dart`        | Diverifikasi ✓ (4 file)                                                           |
| DEP-008 | `lib/presentation/pages/settings/sections/*.dart`         | Ada ✓ (15 file)                                                                   |
| DEP-009 | 8 screenshot existing                                     | Ada ✓ (standby, settings, wisdom, slideshow, iqomah, pre-adzan, imam-schedule x2) |
| DEP-010 | 16 screenshot baru di `guide/`                            | Belum ada — harus dibuat di Phase 5                                               |
| DEP-011 | Bootstrap v5.3.8 + Bootstrap Icons CDN                    | Dipakai di index.html ✓                                                           |
