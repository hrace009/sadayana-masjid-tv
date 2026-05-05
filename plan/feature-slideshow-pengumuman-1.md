---
goal: "Implementasi Fitur Slideshow Pengumuman Masjid - 3 Gambar, Picker Android TV, dan Tampilan Aman 1280x720"
version: "1.0"
date_created: "2026-05-04"
last_updated: "2026-05-05"
owner: "Gulajava Ministudio"
status: "Planned"
tags: [feature, slideshow, announcement, android-tv, settings, sqlite, storage, display]
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

Dokumen ini mendefinisikan rencana implementasi fitur **Slideshow Pengumuman
Masjid** untuk aplikasi Miqotul Khoir TV. Fitur menampilkan maksimal 3 gambar
pengumuman secara periodik di layar utama sebagai state full-screen terpisah
dari Wisdom Quote, dengan jadwal aktif sendiri, toggle ON/OFF sendiri, serta
manajemen gambar melalui menu Settings.

Gambar dipilih melalui system file picker Android TV, lalu **diimpor ke
storage internal aplikasi** agar fitur tetap stabil, offline-first, dan tidak
bergantung pada lokasi file eksternal. Saat gambar dihapus dari slideshow,
metadata database dan file internal harus dihapus dalam operasi yang sama.

Tampilan slideshow menggunakan layar penuh, tetapi area gambar aktif dibatasi
ke **kanvas aman 1280x720** yang dipusatkan di layar TV. Jika rasio atau ukuran
gambar lebih besar dari kanvas tersebut, gambar dirender dengan perilaku setara
`object-fit: contain`, dengan implementasi MVP menggunakan `BoxFit.scaleDown`
agar gambar tidak terpotong kiri-kanan.

## 1. Requirements & Constraints

- **REQ-001**: Fitur slideshow harus bersifat opsional dan **default OFF** pada
  fresh install maupun setelah migration.
- **REQ-002**: Slideshow hanya boleh dievaluasi oleh runtime jika
  `isSlideshowEnabled == true`, minimal ada 1 gambar tersimpan, dan waktu saat
  ini berada di dalam window aktif slideshow.
- **REQ-003**: Slideshow dan Wisdom Quote harus memiliki jadwal aktif terpisah.
- **REQ-004**: Jika window slideshow overlap dengan window Wisdom Quote,
  slideshow harus memiliki prioritas lebih tinggi daripada Wisdom Quote.
- **REQ-005**: State sholat utama tetap memiliki prioritas tertinggi, sehingga
  urutan prioritas runtime harus: prayer cycle -> midnight mode -> slideshow ->
  wisdom -> standby.
- **REQ-006**: Jumlah gambar slideshow dibatasi **maksimal 3 gambar** dengan 3
  slot tetap yang terurut.
- **REQ-007**: Pengguna dapat menambahkan, mengganti, mempratinjau, dan
  menghapus gambar dari tiap slot melalui menu Settings.
- **REQ-008**: Menambahkan gambar tidak boleh otomatis menyalakan fitur
  slideshow.
- **REQ-009**: Jika gambar terakhir dihapus, toggle slideshow harus otomatis
  dimatikan sebagai perilaku UX yang konsisten.
- **REQ-010**: Saat toggle slideshow OFF, gambar yang sudah diimpor harus tetap
  tersimpan dan tetap bisa dikelola dari UI settings.
- **REQ-011**: Saat gambar dihapus dari slideshow, file fisik di internal
  storage aplikasi dan metadata baris database harus dihapus dalam satu alur
  operasi.
- **REQ-012**: Gambar dipilih melalui system file picker dengan filter image
  statis yang didukung: `jpg`, `jpeg`, `png`, dan `webp`.
- **REQ-013**: Gambar yang dipilih harus disalin ke direktori app-specific
  internal storage menggunakan nama file terkontrol aplikasi.
- **REQ-014**: Slideshow harus mempunyai konfigurasi terpisah untuk:
  `slideshowIntervalMinutes`, `slideshowSlotDurationMinutes`,
  `slideshowImageDurationSeconds`, `slideshowStartHour`,
  `slideshowStartMinute`, `slideshowEndHour`, dan
  `slideshowEndMinute`.
- **REQ-015**: `slideshowIntervalMinutes` harus didefinisikan sebagai jeda
  antar-slot setelah satu slot slideshow selesai.
- **REQ-016**: `slideshowSlotDurationMinutes` harus didefinisikan sebagai lama
  total satu slot slideshow tampil di layar utama.
- **REQ-017**: `slideshowImageDurationSeconds` harus didefinisikan sebagai durasi
  satu gambar di dalam slot slideshow sebelum berpindah ke gambar berikutnya.
- **REQ-018**: Saat slot slideshow aktif, urutan gambar mengikuti urutan slot:
  slot 1 -> slot 2 -> slot 3, dengan slot kosong diabaikan.
- **REQ-019**: Tampilan slideshow harus menggunakan state full-screen baru,
  bukan overlay di atas `StandbyLayout`.
- **REQ-020**: Area gambar aktif harus dibatasi ke kanvas aman 1280x720 yang
  dipusatkan pada layar 1920x1080 maupun 1280x720.
- **REQ-021**: Gambar tidak boleh di-crop kiri-kanan atau atas-bawah. Runtime
  harus menggunakan strategi render setara `object-fit: contain` dengan MVP
  `BoxFit.scaleDown`.
- **REQ-022**: UI Settings harus menampilkan 3 slot tetap, bukan daftar dinamis
  tanpa batas.
- **REQ-023**: Section settings slideshow harus tetap memperbolehkan user
  mengelola gambar meskipun toggle slideshow sedang OFF.
- **REQ-024**: Tersedia halaman pratinjau fullscreen untuk melihat satu gambar
  secara penuh dengan aturan layout yang sama seperti runtime slideshow.

- **SEC-001**: File sumber dari picker tidak boleh dipakai langsung pada
  runtime. Aplikasi hanya boleh merender file hasil impor dari internal
  storage-nya sendiri.
- **SEC-002**: Semua update SQLite wajib menggunakan repository/data source yang
  sudah ada dan parameterized query bawaan `sqflite`.
- **SEC-003**: Nama file hasil impor harus digenerate aplikasi agar tidak
  bergantung pada path eksternal pengguna.
