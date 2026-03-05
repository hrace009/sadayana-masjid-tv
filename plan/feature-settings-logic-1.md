---
goal: "Implementasi Settings Logic — SettingsCubit, Auto-Save Mechanism, PIN Hash/Verify"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-20
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, settings, cubit, auto-save, pin, logic, content-management]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Plan ini mencakup implementasi **business logic** untuk settings dan content management: `SettingsCubit` yang mengelola state settings, mekanisme auto-save (save ke database setiap kali value berubah), PIN protection logic (hash, verify, enable/disable), dan callback notification ke cubits lain saat settings berubah. Plan ini **tidak mencakup UI** (itu di Plan 12).

**Source Specification**: [spec-process-settings.md](../spec/spec-process-settings.md) (SPEC-06 Part A)

## 1. Requirements & Constraints

- **REQ-001**: Setiap perubahan settings harus langsung disimpan ke database (auto-save)
- **REQ-002**: Settings menu harus dilindungi PIN (opsional, bisa di-enable/disable)
- **REQ-003**: PIN disimpan sebagai SHA-256 hash, bukan plaintext
- **REQ-004**: Perubahan settings Ihtiyat dan lokasi harus trigger recalculation prayer times
- **REQ-005**: Perubahan settings iqomah/sholat duration harus update TransitionConfig
- **REQ-006**: Running text bisa diubah kapan saja
- **REQ-007**: Settings state harus merefleksikan database state saat loaded
- **CON-001**: Menggunakan Cubit, bukan Bloc
- **CON-002**: Auto-save harus debounced — tidak save setiap keystroke, tapi setelah user berhenti input (500ms delay)
- **GUD-001**: Setiap update settings harus menampilkan success feedback ke UI (brief visual confirmation)
- **GUD-002**: Settings loading state saat pertama kali buka menu
- **PAT-001**: Debounce pattern untuk text input auto-save
- **PAT-002**: State pattern: Initial → Loading → Loaded → Saving → Loaded

## 2. Implementation Steps

### Phase 1: SettingsCubit States

- GOAL-001: Mendefinisikan states untuk settings management

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat file `lib/presentation/cubits/settings/settings_state.dart` | ✅ | 2026-02-20 |
| TASK-002 | Implementasi state classes: `SettingsState` (abstract, Equatable) → `SettingsInitial`, `SettingsLoading`, `SettingsLoaded({Settings settings, bool isSaving = false, String? lastSavedField})`, `SettingsError({String message, Settings? lastKnownSettings})` | ✅ | 2026-02-20 |
| TASK-003 | `SettingsLoaded` harus memiliki `copyWith()` untuk update `isSaving` dan `lastSavedField` tanpa reload seluruh settings | ✅ | 2026-02-20 |

### Phase 2: SettingsCubit Implementation

- GOAL-002: Membuat Cubit dengan auto-save, debounce, dan PIN management

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-004 | Buat file `lib/presentation/cubits/settings/settings_cubit.dart` | ✅ | 2026-02-20 |
| TASK-005 | Implementasi `SettingsCubit extends Cubit<SettingsState>`. Constructor menerima: `SettingsRepository`, `PrayerTimeCubit` (untuk trigger recalculation), `DisplayStateCubit` (untuk trigger config update). Initial state: `SettingsInitial()` | ✅ | 2026-02-20 |
| TASK-006 | Implementasi `Future<void> loadSettings()`: emit `SettingsLoading()` → call `settingsRepository.getSettings()` → emit `SettingsLoaded(settings)`. Panggil di init | ✅ | 2026-02-20 |
| TASK-007 | Implementasi private `Timer? _debounceTimer` dan `void _debounceSave(String field, Map<String, dynamic> updates)`: cancel existing timer → start new timer (500ms) → call `_saveField()` | ✅ | 2026-02-20 |
| TASK-008 | Implementasi private `Future<void> _saveField(String field, Map<String, dynamic> updates)`: emit `SettingsLoaded(isSaving: true)` → call `settingsRepository.updateSettings(updates)` → reload settings → emit `SettingsLoaded(settings, isSaving: false, lastSavedField: field)` | ✅ | 2026-02-20 |

