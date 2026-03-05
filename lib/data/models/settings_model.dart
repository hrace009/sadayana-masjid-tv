import 'package:miqotul_khoir_tv/domain/entities/settings.dart';

/// Data model yang mengkonversi antara [Settings] entity dan SQLite map.
///
/// Extends [Settings] sehingga bisa digunakan di mana pun [Settings] diterima
/// (Liskov Substitution Principle).
///
/// Mapping conventions:
/// - SQLite column names: `snake_case`
/// - Dart field names: `camelCase`
/// - Boolean: SQLite `INTEGER` (0/1) → Dart `bool`
///
/// Ref: SPEC-01 §4.4
class SettingsModel extends Settings {
  const SettingsModel({
    super.isFirstRun,
    super.mosqueName,
    super.mosqueAddress,
    super.cityName,
    super.provinceName,
    super.latitude,
    super.longitude,
    super.timezone,
    super.calculationMethod,
    super.offsetSubuh,
    super.offsetSyuruq,
    super.offsetDhuha,
    super.offsetDzuhur,
    super.offsetAshar,
    super.offsetMaghrib,
    super.offsetIsya,
    super.dhuhaOffsetMinutes,
    super.hijriAdjustment,
    super.iqomahSubuh,
    super.iqomahDzuhur,
    super.iqomahAshar,
    super.iqomahMaghrib,
    super.iqomahIsya,
    super.iqomahJumat,
    super.preAdzanMinutes,
    super.sholatDurationMinutes,
    super.sholatJumatDurationMinutes,
    super.adzanDurationSeconds,
    super.runningText,
    super.settingsPinHash,
    super.elevation,
    super.isTreasuryEnabled,
    super.treasuryBalance,
    super.treasuryIncome,
    super.treasuryExpense,
  });

  /// Membuat [SettingsModel] dari raw SQLite `Map<String, dynamic>`.
  ///
  /// Melakukan konversi:
  /// - `is_first_run` (int 0/1) → `isFirstRun` (bool)
  /// - Semua snake_case keys → camelCase fields
  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      isFirstRun: (map['is_first_run'] as int) == 1,
      mosqueName: map['mosque_name'] as String,
      mosqueAddress: map['mosque_address'] as String,
      cityName: map['city_name'] as String,
      provinceName: map['province_name'] as String? ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timezone: map['timezone'] as String,
      calculationMethod: map['calculation_method'] as String,
      offsetSubuh: map['offset_subuh'] as int,
      offsetSyuruq: map['offset_syuruq'] as int,
      offsetDhuha: map['offset_dhuha'] as int,
      offsetDzuhur: map['offset_dzuhur'] as int,
      offsetAshar: map['offset_ashar'] as int,
      offsetMaghrib: map['offset_maghrib'] as int,
      offsetIsya: map['offset_isya'] as int,
      dhuhaOffsetMinutes: map['dhuha_offset_minutes'] as int,
      hijriAdjustment: map['hijri_adjustment'] as int,
      iqomahSubuh: map['iqomah_subuh'] as int,
      iqomahDzuhur: map['iqomah_dzuhur'] as int,
      iqomahAshar: map['iqomah_ashar'] as int,
      iqomahMaghrib: map['iqomah_maghrib'] as int,
      iqomahIsya: map['iqomah_isya'] as int,
      iqomahJumat: map['iqomah_jumat'] as int,
      preAdzanMinutes: map['pre_adzan_minutes'] as int,
      sholatDurationMinutes: map['sholat_duration_minutes'] as int,
      sholatJumatDurationMinutes: map['sholat_jumat_duration_minutes'] as int,
      adzanDurationSeconds: map['adzan_duration_seconds'] as int,
      runningText: map['running_text'] as String,
      settingsPinHash: map['settings_pin_hash'] as String,
      elevation: (map['elevation'] as int?) ?? 0,
      isTreasuryEnabled: (map['is_treasury_enabled'] as int? ?? 0) == 1,
      treasuryBalance: map['treasury_balance'] as int? ?? 0,
      treasuryIncome: map['treasury_income'] as int? ?? 0,
      treasuryExpense: map['treasury_expense'] as int? ?? 0,
    );
  }

  /// Mengkonversi entity ke SQLite-compatible map.
  ///
  /// Output menggunakan snake_case keys sesuai column names di database.
  /// Boolean `isFirstRun` → int (0/1).
  /// Tidak menyertakan `id`, `created_at`, `updated_at` karena
  /// dikelola oleh database.
  Map<String, dynamic> toMap() {
    return {
      'is_first_run': isFirstRun ? 1 : 0,
      'mosque_name': mosqueName,
      'mosque_address': mosqueAddress,
      'city_name': cityName,
      'province_name': provinceName,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'calculation_method': calculationMethod,
      'offset_subuh': offsetSubuh,
      'offset_syuruq': offsetSyuruq,
      'offset_dhuha': offsetDhuha,
      'offset_dzuhur': offsetDzuhur,
      'offset_ashar': offsetAshar,
      'offset_maghrib': offsetMaghrib,
      'offset_isya': offsetIsya,
      'dhuha_offset_minutes': dhuhaOffsetMinutes,
      'hijri_adjustment': hijriAdjustment,
      'iqomah_subuh': iqomahSubuh,
      'iqomah_dzuhur': iqomahDzuhur,
      'iqomah_ashar': iqomahAshar,
      'iqomah_maghrib': iqomahMaghrib,
      'iqomah_isya': iqomahIsya,
      'iqomah_jumat': iqomahJumat,
      'pre_adzan_minutes': preAdzanMinutes,
      'sholat_duration_minutes': sholatDurationMinutes,
      'sholat_jumat_duration_minutes': sholatJumatDurationMinutes,
      'adzan_duration_seconds': adzanDurationSeconds,
      'running_text': runningText,
      'settings_pin_hash': settingsPinHash,
      'elevation': elevation,
      'is_treasury_enabled': isTreasuryEnabled ? 1 : 0,
      'treasury_balance': treasuryBalance,
      'treasury_income': treasuryIncome,
      'treasury_expense': treasuryExpense,
    };
  }
}
