import 'package:miqotul_khoir_tv/domain/entities/settings.dart';

/// Port: Abstract interface untuk akses data Settings.
///
/// Didefinisikan di domain layer agar tidak bergantung pada
/// implementation details (SQLite, SharedPreferences, dll).
///
/// Implementasi konkret: `SettingsRepositoryImpl` di `data/repositories/`.
///
/// Ref: SPEC-01 §4.3
abstract class SettingsRepository {
  /// Mengambil settings saat ini (selalu 1 row, id = 1).
  Future<Settings> getSettings();

  /// Update satu atau lebih field settings.
  ///
  /// [updates] adalah Map dari column name (snake_case) ke value baru.
  /// Hanya field yang ada di map yang akan di-update.
  Future<void> updateSettings(Map<String, dynamic> updates);

  /// Cek apakah ini first run (belum melewati Setup Wizard).
  Future<bool> isFirstRun();

  /// Tandai first run selesai (set `is_first_run = 0`).
  Future<void> completeFirstRun();

  /// Reset semua pengaturan ke default dan kembalikan state is_first_run = 1.
  Future<void> resetSettings();

  /// Verify PIN input.
  ///
  /// Return `true` jika:
  /// - PIN disabled (hash kosong), atau
  /// - Hash dari [inputPin] cocok dengan hash yang tersimpan.
  Future<bool> verifyPin(String inputPin);

  /// Set atau update PIN proteksi.
  ///
  /// [newPin] kosong = disable PIN protection.
  Future<void> setPin(String newPin);
}
