# 📄 Product Requirement Document (PRD)
**Nama Fitur:** Mode Hemat Daya Tengah Malam (Midnight Screensaver)
**Status:** Perencanaan (Draft)
**Platform:** Android TV (Flutter)

## 1. Ringkasan Eksekutif
Fitur ini bertujuan untuk mengaktifkan "Mode Tidur" cerdas pada jam-jam malam saat masjid sedang kosong atau aktivitas jamaah minim. Alih-alih mematikan TV sepenuhnya, aplikasi akan menampilkan layar hitam pekat yang memuat informasi esensial: Jam Saat Ini dan Jadwal Subuh. Untuk mencegah kerusakan piksel TV (*screen burn-in*), teks informasi tersebut akan melayang atau berpindah posisi secara berkala dan perlahan. Fitur ini bersifat opsional dan DKM memiliki kendali penuh melalui menu pengaturan.

## 2. Tujuan & Metrik Keberhasilan
* **Keawetan Perangkat Keras:** Mencegah *screen burn-in* pada panel TV LED/OLED akibat gambar statis (seperti tabel jadwal sholat) yang menyala berjam-jam.
* **Efisiensi Sumber Daya:** Menghentikan *render loop* berat (seperti *running text* dan animasi *glassmorphism*) agar CPU/GPU Set Top Box/Android TV bisa mendingin dan menghemat daya listrik.
* **Fungsionalitas Berkelanjutan:** Tetap memberikan panduan waktu bagi jamaah yang sedang *qiyamullail* atau i'tikaf di sepertiga malam.
* **Kendali DKM:** Memastikan pengurus masjid dapat menghidupkan/mematikan fitur ini serta tetap bisa mengakses menu pengaturan saat mode ini aktif.

## 3. Spesifikasi Kebutuhan Fungsional (Functional Requirements)

### A. Konfigurasi Pengaturan (Settings Menu)
* **Toggle Utama:** Harus tersedia *switch* atau *checkbox* "Aktifkan Mode Hemat Daya Malam" di halaman Pengaturan.
* **Kondisi Bawaan (Default):** Secara bawaan (saat *first install*), fitur ini berada dalam kondisi **TIDAK AKTIF (OFF)**.
* **Parameter Waktu:** Jika diaktifkan, DKM dapat mengatur dua parameter menggunakan *dialog picker* yang ramah *remote* TV:
  * `Jam Mulai` (Contoh standar: 23:00)
  * `Jam Berakhir` (Contoh standar: 03:30)

### B. Logika Pemicu Waktu (Time Triggering)
* Evaluasi pemicu hanya berjalan jika *toggle* utama dalam keadaan **AKTIF**.
* Ketika jam sistem memasuki `Jam Mulai`, *State Machine* aplikasi otomatis beralih ke Mode Hemat Daya.
* Ketika jam sistem memasuki `Jam Berakhir`, *State Machine* otomatis kembali ke Mode Siaga (*StandbyState*) yang menampilkan UI penuh.

### C. Komponen Antarmuka & Anti Burn-in (Screensaver)
* **Latar Belakang:** Layar berwarna hitam mutlak (`#000000`).
* **Elemen Teks:**
  * **Jam Utama:** Menampilkan jam dan menit (HH:mm) dengan ukuran *font* sangat besar. Warna menggunakan putih redup atau hijau redup agar nyaman di ruangan gelap.
  * **Info Subuh:** Menampilkan teks jadwal Subuh di bawah jam utama (Contoh: "Subuh - 04:39") dengan ukuran *font* proporsional.
* **Logika Pergerakan (Anti Burn-in):**
  * Blok elemen teks tidak boleh statis di satu titik.
  * Setiap interval tertentu (misal: 1 atau 2 menit), blok teks berpindah koordinat.
  * Transisi perpindahan harus menggunakan animasi yang sangat lambat dan halus (durasi transisi ~10-15 detik) agar tidak mendistraksi jamaah.
* **Suspensi Latar Belakang:** *Running text* (*marquee*) dan *timer* hitung mundur sholat di belakang layar wajib dihentikan sementara (di-*pause*) selama mode ini aktif untuk membebaskan memori.

### D. Interaksi Remote TV (Escape Hatch)
* Aksesibilitas tidak boleh terputus saat layar menjadi hitam.
* Menekan tombol **OK/Center** atau **Menu** pada *remote* TV harus langsung memunculkan layar/dialog Pengaturan.
* (Opsional) Menekan tombol arah (D-Pad) dapat "membangunkan" layar ke UI normal selama 1 menit, sebelum kembali ke layar hitam jika tidak ada aktivitas lanjutan.

## 4. Panduan Implementasi Arsitektur (Technical Guidelines)

Mengacu pada *Clean Architecture* yang diterapkan, berikut rancangannya:

* **Data Layer (SQLite & Repository):**
  * Tambahkan kolom di tabel preferensi:
    * `is_midnight_mode_enabled` (BOOLEAN, default 0).
    * `midnight_start_time` (TEXT, format HH:mm).
    * `midnight_end_time` (TEXT, format HH:mm).
* **Domain Layer (Use Case):**
  * Buat `CheckMidnightModeUseCase` yang dipanggil setiap menit oleh *timer* utama untuk memvalidasi apakah waktu saat ini berada di antara `Jam Mulai` dan `Jam Berakhir`.
* **Presentation Layer (BLoC/Cubit & UI):**
  * Tambahkan *state* baru: `MidnightStandbyState`.
  * Gunakan `AnimatedAlign` atau kalkulasi matriks dengan `Transform.translate` untuk menangani pergerakan teks anti burn-in tanpa memicu *rebuild* seluruh layar.
  * Gunakan `Focus` node atau `RawKeyboardListener` pada lapisan terluar *widget* `MidnightStandbyState` untuk mendengarkan *event* `LogicalKeyboardKey.select`. Jika terdeteksi, panggil *routing* ke halaman Pengaturan.

## 5. Skenario Pengujian (Test Cases)
1. **Uji Kondisi Bawaan:** Pastikan setelah instalasi, fitur ini mati dan layar tidak berubah hitam pada tengah malam.
2. **Uji Simpan Konfigurasi:** Aktifkan fitur, ubah jam, tutup paksa aplikasi, dan buka kembali. Pastikan preferensi tersimpan di SQLite dan statusnya tetap aktif.
3. **Uji Transisi Masuk & Keluar:** Atur jam sistem TV mendekati `Jam Mulai`. Pastikan layar berubah hitam tepat pada waktunya. Lalu atur jam mendekati `Jam Berakhir` dan pastikan UI utama kembali tanpa ada *lag* atau memori bocor (*memory leak*).
4. **Uji Animasi Anti Burn-in:** Biarkan mode ini aktif selama 10 menit. Observasi perpindahan posisi blok teks di layar dan pastikan pergerakannya mulus.
5. **Uji Akses Remote (Escape Hatch):** Saat layar dalam mode hemat daya, tekan tombol OK/Tengah pada *remote* atau emulator. Pastikan menu Pengaturan langsung terbuka dengan baik.