- **SEC-004**: File non-gambar harus ditolak sebelum disimpan ke internal
  storage.

- **CON-001**: Versi database saat ini adalah `9`, sehingga fitur ini harus
  menggunakan migration ke versi `10`.
- **CON-002**: Proyek tetap offline-first; tidak boleh ada network call untuk
  upload, sinkronisasi, atau CDN image.
- **CON-003**: Picker di Android TV bergantung pada Documents Provider / file
  manager yang tersedia di perangkat. Fitur harus menganggap picker sebagai
  jalur impor, bukan jalur baca permanen.
- **CON-004**: Scope MVP hanya mendukung gambar statis. GIF animasi, video, dan
  PDF tidak termasuk cakupan.
- **CON-005**: Layout utama aplikasi hanya dapat merender satu `DisplayState`
  pada satu waktu.
- **CON-006**: Maksimal 3 slot tetap berarti validasi jumlah gambar tidak
  menggunakan list tak terbatas, tetapi menggunakan slot indeks 1..3.
- **CON-007**: Penyimpanan file internal harus kompatibel dengan Android dan
  Windows karena proyek ini juga dijalankan pada desktop selama development.

- **GUD-001**: Ikuti pola migration `if (oldVersion < N)` di
  `DatabaseHelper._onUpgrade()`.
- **GUD-002**: Ikuti pola settings scalar yang sudah ada: toggle memakai
  `_saveField()`, input stepper memakai `_debounceSave()` di `SettingsCubit`.
- **GUD-003**: Ikuti pola repository + local datasource + model seperti fitur
  data lokal lain di proyek ini.
- **GUD-004**: Gunakan `LayoutBuilder` + `FittedBox(fit: BoxFit.scaleDown)`
  untuk kompatibilitas 1920x1080 dan 1280x720.
- **GUD-005**: Gunakan `IslamicBackground` atau background gelap sejenis, tetapi
  area gambar aktif tetap berupa kanvas hitam 1280x720 di tengah layar.
- **GUD-006**: Hanya blok jadwal yang dibuat non-interaktif saat toggle OFF;
  blok manajemen gambar tetap aktif.
- **GUD-007**: Auto-disable toggle saat gambar terakhir dihapus dilakukan dari
  alur UX section settings agar status visual dan state settings tetap sinkron.

- **PAT-001**: Tambahkan state slideshow melalui pola yang sama dengan Wisdom:
  `DisplayStateType` -> entity state -> evaluator -> cubit -> switch di
  `MainDisplayPage`.
- **PAT-002**: Gunakan slot tetap 1..3 sebagai urutan slideshow dan identitas UI
  settings.
- **PAT-003**: Gunakan `file_picker` sebagai pembuka system picker dan
  `path_provider` untuk mendapatkan direktori internal aplikasi.
- **PAT-004**: Gunakan operasi replace yang eksplisit: hapus file lama slot,
  impor file baru, simpan metadata baru.
- **PAT-005**: Gunakan `BoxFit.scaleDown` untuk MVP slideshow runtime dan halaman
  pratinjau.

## 2. Implementation Steps

<!-- markdownlint-disable MD060 -->

### Implementation Phase 1

- **GOAL-001**: Menambahkan kontrak domain dan field konfigurasi slideshow pada
  entity settings, transition config, dan display state.
- **Coverage Review**: Phase ini menutup REQ-001, REQ-014, REQ-019, CON-005,
  CON-006, dan PAT-001.
- **TS-P1-001**: Tambahkan `DisplayStateType.slideshowAnnouncement` sebelum
  `wisdomQuote` agar urutan enum dan switch lebih mudah dibaca dan konsisten
  dengan prioritas runtime.
- **TS-P1-002**: Default values field slideshow harus identik di `Settings`,
  `TransitionConfig`, `SettingsModel`, dan migration SQLite agar tidak ada drift
  konfigurasi antar layer.
- **TS-P1-003**: `SlideshowImage.slotIndex` wajib berada pada rentang `1..3`
  dan merepresentasikan urutan slideshow permanen, bukan ID database dinamis.
- **TS-P1-004**: `SlideshowAnnouncementState.currentIndex` harus 0-based
  terhadap daftar gambar aktif yang telah diurutkan berdasarkan `slotIndex`.
- **TS-P1-005**: `SlideshowAnnouncementState.totalItems` harus menghitung hanya
  slot yang terisi, bukan angka tetap `3`.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                              | Completed | Date |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- | ---- |
| TASK-001 | Update `lib/domain/entities/settings.dart` untuk menambahkan 8 field baru: `isSlideshowEnabled` (default `false`), `slideshowIntervalMinutes` (default `15`), `slideshowSlotDurationMinutes` (default `2`), `slideshowImageDurationSeconds` (default `15`), `slideshowStartHour` (default `6`), `slideshowStartMinute` (default `0`), `slideshowEndHour` (default `21`), dan `slideshowEndMinute` (default `0`). Update constructor defaults, `copyWith()`, dan `props`. |           |      |
| TASK-002 | Update `lib/domain/entities/transition_config.dart` untuk memetakan 8 field slideshow baru dari `Settings` ke `TransitionConfig`, termasuk default values dan `props`.                                                                                                                                                                                                                                                                                                   |           |      |
| TASK-003 | Buat file `lib/domain/entities/slideshow_image.dart` berisi immutable entity `SlideshowImage` dengan field: `int slotIndex` (`1..3`), `String fileName`, `String storedPath`, `String mimeType`, `int width`, `int height`, `int fileSizeBytes`. Entity harus `Equatable` dan `props` mengikuti seluruh field.                                                                                                                                                           |           |      |
| TASK-004 | Buat file `lib/domain/repositories/slideshow_image_repository.dart` dengan interface: `Future<List<SlideshowImage>> getAll()`, `Future<SlideshowImage?> getBySlot(int slotIndex)`, `Future<void> save(SlideshowImage image)`, `Future<void> deleteBySlot(int slotIndex)`, dan `Future<int> count()`.                                                                                                                                                                     |           |      |
| TASK-005 | Buat file `lib/domain/services/slideshow_file_storage_service.dart` dengan interface: `Future<SlideshowImage> importImage({required int slotIndex, required String originalFileName, required Uint8List bytes})` dan `Future<void> deleteStoredImage(String storedPath)`.                                                                                                                                                                                                |           |      |
| TASK-006 | Update `lib/domain/entities/display_state_type.dart` untuk menambahkan enum baru `slideshowAnnouncement`.                                                                                                                                                                                                                                                                                                                                                                |           |      |
| TASK-007 | Update `lib/domain/entities/display_state.dart` untuk menambahkan `SlideshowAnnouncementState` dengan field: `SlideshowImage currentImage`, `int currentIndex`, `int totalItems`, `DateTime currentTime`, `int totalSlotDurationSeconds`, `int remainingSlotSeconds`, `int imageDurationSeconds`, dan `int remainingImageSeconds`.                                                                                                                                       |           |      |