### Phase 3: Individual Setting Update Methods

- GOAL-003: Membuat method untuk setiap setting category

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-009 | Implementasi `void updateIhtiyatOffset(String prayerName, int minutes)`: validate offset ∈ [-30, 30] → `_debounceSave()` → setelah save, panggil `prayerTimeCubit.recalculate()` | ✅ | 2026-02-20 |
| TASK-010 | Implementasi `void updateIqomahDuration(String prayerName, int minutes)`: validate minutes ∈ [1, 30] → `_debounceSave()` → setelah save, panggil `displayStateCubit.onSettingsChanged()` | ✅ | 2026-02-20 |
| TASK-011 | Implementasi `void updateDhuhaOffset(int minutes)`: validate ∈ [10, 30] → `_debounceSave()` → trigger recalculation | ✅ | 2026-02-20 |
| TASK-012 | Implementasi `void updatePreAdzanMinutes(int minutes)`: validate ∈ [5, 30] → `_debounceSave()` → trigger config update | ✅ | 2026-02-20 |
| TASK-013 | Implementasi `void updateSholatDuration(int minutes)`: validate ∈ [10, 45] → `_debounceSave()` → trigger config update | ✅ | 2026-02-20 |
| TASK-014 | Implementasi `void updateAdzanDuration(int seconds)`: validate ∈ [60, 600] → `_debounceSave()` → trigger config update | ✅ | 2026-02-20 |
| TASK-015 | Implementasi `void updateRunningText(String text)`: `_debounceSave()` — no additional triggers needed | ✅ | 2026-02-20 |
| TASK-016 | Implementasi `void updateHijriAdjustment(int days)`: validate ∈ [-2, 2] → `_debounceSave()` → trigger recalculation | ✅ | 2026-02-20 |

### Phase 4: PIN Management

- GOAL-004: implementasi PIN protection logic

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-017 | Implementasi `Future<bool> verifyPin(String inputPin)`: call `settingsRepository.verifyPin(inputPin)` — return true/false | ✅ | 2026-02-20 |
| TASK-018 | Implementasi `Future<void> setPin(String newPin)`: call `settingsRepository.setPin(newPin)` → reload settings | ✅ | 2026-02-20 |
| TASK-019 | Implementasi `Future<void> removePin()`: call `settingsRepository.setPin('')` → reload settings (empty hash = disabled) | ✅ | 2026-02-20 |
| TASK-020 | Implementasi `bool get isPinEnabled`: check dari current settings state `settings.settingsPinHash.isNotEmpty` | ✅ | 2026-02-20 |

### Phase 5: Dispose & Cleanup

- GOAL-005: Resource cleanup

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-021 | Override `Future<void> close()`: cancel `_debounceTimer`, call `super.close()` | ✅ | 2026-02-20 |

### Phase 6: Barrel Export

- GOAL-006: Clean imports

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-022 | Buat file `lib/presentation/cubits/settings/settings.dart` — barrel export | ✅ | 2026-02-20 |

### Phase 7: Testing

