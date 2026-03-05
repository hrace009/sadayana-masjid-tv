import 'package:miqotul_khoir_tv/domain/entities/city.dart';

/// Data model yang mengkonversi antara [City] entity dan SQLite map.
///
/// Extends [City] sehingga bisa digunakan di mana pun [City] diterima
/// (Liskov Substitution Principle).
///
/// Ref: SPEC-01 §4.4
class CityModel extends City {
  const CityModel({
    required super.id,
    required super.provinceName,
    required super.cityName,
    required super.latitude,
    required super.longitude,
    super.elevation,
  });

  /// Membuat [CityModel] dari raw SQLite `Map<String, dynamic>`.
  factory CityModel.fromMap(Map<String, dynamic> map) {
    return CityModel(
      id: map['id'] as int,
      provinceName: map['province_name'] as String,
      cityName: map['city_name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      elevation: (map['elevation'] as num?)?.toInt() ?? 0,
    );
  }

  /// Mengkonversi entity ke SQLite-compatible map.
  ///
  /// Tidak menyertakan `id` karena auto-increment dikelola database.
  Map<String, dynamic> toMap() {
    return {
      'province_name': provinceName,
      'city_name': cityName,
      'latitude': latitude,
      'longitude': longitude,
      'elevation': elevation,
    };
  }
}
