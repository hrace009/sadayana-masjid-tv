---
goal: "Implementasi State Evaluation — DisplayState Classes & EvaluateDisplayStateUseCase (Pure Function)"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, state-machine, evaluation, domain, use-case, display-state]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Plan ini mencakup implementasi **domain layer** untuk display state machine: definisi 5 display state classes (`StandbyState`, `PreAdzanState`, `AdzanState`, `IqomahState`, `SholatState`) dan `EvaluateDisplayStateUseCase` sebagai **pure function** yang menentukan state berdasarkan waktu sekarang dan prayer times.

Plan ini sengaja **dipisahkan dari Cubit** (Plan 08) agar business logic evaluasi state bisa di-test secara independen tanpa dependency ke timer atau Flutter framework.

**Source Specification**: [spec-process-state-machine.md](../spec/spec-process-state-machine.md) (SPEC-04 Part A)

## 1. Requirements & Constraints

- **REQ-001**: Aplikasi memiliki tepat 5 display states: STANDBY, PRE_ADZAN, ADZAN, IQOMAH, SHOLAT
- **REQ-002**: State evaluation harus deterministic — input yang sama selalu menghasilkan state yang sama
- **REQ-003**: `STANDBY` = state default ketika tidak ada event sholat aktif
- **REQ-004**: `PRE_ADZAN` = N menit sebelum waktu sholat (configurable, default: 10 menit)
- **REQ-005**: `ADZAN` = dimulai tepat pada waktu sholat, berlangsung N detik (configurable, default: 180 detik)
- **REQ-006**: `IQOMAH` = setelah ADZAN selesai, berlangsung N menit (configurable per sholat)
- **REQ-007**: `SHOLAT` = setelah IQOMAH selesai, berlangsung N menit (configurable, default: 20 menit)
- **REQ-008**: Setiap state harus menyimpan metadata: prayer name, remaining duration, progress percentage
- **REQ-009**: Transisi state mengikuti urutan strict: STANDBY → PRE_ADZAN → ADZAN → IQOMAH → SHOLAT → STANDBY
- **CON-001**: Use case harus pure function — tidak boleh maintain internal state, timer, atau side-effects
- **CON-002**: State classes harus extend `Equatable`
- **CON-003**: Syuruq dan Dhuha TIDAK memiliki cycle ADZAN/IQOMAH/SHOLAT — hanya informational display
- **GUD-001**: Setiap state class harus self-documenting (fields menjelaskan konteks state)
- **PAT-001**: Sealed class pattern untuk type-safe state matching

## 2. Implementation Steps

### Phase 1: Display State Type Enum

- GOAL-001: Mendefinisikan enum untuk 5 display states

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Buat file `lib/domain/entities/display_state_type.dart` — Enum `DisplayStateType` dengan values: `standby`, `preAdzan`, `adzan`, `iqomah`, `sholat` | ✅ | 2026-02-19 |

### Phase 2: Display State Classes

- GOAL-002: Mendefinisikan immutable state classes yang menyimpan semua data relevan untuk setiap display state

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-002 | Buat file `lib/domain/entities/display_state.dart` — Abstract sealed class `DisplayState` extends `Equatable`. Common field: `DisplayStateType type` (getter) | ✅ | 2026-02-19 |
| TASK-003 | Implementasi `StandbyState` extends `DisplayState`. Fields: `DailyPrayerTimes? dailyPrayerTimes` (nullable — mungkin belum loaded), `PrayerTime? nextPrayer` (sholat berikutnya), `Duration? timeToNextPrayer` (countdown ke sholat berikutnya), `String? runningText` (teks berjalan), `String? hijriDate`, `DateTime currentTime` | ✅ | 2026-02-19 |
| TASK-004 | Implementasi `PreAdzanState` extends `DisplayState`. Fields: `PrayerTime upcomingPrayer` (sholat yang akan datang), `Duration remainingDuration` (countdown ke waktu adzan), `int totalPreAdzanMinutes`, `DailyPrayerTimes dailyPrayerTimes` | ✅ | 2026-02-19 |
| TASK-005 | Implementasi `AdzanState` extends `DisplayState`. Fields: `PrayerTime currentPrayer`, `Duration remainingDuration` (countdown sampai adzan selesai), `int totalAdzanSeconds`, `DailyPrayerTimes dailyPrayerTimes` | ✅ | 2026-02-19 |
| TASK-006 | Implementasi `IqomahState` extends `DisplayState`. Fields: `PrayerTime currentPrayer`, `Duration remainingDuration` (countdown iqomah), `int totalIqomahMinutes`, `DailyPrayerTimes dailyPrayerTimes` | ✅ | 2026-02-19 |
| TASK-007 | Implementasi `SholatState` extends `DisplayState`. Fields: `PrayerTime currentPrayer`, `Duration remainingDuration` (countdown sholat), `int totalSholatMinutes`, `DailyPrayerTimes dailyPrayerTimes` | ✅ | 2026-02-19 |
| TASK-008 | Setiap timed state (PreAdzan, Adzan, Iqomah, Sholat) harus memiliki getter `double progress` yang menghitung `(total - remaining) / total` sebagai 0.0 → 1.0 | ✅ | 2026-02-19 |

