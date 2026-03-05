# Flutter Testing Guide - Miqotul Khoir TV

This comprehensive guide covers testing strategies, patterns, and best practices for the Miqotul Khoir TV Flutter application, with focus on SQLite testing, prayer time calculation testing, state machine testing, and D-Pad navigation testing.

## Overview

Our testing strategy emphasizes comprehensive coverage across all layers:

- **Unit Testing**: SQLite repositories, prayer time calculation, state management (Cubit)
- **Widget Testing**: D-Pad navigation, focus management, state-based UI layouts
- **Integration Testing**: Complete state machine transitions, setup wizard flow
- **Performance Testing**: Timer accuracy, memory leak prevention

## General Testing Guidelines

### Core Testing Principles

- Write unit tests for business logic and services (prayer calculation, state machine)
- Create widget tests for UI components and D-Pad navigation
- Implement integration tests for complete user flows (setup wizard, state transitions)
- Test edge cases thoroughly (invalid coordinates, timer lifecycle, focus traversal)
- Mock external dependencies appropriately (in-memory SQLite for repositories)

### Test Structure

```bash
test/
├── unit/
│   ├── models/           # Model serialization tests
│   ├── repositories/     # SQLite repository tests (in-memory)
│   ├── cubits/          # Cubit state management tests
│   └── services/        # Prayer time calculation tests
├── widget/              # Widget and UI component tests
├── integration/         # End-to-end flow tests
├── mocks/              # Mock implementations
└── test_suite_runner.dart  # Centralized test execution
```

## SQLite Repository Testing

### In-Memory Database Setup

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

group('SettingsRepository Tests', () {
  late Database testDb;
  late SettingsRepository repository;
  
  setUp(() async {
    // Initialize FFI for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Create in-memory database
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // Create settings table
        await db.execute('''
          CREATE TABLE settings (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            mosque_name TEXT NOT NULL DEFAULT '',
            mosque_address TEXT NOT NULL DEFAULT '',
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            offset_subuh INTEGER DEFAULT 0,
            offset_dzuhur INTEGER DEFAULT 0,
            offset_ashar INTEGER DEFAULT 0,
            offset_maghrib INTEGER DEFAULT 0,
            offset_isya INTEGER DEFAULT 0,
            iqomah_subuh INTEGER DEFAULT 10,
            iqomah_dzuhur INTEGER DEFAULT 10,
            iqomah_ashar INTEGER DEFAULT 10,
            iqomah_maghrib INTEGER DEFAULT 7,
            iqomah_isya INTEGER DEFAULT 10,
            running_text TEXT DEFAULT ''
          )
        ''');
        
        // Insert default row
        await db.insert('settings', {
          'id': 1,
          'mosque_name': 'Test Masjid',
          'mosque_address': 'Test Address',
          'latitude': -6.2088,
          'longitude': 106.8456,
        });
      },
    );
    
    repository = SettingsRepository(database: testDb);
  });
  
  tearDown(() async {
    await testDb.close();
  });
  
  test('should return settings from database', () async {
    final settings = await repository.getSettings();
    
    expect(settings.id, equals(1));
    expect(settings.mosqueName, equals('Test Masjid'));
    expect(settings.latitude, equals(-6.2088));
  });
  
  test('should update settings and persist changes', () async {
    final newSettings = Settings(
      id: 1,
      mosqueName: 'Updated Masjid',
      mosqueAddress: 'New Address',
      latitude: -7.2575,
      longitude: 112.7521,
      offsetSubuh: 2,
      offsetDzuhur: -1,
      offsetAshar: 0,
      offsetMaghrib: 1,
      offsetIsya: 0,
      iqomahSubuh: 10,
      iqomahDzuhur: 10,
      iqomahAshar: 10,
      iqomahMaghrib: 7,
      iqomahIsya: 10,
      runningText: 'Test',
    );
    
    await repository.updateSettings(newSettings);
    
    // Verify persisted
    final retrieved = await repository.getSettings();
    expect(retrieved.mosqueName, equals('Updated Masjid'));
    expect(retrieved.latitude, equals(-7.2575));
    expect(retrieved.offsetSubuh, equals(2));
  });
  
  test('should handle transaction failures gracefully', () async {
    // Close database to trigger error
    await testDb.close();
    
    expect(
      () => repository.updateSettings(Settings(/* ... */)),
      throwsA(isA<DatabaseException>()),
    );
  });
});
```

### City Repository Testing

```dart
group('CityRepository Tests', () {
  late Database testDb;
  late CityRepository repository;
  
  setUp(() async {
    testDb = await _createInMemoryDb();
    repository = CityRepository(database: testDb);
  });
  
  test('should return cities grouped by province', () async {
    final citiesByProvince = await repository.getCitiesByProvince();
    
    expect(citiesByProvince.keys, contains('DKI Jakarta'));
    expect(citiesByProvince.keys, contains('Jawa Barat'));
    
    final jakartaCities = citiesByProvince['DKI Jakarta']!;
    expect(jakartaCities.length, greaterThan(0));
    expect(jakartaCities.first.cityName, contains('Jakarta'));
  });
  
  test('should find city by name', () async {
    final city = await repository.findCityByName('Bandung');
    
    expect(city, isNotNull);
    expect(city!.cityName, equals('Bandung'));
    expect(city.provinceName, equals('Jawa Barat'));
    expect(city.latitude, closeTo(-6.9175, 0.01));
  });
});
```

## Prayer Time Calculation Testing

### Astronomical Calculation Tests

```dart
import 'package:adhan/adhan.dart';

