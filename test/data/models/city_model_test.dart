import 'package:flutter_test/flutter_test.dart';

import 'package:miqotul_khoir_tv/data/models/city_model.dart';

/// Unit tests untuk [CityModel] — konversi fromMap/toMap.
///
/// Ref: Plan 02 TASK-018, TASK-019
void main() {
  // ---------------------------------------------------------------------------
  // Test Data
  // ---------------------------------------------------------------------------

  final Map<String, dynamic> cityMap = {
    'id': 42,
    'province_name': 'Jawa Barat',
    'city_name': 'Kota Bandung',
    'latitude': -6.9175,
    'longitude': 107.6191,
    'elevation': 698,
  };

  // ---------------------------------------------------------------------------
  // TEST: CityModel.fromMap() / toMap() round-trip
  // ---------------------------------------------------------------------------

  group('CityModel round-trip', () {
    test('fromMap() maps all fields correctly', () {
      final model = CityModel.fromMap(cityMap);

      expect(model.id, equals(42));
      expect(model.provinceName, equals('Jawa Barat'));
      expect(model.cityName, equals('Kota Bandung'));
      expect(model.latitude, closeTo(-6.9175, 0.0001));
      expect(model.longitude, closeTo(107.6191, 0.0001));
      expect(model.elevation, equals(698));
    });

    test('toMap() converts back correctly (without id)', () {
      final model = CityModel.fromMap(cityMap);
      final map = model.toMap();

      expect(map['province_name'], equals('Jawa Barat'));
      expect(map['city_name'], equals('Kota Bandung'));
      expect(map['latitude'], closeTo(-6.9175, 0.0001));
      expect(map['longitude'], closeTo(107.6191, 0.0001));
      expect(map['elevation'], equals(698));

      // toMap() should NOT include id (auto-increment)
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap → toMap → fromMap produces identical entity', () {
      final original = CityModel.fromMap(cityMap);
      final map = original.toMap();

      // Re-add id for reconstruction
      map['id'] = 42;

      final reconstructed = CityModel.fromMap(map);
      expect(reconstructed, equals(original));
    });
  });
}
