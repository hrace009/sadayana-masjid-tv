---
title: "Database Schema & Data Layer Specification"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
tags: [schema, data-layer, sqlite, offline-first, infrastructure]
---

# Introduction

Spesifikasi ini mendefinisikan database schema, data access layer, dan data management strategy untuk aplikasi Miqotul Khoir TV (MKT). Seluruh data disimpan secara lokal menggunakan SQLite sebagai **single source of truth** tanpa memerlukan koneksi internet setelah instalasi.

Dokumen ini menjadi fondasi bagi semua spec lain karena setiap fitur (Prayer Time, State Machine, Setup Wizard, Settings) bergantung pada data layer ini.

## 1. Purpose & Scope

### Purpose

Mendefinisikan struktur database, repository interfaces, dan data management patterns yang digunakan oleh seluruh fitur aplikasi MKT.

### Scope

- SQLite database schema (tables, columns, types, constraints)
- Repository pattern interfaces (CRUD operations per entity)
- Data seeding strategy untuk `cities` table
- Migration dan versioning strategy
- Transaction safety dan error recovery
- Data validation rules

### Intended Audience

- AI agents yang akan membuat Implementation Plan dan kode
- Developer yang mengimplementasi data layer
- QA yang menulis test untuk repository layer

### Assumptions

- Aplikasi berjalan di single device (tidak ada sync/multi-device)
- SQLite database disimpan di internal storage Android TV
- Tidak ada concurrent write dari proses terpisah
- Data `cities` di-seed sekali saat pertama kali database dibuat

## 2. Definitions

| Term | Definition |
|------|-----------|
| **SQLite** | Embedded relational database engine yang berjalan in-process |
| **Repository** | Abstraksi data access layer yang menyediakan CRUD operations |
| **Data Source** | Implementasi konkret yang berinteraksi langsung dengan SQLite |
| **Entity** | Domain object yang merepresentasikan satu baris data |
| **Seed Data** | Data awal yang di-insert saat database pertama kali dibuat |
| **Migration** | Proses update schema database dari versi lama ke versi baru |
| **Transaction** | Sekelompok operasi database yang dijalankan secara atomik |
| **Singleton Row** | Table yang hanya berisi maksimal 1 baris (e.g. `settings`) |
| **Ihtiyat** | Koreksi waktu sholat (dalam menit) untuk menyesuaikan dengan kebiasaan lokal |

## 3. Requirements, Constraints & Guidelines

### Requirements

- **REQ-001**: Aplikasi menggunakan SQLite sebagai satu-satunya media penyimpanan data persisten
- **REQ-002**: Table `settings` harus berisi tepat 1 row (singleton pattern) dengan `id = 1`
- **REQ-003**: Table `cities` harus di-populate dengan data kota/kabupaten seluruh Indonesia saat database pertama kali dibuat
- **REQ-004**: Setiap field di table `settings` harus memiliki default value yang valid agar aplikasi bisa berfungsi meski belum di-setup
- **REQ-005**: Semua operasi write ke database harus menggunakan SQLite transaction
- **REQ-006**: Repository harus menyediakan interface abstrak (port) yang terpisah dari implementasi konkret (adapter)
- **REQ-007**: Database harus mendukung migration strategy untuk future schema changes
- **REQ-008**: Data `cities` harus mencakup minimal 514 kota/kabupaten di Indonesia dengan koordinat yang akurat

### Security Requirements

- **SEC-001**: Database file harus disimpan di internal storage, tidak boleh di external/SD card
- **SEC-002**: PIN settings (jika diaktifkan) harus di-hash sebelum disimpan, tidak boleh plaintext

### Constraints

- **CON-001**: Tidak boleh menggunakan ORM — query SQL ditulis secara eksplisit untuk transparansi dan kontrol
- **CON-002**: Semua repository harus bisa di-test menggunakan in-memory SQLite database (`sqflite_common_ffi`)
- **CON-003**: Database version dimulai dari 1 dan di-increment untuk setiap schema change
- **CON-004**: Tidak boleh ada foreign key constraint antar table (simplified schema untuk embedded system)
- **CON-005**: Maximum database file size target: < 5 MB (termasuk seed data)

### Guidelines