### Implementation Phase 2

- **GOAL-002**: Menambahkan schema SQLite baru untuk konfigurasi slideshow dan
  penyimpanan metadata 3 slot gambar.
- **Coverage Review**: Phase ini menutup REQ-001, REQ-006, REQ-014, CON-001,
  dan CON-006.
- **TS-P2-001**: Nama tabel metadata slideshow wajib `slideshow_images` dan
  tidak menggunakan surrogate ID tambahan.
- **TS-P2-002**: `slot_index` harus menjadi primary key tunggal dengan `CHECK
  (slot_index BETWEEN 1 AND 3)` agar satu slot selalu merepresentasikan satu row.
- **TS-P2-003**: `stored_path` harus diperlakukan sebagai path internal final
  dan tidak boleh mengandung URI eksternal hasil picker.
- **TS-P2-004**: Tabel `slideshow_images` tidak menggunakan soft delete;
  penghapusan slot berarti row dihapus permanen.
- **TS-P2-005**: Operasi save/upsert metadata slideshow harus memperbarui
  `updated_at` secara eksplisit agar debug state slot lebih mudah dilakukan.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Completed | Date |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-008 | Update `lib/data/datasources/database_helper.dart` dengan menaikkan `_databaseVersion` dari `9` ke `10`.                                                                                                                                                                                                                                                                                                                                                                         |           |      |
| TASK-009 | Tambahkan migration block `if (oldVersion < 10)` di `_onUpgrade()` untuk menambahkan 8 kolom slideshow ke tabel `settings`: `is_slideshow_enabled`, `slideshow_interval_minutes`, `slideshow_slot_duration_minutes`, `slideshow_image_duration_seconds`, `slideshow_start_hour`, `slideshow_start_minute`, `slideshow_end_hour`, dan `slideshow_end_minute`, lengkap dengan default values yang sama seperti domain.                                                             |           |      |
| TASK-010 | Update DDL `CREATE TABLE settings` di `_createTables()` agar 8 kolom slideshow baru tersedia juga pada fresh install.                                                                                                                                                                                                                                                                                                                                                            |           |      |
| TASK-011 | Tambahkan DDL tabel baru `slideshow_images` di `_createTables()` dengan skema: `slot_index INTEGER PRIMARY KEY CHECK (slot_index BETWEEN 1 AND 3)`, `file_name TEXT NOT NULL`, `stored_path TEXT NOT NULL UNIQUE`, `mime_type TEXT NOT NULL`, `width INTEGER NOT NULL`, `height INTEGER NOT NULL`, `file_size_bytes INTEGER NOT NULL`, `created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))`, dan `updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))`. |           |      |
| TASK-012 | Update `lib/data/models/settings_model.dart` agar `fromMap()` dan `toMap()` memetakan 8 field slideshow baru antara snake_case SQLite dan camelCase entity.                                                                                                                                                                                                                                                                                                                      |           |      |
| TASK-013 | Buat file `lib/data/models/slideshow_image_model.dart` dengan `fromMap(Map<String, dynamic>)`, `toMap()`, dan `toEntity()` untuk `SlideshowImage`.                                                                                                                                                                                                                                                                                                                               |           |      |

### Implementation Phase 3

- **GOAL-003**: Menyediakan data access layer untuk CRUD metadata slideshow dan
  service penyimpanan file internal.
- **Coverage Review**: Phase ini menutup REQ-013, SEC-001, SEC-002, SEC-003,
  SEC-004, dan CON-007.
- **TS-P3-001**: Direktori internal slideshow wajib berada di bawah hasil
  `getApplicationDocumentsDirectory()` pada subfolder `slideshow/`.
- **TS-P3-002**: Nama file hasil impor harus digenerate aplikasi dengan pola
  `slide_slot_{slotIndex}_{millisecondsSinceEpoch}.{ext}` untuk mencegah konflik
  dan menghilangkan ketergantungan pada nama file eksternal.
- **TS-P3-003**: Validasi whitelist `jpg`, `jpeg`, `png`, dan `webp` dilakukan
  sebelum file ditulis ke disk.
- **TS-P3-004**: Metadata `width` dan `height` harus dibaca dari bytes gambar
  hasil picker, bukan dari nama file atau asumsi rasio. Jika decode dimensi
  gagal, file diperlakukan sebagai non-image dan harus ditolak sebelum write.
- **TS-P3-005**: Upsert metadata per slot harus deterministik, baik dengan
  `ConflictAlgorithm.replace` atau update eksplisit berbasis `slot_index`.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-014 | Buat file `lib/data/datasources/slideshow_image_local_data_source.dart` dengan operasi `getAll()`, `getBySlot(int)`, `save(Map<String, dynamic>)`, `deleteBySlot(int)`, dan `count()`. `save()` harus menggunakan upsert berbasis `slot_index` dan memperbarui `updated_at` secara eksplisit pada operasi update/save.                                                                                                                                                                                                                                    |           |      |
