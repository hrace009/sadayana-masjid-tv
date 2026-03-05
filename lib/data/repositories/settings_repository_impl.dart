import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:miqotul_khoir_tv/data/datasources/settings_local_data_source.dart';
import 'package:miqotul_khoir_tv/domain/entities/settings.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';

/// Implementasi konkret [SettingsRepository].
///
/// Menghubungkan domain port dengan [SettingsLocalDataSource].
/// Menangani business logic PIN hashing (SHA-256) di layer ini.
///
/// Ref: SPEC-01 §4.3, SEC-002
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _dataSource;

  SettingsRepositoryImpl(this._dataSource);

  @override
  Future<Settings> getSettings() => _dataSource.getSettings();

  @override
  Future<void> updateSettings(Map<String, dynamic> updates) =>
      _dataSource.updateSettings(updates);

  @override
  Future<bool> isFirstRun() async {
    final settings = await _dataSource.getSettings();
    return settings.isFirstRun;
  }

  @override
  Future<void> completeFirstRun() => _dataSource.completeFirstRun();

  @override
  Future<void> resetSettings() => _dataSource.resetSettings();

  @override
  Future<bool> verifyPin(String inputPin) async {
    final settings = await _dataSource.getSettings();
    final storedHash = settings.settingsPinHash;

    // PIN disabled — langsung return true
    if (storedHash.isEmpty) return true;

    // Hash input dan compare
    final inputHash = _hashPin(inputPin);
    return inputHash == storedHash;
  }

  @override
  Future<void> setPin(String newPin) async {
    final hash = newPin.isEmpty ? '' : _hashPin(newPin);
    await _dataSource.updateSettings({'settings_pin_hash': hash});
  }

  /// Hash PIN menggunakan SHA-256.
  ///
  /// Acceptable untuk PIN 6 digit pada aplikasi offline-only
  /// tanpa network attack vector (RISK-002 di plan).
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
