---
goal: "Refactor Picker Slideshow: Migrasi dari file_picker ke image_picker untuk Fix Crash Crashlytics (invalid_format_type)"
version: "1.1"
date_created: "2026-05-26"
last_updated: "2026-05-26"
owner: "Gulajava Ministudio"
status: "Completed"
tags:
  - fix
  - refactor
  - slideshow
  - android-tv
  - crashlytics
  - file-picker
  - image-picker
---

# Refactor Picker Slideshow: Migrasi `file_picker` → `image_picker`

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

<!-- markdownlint-disable -->

Laporan Crashlytics (Issue `a6c29f9`, 13 crash event, v1.3.0) menunjukkan crash
fatal `PlatformException(invalid_format_type, Can't handle the provided file
type., null, null)` saat pengguna mencoba mengimpor gambar slideshow di perangkat
Android TV tertentu. Stack trace menunjuk ke `SlideshowSectionCubit._pickImageBytes`
→ `importIntoSlot`.

## Root Cause Summary

| #   | Penyebab                                                                                                                     | Dampak                                                                                  |
| --- | ---------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| 1   | `file_picker` dengan `FileType.custom` menggunakan `Intent.ACTION_OPEN_DOCUMENT` yang tidak tersedia di semua ROM Android TV | Crash fatal (tidak ada activity handler)                                                |
| 2   | Pemanggilan `_pickImageBytes()` di `importIntoSlot()` dan `replaceSlot()` berada **di luar** blok `try/catch` yang ada       | `PlatformException` tidak tertangkap → naik menjadi `FlutterError` fatal ke Crashlytics |

Solusi yang dipilih adalah mengganti `file_picker` dengan `image_picker` yang
menggunakan intent galeri (`ACTION_PICK`/`ACTION_GET_CONTENT` media), lebih
kompatibel di Android TV. Validasi format tetap dijaga oleh
`SlideshowFileStorageServiceImpl` (tidak berubah). Sekaligus, `_pickImageBytes()`
dibungkus `try/catch PlatformException` agar tidak ada crash bahkan pada device
yang tidak memiliki galeri terpasang.

## Execution Summary (Final)

- **Status Eksekusi**: Semua task pada Phase 1–4 selesai pada 2026-05-26.
- **Validasi Kualitas**:
  - `dart analyze lib/presentation/cubits/slideshow_section/slideshow_section_cubit.dart` → **No issues found**.
  - `flutter test test/presentation/cubits/slideshow_section/slideshow_section_cubit_test.dart --reporter=expanded` → **14 tests passed**.
  - `flutter test --reporter=expanded` → **All tests passed** (513 tests).
- **Verifikasi Dependency**: `file_picker` sudah tidak ada di `pubspec.lock`; dependency aktif telah bermigrasi ke `image_picker`.

---

## 1. Requirements & Constraints

- **REQ-001**: Pengguna tetap bisa memilih gambar dari galeri/penyimpanan perangkat Android TV via UI settings.
- **REQ-002**: Hanya format `jpg`, `jpeg`, `png`, dan `webp` yang diterima — whitelist ini tetap divalidasi di layer `SlideshowFileStorageServiceImpl`, bukan di layer picker.
- **REQ-003**: Jika perangkat tidak memiliki galeri atau picker yang kompatibel, aplikasi tidak boleh crash — tampilkan `errorMessage` melalui state cubit.
- **REQ-004**: Jika pengguna membatalkan picker (cancel), state cubit tidak boleh berubah sama sekali (TS-P4-002 dari plan asal tetap berlaku).
- **REQ-005**: `SlideshowSection` (UI) tidak perlu diubah — panel error sudah ada dan akan menampilkan pesan dari state cubit.
- **SEC-001**: `image_picker` tidak perlu mengembalikan metadata lokasi gambar — `requestFullMetadata: false` wajib diset untuk meminimalkan permission yang diminta.
- **CON-001**: `SlideshowFileStorageServiceImpl`, `SlideshowImageRepository`, entitas domain, dan `SlideshowSection` UI tidak boleh diubah dalam refactor ini.
- **CON-002**: `file_picker` hanya dipakai di `slideshow_section_cubit.dart` (lib) dan test-nya — aman untuk dihapus dari `pubspec.yaml`.
- **GUD-001**: `ImagePicker` diinjeksi sebagai optional constructor parameter ke `SlideshowSectionCubit` agar bisa di-mock dalam unit test tanpa mengubah production code `SlideshowSection`.
- **GUD-002**: Pesan error yang ditampilkan ke user harus ramah dan actionable dalam Bahasa Indonesia.
- **PAT-001**: Perubahan harus surgical — seminimal mungkin, tidak ada refactoring di luar scope crash fix ini.