| TASK-015 | Buat file `lib/data/repositories/slideshow_image_repository_impl.dart` yang mengimplementasikan `SlideshowImageRepository` dan mendelegasikan CRUD ke `SlideshowImageLocalDataSource`.                                                                                                                                                                                                                                                                                                                                                                    |           |      |
| TASK-016 | Tambahkan dependency langsung `file_picker` dan `path_provider` ke `pubspec.yaml`. `path_provider` harus menjadi dependency langsung, bukan hanya transitive dependency.                                                                                                                                                                                                                                                                                                                                                                                  |           |      |
| TASK-017 | Buat file `lib/data/services/slideshow_file_storage_service_impl.dart` yang mengimplementasikan `SlideshowFileStorageService` dengan alur: ambil app documents directory via `getApplicationDocumentsDirectory()`, buat subfolder `slideshow/` jika belum ada, generate nama file internal terkontrol aplikasi dengan pola `slide_slot_{slotIndex}_{millisecondsSinceEpoch}.{ext}`, validasi ekstensi whitelist, decode bytes untuk membaca dimensi gambar, tolak file jika bytes bukan image valid, lalu simpan file dan return entity `SlideshowImage`. |           |      |
| TASK-018 | Implementasikan `deleteStoredImage()` di `SlideshowFileStorageServiceImpl` agar aman dipanggil berulang: jika file ada maka hapus, jika file sudah tidak ada maka no-op.                                                                                                                                                                                                                                                                                                                                                                                  |           |      |

### Implementation Phase 4

- **GOAL-004**: Menambahkan state management presentation untuk manajemen 3 slot
  gambar slideshow dan update scalar settings slideshow.
- **Coverage Review**: Phase ini menutup REQ-007, REQ-008, REQ-009, REQ-010,
  REQ-011, REQ-012, REQ-023, GUD-006, dan GUD-007.
- **TS-P4-001**: `SlideshowSectionCubit` hanya menangani picker, impor file,
  replace file, delete file, dan reload slot. Scalar settings tetap menjadi
  tanggung jawab `SettingsCubit`.
- **TS-P4-002**: `importIntoSlot()` dan `replaceSlot()` tidak boleh memanggil
  `updateSlideshowEnabled(true)`; toggle ON tetap aksi eksplisit user.
- **TS-P4-003**: `deleteFromSlot()` harus menghasilkan state baru yang memuat
  daftar slot terkini sehingga UI dapat menghitung apakah jumlah gambar sisa `0`.
- **TS-P4-004**: `errorMessage` hanya dipakai untuk surface kegagalan I/O atau
  picker, dan tidak boleh diam-diam memodifikasi scalar settings slideshow.
- **TS-P4-005**: Validation rules scalar settings slideshow harus deterministik:
  `slideshowIntervalMinutes` `5..60` step `5`,
  `slideshowSlotDurationMinutes` `1..10` step `1`,
  `slideshowImageDurationSeconds` `5..30` step `5`, jam `0..23`, dan menit
  `0..59` dengan step UI `5` untuk DPadStepper menit.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Completed | Date |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-019 | Buat file `lib/presentation/cubits/slideshow_section/slideshow_section_state.dart` dengan state yang memuat `List<SlideshowImage> images`, `bool isLoading`, `bool isBusy`, dan `String? errorMessage`.                                                                                                                                                                                                                                                                                                           |           |      |
| TASK-020 | Buat file `lib/presentation/cubits/slideshow_section/slideshow_section_cubit.dart` yang mengelola `loadImages()`, `importIntoSlot(int slotIndex)`, `replaceSlot(int slotIndex)`, `deleteFromSlot(int slotIndex)`, dan `clearError()`. Cubit ini bergantung pada `SlideshowImageRepository` dan `SlideshowFileStorageService`.                                                                                                                                                                                     |           |      |
| TASK-021 | Implementasikan `importIntoSlot()` dan `replaceSlot()` dengan `FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'], allowMultiple: false, withData: true)`. Jika user cancel picker, state tidak berubah. Method ini tidak boleh mengaktifkan toggle slideshow secara otomatis.                                                                                                                                                                                         |           |      |
| TASK-022 | Implementasikan alur replace di `SlideshowSectionCubit`: jika slot sudah terisi, hapus file lama via `SlideshowFileStorageService.deleteStoredImage()`, kemudian impor file baru, lalu simpan metadata baru via repository.                                                                                                                                                                                                                                                                                       |           |      |
| TASK-023 | Implementasikan alur delete di `SlideshowSectionCubit`: ambil image by slot, hapus file internal via service, hapus metadata via repository, lalu reload list slot.                                                                                                                                                                                                                                                                                                                                               |           |      |
| TASK-024 | Update `lib/presentation/cubits/settings/settings_cubit.dart` dengan 8 method baru: `updateSlideshowEnabled`, `updateSlideshowIntervalMinutes`, `updateSlideshowSlotDurationMinutes`, `updateSlideshowImageDurationSeconds`, `updateSlideshowStartHour`, `updateSlideshowStartMinute`, `updateSlideshowEndHour`, dan `updateSlideshowEndMinute`. Toggle memakai `_saveField()`, numeric inputs memakai `_debounceSave()`, dan setiap method numeric harus memvalidasi range yang sudah ditetapkan pada phase ini. |           |      |

### Implementation Phase 5

- **GOAL-005**: Mengintegrasikan slideshow ke evaluator runtime, display cubit,
  dan prioritas state utama aplikasi.
- **Coverage Review**: Phase ini menutup REQ-002, REQ-003, REQ-004, REQ-005,
  REQ-015, REQ-016, REQ-017, dan REQ-018.
- **TS-P5-001**: Daftar `slideshowImages` harus diurutkan naik berdasarkan
  `slotIndex` dan hanya memuat slot valid `1..3` sebelum dipakai evaluator.
- **TS-P5-002**: Rumus waktu slideshow wajib eksplisit:
  `slotDurationSeconds = slideshowSlotDurationMinutes * 60`,
  `intervalSeconds = slideshowIntervalMinutes * 60`, dan
  `cycleLengthSeconds = slotDurationSeconds + intervalSeconds`.
- **TS-P5-003**: `positionInCycle = secondsSinceWindowStart % cycleLengthSeconds`.
  Jika `positionInCycle >= slotDurationSeconds`, evaluator harus mengembalikan
  `null` dan lanjut ke wisdom atau standby.
- **TS-P5-004**: Index gambar dihitung dengan rumus
  `(positionInCycle ~/ imageDurationSeconds) % activeImages.length`, sehingga
  setiap slot slideshow selalu dimulai dari gambar pertama aktif.
- **TS-P5-005**: Urutan evaluator harus ditulis literal dan tidak diandalkan pada
  urutan enum: prayer cycle -> midnight -> slideshow -> wisdom -> standby.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-025 | Update signature `evaluate()` di `lib/domain/usecases/evaluate_display_state_use_case.dart` dengan parameter baru `List<SlideshowImage>? slideshowImages`.                                                                                                                                                                                                                                                                                                                        |           |      |
