---
goal: "Setup Database Infrastructure — DatabaseHelper, Schema DDL, Migration & Seed Mechanism"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [infrastructure, database, sqlite, schema, seed, migration]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Plan ini mencakup setup infrastruktur database SQLite untuk aplikasi Miqotul Khoir TV. Fokusnya adalah membuat `DatabaseHelper` singleton, DDL schema untuk table `settings` dan `cities`, migration strategy, mekanisme seed data kota, serta menambahkan dependency packages yang diperlukan.

Plan ini adalah **fondasi paling dasar** — semua plan lain bergantung pada keberhasilan plan ini.

**Source Specification**: [spec-schema-database.md](../spec/spec-schema-database.md) (SPEC-01 Part A)

## 1. Requirements & Constraints

- **REQ-001**: Aplikasi menggunakan SQLite sebagai satu-satunya media penyimpanan data persisten
- **REQ-002**: Table `settings` harus berisi tepat 1 row (singleton pattern) dengan `id = 1`
- **REQ-003**: Table `cities` harus di-populate dengan data kota/kabupaten seluruh Indonesia saat database pertama kali dibuat
- **REQ-004**: Setiap field di table `settings` harus memiliki default value yang valid
- **REQ-005**: Semua operasi write ke database harus menggunakan SQLite transaction
- **REQ-007**: Database harus mendukung migration strategy untuk future schema changes
- **REQ-008**: Data `cities` harus mencakup minimal 514 kota/kabupaten di Indonesia dengan koordinat yang akurat
- **SEC-001**: Database file harus disimpan di internal storage, tidak boleh di external/SD card
- **CON-001**: Tidak boleh menggunakan ORM — query SQL ditulis secara eksplisit
- **CON-003**: Database version dimulai dari 1 dan di-increment untuk setiap schema change
- **CON-004**: Tidak boleh ada foreign key constraint antar table
- **CON-005**: Maximum database file size target: < 5 MB (termasuk seed data)
- **GUD-001**: Gunakan `batch` operations untuk seed data agar performa insert optimal
- **GUD-002**: Semua column name menggunakan `snake_case`
- **GUD-003**: Boolean values direpresentasikan sebagai `INTEGER` (0 = false, 1 = true)
- **GUD-004**: DateTime values disimpan sebagai `TEXT` dalam format ISO 8601
- **PAT-003**: Singleton Database Helper — Satu instance `DatabaseHelper` untuk seluruh aplikasi

## 2. Implementation Steps

### Phase 1: Package Dependencies

- GOAL-001: Menambahkan semua dependency packages yang diperlukan untuk database layer ke `pubspec.yaml`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Jalankan `flutter pub add sqflite` — SQLite plugin untuk Flutter Android | ✅ | 2026-02-18 |
| TASK-002 | Jalankan `flutter pub add path` — Helper untuk construct database file path | ✅ | 2026-02-18 |
| TASK-003 | Jalankan `flutter pub add dev:sqflite_common_ffi` — FFI-based SQLite untuk unit testing di desktop/CI | ✅ | 2026-02-18 |
| TASK-004 | Jalankan `flutter pub get` untuk memastikan semua dependencies terinstall tanpa error | ✅ | 2026-02-18 |

### Phase 2: DatabaseHelper Singleton

- GOAL-002: Membuat `DatabaseHelper` singleton class yang mengelola lifecycle database (init, open, close, migration)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-005 | Buat file `lib/data/datasources/database_helper.dart` | ✅ | 2026-02-18 |
| TASK-006 | Implementasi `DatabaseHelper` class dengan singleton pattern: `static DatabaseHelper? _instance`, `static Database? _database`, `factory DatabaseHelper()` | ✅ | 2026-02-18 |
| TASK-007 | Implementasi `Future<Database> get database` getter yang lazy-init database | ✅ | 2026-02-18 |
| TASK-008 | Implementasi `Future<Database> _initDatabase()` yang membuka database di internal storage path dengan `getDatabasesPath()` dan `join(dbPath, 'miqotul_khoir.db')` | ✅ | 2026-02-18 |
| TASK-009 | Set `_databaseVersion = 1` sebagai konstanta | ✅ | 2026-02-18 |
| TASK-010 | Set `_databaseName = 'miqotul_khoir.db'` sebagai konstanta | ✅ | 2026-02-18 |
| TASK-011 | Tambahkan method `Future<void> close()` untuk menutup database dan reset `_database = null` | ✅ | 2026-02-18 |

### Phase 3: Schema DDL — Table Creation