---

## 2. Implementation Steps

### Implementation Phase 1 — Dependency Update

- **GOAL-001**: Hapus `file_picker` dan tambahkan `image_picker` ke `pubspec.yaml`, lalu jalankan `flutter pub get`.

| Task     | Description                                                                                                                                                                       | Completed | Date       |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-001 | Hapus baris `file_picker: ^11.0.2` dari `dependencies` di `pubspec.yaml`                                                                                                          | ✅         | 2026-05-26 |
| TASK-002 | Tambahkan baris `image_picker: ^1.1.0` ke `dependencies` di `pubspec.yaml`                                                                                                        | ✅         | 2026-05-26 |
| TASK-003 | Jalankan `flutter pub get` dan pastikan `pubspec.lock` terupdate (entry `file_picker` hilang, `image_picker` + `image_picker_android` + `image_picker_platform_interface` muncul) | ✅         | 2026-05-26 |

---

### Implementation Phase 2 — Cubit Refactor

- **GOAL-002**: Ganti implementasi `_pickImageBytes()` di `SlideshowSectionCubit` menggunakan `image_picker`, tambah injeksi `ImagePicker`, dan bungkus `PlatformException` agar tidak crash.

| Task     | Description                                                                                                                                                                                                                                                                                                                                                | Completed | Date       |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-004 | Hapus `import 'package:file_picker/file_picker.dart';` dari `slideshow_section_cubit.dart`                                                                                                                                                                                                                                                                 | ✅         | 2026-05-26 |
| TASK-005 | Tambahkan `import 'package:flutter/services.dart';` (untuk `PlatformException`), `import 'package:image_picker/image_picker.dart';`, dan `import 'package:path/path.dart' as p;` (untuk `p.basename` — ekstraksi nama file yang aman dari path penuh) ke `slideshow_section_cubit.dart`                                                                    | ✅         | 2026-05-26 |
| TASK-006 | Tambahkan field `final ImagePicker _imagePicker;` ke `SlideshowSectionCubit` dan tambahkan `ImagePicker? imagePicker` sebagai optional parameter di konstruktor. Default ke `ImagePicker()` jika null.                                                                                                                                                     | ✅         | 2026-05-26 |
| TASK-007 | Rewrite method `_pickImageBytes()`: ganti `FilePicker.pickFiles(...)` dengan `_imagePicker.pickImage(source: ImageSource.gallery, requestFullMetadata: false)`. Return `_PickedFile` dari `XFile.readAsBytes()` dan `p.basename(image.path)`. Wrap seluruh body dengan `try/catch PlatformException` yang emit `errorMessage` ke state lalu return `null`. | ✅         | 2026-05-26 |
| TASK-008 | Update komentar doc `_pickImageBytes()` agar mencerminkan penggunaan `image_picker` dan tidak lagi menyebut `FilePicker`/`withData`.                                                                                                                                                                                                                       | ✅         | 2026-05-26 |

**Detail TASK-007 — implementasi `_pickImageBytes()` setelah refactor:**

```dart
Future<_PickedFile?> _pickImageBytes() async {
  try {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (image == null) return null; // user cancel — no state change
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) return null;
    return _PickedFile(fileName: p.basename(image.path), data: bytes);
  } on PlatformException {
    emit(
      state.copyWith(
        errorMessage:
            'Tidak dapat membuka galeri gambar. Pastikan perangkat '
            'memiliki aplikasi galeri atau pengelola file yang kompatibel.',
      ),
    );
    return null;
  }
}
```

