---
goal: "Implementasi PrayerTimeCubit — State Management, Midnight Recalculation Timer, Error Handling"
version: 1.0
date_created: 2026-02-18
last_updated: 2026-02-18
owner: "Gulajava Ministudio"
status: 'Completed'
tags: [feature, prayer-time, cubit, state-management, timer, presentation]
---

# Introduction

![Status: Completed](https://img.shields.io/badge/status-Completed-green)

Plan ini mencakup implementasi `PrayerTimeCubit` yang membungkus `CalculatePrayerTimesUseCase` dalam reactive state management. Cubit ini bertanggung jawab untuk: mengelola state loading/loaded/error, auto-recalculation saat midnight (00:00), dan menyediakan `DailyPrayerTimes` ke semua widget consumer.

**Source Specification**: [spec-process-prayer-time.md](../spec/spec-process-prayer-time.md) (SPEC-03 Part B)

## 1. Requirements & Constraints

- **REQ-001**: `PrayerTimeCubit` harus auto-calculate prayer times saat initialized
- **REQ-002**: Prayer times harus di-recalculate otomatis setiap midnight (00:00) untuk hari baru
- **REQ-003**: State harus menampilkan loading indicator saat kalkulasi sedang berlangsung
- **REQ-004**: Error state harus menyimpan pesan error yang informatif
- **REQ-005**: Cubit harus menyediakan method untuk force-recalculate (trigger dari settings change)
- **CON-001**: Menggunakan `Cubit` dari `flutter_bloc`, bukan `Bloc` (sesuai GEMINI.md)
- **CON-002**: Timer harus di-dispose di `close()` untuk mencegah memory leak
- **CON-003**: State harus extend `Equatable` untuk efficient rebuild
- **GUD-001**: Midnight timer harus menghitung exact duration sampai 00:00:01 berikutnya, bukan interval fixed
- **PAT-001**: State pattern: Initial → Loading → Loaded / Error
- **PAT-002**: Timer lifecycle: create di init, cancel di close

## 2. Implementation Steps

### Phase 1: Package Dependencies

- GOAL-001: Menambahkan flutter_bloc package

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Jalankan `flutter pub add flutter_bloc` — State management (Cubit/Bloc) | ✅ | 2026-02-19 |
| TASK-002 | Jalankan `flutter pub get` | ✅ | 2026-02-19 |

### Phase 2: PrayerTimeCubit States

- GOAL-002: Mendefinisikan semua possible states untuk PrayerTimeCubit

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-003 | Buat file `lib/presentation/cubits/prayer_time/prayer_time_state.dart` | ✅ | 2026-02-19 |
| TASK-004 | Implementasi sealed class hierarchy: `PrayerTimeState` (abstract, extends `Equatable`) → `PrayerTimeInitial`, `PrayerTimeLoading`, `PrayerTimeLoaded({DailyPrayerTimes dailyPrayerTimes})`, `PrayerTimeError({String message})` | ✅ | 2026-02-19 |
| TASK-005 | `PrayerTimeLoaded` harus mengandung semua info: `DailyPrayerTimes dailyPrayerTimes`, `DateTime lastCalculatedAt` | ✅ | 2026-02-19 |

### Phase 3: PrayerTimeCubit Implementation

- GOAL-003: Implementasi Cubit dengan kalkulasi, midnight timer, dan error handling

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-006 | Buat file `lib/presentation/cubits/prayer_time/prayer_time_cubit.dart` | ✅ | 2026-02-19 |
| TASK-007 | Implementasi `PrayerTimeCubit extends Cubit<PrayerTimeState>`. Constructor menerima `CalculatePrayerTimesUseCase`. State awal: `PrayerTimeInitial()` | ✅ | 2026-02-19 |
| TASK-008 | Implementasi `Future<void> loadPrayerTimes({DateTime? date})`: emit `PrayerTimeLoading()` → panggil `useCase.execute(date: date)` → emit `PrayerTimeLoaded(result, DateTime.now())` | ✅ | 2026-02-19 |
| TASK-009 | Wrap `execute()` dalam try-catch: jika exception → emit `PrayerTimeError(e.toString())` | ✅ | 2026-02-19 |
| TASK-010 | Implementasi `void _startMidnightTimer()`: hitung `Duration` sampai 00:00:01 besok → `Timer(duration, () { loadPrayerTimes(); _startMidnightTimer(); })`. Simpan reference di `Timer? _midnightTimer` | ✅ | 2026-02-19 |
| TASK-011 | Panggil `loadPrayerTimes()` dan `_startMidnightTimer()` di constructor atau via `init()` method | ✅ | 2026-02-19 |
| TASK-012 | Implementasi `Future<void> recalculate()` — public method untuk force recalculation (dipanggil saat settings berubah). Panggil `loadPrayerTimes()` dan restart midnight timer | ✅ | 2026-02-19 |
| TASK-013 | Override `Future<void> close()`: cancel `_midnightTimer`, lalu `super.close()` | ✅ | 2026-02-19 |

### Phase 4: Barrel Export Files

- GOAL-004: Membuat barrel exports untuk clean imports

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-014 | Buat file `lib/presentation/cubits/prayer_time/prayer_time.dart` — barrel export yang mengekspor `prayer_time_cubit.dart` dan `prayer_time_state.dart` | ✅ | 2026-02-19 |

### Phase 5: Testing

- GOAL-005: Unit tests untuk PrayerTimeCubit

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-015 | Tambahkan dev dependency: `flutter pub add dev:bloc_test` dan `flutter pub add dev:mocktail` | ✅ | 2026-02-19 |
| TASK-016 | Buat file `test/presentation/cubits/prayer_time/prayer_time_cubit_test.dart` | ✅ | 2026-02-19 |
| TASK-017 | Setup: `MockCalculatePrayerTimesUseCase` (extends Mock), create mock `DailyPrayerTimes` test data | ✅ | 2026-02-19 |
| TASK-018 | TEST: Initial state is `PrayerTimeInitial` | ✅ | 2026-02-19 |
| TASK-019 | TEST: `loadPrayerTimes()` emits `[PrayerTimeLoading, PrayerTimeLoaded]` when use case succeeds — gunakan `blocTest()` dari `bloc_test` package | ✅ | 2026-02-19 |
| TASK-020 | TEST: `loadPrayerTimes()` emits `[PrayerTimeLoading, PrayerTimeError]` when use case throws exception | ✅ | 2026-02-19 |
| TASK-021 | TEST: `PrayerTimeLoaded` mengandung valid `DailyPrayerTimes` dan `lastCalculatedAt` | ✅ | 2026-02-19 |
| TASK-022 | TEST: `recalculate()` re-emits loading and loaded states | ✅ | 2026-02-19 |
| TASK-023 | TEST: `close()` cancels midnight timer (verify no further emissions after close) | ✅ | 2026-02-19 |
| TASK-024 | Jalankan `flutter test test/presentation/cubits/prayer_time/ --reporter=expanded` | ✅ | 2026-02-19 |

## 3. Alternatives

- **ALT-001**: Menggunakan `StreamController` manual tanpa Cubit — Ditolak karena Cubit memberikan structured state management, testability via `blocTest`, dan DevTools integration
- **ALT-002**: Menggunakan `ChangeNotifier` (Provider) — Ditolak sesuai GEMINI.md: semua state management harus menggunakan Cubit
- **ALT-003**: Menggunakan periodic timer (setiap 1 jam) instead of midnight timer — Ditolak karena tidak efisien dan prayer times hanya perlu diupdate sekali per hari

## 4. Dependencies

- **DEP-001**: `flutter_bloc` (^8.1.0) — Cubit state management
- **DEP-002**: `bloc_test` (^9.1.0) — dev dependency, testing utilities untuk Cubit
- **DEP-003**: `mocktail` (^1.0.0) — dev dependency, mocking framework
- **DEP-004**: Plan 05 `CalculatePrayerTimesUseCase` — Use case yang di-wrap oleh Cubit
- **DEP-005**: Plan 05 `DailyPrayerTimes` entity — Data yang disimpan dalam state

## 5. Files

- **FILE-001**: `lib/presentation/cubits/prayer_time/prayer_time_state.dart` — [NEW] Cubit states
- **FILE-002**: `lib/presentation/cubits/prayer_time/prayer_time_cubit.dart` — [NEW] Cubit implementation
- **FILE-003**: `lib/presentation/cubits/prayer_time/prayer_time.dart` — [NEW] Barrel export
- **FILE-004**: `pubspec.yaml` — [MODIFY] Add flutter_bloc, bloc_test, mocktail
- **FILE-005**: `test/presentation/cubits/prayer_time/prayer_time_cubit_test.dart` — [NEW] Tests

## 6. Testing

- **TEST-001**: Initial state is `PrayerTimeInitial`
- **TEST-002**: Successful load emits `[Loading, Loaded]` sequence
- **TEST-003**: Failed load emits `[Loading, Error]` sequence
- **TEST-004**: `PrayerTimeLoaded` contains valid data
- **TEST-005**: `recalculate()` triggers new load cycle
- **TEST-006**: `close()` properly cancels midnight timer

**Test Command**: `flutter test test/presentation/cubits/prayer_time/ --reporter=expanded`

## 7. Risks & Assumptions

- **RISK-001**: Midnight timer drift — `Timer` mungkin tidak 100% akurat untuk exact midnight. Mitigasi: target 00:00:01 (1 detik setelah midnight) untuk safety margin
- **RISK-002**: Cubit `emit()` called after `close()` — Mitigasi: check `isClosed` sebelum emit dalam async callbacks
- **ASSUMPTION-001**: Plan 05 `CalculatePrayerTimesUseCase` sudah selesai dan tested
- **ASSUMPTION-002**: `flutter_bloc` package stabil di versi terbaru
- **ASSUMPTION-003**: `bloc_test` package kompatibel dengan `flutter_bloc` version yang digunakan

## 8. Related Specifications / Further Reading

- [SPEC-03: Prayer Time Calculation](../spec/spec-process-prayer-time.md) — Source specification §5 (Cubit)
- Plan 05: `feature-prayer-calculation-1.md` — Prerequisite (use case, entities)
- Plan 07: `feature-state-evaluation-1.md` — Consumer (needs prayer times to evaluate display state)
- [flutter_bloc Documentation](https://bloclibrary.dev/) — Cubit patterns and best practices
