import 'package:miqotul_khoir_tv/data/datasources/city_local_data_source.dart';
import 'package:miqotul_khoir_tv/domain/entities/city.dart';
import 'package:miqotul_khoir_tv/domain/repositories/city_repository.dart';

/// Implementasi konkret [CityRepository].
///
/// Pure delegation ke [CityLocalDataSource] — tidak ada business logic
/// tambahan di layer ini untuk cities.
///
/// Ref: SPEC-01 §4.3
class CityRepositoryImpl implements CityRepository {
  final CityLocalDataSource _dataSource;

  CityRepositoryImpl(this._dataSource);

  @override
  Future<List<String>> getProvinces() => _dataSource.getProvinces();

  @override
  Future<List<City>> getCitiesByProvince(String provinceName) =>
      _dataSource.getCitiesByProvince(provinceName);

  @override
  Future<List<City>> searchCities(String query) =>
      _dataSource.searchCities(query);

  @override
  Future<City?> getCityById(int id) => _dataSource.getCityById(id);
}