| TASK-026 | Implementasikan `_evaluateSlideshowWindow()` di `EvaluateDisplayStateUseCase` setelah midnight mode dan sebelum wisdom quote. Logika harus: hitung window aktif slideshow, hitung `slotDurationSeconds`, `intervalSeconds`, dan `cycleLengthSeconds`, cek apakah `now` berada di dalam slot slideshow, lalu pilih gambar berdasarkan `(positionInCycle ~/ slideshowImageDurationSeconds) % activeImages.length` dengan slot kosong diabaikan dan urutan slot tetap `1 -> 2 -> 3`. |           |      |
| TASK-027 | Pastikan evaluator memakai guard lengkap: slideshow hanya boleh aktif jika config enabled, `slideshowImages != null`, dan `slideshowImages.isNotEmpty`. Jika tidak, evaluator harus lanjut ke wisdom check atau standby.                                                                                                                                                                                                                                                          |           |      |
| TASK-028 | Update `lib/presentation/cubits/display_state/display_state_cubit.dart` agar constructor menerima `SlideshowImageRepository slideshowImageRepository`, menyimpan field `_activeSlideshowImages`, dan memuat gambar aktif di `_loadConfig()` bersama settings serta wisdom quotes.                                                                                                                                                                                                 |           |      |
| TASK-029 | Update pemanggilan `_evaluateUseCase.evaluate(...)` di `_tick()` untuk meneruskan `slideshowImages: _activeSlideshowImages`.                                                                                                                                                                                                                                                                                                                                                      |           |      |
| TASK-030 | Pastikan `onSettingsChanged()` di `DisplayStateCubit` me-reload konfigurasi dan gambar slideshow, sehingga toggle, jadwal, dan daftar gambar terbaru langsung mempengaruhi evaluator.                                                                                                                                                                                                                                                                                             |           |      |

### Implementation Phase 6

- **GOAL-006**: Membangun UI Settings Slideshow yang detail, ramah D-pad, dan
  konsisten dengan pola settings yang sudah ada.
- **Coverage Review**: Phase ini menutup REQ-007, REQ-009, REQ-010, REQ-022,
  REQ-023, REQ-024, GUD-006, dan GUD-007.
- **TS-P6-001**: Urutan visual section harus tetap: header -> toggle ->
  ringkasan status -> blok jadwal -> tiga slot gambar.
- **TS-P6-002**: Saat toggle OFF, hanya blok jadwal yang non-interaktif; slot
  gambar, tombol pilih/ganti, pratinjau, dan hapus tetap fokusable dan usable.
- **TS-P6-003**: Thumbnail slot harus ditampilkan dalam box 16:9 berlatar hitam
  dengan fit non-cropping (`BoxFit.contain` atau `BoxFit.scaleDown`) agar preview
  kecil tetap merepresentasikan hasil runtime secara jujur.
- **TS-P6-004**: Listener auto-disable hanya boleh berjalan setelah delete slot
  berhasil tersimpan dan jumlah gambar tersisa benar-benar `0`.
- **TS-P6-005**: Halaman preview harus memakai aturan layout yang sama dengan
  runtime slideshow dan tombol back harus menutup preview tanpa mengubah data.
- **TS-P6-006**: DPadStepper settings slideshow harus memakai konfigurasi UI
  eksplisit: interval `5..60` step `5`, slot duration `1..10` step `1`, image
  duration `5..30` step `5`, jam `0..23`, dan menit `0..59` step `5`.

| Task     | Description                                                                                                                                                                                                                                                                                   | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-031 | Buat file `lib/presentation/pages/settings/sections/slideshow_section.dart` sebagai section baru untuk slideshow. Section harus memakai `BlocBuilder<SettingsCubit, SettingsState>` untuk scalar settings dan `BlocProvider<SlideshowSectionCubit>` untuk manajemen slot gambar.              |           |      |
| TASK-032 | Implementasikan header section dengan judul, deskripsi singkat, dan ringkasan status: ON/OFF, jumlah gambar terisi (`n/3`), interval, durasi slot, durasi per gambar, dan jam aktif.                                                                                                          |           |      |
| TASK-033 | Implementasikan toggle utama `Aktifkan Slideshow Pengumuman` dengan pola `FocusableWidget` + `Switch.adaptive` visual-only seperti feature settings lain.                                                                                                                                     |           |      |
| TASK-034 | Implementasikan blok jadwal dengan `DPadStepper` untuk 7 field durasi/jam. Blok ini harus dibungkus `ExcludeFocus`, `IgnorePointer`, dan `Opacity` saat slideshow OFF, tetapi area manajemen gambar tetap aktif. Gunakan range dan step eksplisit sesuai phase ini.                           |           |      |
| TASK-035 | Implementasikan 3 slot tetap dalam urutan 1..3. Tiap slot harus menampilkan placeholder jika kosong, atau thumbnail + nama file + resolusi jika terisi, serta tombol `Pilih/Ganti`, `Pratinjau`, dan `Hapus`. Thumbnail harus menggunakan preview non-cropping di dalam box 16:9.             |           |      |
| TASK-036 | Implementasikan listener pada `slideshow_section.dart` yang memanggil `context.read<SettingsCubit>().updateSlideshowEnabled(false)` ketika `SlideshowSectionCubit` selesai delete dan jumlah gambar tersisa menjadi `0`. Ini adalah titik UX resmi untuk auto-disable toggle gambar terakhir. |           |      |
| TASK-037 | Update `lib/presentation/pages/settings/settings_menu_page.dart` untuk menambahkan kategori baru `Slideshow Pengumuman` setelah `Kata Mutiara` dan sebelum `Mode Hemat Daya`, serta menyisipkan `SlideshowSection()` pada posisi yang sama di `_sections`.                                    |           |      |
| TASK-038 | Buat file `lib/presentation/pages/slideshow_preview_page.dart` untuk menampilkan satu gambar fullscreen dengan layout aman yang sama seperti runtime slideshow. Halaman ini dibuka dari tombol `Pratinjau` pada tiap slot dan harus ditutup dengan back tanpa mengubah data slideshow.        |           |      |

