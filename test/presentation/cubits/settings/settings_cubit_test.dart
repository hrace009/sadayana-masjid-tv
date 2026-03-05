import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/domain/entities/settings.dart';
import 'package:miqotul_khoir_tv/domain/repositories/settings_repository.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/display_state/display_state_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/prayer_time/prayer_time_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/settings/settings.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockPrayerTimeCubit extends Mock implements PrayerTimeCubit {}

class MockDisplayStateCubit extends Mock implements DisplayStateCubit {}

void main() {
  late SettingsRepository settingsRepository;
  late PrayerTimeCubit prayerTimeCubit;
  late DisplayStateCubit displayStateCubit;
  late SettingsCubit settingsCubit;

  final tSettings = const Settings(cityName: 'Bandung', offsetSubuh: 0);
  final tSettingsUpdated = const Settings(cityName: 'Bandung', offsetSubuh: 2);

  setUp(() {
    settingsRepository = MockSettingsRepository();
    prayerTimeCubit = MockPrayerTimeCubit();
    displayStateCubit = MockDisplayStateCubit();

    // Stub default untuk auto-loadSettings yang dipanggil di konstruktor SettingsCubit.
    // Tanpa stub ini, constructor crash karena getSettings() mengembalikan null.
    when(
      () => settingsRepository.getSettings(),
    ).thenAnswer((_) async => tSettings);

    settingsCubit = SettingsCubit(
      settingsRepository: settingsRepository,
      prayerTimeCubit: prayerTimeCubit,
      displayStateCubit: displayStateCubit,
    );
  });

  tearDown(() {
    settingsCubit.close();
  });

  test('auto-loads settings on creation → emits SettingsLoaded', () async {
    // SettingsCubit memanggil loadSettings() di constructor.
    // Tunggu microtask queue selesai agar hasil async tersedia.
    await Future.microtask(() {});
    expect(settingsCubit.state, isA<SettingsLoaded>());
  });

  blocTest<SettingsCubit, SettingsState>(
    'loadSettings emits [SettingsLoading, SettingsLoaded] when successful',
    build: () {
      when(
        () => settingsRepository.getSettings(),
      ).thenAnswer((_) async => tSettings);
      return settingsCubit;
    },
    act: (cubit) => cubit.loadSettings(),
    expect: () => [SettingsLoading(), SettingsLoaded(settings: tSettings)],
    verify: (_) {
      verify(
        () => settingsRepository.getSettings(),
      ).called(greaterThanOrEqualTo(1));
    },
  );

  blocTest<SettingsCubit, SettingsState>(
    'loadSettings emits [SettingsLoading, SettingsError] when repository throws',
    build: () {
      when(() => settingsRepository.getSettings()).thenThrow('Database error');
      return settingsCubit;
    },
    act: (cubit) => cubit.loadSettings(),
    expect: () => [
      SettingsLoading(),
      const SettingsError(message: 'Database error'),
    ],
  );

  group('Auto-save mechanics', () {
    blocTest<SettingsCubit, SettingsState>(
      'updateIhtiyatOffset debounces and triggers save + recalculate',
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettings);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        // Second getSettings return updated value
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettingsUpdated);

        when(() => prayerTimeCubit.recalculate()).thenAnswer((_) async {});

        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateIhtiyatOffset('Subuh', 2);
        // Wait for debounce (500ms) + buffer
        await Future.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        // 1. isSaving = true
        SettingsLoaded(settings: tSettings, isSaving: true),
        // 2. isSaving = false, new settings
        SettingsLoaded(
          settings: tSettingsUpdated,
          isSaving: false,
          lastSavedField: 'offset_subuh',
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.updateSettings({'offset_subuh': 2}),
        ).called(1);
        verify(() => prayerTimeCubit.recalculate()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'multiple rapid updates only trigger one save (debounce)',
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettingsUpdated);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});

        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateRunningText('A');
        await Future.delayed(const Duration(milliseconds: 100));
        cubit.updateRunningText('B');
        await Future.delayed(const Duration(milliseconds: 100));
        cubit.updateRunningText('C'); // Only this should persist
        await Future.delayed(const Duration(milliseconds: 600));
      },
      verify: (_) {
        verify(
          () => settingsRepository.updateSettings({'running_text': 'C'}),
        ).called(1);
        verifyNever(
          () => settingsRepository.updateSettings({'running_text': 'A'}),
        );
        verifyNever(
          () => settingsRepository.updateSettings({'running_text': 'B'}),
        );
      },
    );
  });

  group('PIN Management', () {
    test('verifyPin returns result from repository', () async {
      when(
        () => settingsRepository.verifyPin('1234'),
      ).thenAnswer((_) async => true);
      when(
        () => settingsRepository.verifyPin('0000'),
      ).thenAnswer((_) async => false);

      expect(await settingsCubit.verifyPin('1234'), true);
      expect(await settingsCubit.verifyPin('0000'), false);
    });

    blocTest<SettingsCubit, SettingsState>(
      'setPin calls repository and reloads settings',
      build: () {
        when(() => settingsRepository.setPin('1234')).thenAnswer((_) async {});
        when(() => settingsRepository.getSettings()).thenAnswer(
          (_) async => tSettings,
        ); // Pin hash update simulation skipped for brevity
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) => cubit.setPin('1234'),
      expect: () => [
        SettingsLoaded(settings: tSettings, isSaving: true),
        SettingsLoaded(settings: tSettings, isSaving: false),
      ],
      verify: (_) {
        verify(() => settingsRepository.setPin('1234')).called(1);
        verify(
          () => settingsRepository.getSettings(),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    test('isPinEnabled returns correctness based on settings', () {
      final settingsNoPin = const Settings(settingsPinHash: '');
      final settingsWithPin = const Settings(settingsPinHash: 'hashed_secret');

      settingsCubit.emit(SettingsLoaded(settings: settingsNoPin));
      expect(settingsCubit.isPinEnabled, false);

      settingsCubit.emit(SettingsLoaded(settings: settingsWithPin));
      expect(settingsCubit.isPinEnabled, true);
    });
  });

  group("Sholat Jum'at", () {
    blocTest<SettingsCubit, SettingsState>(
      "updateSholatJumatDuration menyimpan field dengan nilai valid (45 menit)",
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettings);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        when(
          () => displayStateCubit.onSettingsChanged(),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateSholatJumatDuration(45);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        SettingsLoaded(settings: tSettings, isSaving: true),
        SettingsLoaded(
          settings: tSettings,
          isSaving: false,
          lastSavedField: 'sholat_jumat_duration',
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.updateSettings({
            'sholat_jumat_duration_minutes': 45,
          }),
        ).called(1);
        verify(() => displayStateCubit.onSettingsChanged()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateSholatJumatDuration diabaikan jika nilai di luar range [10, 90]',
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettings);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateSholatJumatDuration(5); // terlalu kecil (< 10)
        cubit.updateSholatJumatDuration(95); // terlalu besar (> 90)
        await Future.delayed(const Duration(milliseconds: 600));
      },
      verify: (_) {
        verifyNever(() => settingsRepository.updateSettings(any()));
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      "updateIqomahDuration dengan nama Jum'at menggunakan "
      "DB key 'iqomah_jumat' (bukan 'iqomah_jum'at')",
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettings);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        when(
          () => displayStateCubit.onSettingsChanged(),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateIqomahDuration("Jum'at", 10);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        SettingsLoaded(settings: tSettings, isSaving: true),
        SettingsLoaded(
          settings: tSettings,
          isSaving: false,
          lastSavedField: 'iqomah_jumat',
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.updateSettings({'iqomah_jumat': 10}),
        ).called(1);
        verifyNever(
          () => settingsRepository.updateSettings({"iqomah_jum'at": 10}),
        );
      },
    );
  });

  group('Treasury Management', () {
    blocTest<SettingsCubit, SettingsState>(
      'updateTreasuryEnabled(true) menyimpan langsung (tanpa debounce)',
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettings);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) => cubit.updateTreasuryEnabled(true),
      expect: () => [
        SettingsLoaded(settings: tSettings, isSaving: true),
        SettingsLoaded(
          settings: tSettings,
          isSaving: false,
          lastSavedField: 'treasury_enabled',
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.updateSettings({'is_treasury_enabled': 1}),
        ).called(1);
        verifyNever(
          () => settingsRepository.updateSettings({'is_treasury_enabled': 0}),
        );
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateTreasuryEnabled(false) menyimpan nilai 0',
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettings);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) => cubit.updateTreasuryEnabled(false),
      verify: (_) {
        verify(
          () => settingsRepository.updateSettings({'is_treasury_enabled': 0}),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateTreasuryBalance menyimpan nilai valid setelah debounce',
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettings);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateTreasuryBalance(5000000);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        SettingsLoaded(settings: tSettings, isSaving: true),
        SettingsLoaded(
          settings: tSettings,
          isSaving: false,
          lastSavedField: 'treasury_balance',
        ),
      ],
      verify: (_) {
        verify(
          () =>
              settingsRepository.updateSettings({'treasury_balance': 5000000}),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateTreasuryIncome menyimpan nilai valid setelah debounce',
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettings);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateTreasuryIncome(2500000);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        SettingsLoaded(settings: tSettings, isSaving: true),
        SettingsLoaded(
          settings: tSettings,
          isSaving: false,
          lastSavedField: 'treasury_income',
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.updateSettings({'treasury_income': 2500000}),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateTreasuryExpense menyimpan nilai valid setelah debounce',
      build: () {
        when(
          () => settingsRepository.getSettings(),
        ).thenAnswer((_) async => tSettings);
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateTreasuryExpense(750000);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [
        SettingsLoaded(settings: tSettings, isSaving: true),
        SettingsLoaded(
          settings: tSettings,
          isSaving: false,
          lastSavedField: 'treasury_expense',
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.updateSettings({'treasury_expense': 750000}),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateTreasuryBalance diabaikan jika nilai negatif',
      build: () {
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateTreasuryBalance(-1);
        await Future.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [],
      verify: (_) {
        verifyNever(() => settingsRepository.updateSettings(any()));
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'updateTreasuryBalance diabaikan jika nilai melebihi batas (> 999.999.999.999)',
      build: () {
        when(
          () => settingsRepository.updateSettings(any()),
        ).thenAnswer((_) async {});
        return settingsCubit;
      },
      seed: () => SettingsLoaded(settings: tSettings),
      act: (cubit) async {
        cubit.updateTreasuryBalance(1000000000000); // 1 triliun — di luar batas
        await Future.delayed(const Duration(milliseconds: 600));
      },
      expect: () => [],
      verify: (_) {
        verifyNever(() => settingsRepository.updateSettings(any()));
      },
    );
  });
}
