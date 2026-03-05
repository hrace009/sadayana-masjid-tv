import 'package:equatable/equatable.dart';

/// Entity untuk menyimpan data sementara selama proses Setup Wizard.
///
/// Data ini hanya disimpan di memory dan baru di-persist ke database
/// (SettingsRepository) pada langkah terakhir (Preview -> Finish).
///
/// Ref: Plan 09 Phase 1
class SetupWizardData extends Equatable {
  final String mosqueName;
  final String mosqueAddress;
  final String cityName;
  final String provinceName;
  final double latitude;
  final double longitude;
  final String timezone;
  final String calculationMethod;
  final int elevation;

  const SetupWizardData({
    this.mosqueName = '',
    this.mosqueAddress = '',
    this.cityName = '',
    this.provinceName = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.timezone = 'Asia/Jakarta',
    this.calculationMethod = 'kemenag',
    this.elevation = 0,
  });

  /// Mengembalikan true jika data identitas masjid valid.
  /// Rule: Nama masjid minimal 3 karakter.
  bool get isIdentityValid => mosqueName.length >= 3;

  /// Mengembalikan true jika data lokasi valid.
  /// Rule: Kota harus dipilih (tidak kosong) dan koordinat valid (!= 0).
  bool get isLocationValid =>
      cityName.isNotEmpty && latitude != 0.0 && longitude != 0.0;

  /// Mengembalikan true jika seluruh data setup valid dan siap disimpan.
  bool get isComplete => isIdentityValid && isLocationValid;

  SetupWizardData copyWith({
    String? mosqueName,
    String? mosqueAddress,
    String? cityName,
    String? provinceName,
    double? latitude,
    double? longitude,
    String? timezone,
    String? calculationMethod,
    int? elevation,
  }) {
    return SetupWizardData(
      mosqueName: mosqueName ?? this.mosqueName,
      mosqueAddress: mosqueAddress ?? this.mosqueAddress,
      cityName: cityName ?? this.cityName,
      provinceName: provinceName ?? this.provinceName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      elevation: elevation ?? this.elevation,
    );
  }

  @override
  List<Object?> get props => [
    mosqueName,
    mosqueAddress,
    cityName,
    provinceName,
    latitude,
    longitude,
    timezone,
    calculationMethod,
    elevation,
  ];
}
