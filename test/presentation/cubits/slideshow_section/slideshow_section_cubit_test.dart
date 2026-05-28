import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';
import 'package:miqotul_khoir_tv/domain/repositories/slideshow_image_repository.dart';
import 'package:miqotul_khoir_tv/domain/services/slideshow_file_storage_service.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/slideshow_section/slideshow_section_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/slideshow_section/slideshow_section_state.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/display_state/display_state_cubit.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSlideshowImageRepository extends Mock
    implements SlideshowImageRepository {}

class MockSlideshowFileStorageService extends Mock
    implements SlideshowFileStorageService {}

class MockImagePickerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements ImagePickerPlatform {}

class MockDisplayStateCubit extends Mock implements DisplayStateCubit {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kSlot1 = SlideshowImage(
  slotIndex: 1,
  fileName: 'slide_slot_1_100.jpg',
  storedPath: '/internal/slideshow/slide_slot_1_100.jpg',
  mimeType: 'image/jpeg',
  width: 1920,
  height: 1080,
  fileSizeBytes: 150000,
);

const _kSlot2 = SlideshowImage(
  slotIndex: 2,
  fileName: 'slide_slot_2_200.jpg',
  storedPath: '/internal/slideshow/slide_slot_2_200.jpg',
  mimeType: 'image/jpeg',
  width: 1920,
  height: 1080,
  fileSizeBytes: 180000,
);

XFile _makeXFile(Uint8List bytes, String name) {
  return XFile.fromData(bytes, name: name, path: '/virtual/$name');
}

/// Unit tests untuk [SlideshowSectionCubit].
///
/// ImagePicker dimock melalui `ImagePickerPlatform.instance`.
///
/// Ref: TASK-049 (Phase 8 — Slideshow Pengumuman), TEST-004, TEST-005, TEST-006
void main() {
  late MockSlideshowImageRepository repo;
  late MockSlideshowFileStorageService storage;
  late MockImagePickerPlatform mockImagePickerPlatform;
  late MockDisplayStateCubit displayCubit;

  setUpAll(() {
    // mocktail perlu fallback value untuk enum/class yang dipakai dengan any()
    registerFallbackValue(ImageSource.gallery);
    registerFallbackValue(const ImagePickerOptions());
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
      const SlideshowImage(
        slotIndex: 1,
        fileName: '_fallback.jpg',
        storedPath: '/fallback.jpg',
        mimeType: 'image/jpeg',
        width: 1,
        height: 1,
        fileSizeBytes: 1,
      ),
    );
  });

  setUp(() {
    repo = MockSlideshowImageRepository();
    storage = MockSlideshowFileStorageService();
    mockImagePickerPlatform = MockImagePickerPlatform();
    ImagePickerPlatform.instance = mockImagePickerPlatform;
    displayCubit = MockDisplayStateCubit();
    when(() => displayCubit.onSettingsChanged()).thenAnswer((_) async {});
  });

  SlideshowSectionCubit buildCubit() => SlideshowSectionCubit(
    imageRepository: repo,
    storageService: storage,
    displayStateCubit: displayCubit,
  );

  // ---------------------------------------------------------------------------
  // loadImages()
  // ---------------------------------------------------------------------------

