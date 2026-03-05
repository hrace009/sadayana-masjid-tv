---
goal: "Implementasi Data Layer — Entities, Models, Repository Interfaces & Implementations"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, data-layer, entity, model, repository, clean-architecture]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-brightgreen)

Plan ini mencakup implementasi seluruh data layer sesuai Clean Architecture: domain entities (`Settings`, `City`), data models (`SettingsModel`, `CityModel` dengan `toMap()`/`fromMap()`), repository interfaces (abstract classes di domain layer), dan repository implementations (concrete classes di data layer yang berinteraksi dengan SQLite).

Plan ini bergantung pada **Plan 01** (DatabaseHelper sudah tersedia) dan menjadi fondasi bagi semua plan selanjutnya yang membutuhkan akses data.

**Source Specification**: [spec-schema-database.md](../spec/spec-schema-database.md) (SPEC-01 Part B)

## 1. Requirements & Constraints

- **REQ-005**: Semua operasi write ke database harus menggunakan SQLite transaction
- **REQ-006**: Repository harus menyediakan interface abstrak (port) yang terpisah dari implementasi konkret (adapter)
- **SEC-002**: PIN settings harus di-hash sebelum disimpan, tidak boleh plaintext
- **CON-001**: Tidak boleh menggunakan ORM — query SQL ditulis secara eksplisit
- **CON-002**: Semua repository harus bisa di-test menggunakan in-memory SQLite database
- **GUD-005**: Repository methods harus mengembalikan domain entities, bukan raw `Map<String, dynamic>`
- **PAT-001**: Clean Architecture — Data layer terpisah dari Domain layer
- **PAT-002**: Repository Pattern — Interface di `domain/`, implementasi di `data/`

## 2. Implementation Steps

### Phase 1: Domain Entities

- GOAL-001: Membuat pure domain entities yang merepresentasikan data bisnis tanpa dependency ke framework/database

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat file `lib/domain/entities/settings.dart` — Implementasi `Settings` class sebagai immutable entity dengan `const` constructor. Fields sesuai SPEC-01 §4.2: `isFirstRun` (bool), `mosqueName` (String), `mosqueAddress` (String), `cityName` (String), `latitude` (double), `longitude` (double), `timezone` (String), `calculationMethod` (String), `offsetSubuh`/`offsetSyuruq`/`offsetDhuha`/`offsetDzuhur`/`offsetAshar`/`offsetMaghrib`/`offsetIsya` (int), `dhuhaOffsetMinutes` (int), `hijriAdjustment` (int), `iqomahSubuh`/`iqomahDzuhur`/`iqomahAshar`/`iqomahMaghrib`/`iqomahIsya` (int), `preAdzanMinutes` (int), `sholatDurationMinutes` (int), `adzanDurationSeconds` (int), `runningText` (String), `settingsPinHash` (String). Extend `Equatable` untuk value equality. Implementasi `copyWith()` method | ✅ | 2026-02-18 |
| TASK-002 | Buat file `lib/domain/entities/city.dart` — Implementasi `City` class sebagai immutable entity dengan `const` constructor. Fields: `id` (int), `provinceName` (String), `cityName` (String), `latitude` (double), `longitude` (double). Extend `Equatable` | ✅ | 2026-02-18 |
| TASK-003 | Tambahkan dependency `equatable` ke `pubspec.yaml` via `flutter pub add equatable` | ✅ | 2026-02-18 |

### Phase 2: Repository Interfaces (Domain Layer Ports)