- **GUD-001**: Gunakan `batch` operations untuk seed data agar performa insert optimal
- **GUD-002**: Semua column name menggunakan `snake_case`
- **GUD-003**: Boolean values direpresentasikan sebagai `INTEGER` (0 = false, 1 = true)
- **GUD-004**: DateTime values disimpan sebagai `TEXT` dalam format ISO 8601 jika diperlukan
- **GUD-005**: Repository methods harus mengembalikan domain entities, bukan raw `Map<String, dynamic>`

### Patterns

- **PAT-001**: Clean Architecture — Data layer terpisah dari Domain layer
- **PAT-002**: Repository Pattern — Interface di `domain/`, implementasi di `data/`
- **PAT-003**: Singleton Database Helper — Satu instance `DatabaseHelper` untuk seluruh aplikasi

## 4. Interfaces & Data Contracts

### 4.1. Database Schema

#### Table: `settings`

Singleton table (selalu 1 row, `id = 1`) yang menyimpan semua konfigurasi aplikasi.

```sql
CREATE TABLE settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  is_first_run INTEGER NOT NULL DEFAULT 1,

  -- Identity
  mosque_name TEXT NOT NULL DEFAULT '',
  mosque_address TEXT NOT NULL DEFAULT '',

  -- Location
  city_name TEXT NOT NULL DEFAULT '',
  latitude REAL NOT NULL DEFAULT -6.9175,
  longitude REAL NOT NULL DEFAULT 107.6191,
  timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',

  -- Calculation Method
  calculation_method TEXT NOT NULL DEFAULT 'singapore',

  -- Time Corrections / Ihtiyat (Minutes, range: -10 to +10)
  offset_subuh INTEGER NOT NULL DEFAULT 0,
  offset_syuruq INTEGER NOT NULL DEFAULT 0,
  offset_dhuha INTEGER NOT NULL DEFAULT 0,
  offset_dzuhur INTEGER NOT NULL DEFAULT 0,
  offset_ashar INTEGER NOT NULL DEFAULT 0,
  offset_maghrib INTEGER NOT NULL DEFAULT 0,
  offset_isya INTEGER NOT NULL DEFAULT 0,

  -- Dhuha offset from Syuruq (Minutes)
  dhuha_offset_minutes INTEGER NOT NULL DEFAULT 20,

  -- Hijri Date Adjustment (Days, range: -2 to +2)
  hijri_adjustment INTEGER NOT NULL DEFAULT 0,

  -- Iqomah Delays (Minutes)
  iqomah_subuh INTEGER NOT NULL DEFAULT 10,
  iqomah_dzuhur INTEGER NOT NULL DEFAULT 10,
  iqomah_ashar INTEGER NOT NULL DEFAULT 10,
  iqomah_maghrib INTEGER NOT NULL DEFAULT 7,
  iqomah_isya INTEGER NOT NULL DEFAULT 10,

  -- Pre-Adzan Countdown (Minutes before adzan)
  pre_adzan_minutes INTEGER NOT NULL DEFAULT 10,

  -- Sholat Duration (Minutes, screen dimming)
  sholat_duration_minutes INTEGER NOT NULL DEFAULT 15,

  -- Adzan Duration (Seconds)
  adzan_duration_seconds INTEGER NOT NULL DEFAULT 180,

  -- Display
  running_text TEXT NOT NULL DEFAULT 'Selamat datang di masjid kami',

  -- PIN Protection (empty = disabled)
  settings_pin_hash TEXT NOT NULL DEFAULT '',

  -- Timestamps
  created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
);
```

**Catatan Desain:**

- `latitude`/`longitude` default ke Bandung (lokasi development) — akan di-overwrite saat Setup Wizard
- `calculation_method` mendukung extensibility untuk metode kalkulasi lain di masa depan
- `dhuha_offset_minutes` — field terpisah karena Dhuha dihitung dari Syuruq + offset, bukan dari library `adhan`
- `pre_adzan_minutes`, `sholat_duration_minutes`, `adzan_duration_seconds` — field timing yang diperlukan oleh State Machine (SPEC-04)
- `settings_pin_hash` — kosong berarti PIN dinonaktifkan

#### Table: `cities`

Lookup table yang di-pre-populate untuk Setup Wizard (city picker).

```sql
CREATE TABLE cities (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  province_name TEXT NOT NULL,
  city_name TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL
);

-- Index untuk query performance
CREATE INDEX idx_cities_province ON cities(province_name);
CREATE INDEX idx_cities_name ON cities(city_name);
```

### 4.2. Domain Entities (Dart)

#### Settings Entity

