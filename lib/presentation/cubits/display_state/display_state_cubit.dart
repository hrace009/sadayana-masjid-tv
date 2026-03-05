import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state.dart';
import 'package:miqotul_khoir_tv/domain/entities/transition_config.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';
import 'package:miqotul_khoir_tv/domain/usecases/evaluate_display_state_use_case.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/prayer_time/prayer_time.dart';

/// Cubit yang mengelola [DisplayState] aplikasi (Standby, Adzan, Sholat, dll).
///
/// Logic:
/// 1. Listen ke [PrayerTimeCubit] untuk mendapatkan jadwal sholat terbaru.
/// 2. Jalankan [_tickTimer] setiap detik untuk evaluasi ulang state via [EvaluateDisplayStateUseCase].
/// 3. Handle App Lifecycle (Pause/Resume) untuk hemat resource & power recovery logic.
class DisplayStateCubit extends Cubit<DisplayState> {
  final EvaluateDisplayStateUseCase _evaluateUseCase;
  final PrayerTimeCubit _prayerTimeCubit;
  final SettingsRepository _settingsRepository;

  StreamSubscription? _prayerTimeSubscription;
  Timer? _tickTimer;

  DailyPrayerTimes? _currentPrayerTimes;
  TransitionConfig _currentConfig;

  DisplayStateCubit({
    required EvaluateDisplayStateUseCase evaluateUseCase,
    required PrayerTimeCubit prayerTimeCubit,
    required SettingsRepository settingsRepository,
  }) : _evaluateUseCase = evaluateUseCase,
       _prayerTimeCubit = prayerTimeCubit,
       _settingsRepository = settingsRepository,
       // Default config, akan di-overwrite saat init()
       _currentConfig = const TransitionConfig(
         preAdzanMinutes: 10,
         adzanDurationSeconds: 180,
         sholatDurationMinutes: 10,
         iqomahMinutes: {}, // Fallback handled in TransitionConfig
       ),
       super(StandbyState(currentTime: DateTime.now())) {
    init();
  }

  /// Inisialisasi cubit: load settings, start subscriptions & timer.
  Future<void> init() async {
    // 1. Load Settings & Config
    await _loadConfig();

    // 2. Subscribe ke PrayerTimeCubit
    _prayerTimeSubscription = _prayerTimeCubit.stream.listen((prayerState) {
      if (prayerState is PrayerTimeLoaded) {
        _currentPrayerTimes = prayerState.dailyPrayerTimes;
        // Trigger immediate tick saat jadwal sholat berubah
        _tick();
      }
    });

    // Initial check jika PrayerTimeCubit sudah loaded
    if (_prayerTimeCubit.state is PrayerTimeLoaded) {
      _currentPrayerTimes =
          (_prayerTimeCubit.state as PrayerTimeLoaded).dailyPrayerTimes;
    }

    // 3. Start Tick Timer
    _startTickTimer();
  }

  Future<void> _loadConfig() async {
    final settings = await _settingsRepository.getSettings();
    _currentConfig = TransitionConfig.fromSettings(settings);
  }

  void _startTickTimer() {
    _tickTimer?.cancel();
    // Jalankan tick pertama immediately, lalu periodic 1 detik
    _tick();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  /// Core loop: Evaluasi state berdasarkan waktu sekarang.
  void _tick() {
    final dailyPrayerTimes = _currentPrayerTimes;
    if (dailyPrayerTimes == null) {
      // Belum ada data jadwal sholat, tetap di Standby (atau initial state)
      return;
    }

    final newState = _evaluateUseCase.evaluate(
      now: DateTime.now(),
      dailyPrayerTimes: dailyPrayerTimes,
      config: _currentConfig,
      hijriDate: dailyPrayerTimes.hijriDate,
    );

    // Smart Emit: Hanya emit jika ada perubahan yang relevan
    // Note: Untuk countdown (PreAdzan, Adzan, Iqomah, Sholat),
    // remainingDuration berubah setiap detik, jadi kita perlu emit terus.
    // Optimization: Bisa cek jika duration changes only seconds, tapi UI butuh itu.
    emit(newState);
  }

  // --- App Lifecycle Handlers (Dipanggil dari UI/Observer) ---

  void onAppPaused() {
    _stopTickTimer();
  }

  void onAppResumed() {
    // Power Recovery Logic:
    // Saat resume, waktu sistem sudah berubah.
    // _tick() akan menggunakan DateTime.now() terbaru -> otomatis correct state.
    _startTickTimer();
  }

  Future<void> onSettingsChanged() async {
    await _loadConfig();
    _tick(); // Immediate re-evaluation dengan config baru
  }

  @override
  Future<void> close() {
    _stopTickTimer();
    _prayerTimeSubscription?.cancel();
    return super.close();
  }
}
