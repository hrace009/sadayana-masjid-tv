---
goal: "Implementasi Setup Wizard Logic — SetupWizardCubit, Data Entity, Validation Rules, Step Navigation"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-20
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, setup-wizard, cubit, logic, validation, first-run]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Plan ini mencakup implementasi **business logic** untuk setup wizard (first-run experience): `SetupWizardCubit` yang mengelola state multi-step wizard, entity `SetupWizardData` untuk menyimpan data sementara selama setup, validation rules untuk setiap step, dan logic navigasi antar step. Plan ini **tidak mencakup UI** (itu di Plan 10).

**Source Specification**: [spec-process-setup-wizard.md](../spec/spec-process-setup-wizard.md) (SPEC-05 Part A)

## 1. Requirements & Constraints

- **REQ-001**: Setup wizard tampil otomatis saat `is_first_run = true` (pertama kali app dibuka)
- **REQ-002**: Wizard memiliki 4 langkah: Welcome → Identity (Nama Masjid) → Location (Pilih Kota) → Preview
- **REQ-003**: User dapat navigasi maju (next) dan mundur (back) antar step
- **REQ-004**: Data wizard disimpan sementara di memory selama proses setup
- **REQ-005**: Pada step terakhir (Preview), semua data disimpan ke database dan `is_first_run` diubah ke false
- **REQ-006**: Setiap step memiliki validation rule sebelum bisa lanjut ke step berikutnya
- **CON-001**: Menggunakan Cubit, bukan Bloc
- **CON-002**: Wizard data TIDAK di-persist selama proses berlangsung — jika app crash mid-setup, wizard ulang dari awal
- **GUD-001**: Step index 0-based: 0=Welcome, 1=Identity, 2=Location, 3=Preview
- **GUD-002**: Validasi Identity: `mosqueName` minimal 3 karakter
- **GUD-003**: Validasi Location: `cityName`, `latitude`, `longitude` harus terisi (tidak kosong/0)
- **PAT-001**: Wizard pattern: linear multi-step with back/next navigation

## 2. Implementation Steps

### Phase 1: SetupWizardData Entity

- GOAL-001: Membuat entity untuk menyimpan data wizard sementara

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat file `lib/domain/entities/setup_wizard_data.dart` — Class `SetupWizardData` (immutable, Equatable) | ✅ | 2026-02-20 |
| TASK-002 | Fields: `String mosqueName` (default: ''), `String mosqueAddress` (default: ''), `String cityName` (default: ''), `String provinceName` (default: ''), `double latitude` (default: 0.0), `double longitude` (default: 0.0), `String timezone` (default: 'Asia/Jakarta'), `String calculationMethod` (default: 'kemenag') | ✅ | 2026-02-20 |
| TASK-003 | Implementasi `copyWith()` method untuk update individual fields | ✅ | 2026-02-20 |
| TASK-004 | Implementasi `bool get isIdentityValid` → `mosqueName.length >= 3` | ✅ | 2026-02-20 |
| TASK-005 | Implementasi `bool get isLocationValid` → `cityName.isNotEmpty && latitude != 0.0 && longitude != 0.0` | ✅ | 2026-02-20 |
| TASK-006 | Implementasi `bool get isComplete` → `isIdentityValid && isLocationValid` | ✅ | 2026-02-20 |

### Phase 2: SetupWizardCubit States

- GOAL-002: Mendefinisikan states untuk wizard navigation

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-007 | Buat file `lib/presentation/cubits/setup_wizard/setup_wizard_state.dart` | ✅ | 2026-02-20 |
| TASK-008 | Implementasi state classes: `SetupWizardState` (abstract, Equatable) → `SetupWizardInProgress({int currentStep, SetupWizardData data, int totalSteps = 4, String? validationError})`, `SetupWizardCompleting` (loading saat menyimpan), `SetupWizardCompleted` (selesai, navigate ke home), `SetupWizardError({String message})` | ✅ | 2026-02-20 |
| TASK-009 | `SetupWizardInProgress` harus memiliki getter `bool get canGoNext` → depends on currentStep validation, `bool get canGoBack` → `currentStep > 0`, `double get progress` → `(currentStep + 1) / totalSteps` | ✅ | 2026-02-20 |