### Implementation Phase 7

- **GOAL-007**: Membangun layout runtime slideshow full-screen dengan kanvas
  aman 1280x720 dan integrasi ke `MainDisplayPage`.
- **Coverage Review**: Phase ini menutup REQ-019, REQ-020, dan REQ-021.
- **TS-P7-001**: Struktur layout runtime wajib eksplisit:
  `Center -> FittedBox(BoxFit.scaleDown) -> SizedBox(1280x720) -> canvas hitam
  -> Image.file(...)`.
- **TS-P7-002**: Layout runtime tidak memakai header besar seperti wisdom quote;
  fokus utama harus tetap pada gambar pengumuman.
- **TS-P7-003**: Footer indikator ditempatkan di bagian bawah kanvas, dengan
  visual ringan dan tidak menutupi area inti gambar.
- **TS-P7-004**: Jika file gambar internal tidak ditemukan, layout harus punya
  fallback aman seperti placeholder kosong atau error container, bukan crash.

| Task     | Description                                                                                                                                                                                                                                         | Completed | Date |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-039 | Buat file `lib/presentation/pages/main_display/layouts/slideshow_layout.dart` sebagai `StatelessWidget` yang menerima `SlideshowAnnouncementState state`.                                                                                           |           |      |
| TASK-040 | Implementasikan background slideshow menggunakan `IslamicBackground` atau layer gelap yang setara, lalu tampilkan kanvas hitam terpusat berukuran desain `1280x720`.                                                                                |           |      |
| TASK-041 | Di dalam kanvas, render gambar dengan `Image.file(File(state.currentImage.storedPath), fit: BoxFit.scaleDown, alignment: Alignment.center, errorBuilder: ...)` atau wrapper setara agar tidak terjadi crop dan file hilang tidak menyebabkan crash. |           |      |
| TASK-042 | Tambahkan footer minimal yang menampilkan indikator posisi gambar (`1 / n`) dan sisa detik gambar aktif atau sisa slot, ditempatkan di bagian bawah kanvas tanpa mengurangi fokus utama ke gambar.                                                  |           |      |
| TASK-043 | Update `lib/presentation/pages/main_display_page.dart` untuk menambahkan case `DisplayStateType.slideshowAnnouncement` yang merender `SlideshowLayout`.                                                                                             |           |      |

### Implementation Phase 8

- **GOAL-008**: Menyelesaikan wiring dependency injection dan seluruh test untuk
  schema, state management, evaluator, dan UI slideshow.
- **Coverage Review**: Phase ini menutup seluruh kebutuhan wiring, validasi,
  serta regression safety untuk REQ-001 s.d. REQ-024 melalui test executable.
- **TS-P8-001**: `main.dart` harus mendaftarkan `SlideshowImageRepository` dan
  `SlideshowFileStorageService` ke dependency injection agar section settings
  tidak menginstansiasi implementasi konkret secara lokal.
- **TS-P8-002**: Test cubit slideshow harus memakai mock repository dan mock
  storage service agar side effect filesystem tidak bocor ke unit test.
- **TS-P8-003**: Widget test section slideshow harus menguji bahwa impor gambar
  tidak mengubah toggle OFF menjadi ON secara otomatis.
- **TS-P8-004**: Test evaluator harus menguji bahwa slideshow menang terhadap
  wisdom saat overlap, tetapi kalah terhadap prayer cycle dan midnight mode.

| Task     | Description                                                                                                                                                                                                                                                                                           | Completed | Date |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---- |
| TASK-044 | Update `lib/main.dart` untuk menginstansiasi `SlideshowImageLocalDataSource`, `SlideshowImageRepositoryImpl`, dan `SlideshowFileStorageServiceImpl`, lalu mendaftarkan `SlideshowImageRepository` dan `SlideshowFileStorageService` ke `MultiRepositoryProvider`.                                     |           |      |
| TASK-045 | Update instantiasi `DisplayStateCubit` di `main.dart` agar menerima `slideshowImageRepository` sebagai dependency baru.                                                                                                                                                                               |           |      |
| TASK-046 | Buat `test/data/models/slideshow_image_model_test.dart` untuk memverifikasi `fromMap`, `toMap`, dan round-trip metadata slideshow image.                                                                                                                                                              |           |      |
| TASK-047 | Tambahkan test baru pada `test/data/models/settings_model_test.dart` untuk memverifikasi 8 field slideshow pada `fromMap()` dan `toMap()`.                                                                                                                                                            |           |      |
| TASK-048 | Buat `test/data/repositories/slideshow_image_repository_impl_test.dart` untuk memverifikasi CRUD `getAll`, `getBySlot`, `save`, `deleteBySlot`, dan `count()` pada database in-memory.                                                                                                                |           |      |
| TASK-049 | Buat `test/presentation/cubits/slideshow_section/slideshow_section_cubit_test.dart` untuk skenario load images, import ke slot kosong, replace slot, delete slot, dan error saat picker cancel, bytes kosong, atau bytes tidak valid sebagai image.                                                   |           |      |
| TASK-050 | Tambahkan test pada `test/presentation/cubits/settings/settings_cubit_test.dart` untuk 8 method slideshow baru.                                                                                                                                                                                       |           |      |
| TASK-051 | Tambahkan unit test pada `test/domain/usecases/evaluate_display_state_use_case_test.dart` untuk prioritas slideshow vs wisdom, guard toggle OFF, guard daftar gambar kosong, perhitungan slot aktif, dan rotasi gambar di dalam slot.                                                                 |           |      |
| TASK-052 | Buat `test/presentation/pages/settings/sections/slideshow_section_test.dart` untuk memverifikasi toggle, disable block jadwal saat OFF, 3 slot tetap, tombol pilih/ganti/hapus, tidak ada auto-enable setelah import, dan auto-disable saat gambar terakhir dihapus.                                  |           |      |
| TASK-053 | Buat `test/presentation/pages/main_display/layouts/slideshow_layout_test.dart` untuk memverifikasi kanvas aman 1280x720, penggunaan `BoxFit.scaleDown`, indikator posisi, dan render tanpa crop pada rasio gambar berbeda.                                                                            |           |      |
| TASK-054 | Buat `test/presentation/pages/slideshow_preview_page_test.dart` untuk memverifikasi halaman preview menampilkan gambar fullscreen dengan `BoxFit.scaleDown`, bahwa tombol back menutup halaman tanpa mengubah data slot, dan bahwa layout preview identik dengan aturan kanvas aman 1280x720 runtime. |           |      |

