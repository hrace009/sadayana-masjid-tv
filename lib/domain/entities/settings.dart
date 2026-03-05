import 'package:equatable/equatable.dart';

/// Domain entity yang merepresentasikan konfigurasi aplikasi.
///
/// Immutable class dengan value equality via [Equatable].
/// Setiap instance merepresentasikan snapshot konfigurasi
/// dari singleton row di table `settings`.
///
/// Ref: SPEC-01 §4.2
class Settings extends Equatable {
  final bool isFirstRun;

  // Identity
  final String mosqueName;
  final String mosqueAddress;

  // Location
  final String cityName;
  final String provinceName;
  final double latitude;
  final double longitude;
  final String timezone;

  // Calculation
  final String calculationMethod;

  // Time Corrections / Ihtiyat (minutes)
  final int offsetSubuh;
  final int offsetSyuruq;
  final int offsetDhuha;
  final int offsetDzuhur;
  final int offsetAshar;
  final int offsetMaghrib;
  final int offsetIsya;

  // Dhuha offset from Syuruq (minutes)
  final int dhuhaOffsetMinutes;

  // Hijri Date Adjustment (days)
  final int hijriAdjustment;

  // Iqomah Delays (minutes)
  final int iqomahSubuh;
  final int iqomahDzuhur;
  final int iqomahAshar;
  final int iqomahMaghrib;
  final int iqomahIsya;

  // Iqomah Jum'at (minutes) — berlaku khusus hari Jumat, setelah khutbah
  final int iqomahJumat;

  // Timing
  final int preAdzanMinutes;
  final int sholatDurationMinutes;

  /// Durasi layar mati khusus hari Jum'at (menit). Mencakup khutbah + sholat 2 rakaat.
  final int sholatJumatDurationMinutes;
  final int adzanDurationSeconds;

  // Display
  final String runningText;

  // PIN
  final String settingsPinHash;

  /// Ketinggian tempat di atas permukaan laut (meter).
  /// Digunakan untuk koreksi waktu Maghrib/Syuruq.
  final int elevation;

  // Informasi Kas Masjid (fitur opsional, default OFF)
  final bool isTreasuryEnabled;
  final int treasuryBalance;
  final int treasuryIncome;
  final int treasuryExpense;

  const Settings({
    this.isFirstRun = true,
    this.mosqueName = '',
    this.mosqueAddress = '',
    this.cityName = '',
    this.provinceName = '',
    this.latitude = -6.9175,
    this.longitude = 107.6191,
    this.timezone = 'Asia/Jakarta',
    this.elevation = 0,
    this.calculationMethod = 'kemenag',
    this.offsetSubuh = 0,
    this.offsetSyuruq = 0,
    this.offsetDhuha = 0,
    this.offsetDzuhur = 0,
    this.offsetAshar = 0,
    this.offsetMaghrib = 0,
    this.offsetIsya = 0,
    this.dhuhaOffsetMinutes = 20,
    this.hijriAdjustment = 0,
    this.iqomahSubuh = 10,
    this.iqomahDzuhur = 10,
    this.iqomahAshar = 10,
    this.iqomahMaghrib = 7,
    this.iqomahIsya = 10,
    this.iqomahJumat = 10,
    this.preAdzanMinutes = 10,
    this.sholatDurationMinutes = 15,
    this.sholatJumatDurationMinutes = 45,
    this.adzanDurationSeconds = 180,
    this.runningText = 'Selamat datang di masjid kami',
    this.settingsPinHash = '',
    this.isTreasuryEnabled = false,
    this.treasuryBalance = 0,
    this.treasuryIncome = 0,
    this.treasuryExpense = 0,
  });

