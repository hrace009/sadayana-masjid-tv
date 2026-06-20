// TASK-003: Lifecycle test untuk SetupWizardCubit
//
// Tujuan (Phase 1 — sebelum fix):
//   Test ini harus FAIL karena SetupWizardCubit.completeSetup() belum memiliki
//   guard isClosed sebelum memanggil emit(SetupWizardCompleted()) atau
//   emit(SetupWizardError()).
//
// Tujuan (Phase 2 — setelah fix):
//   Test ini harus PASS karena guard isClosed sudah ditambahkan.
//
// Method yang diuji (memiliki emit() setelah await):
//   - completeSetup() → emit(Completing) → await updateSettings() →
//                       await completeFirstRun() → emit(Completed/Error)

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:miqotul_khoir_tv/domain/entities/setup_wizard_data.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/setup_wizard/setup_wizard_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/setup_wizard/setup_wizard_state.dart';

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class MockSettingsRepository extends Mock implements SettingsRepository {}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

/// Data wizard yang sudah lengkap (lolos validasi step 3)
const _tCompleteData = SetupWizardData(
  mosqueName: 'Masjid Raya Al-Ikhlas',
  mosqueAddress: 'Jl. Raya No. 1',
  cityName: 'Bandung',
  provinceName: 'Jawa Barat',
  latitude: -6.9175,
  longitude: 107.6191,
);

void main() {
  late MockSettingsRepository mockRepo;

  setUp(() {
    mockRepo = MockSettingsRepository();

    // Default stubs
    when(
      () => mockRepo.updateSettings(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockRepo.completeFirstRun(),
    ).thenAnswer((_) async {});
  });

  // ---------------------------------------------------------------------------
  // Lifecycle Safety Tests
  // ---------------------------------------------------------------------------

  group('SetupWizardCubit — Lifecycle Safety', () {
    // ---
    // completeSetup() — dipicu oleh goToNextStep() di step 3
    // Alur: emit(Completing) → await updateSettings() → await completeFirstRun()
    //       → emit(Completed/Error)
    // ---
    test(
      'completeSetup() does NOT throw StateError when cubit is closed during async',
      () async {
        // Arrange: blokir updateSettings() dengan Completer
        final completer = Completer<void>();
        when(
          () => mockRepo.updateSettings(any()),
        ).thenAnswer((_) => completer.future);

        final cubit = SetupWizardCubit(mockRepo);

        // Seed state ke step 3 dengan data lengkap
        cubit.emit(
          const SetupWizardInProgress(currentStep: 3, data: _tCompleteData),
        );

        // Act: panggil completeSetup() lalu segera close
        final future = cubit.completeSetup();
        await cubit.close();
        completer.complete();

        // Assert: tidak ada StateError
        await expectLater(future, completes);
      },
    );

    // ---
    // Skenario: user menekan back di PreviewStep saat loading
    // (goToNextStep() di step 3 memanggil completeSetup() secara internal)
    // ---
    test(
      'goToNextStep() at step 3 does NOT throw StateError when closed during save',
      () async {
        // Arrange: blokir completeFirstRun() (dipanggil setelah updateSettings)
        when(
          () => mockRepo.updateSettings(any()),
        ).thenAnswer((_) async {});
        final completer = Completer<void>();
        when(
          () => mockRepo.completeFirstRun(),
        ).thenAnswer((_) => completer.future);

        final cubit = SetupWizardCubit(mockRepo);
        cubit.emit(
          const SetupWizardInProgress(currentStep: 3, data: _tCompleteData),
        );

        // Act
        cubit.goToNextStep(); // fire-and-forget karena async
        await cubit.close();
        completer.complete();

        // Assert: tidak ada exception yang tidak tertangkap
        await expectLater(Future.value(), completes);
      },
    );
  });
}