### Phase 3: SetupWizardCubit Implementation

- GOAL-003: Membuat Cubit dengan step navigation, validation, dan data persistence

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-010 | Buat file `lib/presentation/cubits/setup_wizard/setup_wizard_cubit.dart` | ✅ | 2026-02-20 |
| TASK-011 | Implementasi `SetupWizardCubit extends Cubit<SetupWizardState>`. Constructor menerima `SettingsRepository`. Initial state: `SetupWizardInProgress(currentStep: 0, data: SetupWizardData())` | ✅ | 2026-02-20 |
| TASK-012 | Implementasi `void goToNextStep()`: validate current step → jika valid, emit state dengan `currentStep + 1` → jika step terakhir (3), panggil `_completeSetup()` | ✅ | 2026-02-20 |
| TASK-013 | Implementasi `void goToPreviousStep()`: jika `currentStep > 0`, emit state dengan `currentStep - 1` | ✅ | 2026-02-20 |
| TASK-014 | Implementasi `void updateMosqueName(String name)`: update `data.mosqueName` via `copyWith()`, emit updated state, clear validationError | ✅ | 2026-02-20 |
| TASK-015 | Implementasi `void updateMosqueAddress(String address)`: update `data.mosqueAddress` | ✅ | 2026-02-20 |
| TASK-016 | Implementasi `void selectCity(City city)`: update `data.cityName`, `data.provinceName`, `data.latitude`, `data.longitude` dari City entity | ✅ | 2026-02-20 |
| TASK-017 | Implementasi `Future<void> _completeSetup()`: emit `SetupWizardCompleting` → call `settingsRepository.updateSettings({...all wizard data...})` → call `settingsRepository.completeFirstRun()` → emit `SetupWizardCompleted`. Wrap in try-catch → `SetupWizardError` jika gagal | ✅ | 2026-02-20 |
| TASK-018 | Implementasi private `bool _validateCurrentStep()`: step 0 (Welcome) → always valid, step 1 (Identity) → `data.isIdentityValid`, step 2 (Location) → `data.isLocationValid`, step 3 (Preview) → `data.isComplete` | ✅ | 2026-02-20 |

### Phase 4: Barrel Export

- GOAL-004: Clean import structure

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-019 | Buat file `lib/presentation/cubits/setup_wizard/setup_wizard.dart` — barrel export | ✅ | 2026-02-20 |

### Phase 5: Testing

