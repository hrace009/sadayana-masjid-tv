import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';
import 'package:miqotul_khoir_tv/data/models/settings_model.dart';

/// Data source yang berinteraksi langsung dengan SQLite untuk settings.
///
/// Berisi raw SQL operations. Tidak memiliki business logic —
/// itu tanggung jawab repository layer.
///
/// Ref: SPEC-01 §4.4, §9 (Edge Cases)
class SettingsLocalDataSource {
  final DatabaseHelper _databaseHelper;

  SettingsLocalDataSource(this._databaseHelper);

  /// Ambil settings row (singleton, id = 1).
  ///
  /// Selalu mengembalikan [SettingsModel] karena default row
  /// di-insert saat database dibuat (REQ-002).
  Future<SettingsModel> getSettings() async {
    final db = await _databaseHelper.database;
    final results = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    return SettingsModel.fromMap(results.first);
  }

  /// Update satu atau lebih field settings dalam transaction.
  ///
  /// [updates] berisi column name (snake_case) → value baru.
  /// Otomatis menambahkan `updated_at` timestamp (REQ-005).
  Future<void> updateSettings(Map<String, dynamic> updates) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await txn.update('settings', updates, where: 'id = ?', whereArgs: [1]);
    });
  }

  /// Tandai first run selesai (set `is_first_run = 0`).
  Future<void> completeFirstRun() async {
    await updateSettings({'is_first_run': 0});
  }

  /// Reset semua pengaturan ke default dan kembalikan state is_first_run = 1.
  Future<void> resetSettings() async {
    await _databaseHelper.resetSettings();
  }
}