### Phase 3: Transition Configuration Entity

- GOAL-003: Membuat entity yang menyimpan konfigurasi timing untuk state transitions

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-009 | Buat file `lib/domain/entities/transition_config.dart` — Class `TransitionConfig` (immutable) | ✅ | 2026-02-19 |
| TASK-010 | Fields: `int preAdzanMinutes` (default: 10), `int adzanDurationSeconds` (default: 180), `Map<String, int> iqomahMinutes` (per sholat: Subuh=15, Dzuhur=10, Ashar=10, Maghrib=5, Isya=10), `int sholatDurationMinutes` (default: 20) | ✅ | 2026-02-19 |
| TASK-011 | Tambahkan factory `TransitionConfig.fromSettings(Settings settings)` yang mapping settings fields ke configuration | ✅ | 2026-02-19 |

### Phase 4: EvaluateDisplayStateUseCase

- GOAL-004: Implementasi pure function use case yang mengevaluasi display state berdasarkan waktu sekarang

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-012 | Buat file `lib/domain/usecases/evaluate_display_state_use_case.dart` | ✅ | 2026-02-19 |
| TASK-013 | Implementasi `EvaluateDisplayStateUseCase` class. Tidak memiliki state — semua input diterima sebagai parameter | ✅ | 2026-02-19 |
| TASK-014 | Implementasi method utama `DisplayState evaluate({required DateTime now, required DailyPrayerTimes dailyPrayerTimes, required TransitionConfig config, String? runningText})` | ✅ | 2026-02-19 |
| TASK-015 | Logic evaluasi (dalam urutan prioritas): Untuk setiap sholat wajib (`mainPrayers` — Subuh, Dzuhur, Ashar, Maghrib, Isya): (1) Hitung `sholatEndTime` = prayerTime + adzanDuration + iqomahDuration + sholatDuration, (2) Hitung `preAdzanStartTime` = prayerTime - preAdzanMinutes, (3) Cek apakah `now` jatuh di salah satu window: PRE_ADZAN, ADZAN, IQOMAH, SHOLAT, (4) Jika ya → return state yang sesuai dengan `remainingDuration` dihitung | ✅ | 2026-02-19 |
| TASK-016 | Logic PRE_ADZAN: Jika `now` >= `preAdzanStartTime` DAN `now` < `prayerTime` → return `PreAdzanState` | ✅ | 2026-02-19 |
| TASK-017 | Logic ADZAN: Jika `now` >= `prayerTime` DAN `now` < `prayerTime + adzanDuration` → return `AdzanState` | ✅ | 2026-02-19 |
| TASK-018 | Logic IQOMAH: Jika `now` >= `adzanEndTime` DAN `now` < `adzanEndTime + iqomahDuration` → return `IqomahState` | ✅ | 2026-02-19 |
| TASK-019 | Logic SHOLAT: Jika `now` >= `iqomahEndTime` DAN `now` < `iqomahEndTime + sholatDuration` → return `SholatState` | ✅ | 2026-02-19 |
| TASK-020 | Default: Jika tidak ada window yang match → return `StandbyState` dengan `nextPrayer` = sholat berikutnya (dari `dailyPrayerTimes.nextPrayer(now)`) | ✅ | 2026-02-19 |

### Phase 5: Testing

- GOAL-005: Exhaustive unit tests untuk state evaluation logic

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-021 | Buat file `test/domain/entities/display_state_test.dart` | ✅ | 2026-02-19 |
| TASK-022 | TEST: Setiap state class memiliki correct `type` getter (StandbyState.type == DisplayStateType.standby, dll) | ✅ | 2026-02-19 |
| TASK-023 | TEST: Timed states `progress` getter returns 0.0 at start, 0.5 at midpoint, 1.0 at end | ✅ | 2026-02-19 |
| TASK-024 | TEST: `TransitionConfig.fromSettings()` correctly maps all settings fields | ✅ | 2026-02-19 |
| TASK-025 | Buat file `test/domain/usecases/evaluate_display_state_use_case_test.dart` | ✅ | 2026-02-19 |
| TASK-026 | TEST: `evaluate()` returns `StandbyState` when `now` is outside all prayer windows (e.g., 10:00 AM, between Dhuha and Dzuhur) | ✅ | 2026-02-19 |
| TASK-027 | TEST: `evaluate()` returns `PreAdzanState` when `now` is 5 minutes before Dzuhur (within preAdzan window) | ✅ | 2026-02-19 |
| TASK-028 | TEST: `evaluate()` returns `AdzanState` when `now` is exactly at Dzuhur prayer time | ✅ | 2026-02-19 |
| TASK-029 | TEST: `evaluate()` returns `IqomahState` when `now` is after adzan ends (prayerTime + adzanDuration + 1 second) | ✅ | 2026-02-19 |
| TASK-030 | TEST: `evaluate()` returns `SholatState` when `now` is after iqomah ends | ✅ | 2026-02-19 |
| TASK-031 | TEST: State transition sequence: STANDBY → PRE_ADZAN → ADZAN → IQOMAH → SHOLAT → STANDBY — simulate dengan advancing `now` melalui seluruh timeline satu sholat | ✅ | 2026-02-19 |
| TASK-032 | TEST: `StandbyState.nextPrayer` berisi sholat berikutnya yang benar | ✅ | 2026-02-19 |
| TASK-033 | TEST: `PreAdzanState.remainingDuration` menghitung countdown yang benar | ✅ | 2026-02-19 |
| TASK-034 | TEST: Syuruq dan Dhuha TIDAK menghasilkan ADZAN/IQOMAH/SHOLAT states | ✅ | 2026-02-19 |
| TASK-035 | Jalankan `flutter test test/domain/ --reporter=expanded` dan pastikan semua pass | ✅ | 2026-02-19 |

