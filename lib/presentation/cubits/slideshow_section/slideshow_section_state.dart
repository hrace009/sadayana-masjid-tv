import 'package:equatable/equatable.dart';

import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';

/// State untuk [SlideshowSectionCubit].
///
/// [images] selalu memuat daftar terkini slot yang terisi, diurutkan
/// berdasarkan `slotIndex`. UI harus menghitung apakah jumlah gambar
/// tersisa `0` dari list ini untuk menentukan apakah auto-disable diperlukan.
///
/// [isLoading] aktif selama `loadImages()` berjalan.
/// [isBusy]    aktif selama `importIntoSlot()`, `replaceSlot()`, atau
///             `deleteFromSlot()` berjalan.
/// [errorMessage] berisi pesan error I/O atau picker; null jika tidak ada.
///
/// Ref: TASK-019 (Phase 4 — Slideshow Pengumuman), TS-P4-004
class SlideshowSectionState extends Equatable {
  final List<SlideshowImage> images;
  final bool isLoading;
  final bool isBusy;
  final String? errorMessage;

  const SlideshowSectionState({
    required this.images,
    required this.isLoading,
    required this.isBusy,
    this.errorMessage,
  });

  /// State awal sebelum `loadImages()` dipanggil pertama kali.
  const SlideshowSectionState.initial()
    : images = const [],
      isLoading = false,
      isBusy = false,
      errorMessage = null;

  SlideshowSectionState copyWith({
    List<SlideshowImage>? images,
    bool? isLoading,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SlideshowSectionState(
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [images, isLoading, isBusy, errorMessage];
}