- GOAL-003: Implementasi `_onCreate` callback yang membuat semua tables dengan schema sesuai SPEC-01

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-012 | Implementasi `Future<void> _onCreate(Database db, int version)` yang memanggil `_createTables()`, `_insertDefaultSettings()`, dan `_seedCities()` secara berurutan | ✅ | 2026-02-18 |
| TASK-013 | Implementasi `Future<void> _createTables(Database db)` yang menjalankan CREATE TABLE `settings` dengan semua 30+ columns, constraints (`CHECK (id = 1)`), dan default values sesuai SPEC-01 §4.1 | ✅ | 2026-02-18 |
| TASK-014 | Dalam `_createTables()`, jalankan CREATE TABLE `cities` dengan columns: `id INTEGER PRIMARY KEY AUTOINCREMENT`, `province_name TEXT NOT NULL`, `city_name TEXT NOT NULL`, `latitude REAL NOT NULL`, `longitude REAL NOT NULL` | ✅ | 2026-02-18 |
| TASK-015 | Dalam `_createTables()`, jalankan CREATE INDEX `idx_cities_province` ON `cities(province_name)` dan `idx_cities_name` ON `cities(city_name)` | ✅ | 2026-02-18 |
| TASK-016 | Implementasi `Future<void> _insertDefaultSettings(Database db)` yang insert 1 row ke `settings` dengan `{'id': 1}` — semua default values ditangani oleh SQL DEFAULT clause | ✅ | 2026-02-18 |

### Phase 4: Cities Seed Data

- GOAL-004: Menyiapkan dan mengimplementasi mekanisme seed data kota/kabupaten seluruh Indonesia

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-017 | Buat file `assets/data/cities.json` berisi array JSON kota/kabupaten Indonesia (≥ 514 entries). Setiap entry memiliki fields: `province_name` (String), `city_name` (String), `latitude` (double), `longitude` (double). Sumber data: dataset publik BPS/GeoJSON Indonesia | ✅ | 2026-02-18 |
| TASK-018 | Daftarkan `assets/data/` di `pubspec.yaml` pada section `flutter.assets` | ✅ | 2026-02-18 |
| TASK-019 | Implementasi `Future<void> _seedCities(Database db)` di `DatabaseHelper` yang: (1) membaca `assets/data/cities.json` via `rootBundle.loadString()`, (2) parse JSON, (3) insert semua entries ke table `cities` menggunakan `batch` operations | ✅ | 2026-02-18 |
| TASK-020 | Pastikan `_seedCities()` menggunakan `Batch` dari `sqflite` untuk insert performa optimal — bukan individual `INSERT` per row | ✅ | 2026-02-18 |
| TASK-021 | Validasi bahwa total size database setelah seeding < 5 MB (CON-005) | ✅ | 2026-02-18 |

### Phase 5: Migration Strategy

- GOAL-005: Implementasi `_onUpgrade` callback untuk future migration support

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-022 | Implementasi `Future<void> _onUpgrade(Database db, int oldVersion, int newVersion)` dengan pattern `if (oldVersion < N)` untuk setiap version increment | ✅ | 2026-02-18 |
| TASK-023 | Untuk version 1 (saat ini), body `_onUpgrade` kosong karena ini adalah versi pertama — tambahkan komentar `// Migration logic will be added here for future versions` | ✅ | 2026-02-18 |

### Phase 6: Testing Infrastructure

- GOAL-006: Setup testing infrastructure untuk database layer dan tulis unit tests

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-024 | Buat file `test/data/datasources/database_helper_test.dart` | ✅ | 2026-02-18 |
| TASK-025 | Implementasi `setUpAll()` yang menginisialisasi `sqfliteFfiInit()` dan `databaseFactory = databaseFactoryFfi` untuk in-memory testing | ✅ | 2026-02-18 |
| TASK-026 | Implementasi `setUp()` yang membuat `DatabaseHelper` baru dengan `inMemoryDatabasePath` untuk setiap test (isolated) | ✅ | 2026-02-18 |
| TASK-027 | Implementasi `tearDown()` yang memanggil `db.close()` | ✅ | 2026-02-18 |
| TASK-028 | TEST-001: Test `DatabaseHelper` creates `settings` table on first init — verify table exists via `db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='settings'")` | ✅ | 2026-02-18 |
| TASK-029 | TEST-002: Test `DatabaseHelper` creates `cities` table on first init — verify table exists | ✅ | 2026-02-18 |
| TASK-030 | TEST-003: Test default `settings` row is inserted dengan `is_first_run = 1` dan semua default values populated sesuai SPEC-01 | ✅ | 2026-02-18 |
| TASK-031 | TEST-004: Test `cities` table memiliki index `idx_cities_province` dan `idx_cities_name` | ✅ | 2026-02-18 |
| TASK-032 | TEST-005: Test `settings` table enforces singleton constraint (`CHECK (id = 1)`) — insert row dengan `id = 2` harus throw error | ✅ | 2026-02-18 |
| TASK-033 | TEST-006: Test cities table menerima data dengan benar dan bisa di-query | ✅ | 2026-02-18 |
| TASK-034 | Jalankan `flutter test test/data/datasources/database_helper_test.dart --reporter=expanded` dan pastikan semua test pass | ✅ | 2026-02-18 |