## 3. Alternatives

- **ALT-001**: Menggunakan state machine library (seperti `xstate`/`state_machine`) — Ditolak karena logikanya cukup sederhana (5 states, linear transitions) dan custom implementation memberikan kontrol penuh
- **ALT-002**: Menyatukan evaluation logic di dalam Cubit — Ditolak karena memisahkan evaluation sebagai pure function meningkatkan testability dan maintainability
- **ALT-003**: Menggunakan single state class dengan enum field — Ditolak karena sealed class pattern memberikan type-safe pattern matching dan setiap state memiliki fields berbeda

## 4. Dependencies

- **DEP-001**: `equatable` — Value equality untuk state classes (sudah added di Plan 02)
- **DEP-002**: Plan 05 `DailyPrayerTimes` entity — Input data untuk state evaluation
- **DEP-003**: Plan 05 `PrayerTime` entity — Individual prayer time data
- **DEP-004**: Plan 02 `Settings` entity — Sumber data untuk `TransitionConfig`

## 5. Files

- **FILE-001**: `lib/domain/entities/display_state_type.dart` — [NEW] DisplayStateType enum
- **FILE-002**: `lib/domain/entities/display_state.dart` — [NEW] Sealed display state classes
- **FILE-003**: `lib/domain/entities/transition_config.dart` — [NEW] Transition timing configuration
- **FILE-004**: `lib/domain/usecases/evaluate_display_state_use_case.dart` — [NEW] Pure evaluation function
- **FILE-005**: `test/domain/entities/display_state_test.dart` — [NEW] State class tests
- **FILE-006**: `test/domain/usecases/evaluate_display_state_use_case_test.dart` — [NEW] Evaluation tests

## 6. Testing

- **TEST-001**: Each state class has correct `type` getter
- **TEST-002**: `progress` getter returns correct 0.0-1.0 range
- **TEST-003**: `TransitionConfig.fromSettings()` maps correctly
- **TEST-004**: Returns `StandbyState` outside all prayer windows
- **TEST-005**: Returns `PreAdzanState` in pre-adzan window
- **TEST-006**: Returns `AdzanState` at exact prayer time
- **TEST-007**: Returns `IqomahState` after adzan
- **TEST-008**: Returns `SholatState` after iqomah
- **TEST-009**: Full cycle: STANDBY → PRE_ADZAN → ADZAN → IQOMAH → SHOLAT → STANDBY
- **TEST-010**: Syuruq/Dhuha don't trigger prayer cycle states

**Test Command**: `flutter test test/domain/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: Overlapping prayer windows — jika sholat back-to-back (Maghrib → Isya), iqomah/sholat window bisa overlap dengan pre-adzan berikutnya. Mitigasi: evaluasi dalam urutan kronologis, first match wins
- **RISK-002**: Edge case di exact boundary times — `now` tepat di titik transisi bisa non-deterministic. Mitigasi: gunakan inclusive start, exclusive end ( >= start, < end)
- **ASSUMPTION-001**: Plan 05 entities (`PrayerTime`, `DailyPrayerTimes`) sudah selesai
- **ASSUMPTION-002**: Plan 02 `Settings` entity sudah tersedia untuk `TransitionConfig.fromSettings()`
- **ASSUMPTION-003**: Timer precision cukup dalam orde detik (tidak perlu milidetik)

## 8. Related Specifications / Further Reading

- [SPEC-04: Display State Machine](../spec/spec-process-state-machine.md) — Source specification §3-5
- Plan 05: `feature-prayer-calculation-1.md` — Prerequisite (prayer time entities)
- Plan 08: `feature-display-state-machine-1.md` — Next plan yang membungkus ini dalam Cubit dengan timers
- [Architecture Patterns Guide](../docs/ARCHITECTURE_PATTERNS.md) — State machine patterns