<!-- markdownlint-enable MD060 -->

## 3. Alternatives

- **ALT-001**: Menyimpan daftar gambar slideshow sebagai JSON string di tabel
  `settings`. Ditolak karena metadata gambar bukan scalar settings dan akan
  membuat logic CRUD file menjadi sulit diuji serta tidak konsisten dengan pola
  repository lokal proyek ini.
- **ALT-002**: Menyimpan URI eksternal hasil picker dan merender langsung dari
  lokasi aslinya. Ditolak karena file asli bisa dipindah, dihapus, atau izin URI
  bisa hilang, sehingga bertentangan dengan tujuan offline-first dan stabilitas
  perangkat masjid.
- **ALT-003**: Membuat daftar slideshow dinamis tanpa batas. Ditolak karena
  kebutuhan produk saat ini jelas maksimal 3 gambar, dan slot tetap jauh lebih
  ramah untuk D-pad Android TV.
- **ALT-004**: Menampilkan gambar dengan `BoxFit.cover` dan crop tepi layar.
  Ditolak karena dapat memotong isi flyer/pengumuman dan bertentangan dengan
  kebutuhan area aman 1280x720.
- **ALT-005**: Menggabungkan slideshow ke Wisdom Quote sebagai satu engine
  generik konten periodik pada fase awal. Ditolak untuk MVP karena menambah scope
  refactor lintas fitur dan memperbesar risiko regresi pada fitur Wisdom yang
  sudah production-ready.

## 4. Dependencies

- **DEP-001**: `file_picker` untuk membuka system file picker dan memilih satu
  file gambar dengan filter ekstensi.
- **DEP-002**: `path_provider` untuk mendapatkan app documents directory sebagai
  lokasi internal storage hasil impor.
- **DEP-003**: `sqflite` tetap digunakan untuk menyimpan scalar settings dan
  metadata `slideshow_images`.
- **DEP-004**: `flutter_bloc` tetap digunakan untuk `SettingsCubit`,
  `DisplayStateCubit`, dan cubit baru section slideshow.
- **DEP-005**: `path` tetap digunakan untuk membangun path file internal yang
  portable di Android dan Windows.

## 5. Files

- **FILE-001**: `lib/domain/entities/settings.dart` - tambah 8 field scalar
  slideshow.
- **FILE-002**: `lib/domain/entities/transition_config.dart` - mapping scalar
  slideshow untuk evaluator runtime.
- **FILE-003**: `lib/domain/entities/slideshow_image.dart` - entity metadata
  gambar slideshow.
- **FILE-004**: `lib/domain/repositories/slideshow_image_repository.dart` -
  interface CRUD metadata slideshow.
- **FILE-005**: `lib/domain/services/slideshow_file_storage_service.dart` -
  interface impor/hapus file internal.
- **FILE-006**: `lib/domain/entities/display_state_type.dart` - tambah enum
  `slideshowAnnouncement`.
- **FILE-007**: `lib/domain/entities/display_state.dart` - tambah
  `SlideshowAnnouncementState`.
- **FILE-008**: `lib/domain/usecases/evaluate_display_state_use_case.dart` -
  evaluasi runtime slideshow dan prioritas terhadap wisdom.
- **FILE-009**: `lib/data/datasources/database_helper.dart` - migration v10,
  DDL settings, dan DDL `slideshow_images`.
- **FILE-010**: `lib/data/models/settings_model.dart` - mapping 8 field
  slideshow.
- **FILE-011**: `lib/data/models/slideshow_image_model.dart` - model metadata
  slideshow.
- **FILE-012**: `lib/data/datasources/slideshow_image_local_data_source.dart` -
  data source SQLite slideshow.
- **FILE-013**: `lib/data/repositories/slideshow_image_repository_impl.dart` -
  implementasi repository slideshow.
- **FILE-014**: `lib/data/services/slideshow_file_storage_service_impl.dart` -
  implementasi impor/hapus file internal.
- **FILE-015**: `lib/presentation/cubits/settings/settings_cubit.dart` - method
  update scalar slideshow.
- **FILE-016**: `lib/presentation/cubits/display_state/display_state_cubit.dart`
  - load gambar slideshow aktif dan pass ke evaluator.
- **FILE-017**: `lib/presentation/cubits/slideshow_section/slideshow_section_state.dart`
  - state management slot slideshow.
- **FILE-018**: `lib/presentation/cubits/slideshow_section/slideshow_section_cubit.dart`
  - import, replace, delete, dan reload slot slideshow.
- **FILE-019**: `lib/presentation/pages/settings/sections/slideshow_section.dart`
  - UI settings slideshow lengkap.
- **FILE-020**: `lib/presentation/pages/settings/settings_menu_page.dart` -
  tambah kategori dan section slideshow.
- **FILE-021**: `lib/presentation/pages/slideshow_preview_page.dart` - preview
  fullscreen satu gambar.
- **FILE-022**: `lib/presentation/pages/main_display/layouts/slideshow_layout.dart`
  - layout runtime slideshow.
- **FILE-023**: `lib/presentation/pages/main_display_page.dart` - case switch
  slideshow pada `AnimatedSwitcher` utama.
- **FILE-024**: `lib/main.dart` - wiring repository dan dependency slideshow.
- **FILE-025**: `pubspec.yaml` - tambah dependency `file_picker` dan
  `path_provider`.
- **FILE-026**: `test/data/models/slideshow_image_model_test.dart` - unit test
  model slideshow.
- **FILE-027**: `test/data/models/settings_model_test.dart` - update test 8
  field slideshow.
- **FILE-028**: `test/data/repositories/slideshow_image_repository_impl_test.dart`
  - repository CRUD slideshow.
- **FILE-029**: `test/presentation/cubits/slideshow_section/slideshow_section_cubit_test.dart`
  - cubit import/replace/delete slideshow.
- **FILE-030**: `test/presentation/cubits/settings/settings_cubit_test.dart` -
  update test settings slideshow.