## 3. Alternatives

- **ALT-001**: Menggunakan `SharedPreferences` untuk settings — Ditolak karena settings memiliki 30+ fields dengan relational nature (offset per waktu sholat), memerlukan transaction safety, dan migration support yang tidak tersedia di SharedPreferences
- **ALT-002**: Menggunakan `hive` atau `isar` sebagai database — Ditolak karena SQLite lebih mature untuk embedded systems, memiliki built-in transaction safety, dan `sqflite` sudah well-tested untuk Android TV
- **ALT-003**: Seed cities data via hardcoded Dart list — Ditolak karena JSON file lebih maintainable, dapat di-update tanpa recompile, dan memisahkan data dari logic
- **ALT-004**: Menggunakan `drift` (ORM) — Ditolak sesuai CON-001: query SQL ditulis eksplisit untuk transparansi dan kontrol penuh

## 4. Dependencies

- **DEP-001**: `sqflite` (^2.3.0) — SQLite plugin untuk Flutter, provides `Database`, `openDatabase`, `getDatabasesPath`
- **DEP-002**: `path` (^1.9.0) — Path manipulation, provides `join()` untuk construct db file path
- **DEP-003**: `sqflite_common_ffi` (^2.3.0) — dev dependency, FFI-based SQLite untuk desktop/CI testing
- **DEP-004**: Flutter SDK `services` package — provides `rootBundle.loadString()` untuk membaca assets
- **DAT-001**: Dataset kota/kabupaten Indonesia — ≥ 514 entries dengan koordinat (lat/lng), sumber: BPS atau GeoJSON publik

## 5. Files

- **FILE-001**: `lib/data/datasources/database_helper.dart` — [NEW] DatabaseHelper singleton class dengan schema DDL, seed, dan migration
- **FILE-002**: `assets/data/cities.json` — [NEW] JSON dataset kota/kabupaten seluruh Indonesia
- **FILE-003**: `pubspec.yaml` — [MODIFY] Tambah dependencies (`sqflite`, `path`, `sqflite_common_ffi`) dan assets declaration
- **FILE-004**: `test/data/datasources/database_helper_test.dart` — [NEW] Unit tests untuk DatabaseHelper

## 6. Testing

- **TEST-001**: `DatabaseHelper` creates `settings` table with correct schema on first init
- **TEST-002**: `DatabaseHelper` creates `cities` table with correct schema on first init
- **TEST-003**: Default `settings` row exists with `id = 1`, `is_first_run = 1`, dan semua default values valid
- **TEST-004**: `cities` table contains ≥ 500 rows after seeding
- **TEST-005**: Database indexes (`idx_cities_province`, `idx_cities_name`) are created
- **TEST-006**: Singleton constraint (`CHECK (id = 1)`) prevents insertion of row with `id != 1`

**Test Command**: `flutter test test/data/datasources/database_helper_test.dart --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: Cities JSON dataset mungkin memerlukan validasi koordinat — beberapa dataset publik memiliki koordinat yang kurang akurat. Mitigasi: cross-check dengan beberapa sumber data
- **RISK-002**: Seed data insert ≥ 514 rows bisa lambat tanpa batch operations — Mitigasi: wajib gunakan `Batch` dari sqflite
- **RISK-003**: Database file size bisa melebihi 5 MB jika cities data terlalu besar — Mitigasi: monitor size setelah seeding, optimasi jika perlu
- **ASSUMPTION-001**: `sqflite` plugin bekerja di Android TV environment tanpa masalah
- **ASSUMPTION-002**: `sqflite_common_ffi` dapat digunakan untuk testing di Windows development machine
- **ASSUMPTION-003**: `rootBundle.loadString()` dapat membaca JSON file saat `_onCreate` (database initialization)

## 8. Related Specifications / Further Reading

- [SPEC-01: Database Schema & Data Layer](../spec/spec-schema-database.md) — Source specification
- [PRD §6.3 — Database Schema](../Product_Requirement_Document.md) — Original schema definition
- [Architecture Patterns Guide](../docs/ARCHITECTURE_PATTERNS.md) — Offline-first patterns
- [Testing Guide](../docs/TESTING_GUIDE.md) — SQLite testing strategies
- Plan 02: `feature-data-layer-1.md` — Next plan (entities, models, repositories) yang bergantung pada plan ini