**Detail TASK-006 — perubahan konstruktor:**

```dart
SlideshowSectionCubit({
  required SlideshowImageRepository imageRepository,
  required SlideshowFileStorageService storageService,
  DisplayStateCubit? displayStateCubit,
  ImagePicker? imagePicker,          // ← tambah ini
}) : _imageRepository = imageRepository,
     _storageService = storageService,
     _displayStateCubit = displayStateCubit,
     _imagePicker = imagePicker ?? ImagePicker(),   // ← tambah ini
     super(const SlideshowSectionState.initial());
```

> **Catatan**: `SlideshowSection` (UI) memanggil konstruktor tanpa `imagePicker` — tidak perlu diubah karena parameter bersifat optional dengan default `ImagePicker()`.

---

### Implementation Phase 3 — Test Refactor

- **GOAL-003**: Update unit test `slideshow_section_cubit_test.dart` agar menggunakan `image_picker` mock, dan tambahkan regression test untuk skenario `PlatformException`.

| Task     | Description                                                                                                                                                                                                             | Completed | Date       |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-009 | Hapus semua import `file_picker` dari test file. Tambahkan `import 'package:image_picker/image_picker.dart';` dan `import 'package:flutter/services.dart';`.                                                            | ✅         | 2026-05-26 |
| TASK-010 | Ganti class `MockFilePicker` dengan `MockImagePickerPlatform` yang mengimplementasikan `ImagePickerPlatform` (bukan `FilePickerPlatform`). Tetap gunakan `with MockPlatformInterfaceMixin`.                             | ✅         | 2026-05-26 |
| TASK-011 | Di `setUp()`: ganti `FilePickerPlatform.instance = mockPicker` dengan `ImagePickerPlatform.instance = mockImagePickerPlatform`. Rename variabel `mockPicker` → `mockImagePickerPlatform`.                               | ✅         | 2026-05-26 |
| TASK-012 | Tambahkan `registerFallbackValue(ImageSource.gallery)` dan `registerFallbackValue(const ImagePickerOptions())` ke `setUpAll()`.                                                                                         | ✅         | 2026-05-26 |
| TASK-013 | Ganti helper `_makePickerResult(String name, Uint8List bytes)` dengan `_makeXFile(Uint8List bytes, String name)` yang mengembalikan `XFile.fromData(...)` untuk in-memory test data.                                    | ✅         | 2026-05-26 |
| TASK-014 | Update semua stub `when(() => mockPicker.pickFiles(...))` menjadi `when(() => mockImagePickerPlatform.getImageFromSource(source: any(named: 'source'), options: any(named: 'options')))` dengan return type `XFile?`.   | ✅         | 2026-05-26 |
| TASK-015 | Tambahkan grup test baru `'importIntoSlot() — PlatformException dari picker'`: stub `getImageFromSource` agar throw `PlatformException(code: 'invalid_format_type')`, verify cubit emit `errorMessage` dan tidak crash. | ✅         | 2026-05-26 |
| TASK-016 | Tambahkan grup test baru `'replaceSlot() — PlatformException dari picker'`: skenario sama dengan TASK-015 untuk `replaceSlot()`.                                                                                        | ✅         | 2026-05-26 |

**Detail TASK-010 — mock class baru:**

```dart
class MockImagePickerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {}
```

**Detail TASK-014 — contoh stub setelah update:**

```dart
// Sebelum (file_picker):
when(() => mockPicker.pickFiles(
  type: any(named: 'type'),
  allowedExtensions: any(named: 'allowedExtensions'),
  allowMultiple: any(named: 'allowMultiple'),
  withData: any(named: 'withData'),
)).thenAnswer((_) async => _makePickerResult('slide.jpg', fakeBytes));

// Sesudah (image_picker):
when(() => mockImagePickerPlatform.getImageFromSource(
  source: any(named: 'source'),
  options: any(named: 'options'),
)).thenAnswer((_) async => _makeXFile(fakeBytes, 'slide.jpg'));
```

