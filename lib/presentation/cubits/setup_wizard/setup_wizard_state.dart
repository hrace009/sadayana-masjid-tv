import 'package:equatable/equatable.dart';
import '../../../domain/entities/setup_wizard_data.dart';

/// Base state untuk [SetupWizardCubit].
abstract class SetupWizardState extends Equatable {
  const SetupWizardState();

  @override
  List<Object?> get props => [];
}

/// State saat user sedang berada di tengah proses wizard.
///
/// Menyimpan data sementara, step saat ini, dan status validasi.
class SetupWizardInProgress extends SetupWizardState {
  final int currentStep;
  final SetupWizardData data;
  final int totalSteps;
  final String? validationError;

  const SetupWizardInProgress({
    required this.currentStep,
    required this.data,
    this.totalSteps = 4,
    this.validationError,
  });

  /// Mengembalikan true jika current step valid untuk lanjut.
  /// Step 0 (Welcome): always true.
  /// Step 1 (Identity): data.isIdentityValid.
  /// Step 2 (Location): data.isLocationValid.
  /// Step 3 (Preview): data.isComplete.
  bool get canGoNext {
    switch (currentStep) {
      case 0: // Welcome
        return true;
      case 1: // Identity
        return data.isIdentityValid;
      case 2: // Location
        return data.isLocationValid;
      case 3: // Preview
        return data.isComplete;
      default:
        return false;
    }
  }

  /// Mengembalikan true jika bisa kembali ke step sebelumnya.
  /// Step 0 tidak bisa back (harus exit app jika back).
  bool get canGoBack => currentStep > 0;

  /// Progress bar value (0.0 - 1.0).
  /// Menggunakan (currentStep + 1) agar user merasa ada progress.
  double get progress => (currentStep + 1) / totalSteps;

  SetupWizardInProgress copyWith({
    int? currentStep,
    SetupWizardData? data,
    String? validationError,
  }) {
    return SetupWizardInProgress(
      currentStep: currentStep ?? this.currentStep,
      data: data ?? this.data,
      totalSteps: totalSteps,
      validationError: validationError, // Nullable, allow clearing error
    );
  }

  @override
  List<Object?> get props => [currentStep, data, totalSteps, validationError];
}

/// State saat wizard sedang menyimpan data ke database (loading).
class SetupWizardCompleting extends SetupWizardState {
  final SetupWizardData data;
  const SetupWizardCompleting(this.data);

  @override
  List<Object?> get props => [data];
}

/// State saat wizard telah selesai dan berhasil menyimpan data.
/// UI harus navigate ke Home/Main page.
class SetupWizardCompleted extends SetupWizardState {
  const SetupWizardCompleted();
}

/// State jika terjadi error saat proses simpan data.
class SetupWizardError extends SetupWizardState {
  final String message;

  const SetupWizardError(this.message);

  @override
  List<Object?> get props => [message];
}