- GOAL-002: Mendefinisikan abstract repository interfaces di domain layer sebagai ports yang tidak bergantung pada implementation details

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-004 | Buat file `lib/domain/repositories/settings_repository.dart` — Abstract class `SettingsRepository` dengan methods: `Future<Settings> getSettings()`, `Future<void> updateSettings(Map<String, dynamic> updates)`, `Future<bool> isFirstRun()`, `Future<void> completeFirstRun()`, `Future<bool> verifyPin(String inputPin)`, `Future<void> setPin(String newPin)` | ✅ | 2026-02-18 |
| TASK-005 | Buat file `lib/domain/repositories/city_repository.dart` — Abstract class `CityRepository` dengan methods: `Future<List<String>> getProvinces()`, `Future<List<City>> getCitiesByProvince(String provinceName)`, `Future<List<City>> searchCities(String query)`, `Future<City?> getCityById(int id)` | ✅ | 2026-02-18 |
| TASK-006 | Verifikasi bahwa KEDUA file repository interface TIDAK mengimport package `sqflite` atau apapun dari `data/` layer — hanya import dari `domain/entities/` | ✅ | 2026-02-18 |

### Phase 3: Data Models (toMap / fromMap)

- GOAL-003: Membuat model classes yang mengkonversi antara domain entities dan SQLite `Map<String, dynamic>`

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | Buat file `lib/data/models/settings_model.dart` — Class `SettingsModel` yang extends `Settings`. Implementasi `factory SettingsModel.fromMap(Map<String, dynamic> map)` yang mapping semua 30+ fields dari snake_case (SQLite) ke camelCase (Dart), termasuk konversi `int → bool` untuk `is_first_run`. Implementasi `Map<String, dynamic> toMap()` yang mapping balik ke snake_case | ✅ | 2026-02-18 |
| TASK-008 | Buat file `lib/data/models/city_model.dart` — Class `CityModel` yang extends `City`. Implementasi `factory CityModel.fromMap(Map<String, dynamic> map)` dan `Map<String, dynamic> toMap()` | ✅ | 2026-02-18 |

### Phase 4: Local Data Sources

- GOAL-004: Membuat data source classes yang berinteraksi langsung dengan SQLite database via DatabaseHelper

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-009 | Buat file `lib/data/datasources/settings_local_data_source.dart` — Class `SettingsLocalDataSource` dengan constructor yang menerima `DatabaseHelper`. Methods: `Future<SettingsModel> getSettings()` (SELECT * FROM settings WHERE id = 1), `Future<void> updateSettings(Map<String, dynamic> updates)` (UPDATE dalam transaction, auto-set `updated_at`), `Future<void> completeFirstRun()` (UPDATE `is_first_run = 0`) | ✅ | 2026-02-18 |
| TASK-010 | Buat file `lib/data/datasources/city_local_data_source.dart` — Class `CityLocalDataSource` dengan constructor yang menerima `DatabaseHelper`. Methods: `Future<List<String>> getProvinces()` (SELECT DISTINCT province_name ORDER BY province_name), `Future<List<CityModel>> getCitiesByProvince(String province)` (SELECT WHERE province_name = ? ORDER BY city_name), `Future<List<CityModel>> searchCities(String query)` (SELECT WHERE city_name LIKE '%query%', sanitize input), `Future<CityModel?> getCityById(int id)` (SELECT WHERE id = ?) | ✅ | 2026-02-18 |

### Phase 5: Repository Implementations (Data Layer Adapters)

- GOAL-005: Mengimplementasikan concrete repository classes yang menghubungkan domain ports dengan data sources

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-011 | Buat file `lib/data/repositories/settings_repository_impl.dart` — Class `SettingsRepositoryImpl` yang implements `SettingsRepository`. Constructor menerima `SettingsLocalDataSource`. Setiap method delegasikan ke data source. Method `verifyPin()`: jika `settingsPinHash` empty → return true; jika tidak → hash input dengan SHA-256 dan compare. Method `setPin()`: hash pin dengan SHA-256 lalu panggil `updateSettings({'settings_pin_hash': hash})`, empty string = disable PIN | ✅ | 2026-02-18 |
| TASK-012 | Buat file `lib/data/repositories/city_repository_impl.dart` — Class `CityRepositoryImpl` yang implements `CityRepository`. Constructor menerima `CityLocalDataSource`. Setiap method delegasikan ke data source | ✅ | 2026-02-18 |
| TASK-013 | Tambahkan dependency `crypto` ke `pubspec.yaml` via `flutter pub add crypto` — diperlukan untuk SHA-256 PIN hashing | ✅ | 2026-02-18 |