```dart
class Settings {
  final bool isFirstRun;

  // Identity
  final String mosqueName;
  final String mosqueAddress;

  // Location
  final String cityName;
  final double latitude;
  final double longitude;
  final String timezone;

  // Calculation
  final String calculationMethod;

  // Time Corrections (minutes)
  final int offsetSubuh;
  final int offsetSyuruq;
  final int offsetDhuha;
  final int offsetDzuhur;
  final int offsetAshar;
  final int offsetMaghrib;
  final int offsetIsya;
  final int dhuhaOffsetMinutes;

  // Hijri
  final int hijriAdjustment;

  // Iqomah Delays (minutes)
  final int iqomahSubuh;
  final int iqomahDzuhur;
  final int iqomahAshar;
  final int iqomahMaghrib;
  final int iqomahIsya;

  // Timing
  final int preAdzanMinutes;
  final int sholatDurationMinutes;
  final int adzanDurationSeconds;

  // Display
  final String runningText;

  // PIN
  final String settingsPinHash;

  const Settings({...}); // Constructor with all fields
}
```

#### City Entity

```dart
class City {
  final int id;
  final String provinceName;
  final String cityName;
  final double latitude;
  final double longitude;

  const City({...});
}
```

### 4.3. Repository Interfaces (Domain Layer)

#### SettingsRepository

```dart
/// Port: domain/repositories/settings_repository.dart
abstract class SettingsRepository {
  /// Mengambil settings saat ini (selalu 1 row)
  Future<Settings> getSettings();

  /// Update satu atau lebih field settings
  /// [updates] adalah Map<String, dynamic> dari field yang berubah
  Future<void> updateSettings(Map<String, dynamic> updates);

  /// Cek apakah ini first run
  Future<bool> isFirstRun();

  /// Tandai first run selesai
  Future<void> completeFirstRun();

  /// Verify PIN (return true jika cocok atau PIN disabled)
  Future<bool> verifyPin(String inputPin);

  /// Set atau update PIN (empty string = disable)
  Future<void> setPin(String newPin);
}
```

#### CityRepository

```dart
/// Port: domain/repositories/city_repository.dart
abstract class CityRepository {
  /// Mengambil semua province names (distinct, sorted)
  Future<List<String>> getProvinces();

  /// Mengambil semua kota dalam satu provinsi
  Future<List<City>> getCitiesByProvince(String provinceName);

  /// Search kota berdasarkan nama (case-insensitive, LIKE query)
  Future<List<City>> searchCities(String query);

  /// Mengambil satu kota berdasarkan ID
  Future<City?> getCityById(int id);
}
```

### 4.4. Data Source Implementations (Data Layer)

#### DatabaseHelper (Singleton)

```dart
/// data/datasources/database_helper.dart
class DatabaseHelper {
  static const String _databaseName = 'miqotul_khoir.db';
  static const int _databaseVersion = 1;

  // Singleton instance
  static DatabaseHelper? _instance;
  static Database? _database;

  factory DatabaseHelper() => _instance ??= DatabaseHelper._internal();
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Create tables
    await _createTables(db);

    // 2. Insert default settings row
    await _insertDefaultSettings(db);

    // 3. Seed cities data
    await _seedCities(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic per version increment
  }
}
```

### 4.5. File Structure

```
lib/
├── data/
│   ├── datasources/
│   │   ├── database_helper.dart          # Singleton, schema, migrations
│   │   ├── settings_local_data_source.dart  # SQLite operations for settings
│   │   └── city_local_data_source.dart      # SQLite operations for cities
│   ├── models/
│   │   ├── settings_model.dart           # toMap() / fromMap() conversion
│   │   └── city_model.dart               # toMap() / fromMap() conversion
│   └── repositories/
│       ├── settings_repository_impl.dart  # Implements SettingsRepository
│       └── city_repository_impl.dart      # Implements CityRepository
├── domain/
│   ├── entities/
│   │   ├── settings.dart                 # Pure domain entity
│   │   └── city.dart                     # Pure domain entity
│   └── repositories/
│       ├── settings_repository.dart       # Abstract interface (port)
│       └── city_repository.dart           # Abstract interface (port)
```

## 5. Acceptance Criteria