  group('loadImages()', () {
    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'emits [isLoading: true] lalu [isLoading: false, images: loaded]',
      setUp: () {
        when(() => repo.getAll()).thenAnswer((_) async => [_kSlot1]);
      },
      build: buildCubit,
      act: (c) => c.loadImages(),
      expect: () => [
        const SlideshowSectionState(images: [], isLoading: true, isBusy: false),
        const SlideshowSectionState(
          images: [_kSlot1],
          isLoading: false,
          isBusy: false,
        ),
      ],
    );

    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'emits errorMessage jika repo.getAll() throws',
      setUp: () {
        when(() => repo.getAll()).thenThrow(Exception('DB error'));
      },
      build: buildCubit,
      act: (c) => c.loadImages(),
      expect: () => [
        const SlideshowSectionState(images: [], isLoading: true, isBusy: false),
        isA<SlideshowSectionState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.errorMessage, 'errorMessage', isNotNull),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // importIntoSlot() — cancel
  // ---------------------------------------------------------------------------

  group('importIntoSlot() — user cancel', () {
    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'tidak emit state baru jika user membatalkan picker (TS-P4-002)',
      setUp: () {
        when(
          () => mockImagePickerPlatform.getImageFromSource(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => null);
      },
      build: buildCubit,
      act: (c) => c.importIntoSlot(1),
      expect: () => <SlideshowSectionState>[],
    );
  });

  // ---------------------------------------------------------------------------
  // importIntoSlot() — sukses
  // ---------------------------------------------------------------------------

  group('importIntoSlot() — sukses', () {
    final fakeBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'emits [isBusy: true] lalu [isBusy: false, images: loaded] setelah import',
      setUp: () {
        when(
          () => mockImagePickerPlatform.getImageFromSource(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => _makeXFile(fakeBytes, 'slide_slot_1_9999.jpg'),
        );
        when(
          () => storage.importImage(
            slotIndex: any(named: 'slotIndex'),
            originalFileName: any(named: 'originalFileName'),
            bytes: any(named: 'bytes'),
          ),
        ).thenAnswer((_) async => _kSlot1);
        when(() => repo.save(any())).thenAnswer((_) async {});
        when(() => repo.getAll()).thenAnswer((_) async => [_kSlot1]);
      },
      build: buildCubit,
      act: (c) => c.importIntoSlot(1),
      expect: () => [
        const SlideshowSectionState(images: [], isLoading: false, isBusy: true),
        const SlideshowSectionState(
          images: [_kSlot1],
          isLoading: false,
          isBusy: false,
        ),
      ],
    );

    test(
      'importIntoSlot tidak auto-set isSlideshowEnabled ke true (TS-P4-002)',
      () async {
        when(
          () => mockImagePickerPlatform.getImageFromSource(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => _makeXFile(fakeBytes, 'img.jpg'));
        when(
          () => storage.importImage(
            slotIndex: any(named: 'slotIndex'),
            originalFileName: any(named: 'originalFileName'),
            bytes: any(named: 'bytes'),
          ),
        ).thenAnswer((_) async => _kSlot1);
        when(() => repo.save(any())).thenAnswer((_) async {});
        when(() => repo.getAll()).thenAnswer((_) async => [_kSlot1]);

        final cubit = buildCubit();
        await cubit.importIntoSlot(1);

        // Cubit hanya mengelola images, isLoading, isBusy, errorMessage
        // Tidak ada property isSlideshowEnabled di SlideshowSectionState
        expect(cubit.state.images, contains(_kSlot1));
        cubit.close();
      },
    );
  });

  // ---------------------------------------------------------------------------
  // importIntoSlot() — error
  // ---------------------------------------------------------------------------

  group('importIntoSlot() — error pada importImage', () {
    final fakeBytes = Uint8List.fromList([0xFF, 0xD8]);

    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'emits errorMessage dan isBusy: false jika storage.importImage() throws',
      setUp: () {
        when(
          () => mockImagePickerPlatform.getImageFromSource(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => _makeXFile(fakeBytes, 'img.jpg'));
        when(
          () => storage.importImage(
            slotIndex: any(named: 'slotIndex'),
            originalFileName: any(named: 'originalFileName'),
            bytes: any(named: 'bytes'),
          ),
        ).thenThrow(Exception('Disk full'));
      },
      build: buildCubit,
      act: (c) => c.importIntoSlot(2),
      expect: () => [
        const SlideshowSectionState(images: [], isLoading: false, isBusy: true),
        isA<SlideshowSectionState>()
            .having((s) => s.isBusy, 'isBusy', isFalse)
            .having((s) => s.errorMessage, 'errorMessage', contains('Gagal')),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // replaceSlot()
  // ---------------------------------------------------------------------------

  group('replaceSlot()', () {
    final fakeBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'memanggil deleteStoredImage untuk gambar lama, lalu importImage + save',
      setUp: () {
        when(
          () => mockImagePickerPlatform.getImageFromSource(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => _makeXFile(fakeBytes, 'new.png'));
        when(() => repo.getBySlot(1)).thenAnswer((_) async => _kSlot1);
        when(() => storage.deleteStoredImage(any())).thenAnswer((_) async {});
        when(
          () => storage.importImage(
            slotIndex: any(named: 'slotIndex'),
            originalFileName: any(named: 'originalFileName'),
            bytes: any(named: 'bytes'),
          ),
        ).thenAnswer((_) async => _kSlot2);
        when(() => repo.save(any())).thenAnswer((_) async {});
        when(() => repo.getAll()).thenAnswer((_) async => [_kSlot2]);
      },
      build: buildCubit,
      act: (c) => c.replaceSlot(1),
      verify: (_) {
        verify(() => storage.deleteStoredImage(_kSlot1.storedPath)).called(1);
        verify(
          () => storage.importImage(
            slotIndex: 1,
            originalFileName: any(named: 'originalFileName'),
            bytes: any(named: 'bytes'),
          ),
        ).called(1);
        verify(() => repo.save(any())).called(1);
      },
    );

    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'no-op jika user cancel pada replaceSlot',
      setUp: () {
        when(
          () => mockImagePickerPlatform.getImageFromSource(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => null);
      },
      build: buildCubit,
      act: (c) => c.replaceSlot(1),
      expect: () => <SlideshowSectionState>[],
    );
  });

  // ---------------------------------------------------------------------------
  // deleteFromSlot()
  // ---------------------------------------------------------------------------

  group('deleteFromSlot()', () {
    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'memanggil deleteStoredImage + deleteBySlot, lalu reload',
      setUp: () {
        when(() => repo.getBySlot(1)).thenAnswer((_) async => _kSlot1);
        when(() => storage.deleteStoredImage(any())).thenAnswer((_) async {});
        when(() => repo.deleteBySlot(1)).thenAnswer((_) async {});
        when(() => repo.getAll()).thenAnswer((_) async => []);
      },
      build: buildCubit,
      act: (c) => c.deleteFromSlot(1),
      verify: (_) {
        verify(() => storage.deleteStoredImage(_kSlot1.storedPath)).called(1);
        verify(() => repo.deleteBySlot(1)).called(1);
      },
    );

    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'tidak memanggil deleteStoredImage jika slot kosong',
      setUp: () {
        when(() => repo.getBySlot(3)).thenAnswer((_) async => null);
        when(() => repo.deleteBySlot(3)).thenAnswer((_) async {});
        when(() => repo.getAll()).thenAnswer((_) async => []);
      },
      build: buildCubit,
      act: (c) => c.deleteFromSlot(3),
      verify: (_) {
        verifyNever(() => storage.deleteStoredImage(any()));
      },
    );

    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'emits [isBusy: true] lalu [isBusy: false] dengan images kosong',
      setUp: () {
        when(() => repo.getBySlot(1)).thenAnswer((_) async => _kSlot1);
        when(() => storage.deleteStoredImage(any())).thenAnswer((_) async {});
        when(() => repo.deleteBySlot(1)).thenAnswer((_) async {});
        when(() => repo.getAll()).thenAnswer((_) async => []);
      },
      build: buildCubit,
      act: (c) => c.deleteFromSlot(1),
      expect: () => [
        const SlideshowSectionState(images: [], isLoading: false, isBusy: true),
        const SlideshowSectionState(
          images: [],
          isLoading: false,
          isBusy: false,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // clearError()
  // ---------------------------------------------------------------------------

  group('clearError()', () {
    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'menghapus errorMessage dari state',
      build: () {
        final cubit = buildCubit();
        // Paksakan state dengan errorMessage menggunakan seed
        return cubit;
      },
      seed: () => const SlideshowSectionState(
        images: [],
        isLoading: false,
        isBusy: false,
        errorMessage: 'Terjadi kesalahan',
      ),
      act: (c) => c.clearError(),
      expect: () => [
        const SlideshowSectionState(
          images: [],
          isLoading: false,
          isBusy: false,
          errorMessage: null,
        ),
      ],
    );
  });

  group('importIntoSlot() — PlatformException dari picker', () {
    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'emits errorMessage dan tidak crash saat picker melempar PlatformException',
      setUp: () {
        when(
          () => mockImagePickerPlatform.getImageFromSource(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenThrow(PlatformException(code: 'invalid_format_type'));
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

  group('replaceSlot() — PlatformException dari picker', () {
    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'emits errorMessage dan tidak crash saat picker melempar PlatformException',
      setUp: () {
        when(
          () => mockImagePickerPlatform.getImageFromSource(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenThrow(PlatformException(code: 'invalid_format_type'));
      },
      build: buildCubit,
      act: (c) => c.replaceSlot(1),
      expect: () => [
        isA<SlideshowSectionState>()
            .having((s) => s.errorMessage, 'errorMessage', isNotNull)
            .having((s) => s.isBusy, 'isBusy', isFalse),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // Exception non-PlatformException dari readAsBytes() — Finding HIGH
  // -------------------------------------------------------------------------

  group(
    'importIntoSlot() — Exception non-PlatformException dari readAsBytes()',
    () {
      blocTest<SlideshowSectionCubit, SlideshowSectionState>(
        'emits errorMessage dan tidak crash saat readAsBytes() melempar PathNotFoundException',
        setUp: () {
          // XFile dengan path yang tidak ada → readAsBytes() melempar
          // PathNotFoundException (subclass Exception) secara alami.
          when(
            () => mockImagePickerPlatform.getImageFromSource(
              source: any(named: 'source'),
              options: any(named: 'options'),
            ),
          ).thenAnswer((_) async => XFile('/nonexistent/path.jpg'));
        },
        build: buildCubit,
        act: (c) => c.importIntoSlot(1),
        // isBusy:true tidak diemit karena _pickImageBytes() throw sebelum
        // importIntoSlot() sempat memanggil emit(isBusy:true).
        expect: () => [
          isA<SlideshowSectionState>()
              .having((s) => s.errorMessage, 'errorMessage', isNotNull)
              .having((s) => s.isBusy, 'isBusy', isFalse),
        ],
      );
    },
  );

  group('replaceSlot() — Exception non-PlatformException dari readAsBytes()', () {
    blocTest<SlideshowSectionCubit, SlideshowSectionState>(
      'emits errorMessage dan tidak crash saat readAsBytes() melempar PathNotFoundException',
      setUp: () {
        when(
          () => mockImagePickerPlatform.getImageFromSource(
            source: any(named: 'source'),
            options: any(named: 'options'),
          ),
        ).thenAnswer((_) async => XFile('/nonexistent/path.jpg'));
      },
      build: buildCubit,
      act: (c) => c.replaceSlot(1),
      // isBusy:true tidak diemit karena _pickImageBytes() throw sebelum
      // replaceSlot() sempat memanggil emit(isBusy:true).
      expect: () => [
        isA<SlideshowSectionState>()
            .having((s) => s.errorMessage, 'errorMessage', isNotNull)
            .having((s) => s.isBusy, 'isBusy', isFalse),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // importIntoSlot() — _resolveFileName() strategi fallback nama file
  // ---------------------------------------------------------------------------

  group('importIntoSlot() — _resolveFileName() strategi fallback nama file', () {
    final fakeBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

    /// Stub storage/repo agar importIntoSlot() dapat tuntas setelah picker selesai.
    void stubStorageForImport() {
      when(
        () => storage.importImage(
          slotIndex: any(named: 'slotIndex'),
          originalFileName: any(named: 'originalFileName'),
          bytes: any(named: 'bytes'),
        ),
      ).thenAnswer((_) async => _kSlot1);
      when(() => repo.save(any())).thenAnswer((_) async {});
      when(() => repo.getAll()).thenAnswer((_) async => [_kSlot1]);
    }

    /// Helper: pick image dari [filePath], jalankan importIntoSlot(1), lalu
    /// return `originalFileName` yang diteruskan ke storage.importImage().
    Future<String> captureOriginalFileName(String filePath) async {
      final xfile = XFile.fromData(fakeBytes, path: filePath);
      when(
        () => mockImagePickerPlatform.getImageFromSource(
          source: any(named: 'source'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => xfile);
      stubStorageForImport();

      final cubit = buildCubit();
      await cubit.importIntoSlot(1);

      final captured = verify(
        () => storage.importImage(
          slotIndex: any(named: 'slotIndex'),
          originalFileName: captureAny(named: 'originalFileName'),
          bytes: any(named: 'bytes'),
        ),
      ).captured;

      await cubit.close();
      return captured.single as String;
    }

    test(
      'TEST-002: path dengan ekstensi valid (.jpg) — kembalikan basename path',
      () async {
        // p.join menggunakan separator platform yang benar (/ di POSIX, \ di Windows)
        // sehingga p.basename dan XFile.name keduanya menghasilkan 'image.jpg'
        final filePath = p.join('cache', 'image.jpg');
        expect(await captureOriginalFileName(filePath), equals('image.jpg'));
      },
    );

    test(
      'TEST-003: path tanpa ekstensi — fallback ke image.name (basename path)',
      () async {
        // Tidak ada ekstensi → validExts.contains('') = false
        // Fallback ke image.name = path.split(sep).last = 'tmp_file'
        final filePath = p.join('cache', 'tmp_file');
        expect(await captureOriginalFileName(filePath), equals('tmp_file'));
      },
    );

    test(
      'TEST-004: path dengan ekstensi tidak dikenal (.bmp) — fallback ke image.name',
      () async {
        // .bmp bukan dalam whitelist validExts → fallback ke image.name = 'photo.bmp'
        final filePath = p.join('cache', 'photo.bmp');
        expect(await captureOriginalFileName(filePath), equals('photo.bmp'));
      },
    );
  });
}
