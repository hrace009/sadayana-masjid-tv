---
goal: "Implementasi Display State Machine Cubit — Tick Timer, State Transitions, Power Recovery Logic"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
status: 'Planned'
tags: [feature, state-machine, cubit, timer, display, transitions, recovery]
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

Plan ini mencakup implementasi `DisplayStateCubit` yang menggunakan `EvaluateDisplayStateUseCase` (Plan 07) untuk menentukan state display secara real-time. Cubit ini mengelola **tick timer** (1-second interval) untuk re-evaluate state setiap detik, menangani transisi otomatis, dan menyediakan power recovery logic untuk melanjutkan state yang benar setelah app restart.

**Source Specification**: [spec-process-state-machine.md](../spec/spec-process-state-machine.md) (SPEC-04 Part B)

## 1. Requirements & Constraints

- **REQ-001**: Display state harus di-evaluate ulang setiap 1 detik menggunakan periodic timer
- **REQ-002**: Setiap kali state berubah (transisi), Cubit harus emit state baru
- **REQ-003**: Setelah power loss/app restart, Cubit harus recovery ke state yang benar berdasarkan waktu sekarang
- **REQ-004**: Timer harus di-stop saat app di-pause dan di-resume saat app kembali aktif
- **REQ-005**: Cubit harus listen ke `PrayerTimeCubit` untuk mendapatkan `DailyPrayerTimes` terbaru
- **REQ-006**: Cubit harus listen ke `SettingsRepository` perubahan untuk update `TransitionConfig`
- **CON-001**: Menggunakan `Cubit` bukan `Bloc` (sesuai GEMINI.md)
- **CON-002**: Tick timer interval: tetap 1 detik — tidak adaptive
- **CON-003**: Timer harus di-cancel di `close()`
- **GUD-001**: Emit state baru hanya jika state type benar-benar berubah (avoid redundant rebuilds)
- **GUD-002**: Log setiap state transition untuk debugging
- **PAT-001**: Timer lifecycle pattern: create → pause → resume → cancel
- **PAT-002**: Observer pattern: listen ke PrayerTimeCubit stream

## 2. Implementation Steps

## Implementation Status
- [x] Phase 1: Logic Implementation
- [x] Phase 2: Testing & Verification
- [x] Phase 3: Documentation

**Status:** ✅ COMPLETED
**Date:** 2026-02-19

### Phase 1: DisplayStateCubit Implementation

- GOAL-001: Membuat Cubit yang mengelola display state dengan tick timer

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat file `lib/presentation/cubits/display_state/display_state_cubit.dart` | | |
| TASK-002 | Implementasi `DisplayStateCubit extends Cubit<DisplayState>`. Constructor menerima: `EvaluateDisplayStateUseCase evaluateUseCase`, `PrayerTimeCubit prayerTimeCubit`, `SettingsRepository settingsRepository`. Initial state: `StandbyState(currentTime: DateTime.now())` | | |
| TASK-003 | Implementasi `Timer? _tickTimer` — periodic timer yang memanggil `_tick()` setiap 1 detik | | |
| TASK-004 | Implementasi `void _tick()`: panggil `evaluateUseCase.evaluate(now: DateTime.now(), dailyPrayerTimes: _currentPrayerTimes, config: _currentConfig)`. Jika result berbeda dari current state type → emit result. Update `_currentDisplayState` | | |
| TASK-005 | Implementasi `StreamSubscription? _prayerTimeSubscription` yang listen ke `prayerTimeCubit.stream`. Saat `PrayerTimeLoaded` diterima → update `_currentPrayerTimes` dan trigger immediate `_tick()` | | |
| TASK-006 | Implementasi `Future<void> init()`: (1) Load settings untuk `TransitionConfig`, (2) Subscribe ke PrayerTimeCubit, (3) Start tick timer. Panggil di constructor atau setelah construction | | |
| TASK-007 | Implementasi smart emit di `_tick()`: compare `newState.runtimeType` dengan `state.runtimeType`. Hanya emit jika berbeda ATAU jika `remainingDuration` berubah signifikan (setiap detik untuk countdown update) | | |
| TASK-008 | Tambahkan `void _startTickTimer()`: `_tickTimer = Timer.periodic(Duration(seconds: 1), (_) => _tick())` | | |
| TASK-009 | Tambahkan `void _stopTickTimer()`: `_tickTimer?.cancel(); _tickTimer = null` | | |

### Phase 2: App Lifecycle Handling

- GOAL-002: Handle app pause/resume untuk timer management dan power recovery

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-010 | Implementasi `void onAppPaused()`: stop tick timer untuk hemat resource saat app di-background | | |
| TASK-011 | Implementasi `void onAppResumed()`: (1) Re-evaluate state immediately via `_tick()`, (2) Restart tick timer. Ini juga berfungsi sebagai power recovery — state akan otomatis correct berdasarkan `DateTime.now()` | | |
| TASK-012 | Di consumer widget level (nanti Plan 10/12), integrasikan dengan `WidgetsBindingObserver.didChangeAppLifecycleState` yang memanggil `onAppPaused()`/`onAppResumed()` | | |

### Phase 3: Settings Update Handling

- GOAL-003: Handle perubahan settings yang mempengaruhi transition config

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-013 | Implementasi `Future<void> onSettingsChanged()`: (1) Reload settings dari repository, (2) Update `_currentConfig` via `TransitionConfig.fromSettings()`, (3) Trigger immediate `_tick()` | | |