### Phase 6: Unit Tests

- GOAL-006: Menulis comprehensive unit tests untuk semua data layer components

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-014 | Buat file `test/data/models/settings_model_test.dart` | ✅ | 2026-02-18 |
| TASK-015 | TEST: `SettingsModel.fromMap()` correctly maps all 30+ fields dari raw SQLite map ke entity properties, termasuk `int → bool` conversion untuk `is_first_run` | ✅ | 2026-02-18 |
| TASK-016 | TEST: `SettingsModel.toMap()` correctly converts entity kembali ke SQLite-compatible map dengan snake_case keys | ✅ | 2026-02-18 |
| TASK-017 | TEST: `SettingsModel` round-trip (fromMap → toMap → fromMap) produces identical data | ✅ | 2026-02-18 |
| TASK-018 | Buat file `test/data/models/city_model_test.dart` | ✅ | 2026-02-18 |
| TASK-019 | TEST: `CityModel.fromMap()` / `toMap()` round-trip produces identical data | ✅ | 2026-02-18 |
| TASK-020 | Buat file `test/data/repositories/settings_repository_impl_test.dart` — Setup: `sqfliteFfiInit()`, in-memory database, create tables via `DatabaseHelper` | ✅ | 2026-02-18 |
| TASK-021 | TEST: `getSettings()` returns default settings on fresh database (is_first_run = true, mosqueName = '', latitude = -6.9175, dll) | ✅ | 2026-02-18 |
| TASK-022 | TEST: `updateSettings({'mosque_name': 'Masjid Al-Ikhlas'})` updates only `mosque_name` field, other fields retain default values | ✅ | 2026-02-18 |
| TASK-023 | TEST: `completeFirstRun()` sets `is_first_run` to false | ✅ | 2026-02-18 |
| TASK-024 | TEST: `verifyPin('')` returns true when PIN is disabled (pin_hash empty) | ✅ | 2026-02-18 |
| TASK-025 | TEST: `setPin('123456')` saves hashed PIN, lalu `verifyPin('123456')` returns true, `verifyPin('000000')` returns false | ✅ | 2026-02-18 |
| TASK-026 | Buat file `test/data/repositories/city_repository_impl_test.dart` — Setup: in-memory database with seeded cities | ✅ | 2026-02-18 |
| TASK-027 | TEST: `getProvinces()` returns distinct, alphabetically sorted province names | ✅ | 2026-02-18 |
| TASK-028 | TEST: `getCitiesByProvince('Jawa Barat')` returns correct cities sorted alphabetically | ✅ | 2026-02-18 |
| TASK-029 | TEST: `searchCities('band')` returns cities containing "band" (case-insensitive), termasuk "Bandung", "Bandung Barat" | ✅ | 2026-02-18 |
| TASK-030 | TEST: `getCityById(1)` returns correct city, `getCityById(99999)` returns null | ✅ | 2026-02-18 |
| TASK-031 | Jalankan semua tests: `flutter test test/data/ --reporter=expanded` dan pastikan semua pass | ✅ | 2026-02-18 |

## 3. Alternatives

- **ALT-001**: Menggunakan `freezed` untuk code generation entities — Ditolak karena menambah build complexity dan proyek ini cukup sederhana untuk manual immutable classes
- **ALT-002**: Membuat repository implementations langsung tanpa data source layer — Ditolak karena memisahkan data source memberikan better testability dan separation of concerns
- **ALT-003**: Menggunakan `bcrypt` untuk PIN hashing — Ditolak karena `crypto` (SHA-256) sudah cukup untuk PIN 6 digit pada aplikasi offline tanpa network attack vector

## 4. Dependencies

- **DEP-001**: `equatable` (2.0.8) — Value equality untuk entities
- **DEP-002**: `crypto` (3.0.7) — SHA-256 hashing untuk PIN
- **DEP-003**: Plan 01 `DatabaseHelper` — Harus sudah selesai dan tested
- **DEP-004**: Plan 01 schema DDL — Tables `settings` dan `cities` harus sudah bisa di-create

