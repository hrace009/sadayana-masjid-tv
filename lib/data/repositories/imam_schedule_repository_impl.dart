import 'package:miqotul_khoir_tv/data/datasources/imam_schedule_local_data_source.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule_display.dart';
import 'package:miqotul_khoir_tv/domain/repositories/imam_schedule_repository.dart';

/// Implementasi konkret [ImamScheduleRepository] yang delegasi ke [ImamScheduleLocalDataSource].
///
/// Pure delegation pattern — tidak ada business logic di layer ini.
class ImamScheduleRepositoryImpl implements ImamScheduleRepository {
  final ImamScheduleLocalDataSource _localDataSource;

  ImamScheduleRepositoryImpl(this._localDataSource);

  @override
  Future<List<ImamScheduleDisplay>> getScheduleForDay(int dayOfWeek) async {
    return await _localDataSource.getScheduleForDay(dayOfWeek);
  }

  @override
  Future<List<ImamSchedule>> getRawScheduleForDay(int dayOfWeek) async {
    return await _localDataSource.getRawScheduleForDay(dayOfWeek);
  }

  @override
  Future<void> setSchedule({
    required int dayOfWeek,
    required String prayerName,
    int? imamId,
    int? khatibId,
  }) async {
    return await _localDataSource.setSchedule(
      dayOfWeek: dayOfWeek,
      prayerName: prayerName,
      imamId: imamId,
      khatibId: khatibId,
    );
  }

  @override
  Future<void> clearScheduleForDay(int dayOfWeek) async {
    return await _localDataSource.clearScheduleForDay(dayOfWeek);
  }
}
