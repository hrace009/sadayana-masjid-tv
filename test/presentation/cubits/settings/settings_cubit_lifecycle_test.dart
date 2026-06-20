// TASK-002: Lifecycle test untuk SettingsCubit
//
// Tujuan (Phase 1 — sebelum fix):
//   Test ini harus FAIL karena SettingsCubit._saveField() dan loadSettings()
//   belum memiliki guard isClosed sebelum memanggil emit().
//
// Tujuan (Phase 2 — setelah fix):
//   Test ini harus PASS karena guard isClosed sudah ditambahkan.
//
// Method yang diuji (memiliki emit() setelah await):
//   - loadSettings()  → emit(SettingsLoading), emit(SettingsLoaded/Error)
//   - _saveField()    → dipanggil via updateIdentity(), updateTreasuryEnabled(),
//                       updateWisdomEnabled(), dll.
//   - setPin()        → emit(SettingsLoaded isSaving=true), emit(SettingsLoaded)
//   - resetSettings() → emit(SettingsLoading), lalu delegasi ke loadSettings()

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:miqotul_khoir_tv/domain/entities/settings.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/display_state/display_state_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/prayer_time/prayer_time_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/settings/settings_cubit.dart';

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockPrayerTimeCubit extends Mock implements PrayerTimeCubit {}

class MockDisplayStateCubit extends Mock implements DisplayStateCubit {}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

const _tSettings = Settings(cityName: 'Bandung', offsetSubuh: 0);

/// Membangun SettingsCubit dengan stub minimal.
/// Karena konstruktor memanggil loadSettings() secara otomatis,
/// settingsRepository.getSettings() harus di-stub sebelum buildCubit() dipanggil.
SettingsCubit _buildCubit({
  required MockSettingsRepository repo,
  required MockPrayerTimeCubit prayerCubit,
  required MockDisplayStateCubit displayCubit,
}) {
  return SettingsCubit(
    settingsRepository: repo,
    prayerTimeCubit: prayerCubit,
    displayStateCubit: displayCubit,
  );
}

void main() {
  late MockSettingsRepository mockRepo;
  late MockPrayerTimeCubit mockPrayerCubit;
  late MockDisplayStateCubit mockDisplayCubit;

  setUp(() {
    mockRepo = MockSettingsRepository();
    mockPrayerCubit = MockPrayerTimeCubit();
    mockDisplayCubit = MockDisplayStateCubit();

    // Default stubs — wajib ada karena konstruktor auto-loads
    when(
      () => mockRepo.getSettings(),
    ).thenAnswer((_) async => _tSettings);
    when(
      () => mockRepo.updateSettings(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepo.setPin(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepo.resetSettings(),
    ).thenAnswer((_) async {});
    when(
      () => mockPrayerCubit.recalculate(),
    ).thenAnswer((_) async {});
    when(
      () => mockDisplayCubit.onSettingsChanged(),
    ).thenAnswer((_) async {});
  });

  // ---------------------------------------------------------------------------
  // Lifecycle Safety Tests
  // ---------------------------------------------------------------------------

  group('SettingsCubit — Lifecycle Safety', () {
    // ---
    // loadSettings(): emit(Loading) → await getSettings() → emit(Loaded/Error)
    // ---
    test(
      'loadSettings() does NOT throw StateError when cubit is closed during async',
      () async {
        // Arrange: blokir getSettings() dengan Completer
        final completer = Completer<Settings>();
        // Override stub agar panggilan *kedua* (dari loadSettings manual) diblokir.
        // Panggilan pertama dari konstruktor sudah selesai menggunakan stub default.
        // Kita perlu build cubit dulu (konstruktor selesai), lalu ganti stub.
        final cubit = _buildCubit(
          repo: mockRepo,
          prayerCubit: mockPrayerCubit,
          displayCubit: mockDisplayCubit,
        );
        // Tunggu konstruktor selesai auto-load
        await Future.microtask(() {});

        // Sekarang blokir getSettings() berikutnya
        when(
          () => mockRepo.getSettings(),
        ).thenAnswer((_) => completer.future);

        // Act: panggil loadSettings() lalu segera close
        final future = cubit.loadSettings();
        await cubit.close();
        completer.complete(_tSettings);

        // Assert: tidak ada StateError
        await expectLater(future, completes);
      },
    );

    // ---
    // _saveField() via updateIdentity(): emit(Loading isSaving=true) → await update → emit(Loaded)
    // ---
    test(
      'updateIdentity() (via _saveField) does NOT throw StateError when closed during save',
      () async {
        // Arrange: build cubit dan tunggu auto-load selesai
        final cubit = _buildCubit(
          repo: mockRepo,
          prayerCubit: mockPrayerCubit,
          displayCubit: mockDisplayCubit,
        );
        await Future.microtask(() {});

        // Blokir updateSettings() agar cubit bisa di-close sebelum await selesai
        final completer = Completer<void>();
        when(
          () => mockRepo.updateSettings(any()),
        ).thenAnswer((_) => completer.future);

        // Act: panggil updateIdentity() (menggunakan _saveField) lalu close
        final future = cubit.updateIdentity(
          mosqueName: 'Masjid Raya',
          mosqueAddress: 'Jl. Raya No. 1',
        );
        await cubit.close();
        completer.complete();

        // Assert
        await expectLater(future, completes);
      },
    );

    // ---
    // setPin(): emit(Loading isSaving=true) → await setPin → await getSettings → emit(Loaded)
    // ---
    test(
      'setPin() does NOT throw StateError when cubit is closed during async',
      () async {
        // Arrange: build cubit dan tunggu auto-load selesai (state = Loaded)
        final cubit = _buildCubit(
          repo: mockRepo,
          prayerCubit: mockPrayerCubit,
          displayCubit: mockDisplayCubit,
        );
        await Future.microtask(() {});

        // Blokir setPin()
        final completer = Completer<void>();
        when(
          () => mockRepo.setPin(any()),
        ).thenAnswer((_) => completer.future);

        // Act
        final future = cubit.setPin('1234');
        await cubit.close();
        completer.complete();

        // Assert
        await expectLater(future, completes);
      },
    );

    // ---
    // resetSettings(): emit(Loading) → await reset → await loadSettings
    // ---
    test(
      'resetSettings() does NOT throw StateError when cubit is closed during async',
      () async {
        // Arrange: build cubit dan tunggu auto-load selesai
        final cubit = _buildCubit(
          repo: mockRepo,
          prayerCubit: mockPrayerCubit,
          displayCubit: mockDisplayCubit,
        );
        await Future.microtask(() {});

        // Blokir resetSettings()
        final completer = Completer<void>();
        when(
          () => mockRepo.resetSettings(),
        ).thenAnswer((_) => completer.future);

        // Act
        final future = cubit.resetSettings();
        await cubit.close();
        completer.complete();

        // Assert
        await expectLater(future, completes);
      },
    );
  });
}