### Phase 4: Dispose & Cleanup

- GOAL-004: Proper resource cleanup saat Cubit di-close

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-014 | Override `Future<void> close()`: (1) Cancel `_tickTimer`, (2) Cancel `_prayerTimeSubscription`, (3) Call `super.close()` | | |

### Phase 5: Barrel Export

- GOAL-005: Clean import structure

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-015 | Buat file `lib/presentation/cubits/display_state/display_state.dart` — barrel export untuk cubit | | |

### Phase 6: Testing

- GOAL-006: Unit tests untuk DisplayStateCubit

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-016 | Buat file `test/presentation/cubits/display_state/display_state_cubit_test.dart` | | |
| TASK-017 | Setup: Mock `EvaluateDisplayStateUseCase`, mock `PrayerTimeCubit`, mock `SettingsRepository`. Buat test data `DailyPrayerTimes` dan `TransitionConfig` | | |
| TASK-018 | TEST: Initial state is `StandbyState` | | |
| TASK-019 | TEST: Cubit emits correct state when PrayerTimeCubit emits `PrayerTimeLoaded` | | |
| TASK-020 | TEST: Tick timer triggers state evaluation every second (verify via fake timer / `fakeAsync`) | | |
| TASK-021 | TEST: `onAppResumed()` re-evaluates state immediately and restarts timer | | |
| TASK-022 | TEST: `onAppPaused()` stops tick timer | | |
| TASK-023 | TEST: `onSettingsChanged()` updates TransitionConfig and re-evaluates | | |
| TASK-024 | TEST: `close()` cancels both timer and subscription (no further emissions) | | |
| TASK-025 | TEST: Power recovery — create Cubit at time T (during IQOMAH window) → initial evaluation returns `IqomahState` | | |
| TASK-026 | Jalankan `flutter test test/presentation/cubits/display_state/ --reporter=expanded` | | |

## 3. Alternatives

- **ALT-001**: Menggunakan `Stream.periodic` instead of `Timer.periodic` — Ditolak karena `Timer.periodic` lebih straightforward dan easier to cancel/restart
- **ALT-002**: Adaptive tick interval (faster during transitions, slower during standby) — Ditolak untuk simplicity, 1-second fixed interval sudah cukup untuk countdown display
- **ALT-003**: Menyimpan last state ke database untuk power recovery — Ditolak karena state bisa di-recalculate dari `DateTime.now()` + prayer times, tidak perlu persist

## 4. Dependencies

- **DEP-001**: Plan 07 `EvaluateDisplayStateUseCase` — Pure evaluation function
- **DEP-002**: Plan 07 `DisplayState` classes — State types yang di-emit
- **DEP-003**: Plan 07 `TransitionConfig` — Timing configuration
- **DEP-004**: Plan 06 `PrayerTimeCubit` — Source of prayer times data
- **DEP-005**: Plan 02 `SettingsRepository` — Source of transition config
- **DEP-006**: `flutter_bloc`, `bloc_test`, `mocktail` — Already added in Plan 06

## 5. Files

- **FILE-001**: `lib/presentation/cubits/display_state/display_state_cubit.dart` — [NEW] DisplayStateCubit
- **FILE-002**: `lib/presentation/cubits/display_state/display_state.dart` — [NEW] Barrel export
- **FILE-003**: `test/presentation/cubits/display_state/display_state_cubit_test.dart` — [NEW] Tests

## 6. Testing

- **TEST-001**: Initial state is `StandbyState`
- **TEST-002**: Correct state emitted when PrayerTimeCubit provides data
- **TEST-003**: Tick timer triggers evaluation every second
- **TEST-004**: `onAppResumed()` recovery works correctly
- **TEST-005**: `onAppPaused()` stops timer
- **TEST-006**: Settings change updates config
- **TEST-007**: `close()` cleans up all resources
- **TEST-008**: Power recovery evaluates correct state from current time

**Test Command**: `flutter test test/presentation/cubits/display_state/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: 1-second tick timer bisa cause performance issues di low-end Android TV jika evaluation logic terlalu heavy — Mitigasi: evaluation logic sudah pure function (Plan 07), sangat ringan
- **RISK-002**: Timer drift over time — accumulative small delays. Mitigasi: timer always uses `DateTime.now()` instead of tracking elapsed time
- **RISK-003**: Race condition antara PrayerTimeCubit update dan tick timer — Mitigasi: semua updates melalui single `_tick()` entry point
- **ASSUMPTION-001**: Plan 06 `PrayerTimeCubit` dan Plan 07 `EvaluateDisplayStateUseCase` sudah selesai dan tested
- **ASSUMPTION-002**: `fakeAsync` dari `package:fake_async` tersedia untuk timer testing
- **ASSUMPTION-003**: Android TV tidak aggressively kill background timer (app tetap foreground sebagai digital signage)

## 8. Related Specifications / Further Reading

- [SPEC-04: Display State Machine](../spec/spec-process-state-machine.md) — Source specification §5-6
- Plan 07: `feature-state-evaluation-1.md` — Prerequisite (evaluation logic)
- Plan 06: `feature-prayer-cubit-1.md` — Prerequisite (prayer times source)
- [Architecture Patterns Guide](../docs/ARCHITECTURE_PATTERNS.md) — Timer management patterns