- GOAL-007: Unit tests untuk SettingsCubit

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-023 | Buat file `test/presentation/cubits/settings/settings_cubit_test.dart` — Setup: mock repositories dan cubits | ✅ | 2026-02-20 |
| TASK-024 | TEST: Initial state is `SettingsInitial` | ✅ | 2026-02-20 |
| TASK-025 | TEST: `loadSettings()` emits `[Loading, Loaded]` with correct settings data | ✅ | 2026-02-20 |
| TASK-026 | TEST: `updateIhtiyatOffset('subuh', 2)` calls repository with `{'offset_subuh': 2}` and triggers prayer recalculation | ✅ | 2026-02-20 |
| TASK-027 | TEST: Auto-save debounce — multiple rapid calls only result in single save (use fake timers) | ✅ | 2026-02-20 |
| TASK-028 | TEST: `updateIhtiyatOffset('subuh', 35)` validates and rejects offset > 30 | ✅ | 2026-02-20 |
| TASK-029 | TEST: `updateIqomahDuration('subuh', 15)` saves and triggers display state config update | ✅ | 2026-02-20 |
| TASK-030 | TEST: `updateRunningText('Selamat datang')` saves without triggering other cubits | ✅ | 2026-02-20 |
| TASK-031 | TEST: `verifyPin('123456')` returns true when PIN matches, false otherwise | ✅ | 2026-02-20 |
| TASK-032 | TEST: `setPin('123456')` calls repository and reloads settings | ✅ | 2026-02-20 |
| TASK-033 | TEST: `removePin()` calls `setPin('')` and PIN becomes disabled | ✅ | 2026-02-20 |
| TASK-034 | TEST: `close()` cancels debounce timer | ✅ | 2026-02-20 |
| TASK-035 | Jalankan `flutter test test/presentation/cubits/settings/ --reporter=expanded` | ✅ | 2026-02-20 |

## 3. Alternatives

- **ALT-001**: Manual save button instead of auto-save — Ditolak karena menambah friction di D-Pad UX, user harus navigate ke save button setiap kali
- **ALT-002**: Using `SharedPreferences` for temporary settings — Ditolak karena SQLite sudah cukup dan menghindari multiple sources of truth
- **ALT-003**: Stream-based settings reactive updates — Ditolak karena Cubit pattern sudah cukup, settings jarang berubah (tidak perlu real-time stream)

## 4. Dependencies

- **DEP-001**: Plan 02 `SettingsRepository` — Data persistence
- **DEP-002**: Plan 02 `Settings` entity — Data model
- **DEP-003**: Plan 06 `PrayerTimeCubit` — Trigger recalculation
- **DEP-004**: Plan 08 `DisplayStateCubit` — Trigger config update
- **DEP-005**: `flutter_bloc`, `bloc_test`, `mocktail` — Already added

## 5. Files

- **FILE-001**: `lib/presentation/cubits/settings/settings_state.dart` — [NEW] States
- **FILE-002**: `lib/presentation/cubits/settings/settings_cubit.dart` — [NEW] Cubit
- **FILE-003**: `lib/presentation/cubits/settings/settings.dart` — [NEW] Barrel
- **FILE-004**: `test/presentation/cubits/settings/settings_cubit_test.dart` — [NEW] Tests

## 6. Testing

- **TEST-001**: Correct initial and loading states
- **TEST-002**: Settings load from repository
- **TEST-003**: Auto-save with debounce works correctly
- **TEST-004**: Ihtiyat update triggers prayer recalculation
- **TEST-005**: Iqomah update triggers display state config update
- **TEST-006**: Running text update doesn't trigger other cubits
- **TEST-007**: Validation rejects out-of-range values
- **TEST-008**: PIN verify/set/remove flow works
- **TEST-009**: Timer cleanup on close

**Test Command**: `flutter test test/presentation/cubits/settings/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: Debounce timer mungkin miss save jika user close settings terlalu cepat — Mitigasi: force-save pending changes di `close()` sebelum cancel timer
- **RISK-002**: Cross-cubit communication (SettingsCubit → PrayerTimeCubit) bisa cause circular dependency — Mitigasi: inject via constructor, one-way dependency
- **ASSUMPTION-001**: Plan 02, 06, 08 sudah selesai
- **ASSUMPTION-002**: Settings changes yang memerlukan recalculation tidak sering terjadi (low frequency)

## 8. Related Specifications / Further Reading

- [SPEC-06: Settings & Content Management](../spec/spec-process-settings.md) — Source specification
- Plan 02: `feature-data-layer-1.md` — Prerequisite (SettingsRepository)
- Plan 06, 08: Prayer & Display Cubits — Cross-cubit notification targets
- Plan 12: `feature-settings-ui-1.md` — Next plan (UI layer)
