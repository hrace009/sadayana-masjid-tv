import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/domain/entities/city.dart';
import 'package:miqotul_khoir_tv/domain/entities/setup_wizard_data.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/setup_wizard/setup_wizard_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/setup_wizard/setup_wizard_state.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SettingsRepository settingsRepository;
  late SetupWizardCubit cubit;

  setUp(() {
    settingsRepository = MockSettingsRepository();
    cubit = SetupWizardCubit(settingsRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('SetupWizardCubit', () {
    test('initial state is correct', () {
      expect(
        cubit.state,
        const SetupWizardInProgress(currentStep: 0, data: SetupWizardData()),
      );
    });

    // --- Update Data Tests ---

    blocTest<SetupWizardCubit, SetupWizardState>(
      'updateMosqueName updates data',
      build: () => cubit,
      act: (cubit) => cubit.updateMosqueName('Masjid Raya'),
      expect: () => [
        const SetupWizardInProgress(
          currentStep: 0,
          data: SetupWizardData(mosqueName: 'Masjid Raya'),
        ),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'selectCity updates location data',
      build: () => cubit,
      act: (cubit) => cubit.selectCity(
        const City(
          id: 1,
          provinceName: 'Jawa Barat',
          cityName: 'Bandung',
          latitude: -6.9175,
          longitude: 107.6191,
        ),
      ),
      expect: () => [
        const SetupWizardInProgress(
          currentStep: 0,
          data: SetupWizardData(
            cityName: 'Bandung',
            provinceName: 'Jawa Barat',
            latitude: -6.9175,
            longitude: 107.6191,
          ),
        ),
      ],
    );

    // --- Navigation Tests ---

    blocTest<SetupWizardCubit, SetupWizardState>(
      'goToNextStep moves from Step 0 to Step 1',
      build: () => cubit,
      seed: () =>
          const SetupWizardInProgress(currentStep: 0, data: SetupWizardData()),
      act: (cubit) => cubit.goToNextStep(),
      expect: () => [
        const SetupWizardInProgress(currentStep: 1, data: SetupWizardData()),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'goToNextStep fails validation at Step 1 (Identity) with invalid name',
      build: () => cubit,
      seed: () => const SetupWizardInProgress(
        currentStep: 1,
        data: SetupWizardData(mosqueName: 'AB'), // too short
      ),
      act: (cubit) => cubit.goToNextStep(),
      expect: () => [
        const SetupWizardInProgress(
          currentStep: 1,
          data: SetupWizardData(mosqueName: 'AB'),
          validationError: 'Nama masjid minimal 3 karakter',
        ),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'goToNextStep moves from Step 1 to Step 2 with valid name',
      build: () => cubit,
      seed: () => const SetupWizardInProgress(
        currentStep: 1,
        data: SetupWizardData(mosqueName: 'Masjid Raya'),
      ),
      act: (cubit) => cubit.goToNextStep(),
      expect: () => [
        const SetupWizardInProgress(
          currentStep: 2,
          data: SetupWizardData(mosqueName: 'Masjid Raya'),
        ),
      ],
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'goToPreviousStep moves back',
      build: () => cubit,
      seed: () =>
          const SetupWizardInProgress(currentStep: 2, data: SetupWizardData()),
      act: (cubit) => cubit.goToPreviousStep(),
      expect: () => [
        const SetupWizardInProgress(currentStep: 1, data: SetupWizardData()),
      ],
    );

    // --- Completion Tests ---

    blocTest<SetupWizardCubit, SetupWizardState>(
      'goToNextStep at Step 3 (Preview) completes setup successfully',
      build: () {
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        when(
          () => settingsRepository.completeFirstRun(),
        ).thenAnswer((_) async {});
        return cubit;
      },
      seed: () => const SetupWizardInProgress(
        currentStep: 3,
        data: SetupWizardData(
          mosqueName: 'Masjid Raya',
          cityName: 'Bandung',
          latitude: -6.9175,
          longitude: 107.6191,
        ),
      ),
      act: (cubit) => cubit.goToNextStep(),
      expect: () => [
        const SetupWizardCompleting(
          SetupWizardData(
            mosqueName: 'Masjid Raya',
            cityName: 'Bandung',
            latitude: -6.9175,
            longitude: 107.6191,
          ),
        ),
        const SetupWizardCompleted(),
      ],
      verify: (_) {
        verify(() => settingsRepository.updateSettings(any())).called(1);
        verify(() => settingsRepository.completeFirstRun()).called(1);
      },
    );

    blocTest<SetupWizardCubit, SetupWizardState>(
      'goToNextStep at Step 3 emits Error if repository fails',
      build: () {
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenThrow(Exception('DB Error'));
        return cubit;
      },
      seed: () => const SetupWizardInProgress(
        currentStep: 3,
        data: SetupWizardData(
          mosqueName: 'Masjid Raya',
          cityName: 'Bandung',
          latitude: -6.9175,
          longitude: 107.6191,
        ),
      ),
      act: (cubit) => cubit.goToNextStep(),
      expect: () => [
        const SetupWizardCompleting(
          SetupWizardData(
            mosqueName: 'Masjid Raya',
            cityName: 'Bandung',
            latitude: -6.9175,
            longitude: 107.6191,
          ),
        ),
        const SetupWizardError(
          'Gagal menyimpan konfigurasi: Exception: DB Error',
        ),
      ],
    );
  });
}
