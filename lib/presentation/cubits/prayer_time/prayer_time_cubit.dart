import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/usecases/calculate_prayer_times_use_case.dart';
import 'prayer_time_state.dart';

/// Cubit untuk mengelola state jadwal sholat.
/// Mengupdate jadwal otomatis setiap hari (midnight).
class PrayerTimeCubit extends Cubit<PrayerTimeState> {
  final CalculatePrayerTimesUseCase _useCase;
  Timer? _midnightTimer;

  PrayerTimeCubit(this._useCase) : super(PrayerTimeInitial()) {
    // Gunakan microtask agar stream listener (bloc_test) sempat subscribe
    // sebelum emit pertama (Loading) terjadi.
    Future.microtask(() => loadPrayerTimes());
  }

  /// Memuat jadwal sholat untuk tanggal [date].
  /// Jika [date] null, menggunakan hari ini.
  Future<void> loadPrayerTimes({DateTime? date}) async {
    // Hindari emit loading jika sudah loaded?
    // Spec bilang: Loading indicator saat kalkulasi sedang berlangsung.
    // Jika ganti hari, loading sebentar wajar.
    emit(PrayerTimeLoading());

    try {
      final result = await _useCase.execute(date: date);

      if (isClosed) return;

      emit(
        PrayerTimeLoaded(
          dailyPrayerTimes: result,
          lastCalculatedAt: DateTime.now(),
        ),
      );

      // Pastikan timer jalan untuk update besok
      _startMidnightTimer();
    } catch (e) {
      if (isClosed) return;
      emit(PrayerTimeError(e.toString()));
    }
  }

  /// Memaksa kalkulasi ulang (misal: setelah settings berubah).
  Future<void> recalculate() async {
    // Cancel timer lama agar tidak dobel
    _midnightTimer?.cancel();
    await loadPrayerTimes();
  }

  /// Menjadwalkan update otomatis pada pukul 00:00:01 hari berikutnya.
  void _startMidnightTimer() {
    _midnightTimer?.cancel();

    final now = DateTime.now();
    // Besok = H+1
    final tomorrow = now.add(const Duration(days: 1));
    // Target: Besok jam 00:00:01
    final nextMidnight = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      0,
      0,
      1,
    );

    final durationToWait = nextMidnight.difference(now);

    // Safety check: jika duration negatif (aneh), set minimal 1 detik
    final safeDuration = durationToWait.isNegative
        ? const Duration(seconds: 1)
        : durationToWait;

    _midnightTimer = Timer(safeDuration, () {
      // Trigger load untuk hari baru
      loadPrayerTimes();
      // Timer akan direstart di dalam loadPrayerTimes -> _startMidnightTimer
      // Tapi untuk safety, loadPrayerTimes memanggil _startMidnightTimer lagi.
    });
  }

  @override
  Future<void> close() {
    _midnightTimer?.cancel();
    return super.close();
  }
}