group('PrayerTimeCalculator Tests', () {
  late PrayerTimeCalculator calculator;
  
  setUp(() {
    calculator = PrayerTimeCalculator();
  });
  
  group('Coordinate Validation', () {
    test('should reject invalid latitude', () {
      final times = calculator.calculatePrayerTimes(
        date: DateTime.now(),
        latitude: 91.0, // Invalid
        longitude: 106.8456,
        manualCorrections: {},
      );
      
      expect(times, isNull);
    });
    
    test('should reject invalid longitude', () {
      final times = calculator.calculatePrayerTimes(
        date: DateTime.now(),
        latitude: -6.2088,
        longitude: 181.0, // Invalid
        manualCorrections: {},
      );
      
      expect(times, isNull);
    });
    
    test('should accept valid coordinates', () {
      final times = calculator.calculatePrayerTimes(
        date: DateTime(2026, 2, 17),
        latitude: -6.2088, // Jakarta
        longitude: 106.8456,
        manualCorrections: {},
      );
      
      expect(times, isNotNull);
    });
  });
  
  group('Manual Corrections', () {
    test('should apply positive correction to Subuh', () {
      final without = calculator.calculatePrayerTimes(
        date: DateTime(2026, 2, 17),
        latitude: -6.2088,
        longitude: 106.8456,
        manualCorrections: {},
      );
      
      final withCorrection = calculator.calculatePrayerTimes(
        date: DateTime(2026, 2, 17),
        latitude: -6.2088,
        longitude: 106.8456,
        manualCorrections: {PrayerType.subuh: 5},
      );
      
      expect(withCorrection!.fajr.isAfter(without!.fajr), isTrue);
      expect(
        withCorrection.fajr.difference(without.fajr).inMinutes,
        equals(5),
      );
    });
    
    test('should apply negative correction to Maghrib', () {
      final without = calculator.calculatePrayerTimes(
        date: DateTime(2026, 2, 17),
        latitude: -6.2088,
        longitude: 106.8456,
        manualCorrections: {},
      );
      
      final withCorrection = calculator.calculatePrayerTimes(
        date: DateTime(2026, 2, 17),
        latitude: -6.2088,
        longitude: 106.8456,
        manualCorrections: {PrayerType.maghrib: -3},
      );
      
      expect(withCorrection!.maghrib.isBefore(without!.maghrib), isTrue);
      expect(
        without.maghrib.difference(withCorrection.maghrib).inMinutes,
        equals(3),
      );
    });
  });
  
  group('Edge Cases', () {
    test('should calculate prayer times near equator', () {
      final times = calculator.calculatePrayerTimes(
        date: DateTime(2026, 2, 17),
        latitude: 0.0, // Equator
        longitude: 106.8456,
        manualCorrections: {},
      );
      
      expect(times, isNotNull);
      expect(times!.fajr.isBefore(times.sunrise), isTrue);
      expect(times.sunrise.isBefore(times.dhuhr), isTrue);
    });
    
    test('should calculate prayer times in southern hemisphere', () {
      final times = calculator.calculatePrayerTimes(
        date: DateTime(2026, 2, 17),
        latitude: -33.8688, // Sydney
        longitude: 151.2093,
        manualCorrections: {},
      );
      
      expect(times, isNotNull);
    });
  });
});
```

### Daily Refresh Testing

```dart
group('PrayerTimeCubit Daily Refresh', () {
  late PrayerTimeCubit cubit;
  late MockPrayerTimeCalculator mockCalculator;
  late MockSettingsRepository mockSettingsRepo;
  
  setUp(() {
    mockCalculator = MockPrayerTimeCalculator();
    mockSettingsRepo = MockSettingsRepository();
    cubit = PrayerTimeCubit(
      calculator: mockCalculator,
      settingsRepository: mockSettingsRepo,
    );
  });
  
  test('should refresh prayer times at midnight', () async {
    // Mock settings
    when(mockSettingsRepo.getSettings()).thenAnswer((_) async => Settings(
      latitude: -6.2088,
      longitude: 106.8456,
      offsetSubuh: 0,
      // ... other fields
    ));
    
    // Mock calculation
    when(mockCalculator.calculatePrayerTimes(
      date: any(named: 'date'),
      latitude: any(named: 'latitude'),
      longitude: any(named: 'longitude'),
      manualCorrections: any(named: 'manualCorrections'),
    )).thenReturn(mockPrayerTimes);
    
    // Trigger refresh
    await cubit.refreshPrayerTimes();
    
    // Verify cubit emits success
    expect(cubit.state, isA<PrayerTimeSuccess>());
  });
});
```

## State Machine Testing

### DisplayStateCubit Tests

```dart
import 'package:bloc_test/bloc_test.dart';