- **FILE-031**: `test/domain/usecases/evaluate_display_state_use_case_test.dart`
  - update test evaluator slideshow.
- **FILE-032**: `test/presentation/pages/settings/sections/slideshow_section_test.dart`
  - widget test settings slideshow.
- **FILE-033**: `test/presentation/pages/main_display/layouts/slideshow_layout_test.dart`
  - widget test layout slideshow.
- **FILE-034**: `test/presentation/pages/slideshow_preview_page_test.dart` -
  widget test halaman pratinjau slideshow.

## 6. Testing

- **TEST-001**: Verifikasi `SettingsModel.fromMap()` dan `toMap()` memetakan 8
  field slideshow dengan default value yang benar.
- **TEST-002**: Verifikasi `SlideshowImageModel` melakukan round-trip map <->
  entity tanpa kehilangan metadata slot.
- **TEST-003**: Verifikasi repository `slideshow_images` dapat menyimpan,
  membaca, mengganti, dan menghapus slot 1..3 pada database in-memory.
- **TEST-004**: Verifikasi `SlideshowSectionCubit.importIntoSlot()` tidak
  mengubah state saat user cancel picker.
- **TEST-005**: Verifikasi `SlideshowSectionCubit.replaceSlot()` menghapus file
  lama lalu menyimpan metadata baru ke slot yang sama.
- **TEST-006**: Verifikasi `SlideshowSectionCubit.deleteFromSlot()` menghapus
  file internal dan metadata repository untuk slot yang dipilih.
- **TEST-007**: Verifikasi `SettingsCubit.updateSlideshowEnabled(false)` dan 7
  method slideshow lain memicu save dengan key snake_case yang benar.
- **TEST-008**: Verifikasi `EvaluateDisplayStateUseCase` mengembalikan
  `SlideshowAnnouncementState` hanya saat toggle slideshow ON, ada gambar, dan
  waktu berada di slot aktif.
- **TEST-009**: Verifikasi prioritas runtime tetap `prayer -> midnight ->
  slideshow -> wisdom -> standby`.
- **TEST-010**: Verifikasi rotasi gambar di dalam slot slideshow mengikuti
  `slideshowImageDurationSeconds` dan slot kosong diabaikan.
- **TEST-011**: Verifikasi widget `SlideshowSection` menampilkan 3 slot tetap,
  placeholder untuk slot kosong, dan tombol aksi yang benar untuk slot terisi.
- **TEST-012**: Verifikasi blok jadwal di `SlideshowSection` non-interaktif saat
  toggle OFF, tetapi manajemen gambar tetap fokusable dan usable.
- **TEST-013**: Verifikasi listener auto-disable memanggil
  `updateSlideshowEnabled(false)` saat gambar terakhir dihapus.
- **TEST-014**: Verifikasi `SlideshowLayout` merender kanvas aman 1280x720 dan
  gambar menggunakan `BoxFit.scaleDown` tanpa crop pada rasio berbeda.
- **TEST-015**: Verifikasi impor atau replace gambar tidak pernah mengubah toggle
  slideshow OFF menjadi ON secara otomatis.
- **TEST-016**: Verifikasi update method dan DPadStepper slideshow mematuhi range
  yang ditetapkan: interval `5..60`, slot duration `1..10`, image duration
  `5..30`, jam `0..23`, dan menit dengan step UI `5`.
- **TEST-017**: Verifikasi `SlideshowLayout` tidak crash saat file internal
  hilang dan menampilkan fallback aman dari `errorBuilder`.
- **TEST-018**: Verifikasi `SlideshowPreviewPage` menampilkan gambar fullscreen
  dengan layout kanvas 1280x720 dan `BoxFit.scaleDown` yang identik dengan
  runtime slideshow, serta tombol back menutup halaman tanpa mengubah data slot.
- **TEST-019**: Verifikasi file dengan bytes non-image ditolak sebelum disimpan
  ke internal storage, dan `SlideshowSectionCubit` menampilkan error tanpa
  membuat metadata slot baru.

## 7. Risks & Assumptions

- **RISK-001**: Beberapa perangkat Android TV mungkin memiliki Documents
  Provider atau file manager yang UX-nya buruk untuk remote D-pad. Mitigasi:
  gunakan picker hanya untuk impor satu file, lalu seluruh pengelolaan dilakukan
  dari UI aplikasi.
- **RISK-002**: `withData: true` membaca file ke memori saat impor. Mitigasi:
  fitur dibatasi maksimal 3 gambar, impor dilakukan manual, dan format terbatas
  ke gambar statis umum.
- **RISK-003**: Jika replace gagal setelah file lama dihapus, slot bisa menjadi
  kosong. Mitigasi: urutkan operasi dengan jelas dan tampilkan error state di
  `SlideshowSectionCubit`.
- **RISK-004**: Overlap jadwal slideshow dan wisdom bisa membingungkan admin jika
  tidak dijelaskan. Mitigasi: tulis ringkasan prioritas di deskripsi settings dan
  enforce evaluator order secara deterministik.
- **ASSUMPTION-001**: Product menerima batas tetap 3 slot dan urutan slot tetap
  1..3 untuk MVP.
- **ASSUMPTION-002**: Product menerima bahwa slideshow OFF tidak menghapus data,
  sedangkan aksi hapus slot menghapus file internal secara permanen.
- **ASSUMPTION-003**: Product menerima area aman 1280x720 sebagai baseline visual
  untuk mencegah crop pada TV.
- **ASSUMPTION-004**: Slide yang dipakai masjid berbentuk gambar statis dan tidak
  memerlukan animasi transisi kompleks atau zoom/pan.

## 8. Related Specifications / Further Reading

- [spec/spec-process-settings.md](../spec/spec-process-settings.md)
- [spec/spec-process-state-machine.md](../spec/spec-process-state-machine.md)
- [docs/UI_UX_GUIDE.md](../docs/UI_UX_GUIDE.md)
- [docs/ARCHITECTURE_PATTERNS.md](../docs/ARCHITECTURE_PATTERNS.md)
- [Android Developers - Access documents and other files from shared storage](https://developer.android.com/training/data-storage/shared/documents-files)
- [pub.dev - file_picker](https://pub.dev/packages/file_picker)
- [pub.dev - path_provider](https://pub.dev/packages/path_provider)
