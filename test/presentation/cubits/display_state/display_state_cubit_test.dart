import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/domain/entities/daily_prayer_times.dart';
import 'package:miqotul_khoir_tv/domain/entities/display_state.dart';
import 'package:miqotul_khoir_tv/domain/entities/prayer_time.dart';
import 'package:miqotul_khoir_tv/domain/entities/settings.dart';
import 'package:miqotul_khoir_tv/domain/entities/transition_config.dart';
import 'package:miqotul_khoir_tv/domain/entities/wisdom_quote.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';
import 'package:miqotul_khoir_tv/domain/repositories/wisdom_quote_repository.dart';
import 'package:miqotul_khoir_tv/domain/usecases/evaluate_display_state_use_case.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/display_state/display_state.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/prayer_time/prayer_time.dart';

// Mocks
class MockEvaluateDisplayStateUseCase extends Mock
    implements EvaluateDisplayStateUseCase {}

class MockPrayerTimeCubit extends Mock implements PrayerTimeCubit {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockWisdomQuoteRepository extends Mock implements WisdomQuoteRepository {}

class MockDailyPrayerTimes extends Mock implements DailyPrayerTimes {}

class MockPrayerTime extends Mock implements PrayerTime {}

// Fakes
// Removed FakeDisplayState as DisplayState is sealed.

void main() {
  late EvaluateDisplayStateUseCase evaluateUseCase;
  late PrayerTimeCubit prayerTimeCubit;
  late SettingsRepository settingsRepository;
  late WisdomQuoteRepository wisdomQuoteRepository;
  late DailyPrayerTimes dailyPrayerTimes;
  late StreamController<PrayerTimeState> prayerTimeStreamController;

  setUpAll(() {
    registerFallbackValue(StandbyState(currentTime: DateTime.now()));
    registerFallbackValue(
      TransitionConfig(
        preAdzanMinutes: 10,
        adzanDurationSeconds: 180,
        sholatDurationMinutes: 15, // Aligned with Settings default
        iqomahMinutes: {},
      ),
    );

    // Create valid dummy data for fallbacks
    final dummyTime = DateTime.now();
    final dummyPT = PrayerTime(
      name: 'Subuh',
      time: dummyTime,
      originalTime: dummyTime,
      ihtiyatMinutes: 0,
    );

    final dummyDPT = DailyPrayerTimes(
      date: dummyTime,
      hijriDate: '',
      subuh: dummyPT,
      syuruq: dummyPT,
      dhuha: dummyPT,
      dzuhur: dummyPT,
      ashar: dummyPT,
      maghrib: dummyPT,
      isya: dummyPT,
    );

    registerFallbackValue(
      DailyPrayerTimes(
        date: dummyTime,
        hijriDate: '',
        subuh: dummyPT,
        syuruq: dummyPT,
        dhuha: dummyPT,
        dzuhur: dummyPT,
        ashar: dummyPT,
        maghrib: dummyPT,
        isya: dummyPT,
      ),
    );

    registerFallbackValue(
      PrayerTimeLoaded(dailyPrayerTimes: dummyDPT, lastCalculatedAt: dummyTime),
    );
    registerFallbackValue(PrayerTimeInitial());
  });

  int evaluateCallCount = 0;

  setUp(() {
    evaluateCallCount = 0;
    evaluateUseCase = MockEvaluateDisplayStateUseCase();
    prayerTimeCubit = MockPrayerTimeCubit();
    settingsRepository = MockSettingsRepository();
    wisdomQuoteRepository = MockWisdomQuoteRepository();
    dailyPrayerTimes = MockDailyPrayerTimes();
    prayerTimeStreamController = StreamController<PrayerTimeState>();

    // Default Mocks
    when(
      () => wisdomQuoteRepository.getByIds(any()),
    ).thenAnswer((_) async => const []);
    when(
      () => prayerTimeCubit.stream,
    ).thenAnswer((_) => prayerTimeStreamController.stream);
    when(() => prayerTimeCubit.state).thenReturn(PrayerTimeInitial());
    when(() => dailyPrayerTimes.hijriDate).thenReturn('');
    when(() => dailyPrayerTimes.date).thenReturn(DateTime.now());
    when(
      () => settingsRepository.getSettings(),
    ).thenAnswer((_) async => const Settings());

    // Default Evaluate Behavior with Counter
    when(
      () => evaluateUseCase.evaluate(
        now: any(named: 'now'),
        dailyPrayerTimes: any(named: 'dailyPrayerTimes'),
        config: any(named: 'config'),
        hijriDate: any(named: 'hijriDate'),
        activeQuotes: any(named: 'activeQuotes'),
      ),
    ).thenAnswer((invocation) {
      evaluateCallCount++;
      return StandbyState(currentTime: DateTime.now());
    });
  });

  tearDown(() {
    prayerTimeStreamController.close();
  });

  group('DisplayStateCubit', () {
    test('initial state is StandbyState', () {
      final cubit = DisplayStateCubit(
        evaluateUseCase: evaluateUseCase,
        prayerTimeCubit: prayerTimeCubit,
        settingsRepository: settingsRepository,
        wisdomQuoteRepository: wisdomQuoteRepository,
      );
      expect(cubit.state, isA<StandbyState>());
      cubit.close();
    });

    test('updates state when PrayerTimeCubit emits Loaded', () async {
      final cubit = DisplayStateCubit(
        evaluateUseCase: evaluateUseCase,
        prayerTimeCubit: prayerTimeCubit,
        settingsRepository: settingsRepository,
        wisdomQuoteRepository: wisdomQuoteRepository,
      );

      // Verify initialization
      await Future.delayed(const Duration(milliseconds: 50));
      verify(() => settingsRepository.getSettings()).called(1);

      // Emit PrayerTimeLoaded
      final newState = StandbyState(currentTime: DateTime.now());
      when(
        () => evaluateUseCase.evaluate(
          now: any(named: 'now'),
          dailyPrayerTimes: any(named: 'dailyPrayerTimes'),
          config: any(named: 'config'),
          hijriDate: any(named: 'hijriDate'),
          activeQuotes: any(named: 'activeQuotes'),
        ),
      ).thenReturn(newState);

      // Fix: Named arguments
      prayerTimeStreamController.add(
        PrayerTimeLoaded(
          dailyPrayerTimes: dailyPrayerTimes,
          lastCalculatedAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(cubit.state, isA<StandbyState>());
      cubit.close();
    });

    test('tick timer triggers regular evaluation', () async {
      final cubit = DisplayStateCubit(
        evaluateUseCase: evaluateUseCase,
        prayerTimeCubit: prayerTimeCubit,
        settingsRepository: settingsRepository,
        wisdomQuoteRepository: wisdomQuoteRepository,
      );

      // Verify initialization
      await Future.delayed(const Duration(milliseconds: 50));

      // Pre-load prayer times
      prayerTimeStreamController.add(
        PrayerTimeLoaded(
          dailyPrayerTimes: dailyPrayerTimes,
          lastCalculatedAt: DateTime.now(),
        ),
      );

      // Allow listener to fire & initial tick
      await Future.delayed(const Duration(milliseconds: 50));

      // Initial call count check
      expect(
        evaluateCallCount,
        greaterThan(0),
        reason: 'Should evaluate immediately upon data load',
      );
      final initialCount = evaluateCallCount;

      // Advance 2 seconds (real time)
      await Future.delayed(const Duration(milliseconds: 2100));

      // Should be called roughly 2 more times
      expect(
        evaluateCallCount,
        greaterThan(initialCount + 1),
        reason: 'Should evaluate periodically',
      );

      cubit.close();
    });

    test('onAppPaused stops the timer', () async {
      final cubit = DisplayStateCubit(
        evaluateUseCase: evaluateUseCase,
        prayerTimeCubit: prayerTimeCubit,
        settingsRepository: settingsRepository,
        wisdomQuoteRepository: wisdomQuoteRepository,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Load data
      prayerTimeStreamController.add(
        PrayerTimeLoaded(
          dailyPrayerTimes: dailyPrayerTimes,
          lastCalculatedAt: DateTime.now(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Pause
      cubit.onAppPaused();

      // Reset logic: capture current count
      final countBeforePause = evaluateCallCount;

      // Advance 2 seconds
      await Future.delayed(const Duration(milliseconds: 2000));

      // Should NOT increase count
      expect(
        evaluateCallCount,
        equals(countBeforePause),
        reason: 'Timer should be paused',
      );

      cubit.close();
    });

    test('onAppResumed restarts the timer and evaluates immediately', () async {
      final cubit = DisplayStateCubit(
        evaluateUseCase: evaluateUseCase,
        prayerTimeCubit: prayerTimeCubit,
        settingsRepository: settingsRepository,
        wisdomQuoteRepository: wisdomQuoteRepository,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      prayerTimeStreamController.add(
        PrayerTimeLoaded(
          dailyPrayerTimes: dailyPrayerTimes,
          lastCalculatedAt: DateTime.now(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      cubit.onAppPaused();

      final countBeforeResume = evaluateCallCount;

      // Resume
      cubit.onAppResumed();

      // Should evaluate immediately
      expect(
        evaluateCallCount,
        greaterThan(countBeforeResume),
        reason: 'Should evaluate immediately on resume',
      );

      final countAfterResume = evaluateCallCount;

      // Advance 1.1 second -> should evaluate again
      await Future.delayed(const Duration(milliseconds: 1100));
      expect(
        evaluateCallCount,
        greaterThan(countAfterResume),
        reason: 'Timer should resume ticking',
      );

      cubit.close();
    });

    test('onSettingsChanged reloads config and re-evaluates', () async {
      final cubit = DisplayStateCubit(
        evaluateUseCase: evaluateUseCase,
        prayerTimeCubit: prayerTimeCubit,
        settingsRepository: settingsRepository,
        wisdomQuoteRepository: wisdomQuoteRepository,
      );

      // Verify initialization
      await Future.delayed(const Duration(milliseconds: 50));

      // Emit PrayerTimeLoaded so that _tick has data to work with
      prayerTimeStreamController.add(
        PrayerTimeLoaded(
          dailyPrayerTimes: dailyPrayerTimes,
          lastCalculatedAt: DateTime.now(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final countBeforeChange = evaluateCallCount;
      expect(countBeforeChange, greaterThan(0));

      // Simulate Settings Change
      await cubit.onSettingsChanged();

      // Verify Config Reloaded & Tick Called
      verify(() => settingsRepository.getSettings()).called(2); // Init + Change

      // Check if evaluate was called AGAIN
      expect(
        evaluateCallCount,
        greaterThan(countBeforeChange),
        reason: 'Should evaluate again after settings change',
      );

      cubit.close();
    });

    test('loads wisdomQuoteRepository.getByIds saat init()', () async {
      // Verifikasi bahwa _loadConfig memanggil wisdomQuoteRepository.getByIds dengan
      // settings.wisdomSelectedIds (default = [] → getByIds([]) dipanggil)
      final cubit = DisplayStateCubit(
        evaluateUseCase: evaluateUseCase,
        prayerTimeCubit: prayerTimeCubit,
        settingsRepository: settingsRepository,
        wisdomQuoteRepository: wisdomQuoteRepository,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Default settings.wisdomSelectedIds = [] → getByIds([]) harus dipanggil
      verify(() => wisdomQuoteRepository.getByIds(any())).called(1);

      cubit.close();
    });

    test(
      '_tick meneruskan activeQuotes ke evaluate saat WisdomQuoteRepository menyediakan data',
      () async {
        final wisdomQuote = const WisdomQuote(
          id: 'quran_001',
          type: 'quran',
          label: 'Ayat Al-Quran',
          translationText:
              'Karena sesungguhnya bersama kesulitan ada kemudahan.',
          reference: 'QS. Al-Insyirah [94]: 6',
        );

        // Stub settings dengan wisdomSelectedIds non-kosong
        const settingsWithWisdom = Settings(
          isWisdomEnabled: true,
          wisdomSelectedIds: ['quran_001'],
          wisdomIntervalMinutes: 15,
          wisdomDurationMinutes: 3,
          wisdomStartHour: 6,
          wisdomStartMinute: 0,
          wisdomEndHour: 21,
          wisdomEndMinute: 0,
        );

        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => settingsWithWisdom);
        when(
          () => wisdomQuoteRepository.getByIds(['quran_001']),
        ).thenAnswer((_) async => [wisdomQuote]);

        // evaluate tetap return StandbyState — kita hanya verifikasi argument passing
        int callsWithWisdom = 0;
        when(
          () => evaluateUseCase.evaluate(
            now: any(named: 'now'),
            dailyPrayerTimes: any(named: 'dailyPrayerTimes'),
            config: any(named: 'config'),
            hijriDate: any(named: 'hijriDate'),
            activeQuotes: any(named: 'activeQuotes'),
          ),
        ).thenAnswer((invocation) {
          final quotes =
              invocation.namedArguments[const Symbol('activeQuotes')]
                  as List<WisdomQuote>?;
          if (quotes != null && quotes.isNotEmpty) callsWithWisdom++;
          evaluateCallCount++;
          return StandbyState(currentTime: DateTime.now());
        });

        final cubit = DisplayStateCubit(
          evaluateUseCase: evaluateUseCase,
          prayerTimeCubit: prayerTimeCubit,
          settingsRepository: settingsRepository,
          wisdomQuoteRepository: wisdomQuoteRepository,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Emit PrayerTimeLoaded agar _tick dipanggil
        prayerTimeStreamController.add(
          PrayerTimeLoaded(
            dailyPrayerTimes: dailyPrayerTimes,
            lastCalculatedAt: DateTime.now(),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify getByIds dipanggil dengan ids yang benar
        verify(() => wisdomQuoteRepository.getByIds(['quran_001'])).called(1);

        // evaluate seharusnya dipanggil dengan activeQuotes non-kosong
        expect(
          callsWithWisdom,
          greaterThan(0),
          reason: 'evaluate harus menerima activeQuotes yang berisi 1 item',
        );

        cubit.close();
      },
    );
  });
}
