import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state.dart';
import 'package:miqotul_khoir_tv/domain/entities/slideshow_image.dart';
import 'package:miqotul_khoir_tv/domain/entities/transition_config.dart';
import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';
import 'package:miqotul_khoir_tv/domain/repositories/slideshow_image_repository.dart';
import 'package:miqotul_khoir_tv/domain/repositories/wisdom_quote_repository.dart';
import 'package:miqotul_khoir_tv/domain/usecases/evaluate_display_state_use_case.dart';
import 'package:miqotul_khoir_tv/domain/services/audio_alert_service.dart';
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
  final WisdomQuoteRepository _wisdomQuoteRepository;
  final SlideshowImageRepository _slideshowImageRepository;
  final AudioAlertService _audioAlertService;

  StreamSubscription? _prayerTimeSubscription;
  Timer? _tickTimer;

  DailyPrayerTimes? _currentPrayerTimes;
  TransitionConfig _currentConfig;
  List<WisdomQuote> _activeQuotes = const [];
  List<SlideshowImage> _activeSlideshowImages = const [];

  bool _preAdzanAlertFired = false;
  bool _preIqomahAlertFired = false;

  DisplayStateCubit({
    required EvaluateDisplayStateUseCase evaluateUseCase,
    required PrayerTimeCubit prayerTimeCubit,
    required SettingsRepository settingsRepository,
    required WisdomQuoteRepository wisdomQuoteRepository,
    required SlideshowImageRepository slideshowImageRepository,
    required AudioAlertService audioAlertService,
  }) : _evaluateUseCase = evaluateUseCase,
       _prayerTimeCubit = prayerTimeCubit,
       _settingsRepository = settingsRepository,
       _wisdomQuoteRepository = wisdomQuoteRepository,
       _slideshowImageRepository = slideshowImageRepository,
       _audioAlertService = audioAlertService,
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
    _activeQuotes = await _wisdomQuoteRepository.getByIds(
      settings.wisdomSelectedIds,
    );
    _activeSlideshowImages = await _slideshowImageRepository.getAll();
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

    final previous = state;
    final newState = _evaluateUseCase.evaluate(
      now: DateTime.now(),
      dailyPrayerTimes: dailyPrayerTimes,
      config: _currentConfig,
      hijriDate: dailyPrayerTimes.hijriDate,
      activeQuotes: _activeQuotes,
      slideshowImages: _activeSlideshowImages,
    );

    _checkAlertStop(previous, newState);
    emit(newState);
    _checkAlertTrigger(newState);
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

  /// Menghentikan alarm jika state bertransisi keluar dari PreAdzan atau Iqomah,
  /// dan me-reset flag agar siklus berikutnya dapat membunyikan alarm kembali.
  void _checkAlertStop(DisplayState previous, DisplayState next) {
    if (previous is PreAdzanState && next is! PreAdzanState) {
      _audioAlertService.stopAlert();
      _preAdzanAlertFired = false;
    }
    if (previous is IqomahState && next is! IqomahState) {
      _audioAlertService.stopAlert();
      _preIqomahAlertFired = false;
    }
  }

  /// Membunyikan alarm satu kali saat threshold waktu tercapai dan toggle aktif.
  void _checkAlertTrigger(DisplayState newState) {
    if (newState is PreAdzanState &&
        !_preAdzanAlertFired &&
        _currentConfig.isPreAdzanAlertEnabled &&
        newState.remainingDuration.inSeconds <=
            _currentConfig.preAdzanAlertSeconds) {
      _audioAlertService.playAlert();
      _preAdzanAlertFired = true;
    } else if (newState is IqomahState &&
        !_preIqomahAlertFired &&
        _currentConfig.isPreIqomahAlertEnabled &&
        newState.remainingDuration.inSeconds <=
            _currentConfig.preIqomahAlertSeconds) {
      _audioAlertService.playAlert();
      _preIqomahAlertFired = true;
    }
  }

  @override
  Future<void> close() {
    _stopTickTimer();
    _prayerTimeSubscription?.cancel();
    _audioAlertService.stopAlert();
    _audioAlertService.dispose();
    return super.close();
  }
}
