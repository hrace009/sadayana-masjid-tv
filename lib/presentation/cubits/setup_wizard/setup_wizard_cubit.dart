import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/city.dart';
import '../../../domain/entities/setup_wizard_data.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'setup_wizard_state.dart';

/// Cubit untuk mengelola state dan logic dari Setup Wizard.
///
/// Menangani:
/// - Navigasi antar step (Welcome -> Identity -> Location -> Preview)
/// - Validasi input di setiap step
/// - Penyimpanan data ke repository saat wizard selesai
class SetupWizardCubit extends Cubit<SetupWizardState> {
  final SettingsRepository settingsRepository;

  SetupWizardCubit(this.settingsRepository)
    : super(
        const SetupWizardInProgress(currentStep: 0, data: SetupWizardData()),
      );

  /// Pindah ke step berikutnya.
  /// Melakukan validasi sebelum pindah. Jika validasi gagal, emit error.
  /// Jika di step terakhir, panggil [_completeSetup].
  void goToNextStep() {
    final currentState = state;
    if (currentState is! SetupWizardInProgress) return;

    // Validate current step logic
    if (!_validateCurrentStep(currentState)) {
      String errorMsg = 'Data belum lengkap';
      if (currentState.currentStep == 1) {
        errorMsg = 'Nama masjid minimal 3 karakter';
      } else if (currentState.currentStep == 2) {
        errorMsg = 'Silakan pilih kota terlebih dahulu';
      }

      emit(currentState.copyWith(validationError: errorMsg));
      return;
    }

    // Jika step terakhir (Preview = 3), complete setup
    if (currentState.currentStep >= 3) {
      completeSetup();
    } else {
      // Pindah ke step berikutnya, clear error
      emit(
        currentState.copyWith(
          currentStep: currentState.currentStep + 1,
          validationError:
              null, // Clear previous error logic handled by copyWith
        ),
      );
    }
  }

  /// Pindah ke step sebelumnya.
  void goToPreviousStep() {
    final currentState = state;
    if (currentState is! SetupWizardInProgress) return;

    if (currentState.canGoBack) {
      emit(
        currentState.copyWith(
          currentStep: currentState.currentStep - 1,
          validationError: null,
        ),
      );
    }
  }

  /// Update nama masjid (Step 1).
  void updateMosqueName(String name) {
    final currentState = state;
    if (currentState is! SetupWizardInProgress) return;

    final newData = currentState.data.copyWith(mosqueName: name);
    emit(currentState.copyWith(data: newData, validationError: null));
  }

  /// Update alamat masjid (Step 1).
  void updateMosqueAddress(String address) {
    final currentState = state;
    if (currentState is! SetupWizardInProgress) return;

    final newData = currentState.data.copyWith(mosqueAddress: address);
    emit(currentState.copyWith(data: newData));
  }

  /// Pilih kota (Step 2).
  void selectCity(City city) {
    final currentState = state;
    if (currentState is! SetupWizardInProgress) return;

    final newData = currentState.data.copyWith(
      cityName: city.cityName,
      provinceName: city.provinceName,
      latitude: city.latitude,
      longitude: city.longitude,
      elevation: city.elevation,
    );
    emit(currentState.copyWith(data: newData, validationError: null));
  }

  /// Internal: Validasi step sebelum lanjut.
  bool _validateCurrentStep(SetupWizardInProgress state) {
    switch (state.currentStep) {
      case 0: // Welcome
        return true;
      case 1: // Identity
        return state.data.isIdentityValid;
      case 2: // Location
        return state.data.isLocationValid;
      case 3: // Preview
        return state.data.isComplete;
      default:
        return false;
    }
  }

  /// Finalisasi setup: simpan data dan tandai first run selesai.
  Future<void> completeSetup() async {
    final currentState = state;
    if (currentState is! SetupWizardInProgress) return;
    final data = currentState.data;

    emit(SetupWizardCompleting(data));

    try {
      // 1. Update settings data
      final updates = {
        'mosque_name': data.mosqueName,
        'mosque_address': data.mosqueAddress,
        'city_name': data.cityName,
        'province_name': data.provinceName,
        'latitude': data.latitude,
        'longitude': data.longitude,
        'timezone': data.timezone,
        'calculation_method': data.calculationMethod,
        'elevation': data.elevation,
      };

      await settingsRepository.updateSettings(updates);

      await settingsRepository.completeFirstRun();

      if (isClosed) return;
      emit(SetupWizardCompleted());
    } catch (e) {
      if (isClosed) return;
      emit(SetupWizardError('Gagal menyimpan konfigurasi: $e'));
    }
  }
}
