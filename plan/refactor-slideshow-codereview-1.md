---
goal: "Code Review Remediation: Perbaikan 3 Temuan Review pada SlideshowSectionCubit Post-Refactor"
version: "1.0"
date_created: "2026-05-28"
last_updated: "2026-05-28"
owner: "Gulajava Ministudio"
status: "Completed"
tags:
  - fix
  - code-review
  - slideshow
  - android-tv
  - defensive-coding
---

# Code Review Remediation: Post-Refactor `SlideshowSectionCubit`

![Status: Completed](https://img.shields.io/badge/status-Completed-green)
<!-- markdownlint-disable -->

Setelah implementasi `refactor-slideshow-picker-1.md` (migrasi `file_picker` → `image_picker`) selesai
dan semua 513 test lulus, dilakukan code review terhadap hasil implementasi. Review menemukan **3 temuan**
yang perlu diperbaiki:

1. **(HIGH)** `_pickImageBytes()` hanya menangkap `PlatformException`. `XFile.readAsBytes()` berpotensi
   melempar `FileSystemException` atau exception I/O lainnya yang tidak akan tertangkap, sehingga
   membuka potensi crash baru pada ROM Android TV tertentu.
2. **(MEDIUM)** `p.basename(image.path)` digunakan sebagai sumber nama file. Pada ROM tertentu, `path`
   dari `image_picker` dapat berupa path cache tanpa ekstensi yang dikenali. `XFile.name` lebih semantically
   tepat sebagai fallback. Solusi yang disepakati: implementasi helper `_resolveFileName()` dengan logika
   fallback `path → name`.
3. **(LOW)** Dokumen `refactor-slideshow-picker-1.md` memiliki teks DEP-002 dan DEP-004 yang tidak sinkron
   dengan kondisi aktual `pubspec.yaml`: teks lama menyebut keduanya sebagai transitive dependency "tidak
   perlu ditambahkan eksplisit", padahal keduanya sudah ditambahkan secara eksplisit di `dev_dependencies`.

---

## 1. Requirements & Constraints

- **REQ-001**: `_pickImageBytes()` harus menangani semua exception yang mungkin dilempar, tidak hanya
  `PlatformException`. Exception yang bukan `PlatformException` (contoh: `FileSystemException` dari
  `readAsBytes()`) harus ditangkap dan dikonversi menjadi error message pada state, bukan dibiarkan
  propagate sebagai crash.
- **REQ-002**: Broad catch tidak boleh menelan `Error` subclass (misal `OutOfMemoryError`). Gunakan
  `on Exception` — bukan bare `catch (e)` — agar Dart `Error` tetap propagate secara alami.
- **REQ-003**: Nama file yang digunakan sebagai `originalFileName` di `SlideshowFileStorageServiceImpl`
  harus memiliki ekstensi yang dikenali (`jpg`, `jpeg`, `png`, `webp`). Jika ekstensi tidak dapat
  diperoleh dari `image.path`, harus ada fallback ke `image.name`.
- **REQ-004**: `_resolveFileName()` harus memiliki prioritas: path dulu (karena lebih reliabel sebagai
  path file aktual plugin), lalu `image.name` sebagai fallback.
- **REQ-005**: Semua 513 test yang sudah ada sebelumnya tidak boleh mengalami regresi (tetap PASS).
- **CON-001**: Tidak ada perubahan pada `SlideshowFileStorageServiceImpl`, layer domain, atau skema database.
- **CON-002**: Tidak ada dependency baru yang ditambahkan ke `pubspec.yaml`.
- **SEC-001**: Broad exception catch tidak boleh menyembunyikan exception keamanan atau logika bisnis.
  Cakupan dibatasi pada blok I/O di `_pickImageBytes()` saja.

---

## 2. Implementation Steps

### Phase 1 — HIGH: Perluas Cakupan Exception pada `_pickImageBytes()`

- **GOAL-001**: Memastikan semua exception yang mungkin dilempar dari operasi I/O di `_pickImageBytes()`
  tertangkap dan dikonversi menjadi error state, tidak menjadi crash fatal.

**Perubahan kode yang diharapkan:**

```dart
// SEBELUM — hanya tangkap PlatformException
} on PlatformException {
  emit(state.copyWith(errorMessage: 'Tidak dapat membuka galeri gambar...'));
  return null;
}

// SESUDAH — tambahkan catch untuk Exception lainnya (FileSystemException, dll)
} on PlatformException {
  emit(state.copyWith(errorMessage: 'Tidak dapat membuka galeri gambar...'));
  return null;
} on Exception {
  emit(state.copyWith(
    errorMessage: 'Gagal membaca file gambar. Silakan coba lagi.',
  ));
  return null;
}
```

| Task     | Description                                                                                                                                                                                                                                                                                                                                                                                                                                         | Completed | Date       |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------: | ---------- |
| TASK-001 | Di `slideshow_section_cubit.dart`: tambahkan blok `on Exception` setelah blok `on PlatformException` di `_pickImageBytes()` (baris ~200)                                                                                                                                                                                                                                                                                                            |     ✅     | 2026-05-28 |
| TASK-002 | Di `slideshow_section_cubit_test.dart`: tambahkan **2 test** — (1) `importIntoSlot() — Exception non-PlatformException dari readAsBytes()` dan (2) `replaceSlot() — Exception non-PlatformException dari readAsBytes()`. Kedua test meng-stub `getImageFromSource` agar return `XFile('/nonexistent/path.jpg')` biasa sehingga `readAsBytes()` melempar `PathNotFoundException` secara alami. Verifikasi state emit `errorMessage` dan tidak crash. |     ✅     | 2026-05-28 |
| TASK-003 | Jalankan `flutter test test/presentation/cubits/slideshow_section/` dan pastikan semua test PASS                                                                                                                                                                                                                                                                                                                                                    |     ✅     | 2026-05-28 |

> **Catatan TASK-002**: Menggunakan `XFile('/nonexistent/path.jpg')` biasa (bukan subclass kustom) adalah
> pendekatan yang lebih sederhana dan reliabel. `readAsBytes()` akan melempar `PathNotFoundException`
> (subclass dari `Exception`) secara alami karena path tidak ditemukan di filesystem. `replaceSlot()` juga
> wajib dicover karena keduanya memanggil `_pickImageBytes()` yang mengandung blok `on Exception` baru.

---

### Phase 2 — MEDIUM: Implementasi `_resolveFileName()` dengan Fallback

- **GOAL-002**: Memastikan nama file yang dikirim ke `SlideshowFileStorageServiceImpl` selalu memiliki
  ekstensi yang dikenali, bahkan pada ROM Android TV yang menghasilkan path cache tanpa ekstensi valid.

**Method helper baru:**

```dart
/// Menentukan nama file dari [XFile] hasil picker dengan strategi fallback.
///
/// Prioritas:
/// 1. `p.basename(image.path)` — jika ekstensinya ada dalam whitelist
/// 2. `image.name` — nama file sebagaimana dipilih user (fallback)
/// 3. `p.basename(image.path)` — jika `image.name` kosong (last resort)
///
/// Whitelist ekstensi disesuaikan dengan `SlideshowFileStorageServiceImpl._allowedExtensions`.
String _resolveFileName(XFile image) {
  const validExts = {'jpg', 'jpeg', 'png', 'webp'};

  final nameFromPath = p.basename(image.path);
  final extFromPath =
      p.extension(nameFromPath).replaceFirst('.', '').toLowerCase();

  if (validExts.contains(extFromPath)) {
    return nameFromPath;
  }

  final fallbackName = image.name;
  return fallbackName.isNotEmpty ? fallbackName : nameFromPath;
}
```

**Perubahan di `_pickImageBytes()`:**

```dart
// SEBELUM
return _PickedFile(fileName: p.basename(image.path), data: bytes);

// SESUDAH
return _PickedFile(fileName: _resolveFileName(image), data: bytes);
```

| Task     | Description                                                                                                                                                                                                                                                                                         | Completed | Date       |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------: | ---------- |
| TASK-004 | Di `slideshow_section_cubit.dart`: tambahkan private method `_resolveFileName(XFile image)` di bagian private helpers (sebelum `_PickedFile` class)                                                                                                                                                 |     ✅     | 2026-05-28 |
| TASK-005 | Di `slideshow_section_cubit.dart`: ganti `p.basename(image.path)` dengan `_resolveFileName(image)` pada baris return di `_pickImageBytes()`                                                                                                                                                         |     ✅     | 2026-05-28 |
| TASK-006 | Di `slideshow_section_cubit_test.dart`: tambahkan grup test `_resolveFileName()` dengan 3 skenario: (a→TEST-002) path berekstensi valid → pakai path, (b→TEST-003) path tanpa ekstensi valid → fallback ke `image.name`, (c→TEST-004) path dengan ekstensi tidak dikenal → fallback ke `image.name` |     ✅     | 2026-05-28 |
| TASK-007 | Jalankan `flutter test test/presentation/cubits/slideshow_section/` dan pastikan semua test PASS                                                                                                                                                                                                    |     ✅     | 2026-05-28 |

> **Catatan TASK-006**: `_resolveFileName()` adalah private method. Test dilakukan secara indirect melalui
> `importIntoSlot()` dengan menyiapkan XFile dengan kombinasi `path` dan `name` yang berbeda-beda,
> lalu memverifikasi `originalFileName` yang dikirim ke `_storageService.importImage()` via argument
> captor mocktail (`captured`).

---

### Phase 3 — LOW: Sinkronisasi Teks DEP-002 & DEP-004 di Dokumen Lama

- **GOAL-003**: Menyinkronkan dokumentasi `refactor-slideshow-picker-1.md` agar sesuai dengan kondisi
  aktual `pubspec.yaml` sehingga tidak menyesatkan kontributor berikutnya.

**Kondisi aktual `pubspec.yaml` (baris 69–70):**

```yaml
dev_dependencies:
  image_picker_platform_interface: ^2.11.1   # eksplisit
  plugin_platform_interface: ^2.1.8          # eksplisit
```

**Teks DEP-002 yang perlu diperbarui:**

```markdown
# SEBELUM
- **DEP-002**: `image_picker_platform_interface` — transitive dependency dari `image_picker`,
  dibutuhkan di test untuk `ImagePickerPlatform.instance`.

# SESUDAH
- **DEP-002**: `image_picker_platform_interface: ^2.11.1` — ditambahkan secara eksplisit ke
  `dev_dependencies` di `pubspec.yaml` untuk menghindari lint `depend_on_referenced_packages`.
  Dibutuhkan di test untuk `ImagePickerPlatform.instance` dan `ImagePickerPlatform.instance =`.
```

**Teks DEP-004 yang perlu diperbarui:**

```markdown
# SEBELUM
- **DEP-004**: `plugin_platform_interface` — transitive dependency ... Tidak perlu ditambahkan
  secara eksplisit ke `pubspec.yaml`; tetap dibutuhkan untuk `MockPlatformInterfaceMixin` di test file.

# SESUDAH
- **DEP-004**: `plugin_platform_interface: ^2.1.8` — ditambahkan secara eksplisit ke
  `dev_dependencies` di `pubspec.yaml` untuk menghindari lint `depend_on_referenced_packages`.
  Dibutuhkan untuk `MockPlatformInterfaceMixin` di test file.
```

| Task     | Description                                                                                                      | Completed | Date       |
| -------- | ---------------------------------------------------------------------------------------------------------------- | :-------: | ---------- |
| TASK-008 | Di `plan/refactor-slideshow-picker-1.md`: perbarui teks DEP-002 dan DEP-004 sesuai kondisi aktual `pubspec.yaml` |     ✅     | 2026-05-28 |

---

## 3. Alternatives

- **ALT-001**: Gunakan bare `catch (e)` alih-alih `on Exception` untuk broad catch. Ditolak karena
  `catch (e)` juga menangkap Dart `Error` subclass (`OutOfMemoryError`, `StackOverflowError`) yang
  sebaiknya tidak diswallow.
- **ALT-002**: Untuk Finding 2, ganti langsung ke `image.name` tanpa fallback. Ditolak karena ada
  laporan pada beberapa ROM bahwa `XFile.name` mengembalikan string kosong. Fallback `path → name`
  lebih defensive.
- **ALT-003**: Untuk Finding 2, tetap gunakan `p.basename(image.path)` saja (tidak ada perubahan).
  Ditolak karena tidak menyelesaikan potensi ekstensi tidak valid yang bisa menyebabkan
  `Exception('Format file tidak didukung')` di `SlideshowFileStorageServiceImpl`.

---

## 4. Dependencies

- **DEP-001**: Tidak ada dependency baru. Semua perubahan menggunakan paket yang sudah ada:
  `flutter/services.dart` (sudah diimpor), `path` (sudah ada), `image_picker` (sudah ada).

---

## 5. Files Affected

- **FILE-001**: `lib/presentation/cubits/slideshow_section/slideshow_section_cubit.dart` — tambah
  blok `on Exception`, tambah method `_resolveFileName()`, ganti `p.basename(image.path)` dengan
  `_resolveFileName(image)`.
- **FILE-002**: `test/presentation/cubits/slideshow_section/slideshow_section_cubit_test.dart` —
  tambah test untuk `on Exception` (TASK-002) dan 3 skenario `_resolveFileName()` (TASK-006).
- **FILE-003**: `plan/refactor-slideshow-picker-1.md` — perbarui teks DEP-002 dan DEP-004 (TASK-008).

---

## 6. Testing

- **TEST-001** *(validates TASK-002)*: `importIntoSlot() — Exception non-PlatformException dari readAsBytes()` — stub
  picker return `XFile('/nonexistent/path.jpg')`, verifikasi state emit `errorMessage` dan tidak crash.
  `replaceSlot()` juga harus dicover dengan skenario yang sama.
- **TEST-002** *(validates TASK-006 skenario a)*: `_resolveFileName() — path berekstensi valid` — `importIntoSlot()` dengan XFile
  `path='/cache/image.jpg'`, `name='image.jpg'`; verifikasi `originalFileName='image.jpg'` dikirim
  ke storage service.
- **TEST-003** *(validates TASK-006 skenario b)*: `_resolveFileName() — path tanpa ekstensi, fallback ke image.name` — `importIntoSlot()`
  dengan XFile `path=p.join('cache','tmp_file')`; tidak ada ekstensi → `validExts.contains('') = false` →
  fallback ke `image.name` = `'tmp_file'` (cross_file IO: `name = path.split(separator).last`);
  verifikasi `originalFileName='tmp_file'` dikirim ke storage service.
- **TEST-004** *(validates TASK-006 skenario c)*: `_resolveFileName() — ekstensi tidak dikenal (.bmp), fallback ke image.name` — `importIntoSlot()`
  dengan XFile `path=p.join('cache','photo.bmp')`; `.bmp` bukan dalam whitelist `validExts` →
  fallback ke `image.name` = `'photo.bmp'`; verifikasi `originalFileName='photo.bmp'` dikirim ke storage service.
- **TEST-005** *(validates TASK-003 & TASK-007)*: Full test suite (`flutter test --reporter=expanded`) harus green.
  Hasil akhir: **518 tests passed** (513 baseline + 2 test Phase 1 + 3 test Phase 2).

---

## 7. Risks & Assumptions

- **RISK-001**: Test untuk Finding 1 menggunakan `XFile('/nonexistent/path.jpg')` biasa agar
  `readAsBytes()` melempar `PathNotFoundException` secara alami. Pendekatan ini dipilih karena lebih
  sederhana dan tidak membutuhkan subclass kustom. Asumsi: filesystem test environment tidak
  memiliki file di path `/nonexistent/` — valid untuk semua environment standar Flutter test.
- **RISK-002**: Indirect testing `_resolveFileName()` via `importIntoSlot()` menggunakan argument
  captor. Jika API `importImage()` berubah, test ini bisa false-negative. Mitigasi: test sudah
  mencakup 3 skenario yang mewakili branch logika di `_resolveFileName()`.
- **RISK-003**: Perubahan pada `_pickImageBytes()` (tambah `on Exception`) adalah surgical — tidak
  ada perubahan pada alur normal atau error handling `importIntoSlot()`/`replaceSlot()`. Risiko
  regresi sangat rendah.

