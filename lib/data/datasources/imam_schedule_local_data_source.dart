import 'package:sqflite/sqflite.dart';

import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';
import 'package:miqotul_khoir_tv/data/models/imam_schedule_model.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule_display.dart';

/// Data source yang berinteraksi langsung dengan SQLite untuk jadwal imam.
///
/// Berisi raw SQL operations untuk tabel `imam_schedules` termasuk LEFT JOIN
/// ke tabel `imams` untuk resolusi nama imam dan khatib.
///
/// TASK-014: Normalisasi aturan Jumat:
/// - hari Jumat (day_of_week=5): slot Dzuhur disimpan sebagai 'jumat'
/// - hari non-Jumat: tidak boleh ada entry dengan prayer_name='jumat'
/// - clearScheduleForDay(5) membersihkan 'dzuhur' dan 'jumat' untuk Jumat
class ImamScheduleLocalDataSource {
  final DatabaseHelper _databaseHelper;

  ImamScheduleLocalDataSource(this._databaseHelper);

  /// Ambil jadwal untuk [dayOfWeek] dalam bentuk resolved DTO.
  ///
  /// Selalu mengembalikan tepat 5 item (urutan: subuh, dzuhur/jumat, ashar,
  /// maghrib, isya) melalui LEFT JOIN ke tabel imams. Slot yang belum diisi
  /// memiliki `imamId == null` dan `imamName == null`.
  /// Pada hari Jumat, slot kedua menggunakan `prayerName = 'jumat'`.
  ///
  /// Jika belum ada satu pun row untuk hari target, mengembalikan list kosong
  /// (bukan list 5 slot kosong).
  Future<List<ImamScheduleDisplay>> getScheduleForDay(int dayOfWeek) async {
    final db = await _databaseHelper.database;

    // Check: ada row untuk hari ini?
    final checkResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM imam_schedules WHERE day_of_week = ?',
      [dayOfWeek],
    );
    final rowCount = (checkResult.first['count'] as int?) ?? 0;
    if (rowCount == 0) {
      return [];
    }

    // LEFT JOIN untuk resolve nama imam dan khatib
    final query = '''
      SELECT
        sch.id,
        sch.day_of_week,
        sch.prayer_name,
        sch.imam_id,
        COALESCE(imam.name, NULL) as imam_name,
        sch.khatib_id,
        COALESCE(khatib.name, NULL) as khatib_name
      FROM imam_schedules sch
      LEFT JOIN imams imam ON sch.imam_id = imam.id
      LEFT JOIN imams khatib ON sch.khatib_id = khatib.id
      WHERE sch.day_of_week = ?
      ORDER BY
        CASE sch.prayer_name
          WHEN 'subuh' THEN 1
          WHEN 'dzuhur' THEN 2
          WHEN 'jumat' THEN 2
          WHEN 'ashar' THEN 3
          WHEN 'maghrib' THEN 4
          WHEN 'isya' THEN 5
        END ASC
    ''';

    final results = await db.rawQuery(query, [dayOfWeek]);

    // Map hasil ke ImamScheduleDisplay dengan label
    return results.map((row) {
      final prayerName = row['prayer_name'] as String;
      final prayerLabel = _getPrayerLabel(prayerName);
      return ImamScheduleDisplay(
        dayOfWeek: dayOfWeek,
        prayerName: prayerName,
        prayerLabel: prayerLabel,
        imamId: row['imam_id'] as int?,
        imamName: row['imam_name'] as String?,
        khatibId: row['khatib_id'] as int?,
        khatibName: row['khatib_name'] as String?,
      );
    }).toList();
  }

  /// Ambil raw entity jadwal untuk [dayOfWeek] tanpa JOIN.
  ///
  /// Hanya mengembalikan baris yang benar-benar tersimpan di database.
  Future<List<ImamScheduleModel>> getRawScheduleForDay(int dayOfWeek) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'imam_schedules',
      where: 'day_of_week = ?',
      whereArgs: [dayOfWeek],
      orderBy: '''
        CASE prayer_name
          WHEN 'subuh' THEN 1
          WHEN 'dzuhur' THEN 2
          WHEN 'jumat' THEN 2
          WHEN 'ashar' THEN 3
          WHEN 'maghrib' THEN 4
          WHEN 'isya' THEN 5
        END ASC
      ''',
    );
    return results.map(ImamScheduleModel.fromMap).toList();
  }

  /// Menyimpan atau memperbarui satu slot jadwal (upsert).
  ///
  /// Operasi ini bersifat upsert: jika baris dengan kombinasi
  /// ([dayOfWeek], [prayerName]) sudah ada, baris tersebut diperbarui;
  /// jika belum ada, baris baru dibuat.
  ///
  /// NORMALISASI JUMAT (TASK-014):
  /// - Jika [dayOfWeek] == 5 (Jumat) dan [prayerName] == 'dzuhur',
  ///   ubah menjadi 'jumat' dan hapus entry 'dzuhur' lama jika ada.
  /// - Jika [dayOfWeek] != 5 dan [prayerName] == 'jumat', throw error.
  ///
  /// [imamId] null berarti slot imam dikosongkan.
  /// [khatibId] null berarti slot khatib dikosongkan.
  Future<void> setSchedule({
    required int dayOfWeek,
    required String prayerName,
    int? imamId,
    int? khatibId,
  }) async {
    final db = await _databaseHelper.database;

    // Validasi aturan Jumat
    if (dayOfWeek != 5 && prayerName == 'jumat') {
      throw Exception(
        'prayer_name "jumat" hanya boleh untuk hari Jumat (day_of_week=5)',
      );
    }

    String normalizedPrayerName = prayerName;

    // Normalisasi untuk Jumat
    if (dayOfWeek == 5 && prayerName == 'dzuhur') {
      normalizedPrayerName = 'jumat';

      // Hapus entry 'dzuhur' lama jika ada (untuk menjaga konsistensi)
      await db.delete(
        'imam_schedules',
        where: 'day_of_week = ? AND prayer_name = ?',
        whereArgs: [dayOfWeek, 'dzuhur'],
      );
    }

    // Upsert menggunakan ConflictAlgorithm.replace
    await db.insert('imam_schedules', {
      'day_of_week': dayOfWeek,
      'prayer_name': normalizedPrayerName,
      'imam_id': imamId,
      'khatib_id': khatibId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Menghapus semua entri jadwal untuk [dayOfWeek] tertentu.
  ///
  /// Untuk Jumat (day_of_week=5), menghapus kedua 'dzuhur' dan 'jumat'
  /// agar konsistensi terjaga.
  Future<void> clearScheduleForDay(int dayOfWeek) async {
    final db = await _databaseHelper.database;

    if (dayOfWeek == 5) {
      // Jumat: hapus dzuhur dan jumat
      await db.delete(
        'imam_schedules',
        where: 'day_of_week = ? AND prayer_name IN (?, ?)',
        whereArgs: [dayOfWeek, 'dzuhur', 'jumat'],
      );
    } else {
      // Hari biasa: hapus semua
      await db.delete(
        'imam_schedules',
        where: 'day_of_week = ?',
        whereArgs: [dayOfWeek],
      );
    }
  }

  /// Helper: konversi prayer_name ke label siap tampil.
  String _getPrayerLabel(String prayerName) {
    switch (prayerName) {
      case 'subuh':
        return 'Subuh';
      case 'dzuhur':
        return 'Dzuhur';
      case 'jumat':
        return 'Jumat';
      case 'ashar':
        return 'Ashar';
      case 'maghrib':
        return 'Maghrib';
      case 'isya':
        return 'Isya';
      default:
        return prayerName;
    }
  }
}
