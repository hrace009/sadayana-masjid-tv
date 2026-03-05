import 'package:miqotul_khoir_tv/domain/entities/city.dart';

/// Port: Abstract interface untuk akses data City.
///
/// Didefinisikan di domain layer agar tidak bergantung pada
/// implementation details (SQLite, SharedPreferences, dll).
///
/// Implementasi konkret: `CityRepositoryImpl` di `data/repositories/`.
///
/// Ref: SPEC-01 §4.3
abstract class CityRepository {
  /// Mengambil semua province names (distinct, sorted alphabetically).
  Future<List<String>> getProvinces();

  /// Mengambil semua kota dalam satu provinsi, sorted by city name.
  Future<List<City>> getCitiesByProvince(String provinceName);

  /// Search kota berdasarkan nama (case-insensitive, LIKE query).
  Future<List<City>> searchCities(String query);

  /// Mengambil satu kota berdasarkan ID.
  ///
  /// Return `null` jika tidak ditemukan.
  Future<City?> getCityById(int id);
}