group('DisplayStateCubit Tests', () {
  late DisplayStateCubit cubit;
  late MockPrayerTimeRepository mockPrayerRepo;
  late MockSettingsRepository mockSettingsRepo;
  
  setUp(() {
    mockPrayerRepo = MockPrayerTimeRepository();
    mockSettingsRepo = MockSettingsRepository();
    cubit = DisplayStateCubit(
      prayerRepository: mockPrayerRepo,
      settingsRepository: mockSettingsRepo,
    );
  });
  
  tearDown(() {
    cubit.close();
  });
  
  blocTest<DisplayStateCubit, DisplayState>(
    'should emit StandbyState initially',
    build: () => cubit,
    verify: (cubit) {
      expect(cubit.state, isA<StandbyState>());
    },
  );
  
  blocTest<DisplayStateCubit, DisplayState>(
    'should transition to PreAdzanState when 10 minutes before prayer',
    build: () {
      // Setup mock prayer times
      final now = DateTime(2026, 2, 17, 4, 20); // 04:20
      final prayerTimes = [
        PrayerTime(type: PrayerType.subuh, time: DateTime(2026, 2, 17, 4, 30)), // 04:30
      ];
      
      when(mockPrayerRepo.getTodayPrayerTimes())
          .thenAnswer((_) async => prayerTimes);
      when(mockSettingsRepo.getSettings())
          .thenAnswer((_) async => Settings(/* ... */));
      
      return cubit;
    },
    act: (cubit) => cubit.checkAndTransitionState(
      DateTime(2026, 2, 17, 4, 20),
    ),
    expect: () => [
      isA<PreAdzanState>()
          .having((s) => s.nextPrayer.type, 'prayer type', PrayerType.sub uh)
          .having((s) => s.remainingTime.inMinutes, 'remaining minutes', 10),
    ],
  );
  
  blocTest<DisplayStateCubit, DisplayState>(
    'should transition to AdzanState when prayer time arrives',
    build: () {
      final now = DateTime(2026, 2, 17, 4, 30);
      final prayerTimes = [
        PrayerTime(type: PrayerType.subuh, time: DateTime(2026, 2, 17, 4, 30)),
      ];
      
      when(mockPrayerRepo.getTodayPrayerTimes())
          .thenAnswer((_) async => prayerTimes);
      when(mockSettingsRepo.getSettings())
          .thenAnswer((_) async => Settings(/* ... */));
      
      return cubit;
    },
    act: (cubit) => cubit.checkAndTransitionState(now),
    expect: () => [
      isA<AdzanState>()
          .having((s) => s.currentPrayer.type, 'prayer type', PrayerType.subuh),
    ],
  );
  
  blocTest<DisplayStateCubit, DisplayState>(
    'should transition from Adzan to Iqomah',
    build: () => cubit,
    seed: () => AdzanState(
      currentPrayer: PrayerTime(
        type: PrayerType.subuh,
        time: DateTime(2026, 2, 17, 4, 30),
      ),
    ),
    act: (cubit) => cubit.transitionToIqomah(),
    expect: () => [
      isA<IqomahState>()
          .having((s) => s.currentPrayer.type, 'prayer type', PrayerType.subuh)
          .having((s) => s.remainingTime.inMinutes, 'iqomah duration', 10),
    ],
  );
  
  blocTest<DisplayStateCubit, DisplayState>(
    'should transition from Iqomah to Sholat when countdown ends',
    build: () => cubit,
    seed: () => IqomahState(
      currentPrayer: PrayerTime(
        type: PrayerType.subuh,
        time: DateTime(2026, 2, 17, 4, 30),
      ),
      remainingTime: Duration.zero,
    ),
    act: (cubit) => cubit.checkAndTransitionState(DateTime.now()),
    expect: () => [
      isA<SholatState>(),
    ],
  );
});
```

## Timer Management Testing

### Countdown Timer Tests

```dart
group('CountdownTimer Widget Tests', () {
  testWidgets('should update countdown every second', (tester) async {
    final startTime = Duration(minutes: 5);
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountdownTimer(
            remainingTime: startTime,
            nextPrayer: PrayerTime(
              type: PrayerType.subuh,
              time: DateTime.now().add(startTime),
            ),
          ),
        ),
      ),
    );
    
    // Initial state
    expect(find.text('05:00'), findsOneWidget);
    
    // Wait 1 second
    await tester.pump(Duration(seconds: 1));
    
    // Should decrease
    expect(find.text('04:59'), findsOneWidget);
  });
  
  testWidgets('should dispose timer properly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CountdownTimer(
            remainingTime: Duration(minutes: 1),
            nextPrayer: mockPrayerTime,
          ),
        ),
      ),
    );
    
    // Dispose widget
    await tester.pumpWidget(Container());
    
    // No memory leak should occur (verified via memory profiler)
  });
});
```

### Timer Memory Leak Tests

```dart
group('Timer Memory Leak Prevention', () {
  testWidgets('should cancel timer in dispose', (tester) async {
    var timerCanceled = false;
    
    final testWidget = _TestTimerWidget(
      onTimerCanceled: () => timerCanceled = true,
    );
    
    await tester.pumpWidget(MaterialApp(home: testWidget));
    
    // Widget is active, timer should be running
    expect(timerCanceled, isFalse);
    
    // Remove widget from tree
    await tester.pumpWidget(Container());
    
    // Timer should be canceled
    expect(timerCanceled, isTrue);
  });
});
```

## D-Pad Navigation Testing

### Focus Traversal Tests

```dart
group('D-Pad Navigation Tests', () {
  testWidgets('should move focus with arrow keys', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FocusableMenuItem(
                label: 'Item 1',
                icon: Icons.home,
                autofocus: true,
                onTap: () {},
              ),
              FocusableMenuItem(
                label: 'Item 2',
                icon: Icons.settings,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    
    // First item should have focus
    expect(
      tester.widget<FocusableMenuItem>(find.byType(FocusableMenuItem).first),
      isNotNull,
    );
    
    // Press Down arrow
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    
    // Focus should move to second item
    final secondItem = find.byType(FocusableMenuItem).at(1);
    expect(Focus.of(tester.element(secondItem)).hasFocus, isTrue);
  });
  
  testWidgets('should trigger action on Enter key', (tester) async {
    var wasPressed = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusableMenuItem(
            label: 'Test',
            icon: Icons.check,
            autofocus: true,
            onTap: () => wasPressed = true,
          ),
        ),
      ),
    );
    
    // Press Enter
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    
    expect(wasPressed, isTrue);
  });
  
  testWidgets('should show focus indicator', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrayerTimeCard(
            name: 'Subuh',
            time: '04:30',
            isNext: false,
          ),
        ),
      ),
    );
    
    // Get the card widget
    final card = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    
    // When focused, should have white border
    // (This test assumes card is focused by default)
    expect(
      (card.decoration as BoxDecoration).border,
      isNotNull,
    );
  });
});
```

## Setup Wizard Testing

### Multi-Step Flow Tests

```dart
group('SetupWizardCubit Tests', () {
  late SetupWizardCubit cubit;
  late MockSettingsRepository mockRepo;
  
  setUp(() {
    mockRepo = MockSettingsRepository();
    cubit = SetupWizardCubit(settingsRepository: mockRepo);
  });
  
  blocTest<SetupWizardCubit, SetupWizardState>(
    'should advance through wizard steps',
    build: () => cubit,
    act: (cubit) {
      cubit.nextStep(); // Welcome → Mosque Identity
      cubit.nextStep(); // Mosque Identity → Location
      cubit.nextStep(); // Location → Confirmation
    },
    expect: () => [
      isA<SetupWizardState>()
          .having((s) => s.currentStep, 'step', SetupStep.mosqueIdentity),
      isA<SetupWizardState>()
          .having((s) => s.currentStep, 'step', SetupStep.location),
      isA<SetupWizardState>()
          .having((s) => s.currentStep, 'step', SetupStep.confirmation),
    ],
  );
  
  blocTest<SetupWizardCubit, SetupWizardState>(
    'should go back to previous step',
    build: () => cubit,
    seed: () => SetupWizardState(currentStep: SetupStep.location),
    act: (cubit) => cubit.previousStep(),
    expect: () => [
      isA<SetupWizardState>()
          .having((s) => s.currentStep, 'step', SetupStep.mosqueIdentity),
    ],
  );
  
  blocTest<SetupWizardCubit, SetupWizardState>(
    'should save settings and complete setup',
    build: () {
      when(mockRepo.updateSettings(any))
          .thenAnswer((_) async => {});
      return cubit;
    },
    seed: () => SetupWizardState(
      currentStep: SetupStep.confirmation,
      mosqueData: MosqueData(name: 'Test Masjid', address: 'Test Address'),
      selectedCity: City(
        cityName: 'Jakarta',
        provinceName: 'DKI Jakarta',
        latitude: -6.2088,
        longitude: 106.8456,
      ),
    ),
    act: (cubit) => cubit.completeSetup(),
    expect: () => [
      isA<SetupWizardState>().having((s) => s.isSaving, 'saving', isTrue),
      isA<SetupWizardState>()
          .having((s) => s.isSaving, 'saving', isFalse)
          .having((s) => s.currentStep, 'step', SetupStep.completed),
    ],
  );
});
```

## Widget Testing Best Practices

### BlocProvider Setup

```dart
testWidgets('should display prayer times from cubit', (tester) async {
  final mockCubit = MockDisplayStateCubit();
  
  whenListen(
    mockCubit,
    Stream.fromIterable([
      StandbyState(
        currentTime: DateTime.now(),
        prayerTimes: [
          PrayerTime(type: PrayerType.subuh, time: DateTime.now()),
        ],
        runningText: 'Test',
      ),
    ]),
    initialState: const DisplayInitial(),
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<DisplayStateCubit>.value(
        value: mockCubit,
        child: MainDisplayPage(),
      ),
    ),
  );
  
  await tester.pump();
  
  // Verify prayer time cards are displayed
  expect(find.byType(PrayerTimeCard), findsWidgets);
});
```

## Running Tests

### Basic Commands

```bash
# Run all tests
flutter test --reporter=expanded

