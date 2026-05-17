import 'package:miqotul_khoir_tv/domain/entities/imam_schedule.dart';

/// Data model yang mengkonversi antara [ImamSchedule] entity dan SQLite map.
///
/// Extends [ImamSchedule] sehingga bisa digunakan di mana pun [ImamSchedule] diterima
/// (Liskov Substitution Principle).
///
/// Mapping conventions:
/// - SQLite column names: `snake_case`
/// - Dart field names: `camelCase`
class ImamScheduleModel extends ImamSchedule {
  const ImamScheduleModel({
    required super.id,
    required super.dayOfWeek,
    required super.prayerName,
    super.imamId,
    super.khatibId,
  });

  /// Membuat [ImamScheduleModel] dari raw SQLite `Map<String, dynamic>`.
  factory ImamScheduleModel.fromMap(Map<String, dynamic> map) {
    return ImamScheduleModel(
      id: map['id'] as int,
      dayOfWeek: map['day_of_week'] as int,
      prayerName: map['prayer_name'] as String,
      imamId: map['imam_id'] as int?,
      khatibId: map['khatib_id'] as int?,
    );
  }

  /// Mengkonversi entity ke SQLite-compatible map.
  ///
  /// Tidak menyertakan `id` jika digunakan untuk insert (auto-increment),
  /// namun sertakan jika untuk update.
  Map<String, dynamic> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'day_of_week': dayOfWeek,
      'prayer_name': prayerName,
      'imam_id': imamId,
      'khatib_id': khatibId,
    };
  }

  /// Alias method untuk compatibility dengan existing patterns.
  ImamSchedule toEntity() => this;
}
