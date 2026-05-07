import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';
import 'package:miqotul_khoir_tv/domain/repositories/slideshow_image_repository.dart';
import 'package:miqotul_khoir_tv/domain/services/slideshow_file_storage_service.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/slideshow_section/slideshow_section_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/slideshow_section/slideshow_section_state.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSlideshowImageRepository extends Mock
    implements SlideshowImageRepository {}

class MockSlideshowFileStorageService extends Mock
    implements SlideshowFileStorageService {}

class MockFilePicker extends Mock
    with MockPlatformInterfaceMixin
    implements FilePicker {}

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

FilePickerResult _makePickerResult(String name, Uint8List bytes) {
  return FilePickerResult([
    PlatformFile(name: name, size: bytes.length, bytes: bytes),
  ]);
}

/// Unit tests untuk [SlideshowSectionCubit].
///
/// FilePicker dimock melalui `FilePicker.platform` setter yang
/// disediakan package `file_picker` untuk testing.
///
/// Ref: TASK-049 (Phase 8 — Slideshow Pengumuman), TEST-004, TEST-005, TEST-006
void main() {
  late MockSlideshowImageRepository repo;
  late MockSlideshowFileStorageService storage;
  late MockFilePicker mockPicker;

  setUpAll(() {
    // mocktail perlu fallback value untuk enum/class yang dipakai dengan any()
    registerFallbackValue(FileType.any);
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
    mockPicker = MockFilePicker();
    FilePicker.platform = mockPicker;
  });

  SlideshowSectionCubit buildCubit() =>
      SlideshowSectionCubit(imageRepository: repo, storageService: storage);

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
          () => mockPicker.pickFiles(
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
            allowMultiple: any(named: 'allowMultiple'),
            withData: any(named: 'withData'),
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
          () => mockPicker.pickFiles(
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
            allowMultiple: any(named: 'allowMultiple'),
            withData: any(named: 'withData'),
          ),
        ).thenAnswer(
          (_) async => _makePickerResult('slide_slot_1_9999.jpg', fakeBytes),
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
          () => mockPicker.pickFiles(
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
            allowMultiple: any(named: 'allowMultiple'),
            withData: any(named: 'withData'),
          ),
        ).thenAnswer((_) async => _makePickerResult('img.jpg', fakeBytes));
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
          () => mockPicker.pickFiles(
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
            allowMultiple: any(named: 'allowMultiple'),
            withData: any(named: 'withData'),
          ),
        ).thenAnswer((_) async => _makePickerResult('img.jpg', fakeBytes));
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
          () => mockPicker.pickFiles(
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
            allowMultiple: any(named: 'allowMultiple'),
            withData: any(named: 'withData'),
          ),
        ).thenAnswer((_) async => _makePickerResult('new.png', fakeBytes));
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
          () => mockPicker.pickFiles(
            type: any(named: 'type'),
            allowedExtensions: any(named: 'allowedExtensions'),
            allowMultiple: any(named: 'allowMultiple'),
            withData: any(named: 'withData'),
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
}