**Detail TASK-015 — regression test `PlatformException`:**

```dart
group('importIntoSlot() — PlatformException dari picker', () {
  blocTest<SlideshowSectionCubit, SlideshowSectionState>(
    'emits errorMessage dan tidak crash saat picker melempar PlatformException',
    setUp: () {
      when(() => mockImagePickerPlatform.getImageFromSource(
        source: any(named: 'source'),
        options: any(named: 'options'),
      )).thenThrow(PlatformException(code: 'invalid_format_type'));
    },
    build: buildCubit,
    act: (c) => c.importIntoSlot(1),
    expect: () => [
      isA<SlideshowSectionState>()
          .having((s) => s.errorMessage, 'errorMessage', isNotNull)
          .having((s) => s.isBusy, 'isBusy', isFalse),
    ],
  );
});
```

---

### Implementation Phase 4 — Analyze & Validate

- **GOAL-004**: Pastikan tidak ada error compile, analyze warning, dan semua test hijau sebelum dianggap selesai.

| Task     | Description                                                                                                                                                                                    | Completed | Date       |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| TASK-017 | Jalankan `dart analyze lib/presentation/cubits/slideshow_section/slideshow_section_cubit.dart` — harus zero issues.                                                                            | ✅         | 2026-05-26 |
| TASK-018 | Jalankan `flutter test test/presentation/cubits/slideshow_section/slideshow_section_cubit_test.dart --reporter=expanded` — semua test harus PASS termasuk 2 test regression baru dari Phase 3. | ✅         | 2026-05-26 |
| TASK-019 | Jalankan `flutter test --reporter=expanded` (full test suite) untuk memastikan tidak ada regresi di modul lain.                                                                                | ✅         | 2026-05-26 |
| TASK-020 | Verifikasi `pubspec.lock` tidak lagi mengandung entry `file_picker`.                                                                                                                           | ✅         | 2026-05-26 |

---

## 3. Alternatives

- **ALT-001**: Tetap gunakan `file_picker` tapi hanya tambah `try/catch PlatformException`. Lebih cepat, tapi tidak menyelesaikan root cause: perangkat tanpa document picker tetap tidak bisa memilih gambar, hanya saja tidak crash lagi. Dipilih sebagai fallback jika `image_picker` terbukti bermasalah di test.
- **ALT-002**: Gunakan `file_picker` dengan `FileType.image` (bukan `FileType.custom`). Menghilangkan whitelist ekstensi di picker, tetapi validasi format tetap ada di `SlideshowFileStorageServiceImpl`. Lebih aman dari sisi intent, tapi masih memakai `ACTION_OPEN_DOCUMENT` di Android yang tetap rentan gagal di beberapa ROM TV.
- **ALT-003**: Tulis wrapper abstrak `abstract class ImagePickerService` lalu inject ke cubit. Lebih testable, tapi menambah file baru dan kompleksitas untuk masalah yang bisa selesai dengan injeksi `ImagePicker` langsung.

---

## 4. Dependencies

- **DEP-001**: `image_picker: ^1.1.0` — package baru yang ditambahkan ke `pubspec.yaml`.
- **DEP-002**: `image_picker_platform_interface` — ditambahkan secara eksplisit ke `dev_dependencies` di `pubspec.yaml` untuk menghindari lint `depend_on_referenced_packages`. Dibutuhkan di test untuk `ImagePickerPlatform.instance`.
- **DEP-003**: `cross_file` — transitive dependency dari `image_picker`, menyediakan class `XFile` dan `XFile(bytes: ...)` untuk in-memory test data.
- **DEP-004**: `plugin_platform_interface` — ditambahkan secara eksplisit ke `dev_dependencies` di `pubspec.yaml` untuk menghindari lint `depend_on_referenced_packages`. Dibutuhkan untuk `MockPlatformInterfaceMixin` di test file.
- **DEP-005**: `path: ^1.9.1` — sudah ada sebagai direct dependency di `pubspec.yaml` (dipakai `DatabaseHelper`). Digunakan di `_pickImageBytes()` untuk `p.basename()`. Tidak perlu ditambahkan.