- **AC-001**: Given database is freshly created, When app starts for the first time, Then `settings` table contains exactly 1 row with `is_first_run = 1` and all defaults populated
- **AC-002**: Given database is freshly created, When app starts for the first time, Then `cities` table contains ≥ 500 rows covering all provinces in Indonesia
- **AC-003**: Given a valid `Settings` entity, When `updateSettings()` is called with partial fields, Then only specified fields are updated and other fields retain their values
- **AC-004**: Given `is_first_run = 1`, When `completeFirstRun()` is called, Then `is_first_run` becomes `0`
- **AC-005**: Given a province name "Jawa Barat", When `getCitiesByProvince("Jawa Barat")` is called, Then it returns all cities in Jawa Barat sorted alphabetically
- **AC-006**: Given search query "band", When `searchCities("band")` is called, Then it returns cities whose name contains "band" (case-insensitive), including "Bandung", "Bandung Barat"
- **AC-007**: Given an ongoing write transaction, When power loss occurs, Then no partial data is committed (transaction atomicity)
- **AC-008**: Given `settings_pin_hash` is empty, When `verifyPin("")` is called, Then it returns `true` (PIN disabled)
- **AC-009**: Given `settings_pin_hash` contains a hash, When `verifyPin()` is called with correct PIN, Then it returns `true`
- **AC-010**: Given database version is 1, When schema needs update, Then `_onUpgrade()` is called and migration runs without data loss
- **AC-011**: Given any repository operation, When called from test, Then it works with in-memory SQLite database (`inMemoryDatabasePath`)

## 6. Test Automation Strategy

### Test Levels

| Level | Scope | Framework |
|-------|-------|-----------|
| **Unit** | Repository implementations, model conversions | `flutter_test` + `sqflite_common_ffi` |
| **Integration** | Database lifecycle (create → seed → query → migrate) | `flutter_test` + `sqflite_common_ffi` |

### Test Approach

- **In-Memory Database**: Semua test menggunakan `databaseFactoryFfi` dengan `inMemoryDatabasePath` — tidak ada file I/O
- **Isolated Tests**: Setiap test membuat database baru, tidak ada shared state
- **Teardown**: `db.close()` wajib dipanggil di `tearDown()`

### Required Tests

- **TEST-001**: `DatabaseHelper` creates tables and seeds data correctly on first init
- **TEST-002**: `SettingsModel.fromMap()` correctly maps all fields from raw SQLite map
- **TEST-003**: `SettingsModel.toMap()` correctly converts entity to SQLite-compatible map
- **TEST-004**: `SettingsRepositoryImpl.getSettings()` returns default settings on fresh database
- **TEST-005**: `SettingsRepositoryImpl.updateSettings()` updates only specified fields
- **TEST-006**: `SettingsRepositoryImpl.completeFirstRun()` sets `is_first_run` to 0
- **TEST-007**: `CityRepositoryImpl.getProvinces()` returns distinct, sorted province names
- **TEST-008**: `CityRepositoryImpl.getCitiesByProvince()` returns correct cities for given province
- **TEST-009**: `CityRepositoryImpl.searchCities()` performs case-insensitive search
- **TEST-010**: `CityModel.fromMap()` / `toMap()` round-trip produces identical data
- **TEST-011**: PIN hash verification works correctly (enabled and disabled scenarios)

### Coverage Requirements

- **Minimum**: 90% line coverage untuk `data/` layer
- **Critical**: 100% coverage untuk `DatabaseHelper._onCreate()` dan migration logic

## 7. Rationale & Context

### Mengapa SQLite, bukan SharedPreferences?

Settings memiliki banyak fields (30+) dengan relasi implisit (offset per waktu sholat, iqomah per waktu sholat). SQLite memberikan:
- Query capability (SELECT specific fields)
- Transaction safety (atomic writes, power loss protection)
- Migration support (schema versioning)
- Consistent testing (in-memory database)

### Mengapa Singleton Row Pattern untuk Settings?

Aplikasi digital signage hanya memiliki satu konfigurasi aktif. Table dengan `CHECK (id = 1)` memastikan integrity secara database-level, bukan hanya application-level.

### Mengapa Tidak Ada Foreign Key?

Untuk embedded system di Android TV:
- Mengurangi complexity dan overhead
- `settings` dan `cities` tidak memiliki true relational dependency
- City selection hanya meng-copy `latitude`/`longitude` ke `settings`, bukan FK reference

### Mengapa dari PRD Ditambahkan Field Tambahan?