## 5. Files

- **FILE-001**: `lib/domain/entities/settings.dart` — [NEW] Settings domain entity
- **FILE-002**: `lib/domain/entities/city.dart` — [NEW] City domain entity
- **FILE-003**: `lib/domain/repositories/settings_repository.dart` — [NEW] Abstract SettingsRepository interface
- **FILE-004**: `lib/domain/repositories/city_repository.dart` — [NEW] Abstract CityRepository interface
- **FILE-005**: `lib/data/models/settings_model.dart` — [NEW] Settings data model (toMap/fromMap)
- **FILE-006**: `lib/data/models/city_model.dart` — [NEW] City data model (toMap/fromMap)
- **FILE-007**: `lib/data/datasources/settings_local_data_source.dart` — [NEW] Settings SQLite operations
- **FILE-008**: `lib/data/datasources/city_local_data_source.dart` — [NEW] City SQLite operations
- **FILE-009**: `lib/data/repositories/settings_repository_impl.dart` — [NEW] SettingsRepository concrete implementation
- **FILE-010**: `lib/data/repositories/city_repository_impl.dart` — [NEW] CityRepository concrete implementation
- **FILE-011**: `test/data/models/settings_model_test.dart` — [NEW] Model conversion tests
- **FILE-012**: `test/data/models/city_model_test.dart` — [NEW] City model tests
- **FILE-013**: `test/data/repositories/settings_repository_impl_test.dart` — [NEW] Settings repo tests
- **FILE-014**: `test/data/repositories/city_repository_impl_test.dart` — [NEW] City repo tests
- **FILE-015**: `pubspec.yaml` — [MODIFY] Add equatable, crypto

## 6. Testing

- **TEST-001**: `SettingsModel.fromMap()` correctly maps all fields dari raw SQLite map
- **TEST-002**: `SettingsModel.toMap()` correctly converts entity ke SQLite-compatible map
- **TEST-003**: `SettingsModel` round-trip (fromMap → toMap → fromMap) identical
- **TEST-004**: `CityModel.fromMap()` / `toMap()` round-trip identical
- **TEST-005**: `getSettings()` returns default settings on fresh database
- **TEST-006**: `updateSettings()` updates only specified fields
- **TEST-007**: `completeFirstRun()` sets `is_first_run` to false
- **TEST-008**: PIN verification works (enabled dan disabled scenarios)
- **TEST-009**: `setPin()` hashes dan saves PIN correctly
- **TEST-010**: `getProvinces()` returns distinct sorted provinces
- **TEST-011**: `getCitiesByProvince()` returns correct filtered cities
- **TEST-012**: `searchCities()` performs case-insensitive search

**Test Command**: `flutter test test/data/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: Settings entity memiliki 30+ fields — bisa error mapping jika ada typo antara snake_case dan camelCase. Mitigasi: round-trip test memvalidasi completeness
- **RISK-002**: SHA-256 hashing tanpa salt — acceptable untuk PIN 6 digit offline-only, tapi bukan best practice untuk production auth. Mitigasi: documented sebagai known limitation
- **ASSUMPTION-001**: Plan 01 (DatabaseHelper) sudah selesai dan semua tests pass sebelum plan ini dimulai
- **ASSUMPTION-002**: `equatable` package kompatibel dengan Flutter version yang digunakan
- **ASSUMPTION-003**: Cities seed data sudah tersedia di `assets/data/cities.json` (dari Plan 01 TASK-017)

## 8. Related Specifications / Further Reading

- [SPEC-01: Database Schema & Data Layer](../spec/spec-schema-database.md) — Source specification §4.2-4.5
- Plan 01: `infrastructure-database-1.md` — Prerequisite (DatabaseHelper, schema)
- Plan 03-12: Semua plan selanjutnya — Consumer dari repository interfaces
- [Architecture Patterns Guide](../docs/ARCHITECTURE_PATTERNS.md) — Repository pattern details
