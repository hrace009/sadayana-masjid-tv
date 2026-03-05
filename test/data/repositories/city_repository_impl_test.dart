import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:miqotul_khoir_tv/data/datasources/city_local_data_source.dart';
import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';
import 'package:miqotul_khoir_tv/data/repositories/city_repository_impl.dart';

/// Unit tests untuk [CityRepositoryImpl].
///
/// Menggunakan in-memory SQLite database dengan seeded cities data.
///
/// Ref: Plan 02 TASK-026 s.d. TASK-030
void main() {
  late DatabaseHelper helper;
  late CityLocalDataSource dataSource;
  late CityRepositoryImpl repository;

  // ---------------------------------------------------------------------------
  // Seed data — insert test cities
  // ---------------------------------------------------------------------------

  Future<void> seedTestCities(Database db) async {
    final cities = [
      {
        'province_name': 'Jawa Barat',
        'city_name': 'Kota Bandung',
        'latitude': -6.9175,
        'longitude': 107.6191,
      },
      {
        'province_name': 'Jawa Barat',
        'city_name': 'Kabupaten Bandung',
        'latitude': -7.0225,
        'longitude': 107.5795,
      },
      {
        'province_name': 'Jawa Barat',
        'city_name': 'Kabupaten Bandung Barat',
        'latitude': -6.8417,
        'longitude': 107.4725,
      },
      {
        'province_name': 'Jawa Barat',
        'city_name': 'Kota Bogor',
        'latitude': -6.5950,
        'longitude': 106.8166,
      },
      {
        'province_name': 'Jawa Tengah',
        'city_name': 'Kota Semarang',
        'latitude': -6.9666,
        'longitude': 110.4196,
      },
      {
        'province_name': 'Jawa Tengah',
        'city_name': 'Kota Solo',
        'latitude': -7.5755,
        'longitude': 110.8243,
      },
      {
        'province_name': 'DKI Jakarta',
        'city_name': 'Jakarta Selatan',
        'latitude': -6.2615,
        'longitude': 106.8106,
      },
    ];

    final batch = db.batch();
    for (final city in cities) {
      batch.insert('cities', city);
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    helper = DatabaseHelper();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await helper.createTablesForTesting(db);
    await helper.insertDefaultSettingsForTesting(db);
    await seedTestCities(db);
    helper.initForTesting(db);

    dataSource = CityLocalDataSource(helper);
    repository = CityRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await helper.close();
    helper.resetForTesting();
  });

  // ---------------------------------------------------------------------------
  // TEST: getProvinces() returns distinct, alphabetically sorted provinces
  // ---------------------------------------------------------------------------

  test(
    'getProvinces() returns distinct, alphabetically sorted province names',
    () async {
      final provinces = await repository.getProvinces();

      expect(provinces, hasLength(3));
      expect(provinces[0], equals('DKI Jakarta'));
      expect(provinces[1], equals('Jawa Barat'));
      expect(provinces[2], equals('Jawa Tengah'));
    },
  );

  // ---------------------------------------------------------------------------
  // TEST: getCitiesByProvince() returns correct cities sorted alphabetically
  // ---------------------------------------------------------------------------

  test('getCitiesByProvince("Jawa Barat") returns correct cities sorted '
      'alphabetically', () async {
    final cities = await repository.getCitiesByProvince('Jawa Barat');

    expect(cities, hasLength(4));
    // Alphabetical order
    expect(cities[0].cityName, equals('Kabupaten Bandung'));
    expect(cities[1].cityName, equals('Kabupaten Bandung Barat'));
    expect(cities[2].cityName, equals('Kota Bandung'));
    expect(cities[3].cityName, equals('Kota Bogor'));

    // Verify all are in Jawa Barat
    for (final city in cities) {
      expect(city.provinceName, equals('Jawa Barat'));
    }
  });

  // ---------------------------------------------------------------------------
  // TEST: searchCities() performs case-insensitive search
  // ---------------------------------------------------------------------------

  test('searchCities("band") returns cities containing "band" '
      '(case-insensitive), including Bandung variants', () async {
    final cities = await repository.searchCities('band');

    expect(cities, hasLength(3));
    final cityNames = cities.map((c) => c.cityName).toList();
    expect(cityNames, contains('Kota Bandung'));
    expect(cityNames, contains('Kabupaten Bandung'));
    expect(cityNames, contains('Kabupaten Bandung Barat'));
  });

  // ---------------------------------------------------------------------------
  // TEST: getCityById() returns correct city or null
  // ---------------------------------------------------------------------------

  test(
    'getCityById() returns correct city for existing id, null for non-existing',
    () async {
      // Get a valid city first
      final cities = await repository.getCitiesByProvince('DKI Jakarta');
      expect(cities, hasLength(1));

      final validId = cities.first.id;
      final found = await repository.getCityById(validId);
      expect(found, isNotNull);
      expect(found!.cityName, equals('Jakarta Selatan'));

      // Non-existing ID
      final notFound = await repository.getCityById(99999);
      expect(notFound, isNull);
    },
  );
}