PRD §6.3 mendefinisikan schema dasar. Spec ini menambahkan:
- `calculation_method` — untuk extensibility metode kalkulasi
- `dhuha_offset_minutes` — karena Dhuha bukan output langsung dari `adhan`
- `pre_adzan_minutes`, `sholat_duration_minutes`, `adzan_duration_seconds` — diperlukan oleh State Machine (SPEC-04)
- `settings_pin_hash` — disebutkan di PRD §3.4 tapi belum ada di schema
- `created_at`, `updated_at` — audit trail standar

## 8. Dependencies & External Integrations

### Third-Party Packages

- **DEP-001**: `sqflite` — SQLite plugin untuk Flutter (Android implementation)
- **DEP-002**: `path` — Helper untuk construct database file path
- **DEP-003**: `sqflite_common_ffi` — FFI-based SQLite untuk unit testing di desktop/CI
- **DEP-004**: `crypto` (atau `dart:convert` + `dart:crypto`) — untuk PIN hashing (SHA-256)

### Data Dependencies

- **DAT-001**: City coordinates dataset — Daftar kota/kabupaten Indonesia (≥ 514 entries) dengan latitude/longitude. Sumber: BPS atau dataset publik GeoJSON Indonesia.

## 9. Examples & Edge Cases

### Edge Case: Power Loss During Write

```dart
// ✅ CORRECT — Semua writes dalam transaction
Future<void> updateSettings(Map<String, dynamic> updates) async {
  final db = await database;
  await db.transaction((txn) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    await txn.update('settings', updates, where: 'id = 1');
  });
}

// ❌ WRONG — Direct update tanpa transaction
Future<void> updateSettings(Map<String, dynamic> updates) async {
  final db = await database;
  await db.update('settings', updates, where: 'id = 1'); // NOT SAFE
}
```

### Edge Case: Settings Table Empty

```dart
// DatabaseHelper._onCreate harus memastikan default row ada
Future<void> _insertDefaultSettings(Database db) async {
  await db.insert('settings', {'id': 1});
  // Semua default values ditangani oleh SQL DEFAULT clause
}
```

### Edge Case: City Search dengan Karakter Khusus

```dart
// Sanitize input untuk LIKE query
Future<List<City>> searchCities(String query) async {
  final db = await database;
  final sanitized = query.replaceAll('%', '').replaceAll('_', '');
  final results = await db.query(
    'cities',
    where: 'city_name LIKE ?',
    whereArgs: ['%$sanitized%'],
    orderBy: 'city_name ASC',
  );
  return results.map((map) => CityModel.fromMap(map)).toList();
}
```

### Edge Case: Migration dari Versi 1 ke 2

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Contoh: Menambahkan field baru dengan default value
    await db.execute(
      'ALTER TABLE settings ADD COLUMN new_field TEXT NOT NULL DEFAULT ""',
    );
  }
}
```

## 10. Validation Criteria

- [ ] Schema dapat dibuat tanpa error di SQLite (test `_onCreate`)
- [ ] Default settings row ter-insert dengan semua default values valid
- [ ] Cities seed data ter-insert lengkap (≥ 500 rows)
- [ ] Repository interface di `domain/` tidak mengimport package `sqflite`
- [ ] Repository implementation di `data/` mengimport dan mengimplementasi interface dari `domain/`
- [ ] Semua test berjalan dengan in-memory database (tidak ada file I/O)
- [ ] Update partial fields tidak menimpa field lain
- [ ] Database file size < 5 MB setelah seeding

## 11. Related Specifications / Further Reading

- [PRD §6.3 — Database Schema](file:///d:/AndroidProject/LatihanFlutter/sadayana_masjid_tv/Product_Requirement_Document.md) — Original schema definition
- SPEC-03: Prayer Time Calculation — Consumer of `offset_*` fields
- SPEC-04: Display State Machine — Consumer of timing fields (`pre_adzan_minutes`, `iqomah_*`, etc.)
- SPEC-05: Setup Wizard — Writes to `settings` and reads `cities`
- SPEC-06: Settings & Content — CRUD operations on `settings`
- [Architecture Patterns Guide](file:///d:/AndroidProject/LatihanFlutter/sadayana_masjid_tv/docs/ARCHITECTURE_PATTERNS.md) — Offline-first dan testing patterns
- [Testing Guide](file:///d:/AndroidProject/LatihanFlutter/sadayana_masjid_tv/docs/TESTING_GUIDE.md) — SQLite testing strategies
