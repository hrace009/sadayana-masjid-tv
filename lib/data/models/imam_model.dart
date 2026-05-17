import 'package:miqotul_khoir_tv/domain/entities/imam.dart';

/// Data model yang mengkonversi antara [Imam] entity dan SQLite map.
///
/// Extends [Imam] sehingga bisa digunakan di mana pun [Imam] diterima
/// (Liskov Substitution Principle).
///
/// Mapping conventions:
/// - SQLite column names: `snake_case`
/// - Dart field names: `camelCase`
/// - Boolean: SQLite `INTEGER` (0/1) → Dart `bool`
class ImanModel extends Imam {
  const ImanModel({
    required super.id,
    required super.name,
    required super.isActive,
  });

  /// Membuat [ImanModel] dari raw SQLite `Map<String, dynamic>`.
  factory ImanModel.fromMap(Map<String, dynamic> map) {
    return ImanModel(
      id: map['id'] as int,
      name: map['name'] as String,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  /// Mengkonversi entity ke SQLite-compatible map.
  ///
  /// Tidak menyertakan `id` jika digunakan untuk insert (auto-increment),
  /// namun sertakan jika untuk update.
  Map<String, dynamic> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'name': name,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Alias method untuk compatibility dengan existing patterns.
  Imam toEntity() => this;
}