  /// Membuat salinan [Settings] dengan field tertentu di-override.
  Settings copyWith({
    bool? isFirstRun,
    String? mosqueName,
    String? mosqueAddress,
    String? cityName,
    String? provinceName,
    double? latitude,
    double? longitude,
    String? timezone,
    String? calculationMethod,
    int? offsetSubuh,
    int? offsetSyuruq,
    int? offsetDhuha,
    int? offsetDzuhur,
    int? offsetAshar,
    int? offsetMaghrib,
    int? offsetIsya,
    int? dhuhaOffsetMinutes,
    int? hijriAdjustment,
    int? iqomahSubuh,
    int? iqomahDzuhur,
    int? iqomahAshar,
    int? iqomahMaghrib,
    int? iqomahIsya,
    int? iqomahJumat,
    int? preAdzanMinutes,
    int? sholatDurationMinutes,
    int? sholatJumatDurationMinutes,
    int? adzanDurationSeconds,
    String? runningText,
    String? settingsPinHash,
    int? elevation,
    bool? isTreasuryEnabled,
    int? treasuryBalance,
    int? treasuryIncome,
    int? treasuryExpense,
  }) {
    return Settings(
      isFirstRun: isFirstRun ?? this.isFirstRun,
      mosqueName: mosqueName ?? this.mosqueName,
      mosqueAddress: mosqueAddress ?? this.mosqueAddress,
      cityName: cityName ?? this.cityName,
      provinceName: provinceName ?? this.provinceName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      offsetSubuh: offsetSubuh ?? this.offsetSubuh,
      offsetSyuruq: offsetSyuruq ?? this.offsetSyuruq,
      offsetDhuha: offsetDhuha ?? this.offsetDhuha,
      offsetDzuhur: offsetDzuhur ?? this.offsetDzuhur,
      offsetAshar: offsetAshar ?? this.offsetAshar,
      offsetMaghrib: offsetMaghrib ?? this.offsetMaghrib,
      offsetIsya: offsetIsya ?? this.offsetIsya,
      dhuhaOffsetMinutes: dhuhaOffsetMinutes ?? this.dhuhaOffsetMinutes,
      hijriAdjustment: hijriAdjustment ?? this.hijriAdjustment,
      iqomahSubuh: iqomahSubuh ?? this.iqomahSubuh,
      iqomahDzuhur: iqomahDzuhur ?? this.iqomahDzuhur,
      iqomahAshar: iqomahAshar ?? this.iqomahAshar,
      iqomahMaghrib: iqomahMaghrib ?? this.iqomahMaghrib,
      iqomahIsya: iqomahIsya ?? this.iqomahIsya,
      iqomahJumat: iqomahJumat ?? this.iqomahJumat,
      preAdzanMinutes: preAdzanMinutes ?? this.preAdzanMinutes,
      sholatDurationMinutes:
          sholatDurationMinutes ?? this.sholatDurationMinutes,
      sholatJumatDurationMinutes:
          sholatJumatDurationMinutes ?? this.sholatJumatDurationMinutes,
      adzanDurationSeconds: adzanDurationSeconds ?? this.adzanDurationSeconds,
      runningText: runningText ?? this.runningText,
      settingsPinHash: settingsPinHash ?? this.settingsPinHash,
      elevation: elevation ?? this.elevation,
      isTreasuryEnabled: isTreasuryEnabled ?? this.isTreasuryEnabled,
      treasuryBalance: treasuryBalance ?? this.treasuryBalance,
      treasuryIncome: treasuryIncome ?? this.treasuryIncome,
      treasuryExpense: treasuryExpense ?? this.treasuryExpense,
    );
  }

  @override
  List<Object?> get props => [
    isFirstRun,
    mosqueName,
    mosqueAddress,
    cityName,
    provinceName,
    latitude,
    longitude,
    timezone,
    calculationMethod,
    offsetSubuh,
    offsetSyuruq,
    offsetDhuha,
    offsetDzuhur,
    offsetAshar,
    offsetMaghrib,
    offsetIsya,
    dhuhaOffsetMinutes,
    hijriAdjustment,
    iqomahSubuh,
    iqomahDzuhur,
    iqomahAshar,
    iqomahMaghrib,
    iqomahIsya,
    iqomahJumat,
    preAdzanMinutes,
    sholatDurationMinutes,
    sholatJumatDurationMinutes,
    adzanDurationSeconds,
    runningText,
    settingsPinHash,
    elevation,
    isTreasuryEnabled,
    treasuryBalance,
    treasuryIncome,
    treasuryExpense,
  ];
}
