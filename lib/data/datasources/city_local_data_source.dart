import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';
import 'package:miqotul_khoir_tv/data/models/city_model.dart';

/// Data source yang berinteraksi langsung dengan SQLite untuk cities.
///
/// Berisi raw SQL operations untuk lookup table kota/kabupaten.
/// Digunakan oleh Setup Wizard city picker.
///
/// Ref: SPEC-01 §4.4, §9 (Edge Cases — search sanitization)
class CityLocalDataSource {
  final DatabaseHelper _databaseHelper;

  CityLocalDataSource(this._databaseHelper);

  /// Ambil semua province names (distinct, sorted alphabetically).
  Future<List<String>> getProvinces() async {
    final db = await _databaseHelper.database;
    final results = await db.rawQuery(
      'SELECT DISTINCT province_name FROM cities ORDER BY province_name ASC',
    );
    return results.map((row) => row['province_name'] as String).toList();
  }

  /// Ambil semua kota dalam satu provinsi, sorted by city name.
  Future<List<CityModel>> getCitiesByProvince(String provinceName) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'cities',
      where: 'province_name = ?',
      whereArgs: [provinceName],
      orderBy: 'city_name ASC',
    );
    return results.map(CityModel.fromMap).toList();
  }

  /// Search kota berdasarkan nama (case-insensitive LIKE query).
  ///
  /// Input di-sanitize: karakter `%` dan `_` dihapus
  /// agar tidak mengganggu LIKE pattern (SPEC-01 §9).
  Future<List<CityModel>> searchCities(String query) async {
    final db = await _databaseHelper.database;
    final sanitized = query.replaceAll('%', '').replaceAll('_', '');
    final results = await db.query(
      'cities',
      where: 'city_name LIKE ?',
      whereArgs: ['%$sanitized%'],
      orderBy: 'city_name ASC',
    );
    return results.map(CityModel.fromMap).toList();
  }

  /// Ambil satu kota berdasarkan ID.
  ///
  /// Return `null` jika tidak ditemukan.
  Future<CityModel?> getCityById(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query('cities', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return CityModel.fromMap(results.first);
  }
}
