import 'package:miqotul_khoir_tv/data/datasources/imam_local_data_source.dart';
import 'package:miqotul_khoir_tv/data/models/imam_model.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam.dart';
import 'package:miqotul_khoir_tv/domain/repositories/imam_repository.dart';

/// Implementasi konkret [ImamRepository] yang delegasi ke [ImamLocalDataSource].
///
/// Pure delegation pattern — tidak ada business logic di layer ini.
class ImamRepositoryImpl implements ImamRepository {
  final ImanLocalDataSource _localDataSource;

  ImamRepositoryImpl(this._localDataSource);

  @override
  Future<List<Imam>> getAll() async {
    return await _localDataSource.getAll();
  }

  @override
  Future<Imam?> getById(int id) async {
    return await _localDataSource.getById(id);
  }

  @override
  Future<int> insert(String name) async {
    return await _localDataSource.insert(name);
  }

  @override
  Future<void> update(Imam imam) async {
    return await _localDataSource.update(
      ImanModel(id: imam.id, name: imam.name, isActive: imam.isActive),
    );
  }

  @override
  Future<void> delete(int id) async {
    return await _localDataSource.delete(id);
  }

  @override
  Future<int> count() async {
    return await _localDataSource.count();
  }
}
