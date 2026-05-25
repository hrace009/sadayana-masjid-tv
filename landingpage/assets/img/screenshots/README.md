# Screenshot Folder

Letakkan screenshot tampilan aplikasi di folder ini.

## Nama File yang Diharapkan

| Nama File                   | Konten                                                          | Digunakan di                   |
| --------------------------- | --------------------------------------------------------------- | ------------------------------ |
| `standby.png`               | Layar standby utama: jam digital, jadwal sholat, kas masjid     | `index.html` — screenshot ke-1 |
| `pre-adzan.png`             | Hitung mundur menjelang waktu Adzan                             | `index.html` — screenshot ke-2 |
| `iqomah.png`                | Hitung mundur Iqomah                                            | `index.html` — screenshot ke-3 |
| `settings.png`              | Menu pengaturan (via remote TV)                                 | `index.html` — screenshot ke-4 |
| `wisdom.png`                | Tampilan Kata Mutiara Islam                                     | `index.html` — screenshot ke-5 |
| `slideshow.png`             | Slideshow pengumuman gambar                                     | `index.html` — screenshot ke-6 |
| `imam-schedule-weekday.png` | Tampilan Jadwal Imam hari biasa di layar utama                  | `index.html` — screenshot ke-7 |
| `imam-schedule-jumat.png`   | Tampilan Jadwal Imam hari Jumat dengan Khatib dan Imam terpisah | `index.html` — screenshot ke-8 |

## Spesifikasi Teknis

- **Format**: PNG
- **Rasio**: 16:9 (resolusi asli Android TV: 1920×1080 px)
- **Ukuran file**: Maksimal 1 MB per gambar
- **Cara ambil screenshot**: gunakan ADB `adb exec-out screencap -p > nama_file.png`

## Cara Mengaktifkan Screenshot di HTML

Setelah file tersedia, ganti setiap blok `<div class="screenshot-placeholder">` di `index.html`
dengan elemen `<img>`:

```html
<img
  src="assets/img/screenshots/standby.png"
  alt="Tampilan layar standby Miqotul Khoir TV Masjid"
  class="img-fluid rounded"
  loading="lazy"
  width="1920"
  height="1080"
/>
```

Tambahkan atribut `loading="lazy"`, `alt` deskriptif, serta `width`/`height` untuk menghindari
Cumulative Layout Shift (CLS).