# Run specific test file
flutter test test/repositories/settings_repository_test.dart --reporter=expanded

# Run tests with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run specific test group
flutter test --plain-name="SQLite" --reporter=expanded
```

### Test Coverage Targets

- **90%+** for repositories (SQLite operations)
- **85%+** for cubits (state management)
- **80%+** for services (prayer calculation)
- **75%+** for widgets (UI components)

## Common Testing Pitfalls

### ❌ DON'T: Forget to dispose resources

```dart
// ❌ WRONG
tearDown(() {
  // Missing cubit.close()
});

// ✅ CORRECT
tearDown(() {
  cubit.close();
  testDb.close();
});
```

### ❌ DON'T: Use real database in tests

```dart
// ❌ WRONG
final db = await openDatabase('real_db.db');

// ✅ CORRECT
final db = await openDatabase(inMemoryDatabasePath);
```

### ❌ DON'T: Test implementation details

```dart
// ❌ WRONG - Testing private method
expect(cubit._calculateNextState(), isA<PreAdzanState>());

// ✅ CORRECT - Testing behavior
await cubit.checkAndTransitionState(DateTime.now());
expect(cubit.state, isA<PreAdzanState>());
```

## Related Documentation

- [Architecture Patterns](ARCHITECTURE_PATTERNS.md) - Implementation patterns to test
- [Development Workflow](DEVELOPMENT_WORKFLOW.md) - Testing workflow and CI/CD
- [UI/UX Guide](UI_UX_GUIDE.md) - Widget patterns to test

---

This guide ensures comprehensive testing coverage for Miqotul Khoir TV.
