# Screenshot Folder

Berisi semua aset screenshot yang digunakan oleh `index.html` dan `panduan.html`.
Folder `guide/` menyimpan screenshot khusus halaman panduan pengguna.

## Inventaris Aset (IMG-001 – IMG-024)

### Folder Root — Sudah Ada (8 file)

| ID      | Nama File                   | Konten                                          | Digunakan di                                             |
| ------- | --------------------------- | ----------------------------------------------- | -------------------------------------------------------- |
| IMG-001 | `standby.png`               | Layar standby: jam, jadwal sholat, kas masjid   | `index.html` + `panduan.html` #ringkasan                 |
| IMG-003 | `settings.png`              | Menu pengaturan (navigasi via remote TV)        | `index.html` + `panduan.html` #navigasi-menu             |
| IMG-019 | `wisdom.png`                | Tampilan full-screen Kata Mutiara Islam         | `index.html` + `panduan.html` #menu-kata-mutiara         |
| IMG-020 | `slideshow.png`             | Slideshow pengumuman gambar full-screen         | `index.html` + `panduan.html` #menu-slideshow-pengumuman |
| IMG-021 | `imam-schedule-weekday.png` | Jadwal Imam hari biasa di layar utama           | `index.html` + `panduan.html` #menu-jadwal-imam          |
| IMG-022 | `imam-schedule-jumat.png`   | Jadwal Imam hari Jumat (Khatib + Imam terpisah) | `index.html` + `panduan.html` #menu-jadwal-imam          |
| IMG-023 | `iqomah.png`                | Countdown iqomah sebelum sholat dimulai         | `index.html` + `panduan.html` #menu-durasi-iqomah        |
| IMG-024 | `pre-adzan.png`             | Hitung mundur menjelang waktu Adzan (pre-adzan) | `index.html` + `panduan.html` #menu-alarm-tanda-waktu    |

### Folder `guide/` — Disiapkan (16 slot, screenshot belum tersedia)

Gunakan `adb exec-out screencap -p > nama_file.png` untuk mengambil screenshot,
lalu simpan di `guide/` sesuai nama file berikut.

| ID      | Nama File (`guide/`)            | Konten                                           | Digunakan di                              |
| ------- | ------------------------------- | ------------------------------------------------ | ----------------------------------------- |
| IMG-002 | `home-settings-overlay.png`     | Ikon ⚙ overlay di layar utama (mode touchscreen) | `panduan.html` #akses-settings            |
| IMG-004 | `pin-gate.png`                  | Halaman PIN gate 6 digit saat membuka pengaturan | `panduan.html` #keamanan-pin              |
| IMG-005 | `setup-welcome.png`             | Setup Wizard Langkah 1 — Selamat Datang          | `panduan.html` #setup-awal                |
| IMG-006 | `setup-identity.png`            | Setup Wizard Langkah 2 — Identitas Masjid        | `panduan.html` #setup-awal                |
| IMG-007 | `setup-location.png`            | Setup Wizard Langkah 3 — Pilih Kota              | `panduan.html` #setup-awal                |
| IMG-008 | `setup-preview.png`             | Setup Wizard Langkah 4 — Pratinjau & Konfirmasi  | `panduan.html` #setup-awal                |
| IMG-009 | `settings-identity.png`         | Menu Identitas Masjid di pengaturan              | `panduan.html` #menu-identitas-masjid     |
| IMG-010 | `settings-ihtiyat.png`          | Menu Koreksi Waktu (Ihtiyat) di pengaturan       | `panduan.html` #menu-koreksi-waktu        |
| IMG-011 | `settings-running-text.png`     | Menu Running Text di pengaturan                  | `panduan.html` #menu-running-text         |
| IMG-012 | `settings-security.png`         | Menu Keamanan PIN di pengaturan                  | `panduan.html` #menu-keamanan-pin         |
| IMG-013 | `settings-treasury.png`         | Menu Informasi Kas di pengaturan                 | `panduan.html` #menu-informasi-kas        |
| IMG-014 | `settings-wisdom-quote.png`     | Menu Kata Mutiara di pengaturan                  | `panduan.html` #menu-kata-mutiara         |
| IMG-015 | `settings-slideshow.png`        | Menu Slideshow Pengumuman di pengaturan          | `panduan.html` #menu-slideshow-pengumuman |
| IMG-016 | `settings-imam-schedule.png`    | Menu Jadwal Imam di pengaturan                   | `panduan.html` #menu-jadwal-imam          |
| IMG-017 | `settings-midnight-mode.png`    | Menu Mode Hemat Daya di pengaturan               | `panduan.html` #menu-mode-hemat-daya      |
| IMG-018 | `settings-reset-data.png`       | Menu Reset Data (tombol reset + dialog)          | `panduan.html` #menu-reset-data           |

## Spesifikasi Teknis

- **Format**: PNG
- **Resolusi**: 1920×1080 px (16:9, resolusi asli Android TV)
- **Ukuran file**: Maksimal 1 MB per gambar
- **Pengambilan screenshot**: `adb exec-out screencap -p > nama_file.png`
- **Kompres PNG**: `pngquant --quality=65-80 nama_file.png` (opsional, untuk ukuran lebih kecil)

## Cara Menambahkan Screenshot Baru ke `panduan.html`

Halaman `panduan.html` tidak menampilkan placeholder kosong untuk screenshot
yang belum tersedia. Setelah file final tersedia di folder `guide/`, tambahkan
blok `<figure>` berikut ke section panduan yang sesuai:

```html
<figure class="guide-figure guide-figure-sm mt-3 mb-0">
  <div class="guide-screenshot-label">
    <i class="bi bi-gear" aria-hidden="true"></i> Tampilan menu pengaturan
  </div>
  <div class="screenshot-container">
    <img
      src="assets/img/screenshots/guide/settings-identity.png"
      alt="Menu Identitas Masjid di pengaturan Miqotul Khoir TV"
      loading="lazy"
      width="1920"
      height="1080"
    />
  </div>
  <figcaption>Tampilan menu Identitas Masjid di pengaturan</figcaption>
</figure>
```

Selalu sertakan `loading="lazy"`, `alt` deskriptif, dan `width`/`height` untuk
mencegah Cumulative Layout Shift (CLS). Jangan memasang screenshot yang berisi
PIN asli, data kas nyata, atau identitas masjid yang tidak boleh dipublikasikan.