---

## 5. Files

- **FILE-001**: `pubspec.yaml` — hapus `file_picker`, tambah `image_picker`.
- **FILE-002**: `lib/presentation/cubits/slideshow_section/slideshow_section_cubit.dart` — satu-satunya file production yang diubah: import, konstruktor, dan `_pickImageBytes()`.
- **FILE-003**: `test/presentation/cubits/slideshow_section/slideshow_section_cubit_test.dart` — update mock setup dan tambah 2 grup regression test.

> File-file berikut **tidak diubah**: `SlideshowSection` (UI), `SlideshowFileStorageServiceImpl`, `SlideshowImageRepositoryImpl`, semua domain entities, `DatabaseHelper`.

---

## 6. Testing

- **TEST-001**: Semua 12 test existing di `slideshow_section_cubit_test.dart` tetap harus PASS setelah refactor (tidak ada regresi pada skenario normal, cancel, sukses, error storage).
- **TEST-002**: Test regression baru: `importIntoSlot()` emit `errorMessage` dan tidak crash saat picker throw `PlatformException` — TASK-015.
- **TEST-003**: Test regression baru: `replaceSlot()` emit `errorMessage` dan tidak crash saat picker throw `PlatformException` — TASK-016.
- **TEST-004**: Full test suite (`flutter test --reporter=expanded`) harus green sebelum task selesai.

---

## 7. Risks & Assumptions

- **RISK-001**: `image_picker` di Android TV tertentu mungkin juga tidak memiliki handler galeri. Mitigasi: `try/catch PlatformException` di `_pickImageBytes()` menangani ini dengan graceful degradation.
- **RISK-002**: `image_picker` pada Android mungkin mengembalikan nama file dengan format berbeda (`photo_picker_12345.jpg`). Mitigasi: validasi ekstensi tetap dilakukan oleh `SlideshowFileStorageServiceImpl` yang memeriksa ekstensi dari `originalFileName` — jika tidak dikenal, exception dilempar dan ditangkap di blok `catch` yang sudah ada di `importIntoSlot()`.
- **RISK-003**: `XFile.name` pada beberapa platform mengembalikan path penuh, bukan hanya nama file. **Dimitigasi proaktif** di TASK-007: implementasi menggunakan `p.basename(image.path)` secara langsung (bukan `image.name`) sehingga nama file selalu akurat terlepas dari platform behavior. Tidak diperlukan fallback tambahan.
- **RISK-004**: `image_picker` v1.1.x mungkin tidak kompatibel dengan Android minSdkVersion 24. Mitigasi: `image_picker` mendukung Android API 21+, lebih rendah dari target project (API 24+), sehingga tidak ada masalah kompatibilitas.
- **ASSUMPTION-001**: `image_picker` dengan `ImageSource.gallery` menggunakan intent yang lebih umum tersedia di Android TV dibandingkan `ACTION_OPEN_DOCUMENT` milik `file_picker`.
- **ASSUMPTION-002**: `SlideshowFileStorageServiceImpl` tidak perlu diubah karena menerima `Uint8List` + nama file — tidak peduli darimana byte itu berasal (file_picker vs image_picker).
- **ASSUMPTION-003**: `image_picker` tidak memerlukan perubahan `AndroidManifest.xml` secara manual karena plugin mendeklarasikan permissions yang diperlukan melalui manifest merger.

---

## 8. Related Specifications / Further Reading

- [feature-slideshow-pengumuman-1.md](feature-slideshow-pengumuman-1.md) — Plan asal fitur slideshow (v1.1, Completed). REQ-012 di plan asal menyebutkan "system file picker Android TV" — plan ini adalah koreksi implementasi dari REQ tersebut.
- [AGENTS.md](../AGENTS.md) section "Slideshow Pengumuman" — daftar file slideshow yang sudah production ready.
- Crashlytics Issue ID: `a6c29f9ec1773af34589c37442f262db` — 13 crash events, v1.3.0 (build 8), perangkat Android 12.5, model ATS-01.
