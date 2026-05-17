import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:miqotul_khoir_tv/data/datasources/database_helper.dart';

/// Unit tests untuk [DatabaseHelper].
///
/// Menggunakan [sqflite_common_ffi] dengan [inMemoryDatabasePath] agar:
/// - Tidak ada file I/O ke disk
/// - Setiap test mendapat fresh database (isolated)
/// - Bisa berjalan di desktop/CI tanpa Android device
///
/// Ref: SPEC-01 §6 — Test Automation Strategy
void main() {
  // ---------------------------------------------------------------------------
  // Setup: Inisialisasi sqflite FFI untuk in-memory testing
  // ---------------------------------------------------------------------------

  setUpAll(() {
    // Inisialisasi sqflite FFI implementation.
    // Wajib dipanggil sekali sebelum semua test.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // ---------------------------------------------------------------------------
  // Helper: Buat in-memory database dengan schema lengkap
  // ---------------------------------------------------------------------------

  /// Membuat fresh in-memory database dengan schema dan default settings.
  ///
  /// Tidak menjalankan [_seedCities] karena memerlukan [rootBundle]
  /// yang tidak tersedia di unit test environment.
  Future<Database> createTestDatabase() async {
    final helper = DatabaseHelper();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await helper.createTablesForTesting(db);
    await helper.insertDefaultSettingsForTesting(db);
    helper.initForTesting(db);
    return db;
  }

  // ---------------------------------------------------------------------------
  // Teardown: Reset singleton state setelah setiap test
  // ---------------------------------------------------------------------------

  tearDown(() async {
    final helper = DatabaseHelper();
    await helper.close();
    helper.resetForTesting();
  });

  // ---------------------------------------------------------------------------
  // TEST-001: settings table dibuat dengan benar
  // ---------------------------------------------------------------------------

  test(
    'TEST-001: DatabaseHelper creates settings table on first init',
    () async {
      final db = await createTestDatabase();

      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='settings'",
      );

      expect(result, hasLength(1));
      expect(result.first['name'], equals('settings'));
    },
  );

  // ---------------------------------------------------------------------------
  // TEST-002: cities table dibuat dengan benar
  // ---------------------------------------------------------------------------

  test('TEST-002: DatabaseHelper creates cities table on first init', () async {
    final db = await createTestDatabase();

    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='cities'",
    );

    expect(result, hasLength(1));
    expect(result.first['name'], equals('cities'));
  });

  // ---------------------------------------------------------------------------
  // TEST-003: Default settings row di-insert dengan benar
  // ---------------------------------------------------------------------------

  test('TEST-003: Default settings row is inserted with is_first_run = 1 '
      'and all default values populated', () async {
    await createTestDatabase();

    final helper = DatabaseHelper();
    final db = await helper.database;
    final rows = await db.query('settings');

    // Harus ada tepat 1 row (singleton pattern)
    expect(rows, hasLength(1));

    final row = rows.first;

    // Verifikasi primary key dan first run flag
    expect(row['id'], equals(1));
    expect(row['is_first_run'], equals(1));

    // Verifikasi identity defaults
    expect(row['mosque_name'], equals(''));
    expect(row['mosque_address'], equals(''));

    // Verifikasi location defaults (Bandung)
    expect(row['city_name'], equals(''));
    expect(row['latitude'], closeTo(-6.9175, 0.0001));
    expect(row['longitude'], closeTo(107.6191, 0.0001));
    expect(row['timezone'], equals('Asia/Jakarta'));

    // Verifikasi calculation method default (Kemenag SIHAT)
    expect(row['calculation_method'], equals('kemenag'));

    // Verifikasi elevation default (sea level)
    expect(row['elevation'], equals(0));

    // Verifikasi ihtiyat offsets (semua 0)
    expect(row['offset_subuh'], equals(0));
    expect(row['offset_syuruq'], equals(0));
    expect(row['offset_dhuha'], equals(0));
    expect(row['offset_dzuhur'], equals(0));
    expect(row['offset_ashar'], equals(0));
    expect(row['offset_maghrib'], equals(0));
    expect(row['offset_isya'], equals(0));

    // Verifikasi dhuha offset
    expect(row['dhuha_offset_minutes'], equals(20));

    // Verifikasi hijri adjustment
    expect(row['hijri_adjustment'], equals(0));

    // Verifikasi iqomah delays
    expect(row['iqomah_subuh'], equals(10));
    expect(row['iqomah_dzuhur'], equals(10));
    expect(row['iqomah_ashar'], equals(10));
    expect(row['iqomah_maghrib'], equals(7));
    expect(row['iqomah_isya'], equals(10));

    // Verifikasi timing fields
    expect(row['pre_adzan_minutes'], equals(10));
    expect(row['sholat_duration_minutes'], equals(15));
    expect(row['adzan_duration_seconds'], equals(180));

    // Verifikasi display
    expect(row['running_text'], equals('Selamat datang di masjid kami'));

    // Verifikasi PIN (disabled by default)
    expect(row['settings_pin_hash'], equals(''));
  });

  // ---------------------------------------------------------------------------
  // TEST-004: cities table memiliki indexes yang benar
  // ---------------------------------------------------------------------------

  test(
    'TEST-004: cities table has idx_cities_province and idx_cities_name indexes',
    () async {
      final db = await createTestDatabase();

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='cities'",
      );

      final indexNames = indexes.map((r) => r['name'] as String).toSet();

      expect(indexNames, contains('idx_cities_province'));
      expect(indexNames, contains('idx_cities_name'));
    },
  );

  // ---------------------------------------------------------------------------
  // TEST-005: settings table enforces singleton constraint (CHECK id = 1)
  // ---------------------------------------------------------------------------

  test('TEST-005: settings table enforces singleton constraint — '
      'inserting row with id = 2 throws DatabaseException', () async {
    final db = await createTestDatabase();

    // Insert row dengan id = 2 harus gagal karena CHECK (id = 1)
    expect(
      () async => db.insert('settings', {'id': 2}),
      throwsA(isA<DatabaseException>()),
    );
  });

  // ---------------------------------------------------------------------------
  // TEST-006: cities table menerima data dengan benar
  // ---------------------------------------------------------------------------

  test(
    'TEST-006: cities table accepts valid city data and retrieves correctly',
    () async {
      final db = await createTestDatabase();

      // Insert sample city
      await db.insert('cities', {
        'province_name': 'Jawa Barat',
        'city_name': 'Kota Bandung',
        'latitude': -6.9175,
        'longitude': 107.6191,
      });

      final result = await db.query(
        'cities',
        where: 'city_name = ?',
        whereArgs: ['Kota Bandung'],
      );

      expect(result, hasLength(1));
      expect(result.first['province_name'], equals('Jawa Barat'));
      expect(result.first['city_name'], equals('Kota Bandung'));
      expect(result.first['latitude'], closeTo(-6.9175, 0.0001));
      expect(result.first['longitude'], closeTo(107.6191, 0.0001));
    },
  );

  // ---------------------------------------------------------------------------
  // TEST-007: Migration v4 → v5 menambah kedua kolom Jum'at dengan default benar
  // ---------------------------------------------------------------------------

  test('TEST-007: migration v4→v5 menambah kolom iqomah_jumat dan '
      'sholat_jumat_duration_minutes dengan default values yang benar', () async {
    // Buat database v4 secara manual (tanpa dua kolom baru Jum'at)
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          is_first_run INTEGER NOT NULL DEFAULT 1,
          mosque_name TEXT NOT NULL DEFAULT '',
          mosque_address TEXT NOT NULL DEFAULT '',
          city_name TEXT NOT NULL DEFAULT '',
          latitude REAL NOT NULL DEFAULT -6.9175,
          longitude REAL NOT NULL DEFAULT 107.6191,
          timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',
          calculation_method TEXT NOT NULL DEFAULT 'kemenag',
          offset_subuh INTEGER NOT NULL DEFAULT 0,
          offset_syuruq INTEGER NOT NULL DEFAULT 0,
          offset_dhuha INTEGER NOT NULL DEFAULT 0,
          offset_dzuhur INTEGER NOT NULL DEFAULT 0,
          offset_ashar INTEGER NOT NULL DEFAULT 0,
          offset_maghrib INTEGER NOT NULL DEFAULT 0,
          offset_isya INTEGER NOT NULL DEFAULT 0,
          dhuha_offset_minutes INTEGER NOT NULL DEFAULT 20,
          hijri_adjustment INTEGER NOT NULL DEFAULT 0,
          iqomah_subuh INTEGER NOT NULL DEFAULT 10,
          iqomah_dzuhur INTEGER NOT NULL DEFAULT 10,
          iqomah_ashar INTEGER NOT NULL DEFAULT 10,
          iqomah_maghrib INTEGER NOT NULL DEFAULT 7,
          iqomah_isya INTEGER NOT NULL DEFAULT 10,
          pre_adzan_minutes INTEGER NOT NULL DEFAULT 10,
          sholat_duration_minutes INTEGER NOT NULL DEFAULT 15,
          adzan_duration_seconds INTEGER NOT NULL DEFAULT 180,
          running_text TEXT NOT NULL DEFAULT 'Selamat datang di masjid kami',
          settings_pin_hash TEXT NOT NULL DEFAULT '',
          elevation INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
      ''');

    // Insert row v4 (kolom Jum'at belum ada)
    await db.insert('settings', {'id': 1, 'is_first_run': 1});

    // Simulasi migration v4 → v5: jalankan ALTER TABLE yang sama dengan _onUpgrade
    await db.execute(
      'ALTER TABLE settings ADD COLUMN iqomah_jumat INTEGER NOT NULL DEFAULT 10',
    );
    await db.execute(
      'ALTER TABLE settings ADD COLUMN sholat_jumat_duration_minutes INTEGER NOT NULL DEFAULT 45',
    );

    // Verifikasi: kolom baru ada dengan nilai default yang benar
    final rows = await db.query('settings');
    expect(rows, hasLength(1));
    expect(
      rows.first['iqomah_jumat'],
      equals(10),
      reason: 'iqomah_jumat harus bernilai default 10 setelah migration',
    );
    expect(
      rows.first['sholat_jumat_duration_minutes'],
      equals(45),
      reason:
          'sholat_jumat_duration_minutes harus bernilai default 45 setelah migration',
    );

    await db.close();
  });

  // ---------------------------------------------------------------------------
  // TEST-008: Fresh install membuat tabel imams dan imam_schedules
  // ---------------------------------------------------------------------------

  test(
    'TEST-008: Fresh install membuat tabel imams dan imam_schedules',
    () async {
      final db = await createTestDatabase();

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('imams', 'imam_schedules') ORDER BY name",
      );

      final tableNames = tables.map((r) => r['name'] as String).toList();
      expect(tableNames, containsAll(['imam_schedules', 'imams']));
    },
  );

  // ---------------------------------------------------------------------------
  // TEST-009: Fresh install settings memiliki 8 kolom imam dengan default benar
  // ---------------------------------------------------------------------------

  test('TEST-009: Fresh install settings table memiliki 8 kolom imam '
      'schedule dengan default values yang benar', () async {
    await createTestDatabase();

    final helper = DatabaseHelper();
    final db = await helper.database;
    final rows = await db.query('settings');

    expect(rows, hasLength(1));
    final row = rows.first;

    expect(row['is_imam_schedule_enabled'], equals(0));
    expect(row['imam_schedule_interval_minutes'], equals(15));
    expect(row['imam_schedule_duration_seconds'], equals(30));
    expect(row['imam_schedule_start_hour'], equals(6));
    expect(row['imam_schedule_start_minute'], equals(0));
    expect(row['imam_schedule_end_hour'], equals(21));
    expect(row['imam_schedule_end_minute'], equals(0));
    expect(row['is_imam_schedule_locked'], equals(0));
  });

  // ---------------------------------------------------------------------------
  // TEST-010: Migration v10 → v11 menambah tabel dan kolom dengan benar
  // ---------------------------------------------------------------------------

  test('TEST-010: migration v10→v11 membuat tabel imams dan imam_schedules '
      'serta menambah 8 kolom settings dengan default values yang benar', () async {
    // Buat database v10 secara manual (tanpa tabel imam dan kolom imam baru)
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          is_first_run INTEGER NOT NULL DEFAULT 1,
          mosque_name TEXT NOT NULL DEFAULT '',
          mosque_address TEXT NOT NULL DEFAULT '',
          city_name TEXT NOT NULL DEFAULT '',
          province_name TEXT NOT NULL DEFAULT '',
          latitude REAL NOT NULL DEFAULT -6.9175,
          longitude REAL NOT NULL DEFAULT 107.6191,
          timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',
          calculation_method TEXT NOT NULL DEFAULT 'kemenag',
          offset_subuh INTEGER NOT NULL DEFAULT 0,
          offset_syuruq INTEGER NOT NULL DEFAULT 0,
          offset_dhuha INTEGER NOT NULL DEFAULT 0,
          offset_dzuhur INTEGER NOT NULL DEFAULT 0,
          offset_ashar INTEGER NOT NULL DEFAULT 0,
          offset_maghrib INTEGER NOT NULL DEFAULT 0,
          offset_isya INTEGER NOT NULL DEFAULT 0,
          dhuha_offset_minutes INTEGER NOT NULL DEFAULT 20,
          hijri_adjustment INTEGER NOT NULL DEFAULT 0,
          iqomah_subuh INTEGER NOT NULL DEFAULT 10,
          iqomah_dzuhur INTEGER NOT NULL DEFAULT 10,
          iqomah_ashar INTEGER NOT NULL DEFAULT 10,
          iqomah_maghrib INTEGER NOT NULL DEFAULT 7,
          iqomah_isya INTEGER NOT NULL DEFAULT 10,
          iqomah_jumat INTEGER NOT NULL DEFAULT 10,
          sholat_jumat_duration_minutes INTEGER NOT NULL DEFAULT 45,
          is_slideshow_enabled INTEGER NOT NULL DEFAULT 0,
          slideshow_interval_minutes INTEGER NOT NULL DEFAULT 15,
          slideshow_slot_duration_minutes INTEGER NOT NULL DEFAULT 2,
          slideshow_image_duration_seconds INTEGER NOT NULL DEFAULT 15,
          slideshow_start_hour INTEGER NOT NULL DEFAULT 6,
          slideshow_start_minute INTEGER NOT NULL DEFAULT 0,
          slideshow_end_hour INTEGER NOT NULL DEFAULT 21,
          slideshow_end_minute INTEGER NOT NULL DEFAULT 0,
          adzan_duration_seconds INTEGER NOT NULL DEFAULT 180,
          running_text TEXT NOT NULL DEFAULT 'Selamat datang di masjid kami',
          settings_pin_hash TEXT NOT NULL DEFAULT '',
          elevation INTEGER NOT NULL DEFAULT 0
        )
      ''');

    // Insert row v10 (tanpa kolom imam)
    await db.insert('settings', {'id': 1, 'is_first_run': 1});

    // Simulasi migration v10 → v11: jalankan SQL yang sama dengan _onUpgrade
    await db.execute('''
        CREATE TABLE imams (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      ''');
    await db.execute('''
        CREATE TABLE imam_schedules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
          prayer_name TEXT NOT NULL CHECK (prayer_name IN ('subuh','dzuhur','ashar','maghrib','isya','jumat')),
          imam_id INTEGER REFERENCES imams(id) ON DELETE SET NULL,
          khatib_id INTEGER REFERENCES imams(id) ON DELETE SET NULL,
          UNIQUE(day_of_week, prayer_name)
        )
      ''');
    await db.execute(
      'ALTER TABLE settings ADD COLUMN is_imam_schedule_enabled INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE settings ADD COLUMN imam_schedule_interval_minutes INTEGER NOT NULL DEFAULT 15',
    );
    await db.execute(
      'ALTER TABLE settings ADD COLUMN imam_schedule_duration_seconds INTEGER NOT NULL DEFAULT 30',
    );
    await db.execute(
      'ALTER TABLE settings ADD COLUMN imam_schedule_start_hour INTEGER NOT NULL DEFAULT 6',
    );
    await db.execute(
      'ALTER TABLE settings ADD COLUMN imam_schedule_start_minute INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE settings ADD COLUMN imam_schedule_end_hour INTEGER NOT NULL DEFAULT 21',
    );
    await db.execute(
      'ALTER TABLE settings ADD COLUMN imam_schedule_end_minute INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE settings ADD COLUMN is_imam_schedule_locked INTEGER NOT NULL DEFAULT 0',
    );

    // Verifikasi: tabel baru ada
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('imams', 'imam_schedules') ORDER BY name",
    );
    final tableNames = tables.map((r) => r['name'] as String).toList();
    expect(tableNames, containsAll(['imam_schedules', 'imams']));

    // Verifikasi: kolom baru ada dengan nilai default yang benar
    final rows = await db.query('settings');
    expect(rows, hasLength(1));
    final row = rows.first;
    expect(row['is_imam_schedule_enabled'], equals(0));
    expect(row['imam_schedule_interval_minutes'], equals(15));
    expect(row['imam_schedule_duration_seconds'], equals(30));
    expect(row['imam_schedule_start_hour'], equals(6));
    expect(row['imam_schedule_start_minute'], equals(0));
    expect(row['imam_schedule_end_hour'], equals(21));
    expect(row['imam_schedule_end_minute'], equals(0));
    expect(row['is_imam_schedule_locked'], equals(0));

    await db.close();
  });

  // ---------------------------------------------------------------------------
  // TEST-011: PRAGMA foreign_keys aktif — ON DELETE SET NULL bekerja
  // ---------------------------------------------------------------------------

  test('TEST-011: PRAGMA foreign_keys aktif — hapus imam menghasilkan '
      'imam_id NULL di imam_schedules (ON DELETE SET NULL)', () async {
    // Buat in-memory DB dan aktifkan foreign keys (seperti _onConfigure)
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');

    // Verifikasi PRAGMA foreign_keys aktif
    final pragmaResult = await db.rawQuery('PRAGMA foreign_keys');
    expect(
      pragmaResult.first.values.first,
      equals(1),
      reason: 'PRAGMA foreign_keys harus bernilai 1 (aktif)',
    );

    // Buat schema minimal
    await db.execute('''
        CREATE TABLE imams (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      ''');
    await db.execute('''
        CREATE TABLE imam_schedules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
          prayer_name TEXT NOT NULL CHECK (prayer_name IN ('subuh','dzuhur','ashar','maghrib','isya','jumat')),
          imam_id INTEGER REFERENCES imams(id) ON DELETE SET NULL,
          khatib_id INTEGER REFERENCES imams(id) ON DELETE SET NULL,
          UNIQUE(day_of_week, prayer_name)
        )
      ''');

    // Insert satu imam, lalu buat jadwal yang mereferensikannya
    final imamId = await db.insert('imams', {'name': 'Ust. Ahmad Fauzi'});
    await db.insert('imam_schedules', {
      'day_of_week': 1,
      'prayer_name': 'subuh',
      'imam_id': imamId,
    });

    // Verifikasi jadwal ada dengan imam_id yang benar
    final before = await db.query('imam_schedules');
    expect(before.first['imam_id'], equals(imamId));

    // Hapus imam — FK ON DELETE SET NULL harus membuat imam_id menjadi NULL
    await db.delete('imams', where: 'id = ?', whereArgs: [imamId]);

    // Verifikasi imam_id di jadwal sekarang NULL
    final after = await db.query('imam_schedules');
    expect(
      after.first['imam_id'],
      isNull,
      reason: 'imam_id harus NULL setelah imam dihapus (ON DELETE SET NULL)',
    );

    await db.close();
  });
}