- GOAL-005: Unit tests untuk wizard logic

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-020 | Buat file `test/domain/entities/setup_wizard_data_test.dart` | ✅ | 2026-02-20 |
| TASK-021 | TEST: `isIdentityValid` returns false for name < 3 chars, true for >= 3 chars | ✅ | 2026-02-20 |
| TASK-022 | TEST: `isLocationValid` returns false for empty city/zero coordinates, true when populated | ✅ | 2026-02-20 |
| TASK-023 | TEST: `isComplete` returns true only when both identity and location are valid | ✅ | 2026-02-20 |
| TASK-024 | TEST: `copyWith()` updates only specified fields | ✅ | 2026-02-20 |
| TASK-025 | Buat file `test/presentation/cubits/setup_wizard/setup_wizard_cubit_test.dart` — Setup: mock SettingsRepository | ✅ | 2026-02-20 |
| TASK-026 | TEST: Initial state is `SetupWizardInProgress(currentStep: 0)` | ✅ | 2026-02-20 |
| TASK-027 | TEST: `goToNextStep()` from step 0 (Welcome) → emits step 1 (always valid, no data needed) | ✅ | 2026-02-20 |
| TASK-028 | TEST: `goToNextStep()` from step 1 with invalid mosqueName (< 3 chars) → emits state with `validationError` | ✅ | 2026-02-20 |
| TASK-029 | TEST: `goToNextStep()` from step 1 with valid mosqueName → emits step 2 | ✅ | 2026-02-20 |
| TASK-030 | TEST: `selectCity(city)` updates data with city coordinates | ✅ | 2026-02-20 |
| TASK-031 | TEST: `goToNextStep()` from step 2 with valid location → emits step 3 (Preview) | ✅ | 2026-02-20 |
| TASK-032 | TEST: `goToNextStep()` from step 3 → emits `[SetupWizardCompleting, SetupWizardCompleted]` and calls repository | ✅ | 2026-02-20 |
| TASK-033 | TEST: `goToPreviousStep()` from step 2 → emits step 1 | ✅ | 2026-02-20 |
| TASK-034 | TEST: `goToPreviousStep()` from step 0 → no change (can't go back) | ✅ | 2026-02-20 |
| TASK-035 | TEST: `_completeSetup()` error → emits `SetupWizardError` | ✅ | 2026-02-20 |
| TASK-036 | Jalankan `flutter test test/presentation/cubits/setup_wizard/ --reporter=expanded` | ✅ | 2026-02-20 |

## 3. Alternatives

- **ALT-001**: Menggunakan `PageController` tanpa Cubit — Ditolak karena wizard membutuhkan validation dan data management yang lebih complex dari sekedar page navigation
- **ALT-002**: Persisting wizard data mid-setup — Ditolak karena menambah complexity dan setup wizard seharusnya selesai dalam satu sesi
- **ALT-003**: Single-page form instead of multi-step wizard — Ditolak karena terlalu banyak input fields, wizard memberikan better UX untuk first-time setup

## 4. Dependencies

- **DEP-001**: Plan 02 `SettingsRepository` — Save wizard data ke database
- **DEP-002**: Plan 02 `City` entity — City selection data
- **DEP-003**: Plan 02 `CityRepository` — City search functionality (used di UI, tapi Cubit menerima City object)
- **DEP-004**: `flutter_bloc` — Already added in Plan 06
- **DEP-005**: `equatable` — Already added in Plan 02

## 5. Files

- **FILE-001**: `lib/domain/entities/setup_wizard_data.dart` — [NEW] Wizard data entity
- **FILE-002**: `lib/presentation/cubits/setup_wizard/setup_wizard_state.dart` — [NEW] Cubit states
- **FILE-003**: `lib/presentation/cubits/setup_wizard/setup_wizard_cubit.dart` — [NEW] Cubit implementation
- **FILE-004**: `lib/presentation/cubits/setup_wizard/setup_wizard.dart` — [NEW] Barrel export
- **FILE-005**: `test/domain/entities/setup_wizard_data_test.dart` — [NEW] Entity tests
- **FILE-006**: `test/presentation/cubits/setup_wizard/setup_wizard_cubit_test.dart` — [NEW] Cubit tests

## 6. Testing

- **TEST-001**: `SetupWizardData` validation rules (identity, location, complete)
- **TEST-002**: `copyWith()` partial update
- **TEST-003**: Initial state correct
- **TEST-004**: Step navigation forward (valid data)
- **TEST-005**: Step navigation forward (invalid data → validation error)
- **TEST-006**: City selection updates data
- **TEST-007**: Complete setup flow → saves to repository
- **TEST-008**: Step navigation backward
- **TEST-009**: Error handling during save

**Test Command**: `flutter test test/presentation/cubits/setup_wizard/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: User mungkin keluar app mid-wizard — data hilang. Mitigasi: documented behavior, wizard restart dari awal
- **RISK-002**: City selection depends on cities data availability — jika seed belum complete, location step error. Mitigasi: Plan 01 ensures cities seeded
- **ASSUMPTION-001**: Plan 01 (Database + seed) dan Plan 02 (Repositories) sudah selesai
- **ASSUMPTION-002**: Wizard selalu dimulai dari step 0 (tidak support resume)
- **ASSUMPTION-003**: Maximum 4 steps cukup untuk initial setup

## 8. Related Specifications / Further Reading

- [SPEC-05: Setup Wizard](../spec/spec-process-setup-wizard.md) — Source specification
- Plan 02: `feature-data-layer-1.md` — Prerequisite (SettingsRepository, CityRepository)
- Plan 10: `feature-setup-wizard-ui-1.md` — Next plan yang membangun UI di atas Cubit ini
