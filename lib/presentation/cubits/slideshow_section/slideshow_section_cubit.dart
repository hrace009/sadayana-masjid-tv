import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import 'package:miqotul_khoir_tv/domain/repositories/slideshow_image_repository.dart';
import 'package:miqotul_khoir_tv/domain/services/slideshow_file_storage_service.dart';
import 'slideshow_section_state.dart';
import '../display_state/display_state_cubit.dart';

/// Cubit yang mengelola manajemen 3 slot gambar slideshow dari Settings UI.
///
/// Bertanggung jawab atas: memuat daftar slot ([loadImages]), mengimpor gambar
/// ke slot kosong ([importIntoSlot]), mengganti gambar pada slot terisi
/// ([replaceSlot]), menghapus gambar dari slot ([deleteFromSlot]), dan
/// membersihkan pesan error ([clearError]).
///
/// **TS-P4-001**: Cubit ini TIDAK mengelola scalar settings slideshow.
/// Scalar settings (toggle, interval, jadwal) tetap menjadi tanggung jawab
/// [SettingsCubit].
///
/// **TS-P4-002**: [importIntoSlot] dan [replaceSlot] tidak boleh mengubah
/// toggle `isSlideshowEnabled` menjadi `true` secara otomatis.
///
/// **TS-P4-003**: [deleteFromSlot] selalu me-reload daftar slot setelah
/// berhasil agar UI dapat menghitung jumlah gambar tersisa.
///
/// **TS-P4-004**: [errorMessage] hanya dipakai untuk surface kegagalan I/O
/// atau picker, dan tidak boleh memodifikasi scalar settings.
///
/// Ref: TASK-020, TASK-021, TASK-022, TASK-023 (Phase 4 — Slideshow Pengumuman)
class SlideshowSectionCubit extends Cubit<SlideshowSectionState> {
  final SlideshowImageRepository _imageRepository;
  final SlideshowFileStorageService _storageService;
  final DisplayStateCubit? _displayStateCubit;
  final ImagePicker _imagePicker;

  SlideshowSectionCubit({
    required SlideshowImageRepository imageRepository,
    required SlideshowFileStorageService storageService,
    DisplayStateCubit? displayStateCubit,
    ImagePicker? imagePicker,
  }) : _imageRepository = imageRepository,
       _storageService = storageService,
       _displayStateCubit = displayStateCubit,
       _imagePicker = imagePicker ?? ImagePicker(),
       super(const SlideshowSectionState.initial());

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Memuat daftar slot dari repository dan memperbarui state.
  ///
  /// Selama loading, [SlideshowSectionState.isLoading] bernilai `true`.
  /// Error yang terjadi akan disimpan di [SlideshowSectionState.errorMessage].
  Future<void> loadImages() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final images = await _imageRepository.getAll();
      emit(state.copyWith(images: images, isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat daftar gambar: ${e.toString()}',
        ),
      );
    }
  }

  /// Membuka file picker lalu mengimpor gambar ke [slotIndex] yang KOSONG.
  ///
  /// Jika user membatalkan picker, state tidak berubah sama sekali (TS-P4-002).
  /// Memanggil ini pada slot yang sudah terisi harus diikuti oleh [replaceSlot].
  ///
  /// Ref: TASK-021
  Future<void> importIntoSlot(int slotIndex) async {
    final bytes = await _pickImageBytes();
    if (bytes == null) return; // user cancel — no state change

    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final image = await _storageService.importImage(
        slotIndex: slotIndex,
        originalFileName: bytes.fileName,
        bytes: bytes.data,
      );
      await _imageRepository.save(image);
      await _reloadImages();
      _displayStateCubit?.onSettingsChanged();
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          errorMessage: 'Gagal mengimpor gambar: ${e.toString()}',
        ),
      );
    }
  }

  /// Mengganti gambar pada [slotIndex] yang sudah terisi dengan gambar baru.
  ///
  /// Alur replace (TASK-022):
  /// 1. Buka file picker.
  /// 2. Jika user cancel → no-op.
  /// 3. Hapus file internal lama via [SlideshowFileStorageService.deleteStoredImage].
  /// 4. Impor file baru dan simpan metadata baru via repository.
  ///
  /// Ref: TASK-021, TASK-022
  Future<void> replaceSlot(int slotIndex) async {
    final bytes = await _pickImageBytes();
    if (bytes == null) return; // user cancel — no state change

    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      // Hapus file internal lama jika ada
      final existingImage = await _imageRepository.getBySlot(slotIndex);
      if (existingImage != null) {
        await _storageService.deleteStoredImage(existingImage.storedPath);
      }

      // Impor file baru lalu simpan metadata
      final newImage = await _storageService.importImage(
        slotIndex: slotIndex,
        originalFileName: bytes.fileName,
        bytes: bytes.data,
      );
      await _imageRepository.save(newImage);
      await _reloadImages();
      _displayStateCubit?.onSettingsChanged();
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          errorMessage: 'Gagal mengganti gambar: ${e.toString()}',
        ),
      );
    }
  }

  /// Menghapus gambar dari [slotIndex].
  ///
  /// Alur delete (TASK-023):
  /// 1. Ambil metadata gambar dari repository.
  /// 2. Hapus file internal via [SlideshowFileStorageService.deleteStoredImage].
  /// 3. Hapus metadata dari repository.
  /// 4. Reload daftar slot agar UI dapat menghitung jumlah gambar tersisa.
  ///
  /// Ref: TASK-023
  Future<void> deleteFromSlot(int slotIndex) async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final image = await _imageRepository.getBySlot(slotIndex);
      if (image != null) {
        await _storageService.deleteStoredImage(image.storedPath);
        await _imageRepository.deleteBySlot(slotIndex);
      }
      await _reloadImages();
      _displayStateCubit?.onSettingsChanged();
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          errorMessage: 'Gagal menghapus gambar: ${e.toString()}',
        ),
      );
    }
  }

  /// Menghapus [SlideshowSectionState.errorMessage] dari state.
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Membuka image picker dan mengembalikan [_PickedFile] berisi bytes dan nama
  /// file, atau `null` jika user membatalkan pilihan.
  ///
  /// Picker hanya bertugas mengambil file dari galeri. Validasi format ekstensi
  /// tetap dilakukan di layer [SlideshowFileStorageService] sesuai whitelist.
  ///
  /// PlatformException dari picker ditangani di sini agar tidak menjadi crash
  /// fatal pada perangkat tanpa aplikasi galeri/pengelola file kompatibel.
  Future<_PickedFile?> _pickImageBytes() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (image == null) return null;

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

  /// Me-reload daftar slot dari repository dan memperbarui state.
  ///
  /// Selalu memanggil emit dengan `isBusy: false` di akhir, baik berhasil
  /// maupun gagal.
  Future<void> _reloadImages() async {
    try {
      final images = await _imageRepository.getAll();
      emit(state.copyWith(images: images, isBusy: false));
    } catch (e) {
      emit(
        state.copyWith(
          isBusy: false,
          errorMessage: 'Gagal memuat ulang daftar gambar: ${e.toString()}',
        ),
      );
    }
  }
}

/// Value object internal untuk meneruskan hasil picker ke method impor.
class _PickedFile {
  final String fileName;
  final Uint8List data;

  _PickedFile({required this.fileName, required this.data});
}
