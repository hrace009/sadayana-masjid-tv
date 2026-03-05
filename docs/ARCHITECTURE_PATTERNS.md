# Architecture Patterns Guide - Miqotul Khoir TV

## Overview

Guide ini mencakup architectural patterns yang digunakan dalam project **Miqotul Khoir TV (MKT)**, termasuk state machine pattern, offline-first data management, prayer time calculation patterns, timer management, dan proven patterns untuk Android TV digital signage.

## Table of Contents

- [State Machine Pattern](#state-machine-pattern)
- [Prayer Time Calculation Pattern](#prayer-time-calculation-pattern)
- [Offline-First Data Pattern](#offline-first-data-pattern)
- [Timer Management Pattern](#timer-management-pattern)
- [Setup Wizard Pattern](#setup-wizard-pattern)
- [Cubit Pattern untuk MKT](#cubit-pattern-untuk-mkt)
- [D-Pad Navigation Pattern](#d-pad-navigation-pattern)
- [UI State Transition Pattern](#ui-state-transition-pattern)
- [Testing Patterns](#testing-patterns)

---

## State Machine Pattern

Pattern utama untuk display logic aplikasi. Aplikasi memiliki 5 state yang transition secara otomatis berdasarkan waktu.

### 5-State Hierarchy

```dart
/// Base abstract class untuk semua display states
abstract class DisplayState extends Equatable {
  const DisplayState();
  @override
  List<Object?> get props => [];
}

/// 1. STANDBY - Default state menampilkan semua info
class StandbyState extends DisplayState {
  final DateTime currentTime;
  final List<PrayerTime> prayerTimes;
  final String runningText;
  
  const StandbyState({
    required this.currentTime,
    required this.prayerTimes,
    required this.runningText,
  });
  
  @override
  List<Object?> get props => [currentTime, prayerTimes, runningText];
}

/// 2. PRE_ADZAN - Countdown H-10 menit sebelum adzan
class PreAdzanState extends DisplayState {
  final PrayerTime nextPrayer;
  final Duration remainingTime;
  
  const PreAdzanState({
    required this.nextPrayer,
    required this.remainingTime,
  });
  
  @override
  List<Object?> get props => [nextPrayer, remainingTime];
}

/// 3. ADZAN - Waktu sholat masuk, play audio
class AdzanState extends DisplayState {
  final PrayerTime currentPrayer;
  
  const AdzanState({required this.currentPrayer});
  
  @override
  List<Object?> get props => [currentPrayer];
}

/// 4. IQOMAH - Countdown menuju waktu sholat
class IqomahState extends DisplayState {
  final PrayerTime currentPrayer;
  final Duration remainingTime;
  
  const IqomahState({
    required this.currentPrayer,
    required this.remainingTime,
  });
  
  @override
  List<Object?> get props => [currentPrayer, remainingTime];
}

/// 5. SHOLAT - Blank screen / dimmed untuk prevent burn-in
class SholatState extends DisplayState {
  final PrayerTime currentPrayer;
  final DateTime endTime;
  
  const SholatState({
    required this.currentPrayer,
    required this.endTime,
  });
  
  @override
  List<Object?> get props => [currentPrayer, endTime];
}
```

### State Transition Logic

```dart
class DisplayStateCubit extends Cubit<DisplayState> {
  final PrayerTimeRepository _prayerRepository;
  final SettingsRepository _settingsRepository;
  Timer? _stateCheckTimer;
  
  DisplayStateCubit({
    required PrayerTimeRepository prayerRepository,
    required SettingsRepository settingsRepository,
  })  : _prayerRepository = prayerRepository,
        _settingsRepository = settingsRepository,
        super(const StandbyState(
          currentTime: DateTime.now(),
          prayerTimes: [],
          runningText: '',
        )) {
    _initializeStateChecking();
  }
  
  /// Initialize periodic state checking (setiap 1 detik)
  void _initializeStateChecking() {
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkAndTransitionState();
    });
  }
  
  /// Core state transition logic
  Future<void> _checkAndTransitionState() async {
    final now = DateTime.now();
    final prayerTimes = await _prayerRepository.getTodayPrayerTimes();
    final settings = await _settingsRepository.getSettings();
    
    // Find next prayer time
    final nextPrayer = _findNextPrayer(now, prayerTimes);
    if (nextPrayer == null) {
      // No more prayers today, stay in standby
      emit(StandbyState(
        currentTime: now,
        prayerTimes: prayerTimes,
        runningText: settings.runningText,
      ));
      return;
    }
    
    final timeUntilPrayer = nextPrayer.time.difference(now);
    
    // State transition logic
    if (timeUntilPrayer <= Duration.zero) {
      // Prayer time has passed, check if in Iqomah or Sholat state
      final currentState = state;
      
      if (currentState is AdzanState) {
        // Transition from Adzan to Iqomah
        final iqomahDuration = _getIqomahDuration(nextPrayer.type, settings);
        emit(IqomahState(
          currentPrayer: nextPrayer,
          remainingTime: iqomahDuration,
        ));
      } else if (currentState is IqomahState) {
        // Check if Iqomah countdown finished
        if (currentState.remainingTime <= Duration.zero) {
          // Transition to Sholat (blank/dimmed screen)
          final sholatDuration = Duration(minutes: 15); // Configurable
          emit(SholatState(
            currentPrayer: nextPrayer,
            endTime: now.add(sholatDuration),
          ));
        }
      } else if (currentState is SholatState) {
        // Check if Sholat time finished
        if (now.isAfter(currentState.endTime)) {
          // Back to Standby
          emit(StandbyState(
            currentTime: now,
            prayerTimes: prayerTimes,
            runningText: settings.runningText,
          ));
        }
      } else {
        // Currently at exact prayer time
        emit(AdzanState(currentPrayer: nextPrayer));
      }
    } else if (timeUntilPrayer <= Duration(minutes: 10)) {
      // Pre-Adzan state (H-10 minutes)
      emit(PreAdzanState(
        nextPrayer: nextPrayer,
        remainingTime: timeUntilPrayer,
      ));
    } else {
      // Standby state
      emit(StandbyState(
        currentTime: now,
        prayerTimes: prayerTimes,
        runningText: settings.runningText,
      ));
    }
  }
  
  PrayerTime? _findNextPrayer(DateTime now, List<PrayerTime> times) {
    return times.firstWhereOrNull(
      (prayer) => prayer.time.isAfter(now),
    );
  }
  
  Duration _getIqomahDuration(PrayerType type, Settings settings) {
    return switch (type) {
      PrayerType.subuh => Duration(minutes: settings.iqomahSubuh),
      PrayerType.dzuhur => Duration(minutes: settings.iqomahDzuhur),
      PrayerType.ashar => Duration(minutes: settings.iqomahAshar),
      PrayerType.maghrib => Duration(minutes: settings.iqomahMaghrib),
      PrayerType.isya => Duration(minutes: settings.iqomahIsya),
      _ => Duration(minutes: 10), // Default
    };
  }
  
  @override
  Future<void> close() {
    _stateCheckTimer?.cancel();
    return super.close();
  }
}
```

### State-Based UI Rendering

```dart
class MainDisplayPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisplayStateCubit, DisplayState>(
      builder: (context, state) {
        return switch (state) {
          StandbyState() => _buildStandbyDisplay(state),
          PreAdzanState() => _buildPreAdzanDisplay(state),
          AdzanState() => _buildAdzanDisplay(state),
          IqomahState() => _buildIqomahDisplay(state),
          SholatState() => _buildSholatDisplay(state),
        };
      },
    );
  }
  
  Widget _buildStandbyDisplay(StandbyState state) {
    return Stack(
      children: [
        // Background image with overlay
        _buildBackground(),
        
        // Main content
        Column(
          children: [
            // Header: Logo, Nama Masjid, Tanggal
            _buildHeader(state),
            
            Expanded(
              child: Row(
                children: [
                  // Left: Large clock
                  Expanded(
                    flex: 2,
                    child: _buildLargeClock(state.currentTime),
                  ),
                  
                  // Right: Info panel
                  Expanded(
                    flex: 1,
                    child: _buildInfoPanel(state),
                  ),
                ],
              ),
            ),
            
            // Bottom: 7 Prayer time cards
            _buildPrayerTimeCards(state.prayerTimes),
            
            // Footer: Running text
            _buildRunningText(state.runningText),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPreAdzanDisplay(PreAdzanState state) {
    return Stack(
      children: [
        _buildBackground(),
        Column(
          children: [
            _buildHeader(state),
            
            Expanded(
              child: Center(
                child: CountdownTimer(
                  remainingTime: state.remainingTime,
                  nextPrayer: state.nextPrayer,
                  isPreAdzan: true,
                ),
              ),
            ),
            
            // Prayer time cards dengan highlight pada next prayer
            _buildPrayerTimeCards(
              state.prayerTimes,
              highlightedPrayer: state.nextPrayer,
            ),
            
            _buildRunningText(state.runningText),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSholatDisplay(SholatState state) {
    // Blank screen atau dimmed clock untuk prevent burn-in
    return Container(
      color: Colors.black,
      child: Center(
        child: Opacity(
          opacity: 0.1,
          child: Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: TextStyle(fontSize: 24.sp, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
```

---

## Prayer Time Calculation Pattern

Pattern untuk kalkulasi waktu sholat secara offline menggunakan astronomical calculation.

### Implementation Pattern

```dart
import 'package:adhan/adhan.dart';

class PrayerTimeCalculator {
  /// Calculate prayer times untuk tanggal tertentu
  /// Returns null jika calculation gagal
  PrayerTimes? calculatePrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required Map<PrayerType, int> manualCorrections,
  }) {
    // Validate coordinates
    if (!_isValidCoordinates(latitude, longitude)) {
      debugPrint('❌ Invalid coordinates: ($latitude, $longitude)');
      return null;
    }
    
    try {
      // Create coordinates object
      final coords = Coordinates(latitude, longitude);
      
      // Kemenag RI (SIHAT): Subuh 20°, Isya 18°, Ihtiyat bawaan +2 menit
      final params = CalculationMethod.other.getParameters();
      params.fajrAngle = 20.0;
      params.ishaAngle = 18.0;
      params.adjustments.fajr = 2;
      params.adjustments.sunrise = -2;
      params.adjustments.dhuhr = 2;
      params.adjustments.asr = 2;
      params.adjustments.maghrib = 2;
      params.adjustments.isha = 2;
      
      // Calculate base times
      final baseTimes = PrayerTimes(coords, date, params);
      
      // Apply manual corrections (ihtiyat)
      return _applyManualCorrections(baseTimes, manualCorrections);
      
    } catch (e) {
      debugPrint('❌ Prayer time calculation error: $e');
      return null;
    }
  }
  
  bool _isValidCoordinates(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
  
  PrayerTimes _applyManualCorrections(
    PrayerTimes base,
    Map<PrayerType, int> corrections,
  ) {
    // Apply correction in minutes to each prayer time
    final correctedFajr = base.fajr.add(
      Duration(minutes: corrections[PrayerType.subuh] ?? 0),
    );
    
    final correctedSunrise = base.sunrise.add(
      Duration(minutes: corrections[PrayerType.syuruq] ?? 0),
    );
    
    // Dhuha = Sunrise + offset (default: 20 minutes)
    final dhuha = correctedSunrise.add(Duration(minutes: 20));
    
    final correctedDhuhr = base.dhuhr.add(
      Duration(minutes: corrections[PrayerType.dzuhur] ?? 0),
    );
    
    final correctedAsr = base.asr.add(
      Duration(minutes: corrections[PrayerType.ashar] ?? 0),
    );
    
    final correctedMaghrib = base.maghrib.add(
      Duration(minutes: corrections[PrayerType.maghrib] ?? 0),
    );
    
    final correctedIsha = base.isha.add(
      Duration(minutes: corrections[PrayerType.isya] ?? 0),
    );
    
    return PrayerTimes.fromDateTime(
      fajr: correctedFajr,
      sunrise: correctedSunrise,
      dhuhr: correctedDhuhr,
      asr: correctedAsr,
      maghrib: correctedMaghrib,
      isha: correctedIsha,
    );
  }
}
```

### Daily Prayer Time Refresh

```dart
class PrayerTimeCubit extends Cubit<PrayerTimeState> {
  final PrayerTimeCalculator _calculator;
  final SettingsRepository _settingsRepository;
  Timer? _midnightRefreshTimer;
  
  PrayerTimeCubit({
    required PrayerTimeCalculator calculator,
    required SettingsRepository settingsRepository,
  })  : _calculator = calculator,
        _settingsRepository = settingsRepository,
        super(const PrayerTimeInitial()) {
    _initializeDailyRefresh();
  }
  
  /// Initialize auto-refresh di tengah malam
  void _initializeDailyRefresh() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);
    
    // Schedule first refresh at midnight
    Timer(timeUntilMidnight, () {
      refreshPrayerTimes();
      
      // Then refresh every 24 hours
      _midnightRefreshTimer = Timer.periodic(
        const Duration(days: 1),
        (_) => refreshPrayerTimes(),
      );
    });
  }
  
  Future<void> refreshPrayerTimes() async {
    emit(const PrayerTimeLoading());
    
    try {
      final settings = await _settingsRepository.getSettings();
      final today = DateTime.now();
      
      final times = _calculator.calculatePrayerTimes(
        date: today,
        latitude: settings.latitude,
        longitude: settings.longitude,
        manualCorrections: {
          PrayerType.subuh: settings.offsetSubuh,
          PrayerType.syuruq: settings.offsetSyuruq,
          PrayerType.dzuhur: settings.offsetDzuhur,
          PrayerType.ashar: settings.offsetAshar,
          PrayerType.maghrib: settings.offsetMaghrib,
          PrayerType.isya: settings.offsetIsya,
        },
      );
      
      if (times == null) {
        emit(const PrayerTimeError(
          message: 'Gagal menghitung waktu sholat',
        ));
        return;
      }
      
      emit(PrayerTimeSuccess(prayerTimes: times));
      
    } catch (e) {
      emit(PrayerTimeError(message: e.toString()));
    }
  }
  
  @override
  Future<void> close() {
    _midnightRefreshTimer?.cancel();
    return super.close();
  }
}
```

---

## Offline-First Data Pattern

Pattern untuk SQLite database sebagai single source of truth.

### Database Schema

```dart
class DatabaseHelper {
  static const String _dbName = 'miqotul_khoir.db';
  static const int _dbVersion = 1;
  
  // Singleton pattern
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  
  DatabaseHelper._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Settings table (singleton - only 1 row)
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        is_first_run INTEGER DEFAULT 1,
        
        -- Mosque Identity
        mosque_name TEXT NOT NULL DEFAULT '',
        mosque_address TEXT NOT NULL DEFAULT '',
        
        -- Location
        city_name TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',
        
        -- Prayer Time Corrections (Minutes)
        offset_subuh INTEGER DEFAULT 0,
        offset_syuruq INTEGER DEFAULT 0,
        offset_dhuha INTEGER DEFAULT 0,
        offset_dzuhur INTEGER DEFAULT 0,
        offset_ashar INTEGER DEFAULT 0,
        offset_maghrib INTEGER DEFAULT 0,
        offset_isya INTEGER DEFAULT 0,
        
        -- Hijri Date Adjustment (Days)
        hijri_adjustment INTEGER DEFAULT 0,
        
        -- Iqomah Delays (Minutes)
        iqomah_subuh INTEGER DEFAULT 10,
        iqomah_dzuhur INTEGER DEFAULT 10,
        iqomah_ashar INTEGER DEFAULT 10,
        iqomah_maghrib INTEGER DEFAULT 7,
        iqomah_isya INTEGER DEFAULT 10,
        
        -- Content
        running_text TEXT DEFAULT ''
      )
    ''');
    
    // Cities table (pre-populated for setup wizard)
    await db.execute('''
      CREATE TABLE cities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        province_name TEXT NOT NULL,
        city_name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');
    
    // Create index for faster city lookup
    await db.execute('''
      CREATE INDEX idx_city_name ON cities(city_name)
    ''');
    
    // Insert default settings row
    await db.insert('settings', {
      'id': 1,
      'is_first_run': 1,
      'mosque_name': '',
      'mosque_address': '',
      'latitude': -6.2088, // Jakarta default
      'longitude': 106.8456,
      'timezone': 'Asia/Jakarta',
    });
    
    // Pre-populate cities (example data)
    await _populateCities(db);
  }
  
  Future<void> _populateCities(Database db) async {
    final cities = [
      {'province_name': 'DKI Jakarta', 'city_name': 'Jakarta Pusat', 
       'latitude': -6.1745, 'longitude': 106.8227},
      {'province_name': 'Jawa Barat', 'city_name': 'Bandung', 
       'latitude': -6.9175, 'longitude': 107.6191},
      {'province_name': 'Jawa Barat', 'city_name': 'Bogor', 
       'latitude': -6.5950, 'longitude': 106.7968},
      {'province_name': 'Jawa Tengah', 'city_name': 'Semarang', 
       'latitude': -6.9667, 'longitude': 110.4167},
      {'province_name': 'Jawa Timur', 'city_name': 'Surabaya', 
       'latitude': -7.2575, 'longitude': 112.7521},
      // ... add more cities
    ];
    
    for (final city in cities) {
      await db.insert('cities', city);
    }
  }
  
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations
  }
}
```

### Repository Pattern dengan Transaction Safety

```dart
class SettingsRepository {
  final DatabaseHelper _dbHelper;
  
  SettingsRepository({required DatabaseHelper dbHelper})
      : _dbHelper = dbHelper;
  
  /// Get settings (singleton row)
  Future<Settings> getSettings() async {
    final db = await _dbHelper.database;
    final result = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    
    if (result.isEmpty) {
      throw Exception('Settings not found');
    }
    
    return Settings.fromMap(result.first);
  }
  
  /// Update settings dengan transaction safety
  Future<void> updateSettings(Settings settings) async {
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        await txn.update(
          'settings',
          settings.toMap(),
          where: 'id = ?',
          whereArgs: [1],
        );
      });
    } catch (e) {
      debugPrint('❌ Failed to update settings: $e');
      rethrow;
    }
  }
  
  /// Update multiple settings atomically
  Future<void> updatePrayerTimeCorrections({
    required Map<PrayerType, int> corrections,
  }) async {
    final db = await _dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        await txn.update(
          'settings',
          {
            'offset_subuh': corrections[PrayerType.subuh],
            'offset_syuruq': corrections[PrayerType.syuruq],
            'offset_dhuha': corrections[PrayerType.dhuha],
            'offset_dzuhur': corrections[PrayerType.dzuhur],
            'offset_ashar': corrections[PrayerType.ashar],
            'offset_maghrib': corrections[PrayerType.maghrib],
            'offset_isya': corrections[PrayerType.isya],
          },
          where: 'id = ?',
          whereArgs: [1],
        );
      });
    } catch (e) {
      debugPrint('❌ Failed to update prayer corrections: $e');
      rethrow;
    }
  }
  
  /// Get all cities grouped by province
  Future<Map<String, List<City>>> getCitiesByProvince() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'cities',
      orderBy: 'province_name ASC, city_name ASC',
    );
    
    final cities = result.map((map) => City.fromMap(map)).toList();
    
    // Group by province
    final grouped = <String, List<City>>{};
    for (final city in cities) {
      grouped.putIfAbsent(city.provinceName, () => []).add(city);
    }
    
    return grouped;
  }
}
```

---

## Timer Management Pattern

Pattern untuk countdown timers dengan proper lifecycle management.

### Countdown Timer Widget

```dart
class CountdownTimer extends StatefulWidget {
  final Duration remainingTime;
  final PrayerTime nextPrayer;
  final bool isPreAdzan;
  
  const CountdownTimer({
    Key? key,
    required this.remainingTime,
    required this.nextPrayer,
    this.isPreAdzan = false,
  }) : super(key: key);
  
  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  
  @override
  void initState() {
    super.initState();
    _remaining = widget.remainingTime;
    _startTimer();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remaining > Duration.zero) {
            _remaining -= const Duration(seconds: 1);
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update timer jika remaining time berubah
    if (widget.remainingTime != oldWidget.remainingTime) {
      _remaining = widget.remainingTime;
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.isPreAdzan 
            ? 'Menuju ${widget.nextPrayer.name}' 
            : 'Iqomah ${widget.nextPrayer.name}',
          style: TextStyle(
            fontSize: 32.sp,
            color: Colors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 32.h),
        
        // Large countdown display
        Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Text(
            _formatTime(hours, minutes, seconds),
            style: const TextStyle(
              fontSize: 96.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
  
  String _formatTime(int hours, int minutes, int seconds) {
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }
}
```

### Periodic Refresh Pattern

```dart
class ClockWidget extends StatefulWidget {
  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _startClock();
  }
  
  void _startClock() {
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Digital clock
        Text(
          DateFormat('HH:mm:ss').format(_currentTime),
          style: TextStyle(
            fontSize: 128.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'monospace',
          ),
        ),
        
        // Date
        Text(
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_currentTime),
          style: TextStyle(
            fontSize: 24.sp,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
```

---

## Setup Wizard Pattern

Pattern untuk first-run setup flow dengan multi-step form.

### Wizard State Machine

```dart
enum SetupStep {
  welcome,
  mosqueIdentity,
  location,
  confirmation,
  completed,
}

class SetupWizardCubit extends Cubit<SetupWizardState> {
  final SettingsRepository _settingsRepository;
  
  SetupWizardCubit({
    required SettingsRepository settingsRepository,
  })  : _settingsRepository = settingsRepository,
        super(const SetupWizardState(
          currentStep: SetupStep.welcome,
          mosqueData: null,
          selectedCity: null,
        ));
  
  void nextStep() {
    final currentStep = state.currentStep;
    
    final nextStep = switch (currentStep) {
      SetupStep.welcome => SetupStep.mosqueIdentity,
      SetupStep.mosqueIdentity => SetupStep.location,
      SetupStep.location => SetupStep.confirmation,
      SetupStep.confirmation => SetupStep.completed,
      SetupStep.completed => SetupStep.completed,
    };
    
    emit(state.copyWith(currentStep: nextStep));
  }
  
  void previousStep() {
    final currentStep = state.currentStep;
    
    final prevStep = switch (currentStep) {
      SetupStep.welcome => SetupStep.welcome,
      SetupStep.mosqueIdentity => SetupStep.welcome,
      SetupStep.location => SetupStep.mosqueIdentity,
      SetupStep.confirmation => SetupStep.location,
      SetupStep.completed => SetupStep.completed,
    };
    
    emit(state.copyWith(currentStep: prevStep));
  }
  
  void setMosqueData({
    required String name,
    required String address,
  }) {
    emit(state.copyWith(
      mosqueData: MosqueData(name: name, address: address),
    ));
  }
  
  void selectCity(City city) {
    emit(state.copyWith(selectedCity: city));
  }
  
  void setManualCoordinates({
    required double latitude,
    required double longitude,
  }) {
    emit(state.copyWith(
      manualCoordinates: Coordinates(latitude, longitude),
    ));
  }
  
  Future<void> completeSetup() async {
    emit(state.copyWith(isSaving: true));
    
    try {
      final mosqueData = state.mosqueData;
      final city = state.selectedCity;
      final manual = state.manualCoordinates;
      
      if (mosqueData == null) {
        throw Exception('Mosque data tidak lengkap');
      }
      
      // Determine coordinates source
      final latitude = manual?.latitude ?? city?.latitude;
      final longitude = manual?.longitude ?? city?.longitude;
      
      if (latitude == null || longitude == null) {
        throw Exception('Koordinat tidak valid');
      }
      
      // Save settings to database
      await _settingsRepository.updateSettings(Settings(
        id: 1,
        isFirstRun: false,
        mosqueName: mosqueData.name,
        mosqueAddress: mosqueData.address,
        cityName: city?.cityName ?? 'Manual',
        latitude: latitude,
        longitude: longitude,
        timezone: 'Asia/Jakarta',
        // Default corrections (0)
        offsetSubuh: 0,
        offsetSyuruq: 0,
        offsetDhuha: 0,
        offsetDzuhur: 0,
        offsetAshar: 0,
        offsetMaghrib: 0,
        offsetIsya: 0,
        // Default Iqomah delays
        iqomahSubuh: 10,
        iqomahDzuhur: 10,
        iqomahAshar: 10,
        iqomahMaghrib: 7,
        iqomahIsya: 10,
        // Default running text
        runningText: 'Selamat datang di ${mosqueData.name}',
      ));
      
      emit(state.copyWith(
        isSaving: false,
        currentStep: SetupStep.completed,
      ));
      
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: e.toString(),
      ));
    }
  }
}
```

### Wizard UI Implementation

```dart
class SetupWizardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<SetupWizardCubit, SetupWizardState>(
        builder: (context, state) {
          return switch (state.currentStep) {
            SetupStep.welcome => _WelcomeStep(),
            SetupStep.mosqueIdentity => _MosqueIdentityStep(),
            SetupStep.location => _LocationStep(),
            SetupStep.confirmation => _ConfirmationStep(),
            SetupStep.completed => _CompletedStep(),
          };
        },
      ),
    );
  }
}

class _LocationStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Pilih Lokasi Masjid',
          style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
        ),
        
        SizedBox(height: 32.h),
        
        // Tab switcher: Pilih Kota vs Manual
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TabButton(
              label: 'Pilih Kota',
              isActive: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
            SizedBox(width: 16.w),
            _TabButton(
              label: 'Koordinat Manual',
              isActive: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
            ),
          ],
        ),
        
        SizedBox(height: 32.h),
        
        // Content based on active tab
        Expanded(
          child: _activeTab == 0 
            ? _buildCitySelector(context)
            : _buildManualCoordinates(context),
        ),
        
        // Navigation buttons
        _buildNavigationButtons(context),
      ],
    );
  }
  
  Widget _buildCitySelector(BuildContext context) {
    return BlocBuilder<CityCubit, CityState>(
      builder: (context, state) {
        if (state is CityLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (state is CitySuccess) {
          return Row(
            children: [
              // Province dropdown
              Expanded(
                child: _buildProvinceDropdown(state.citiesByProvince),
              ),
              
              SizedBox(width: 16.w),
              
              // City dropdown
              Expanded(
                child: _buildCityDropdown(state.citiesInProvince),
              ),
            ],
          );
        }
        
        return Text('Gagal memuat data kota');
      },
    );
  }
}
```

---

## D-Pad Navigation Pattern

Pattern untuk remote control navigation di Android TV.

### Focus Management

```dart
class SettingsMenuItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool autofocus;
  
  const SettingsMenuItem({
    Key? key,
    required this.label,
    required this.onTap,
    this.autofocus = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: autofocus,
      onKey: (node, event) {
        // Handle Enter/Select key
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          
          return InkWell(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: hasFocus 
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.transparent,
                border: Border.all(
                  color: hasFocus ? Colors.amber : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    color: hasFocus ? Colors.amber : Colors.white70,
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: hasFocus ? Colors.white : Colors.white70,
                      fontWeight: hasFocus 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### Custom Focus Traversal

```dart
class PrayerTimeCard extends StatelessWidget {
  final PrayerTime prayerTime;
  final bool isHighlighted;
  final VoidCallback? onFocused;
  
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (hasFocus) {
        if (hasFocus && onFocused != null) {
          onFocused!();
        }
      },
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          
          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isHighlighted
                  ? [Colors.amber.shade700, Colors.amber.shade500]
                  : [Colors.green.shade700, Colors.green.shade900],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: hasFocus ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: hasFocus
                ? [BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )]
                : null,
            ),
            child: Column(
              children: [
                Text(
                  prayerTime.name,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  DateFormat('HH:mm').format(prayerTime.time),
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

## Cubit Pattern untuk MKT

Simplified Cubit pattern tanpa caching, retry, atau network complexity.

### Settings Cubit

```dart
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;
  
  SettingsCubit({required SettingsRepository repository})
      : _repository = repository,
        super(const SettingsInitial());
  
  Future<void> loadSettings() async {
    emit(const SettingsLoading());
    
    try {
      final settings = await _repository.getSettings();
      emit(SettingsSuccess(settings: settings));
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> updateMosqueIdentity({
    required String name,
    required String address,
  }) async {
    // Validate input
    if (name.trim().isEmpty) {
      emit(const SettingsValidationError(
        message: 'Nama masjid tidak boleh kosong',
      ));
      return;
    }
    
    final currentState = state;
    if (currentState is! SettingsSuccess) return;
    
    emit(const SettingsLoading());
    
    try {
      final updatedSettings = currentState.settings.copyWith(
        mosqueName: name.trim(),
        mosqueAddress: address.trim(),
      );
      
      await _repository.updateSettings(updatedSettings);
      emit(SettingsSuccess(settings: updatedSettings));
      
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
  
  Future<void> updatePrayerTimeCorrection({
    required PrayerType type,
    required int minutes,
  }) async {
    // Validation: -10 to +10 minutes
    if (minutes < -10 || minutes > 10) {
      emit(const SettingsValidationError(
        message: 'Koreksi harus antara -10 sampai +10 menit',
      ));
      return;
    }
    
    final currentState = state;
    if (currentState is! SettingsSuccess) return;
    
    try {
      final corrections = {
        PrayerType.subuh: currentState.settings.offsetSubuh,
        PrayerType.syuruq: currentState.settings.offsetSyuruq,
        PrayerType.dhuha: currentState.settings.offsetDhuha,
        PrayerType.dzuhur: currentState.settings.offsetDzuhur,
        PrayerType.ashar: currentState.settings.offsetAshar,
        PrayerType.maghrib: currentState.settings.offsetMaghrib,
        PrayerType.isya: currentState.settings.offsetIsya,
      };
      
      corrections[type] = minutes;
      
      await _repository.updatePrayerTimeCorrections(
        corrections: corrections,
      );
      
      // Reload settings
      await loadSettings();
      
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
}
```

---

## Testing Patterns

### SQLite Repository Testing

```dart
group('SettingsRepository Tests', () {
  late SettingsRepository repository;
  late Database testDb;
  
  setUp(() async {
    // Use in-memory database untuk testing
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        // Create tables sama seperti production
        await db.execute('''CREATE TABLE settings (...)''');
        await db.insert('settings', {
          'id': 1,
          'mosque_name': 'Test Mosque',
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
  
  test('getSettings returns valid settings', () async {
    final settings = await repository.getSettings();
    
    expect(settings.id, equals(1));
    expect(settings.mosqueName, equals('Test Mosque'));
  });
  
  test('updateSettings persists changes', () async {
    final newSettings = Settings(
      id: 1,
      mosqueName: 'Updated Mosque',
      latitude: -7.2575,
      longitude: 112.7521,
    );
    
    await repository.updateSettings(newSettings);
    
    // Verify persisted
    final retrieved = await repository.getSettings();
    expect(retrieved.mosqueName, equals('Updated Mosque'));
  });
});
```

### Cubit Testing

```dart
group('SettingsCubit Tests', () {
  late SettingsCubit cubit;
  late MockSettingsRepository mockRepository;
  
  setUp(() {
    mockRepository = MockSettingsRepository();
    cubit = SettingsCubit(repository: mockRepository);
  });
  
  blocTest<SettingsCubit, SettingsState>(
    'loadSettings emits success state',
    build: () => cubit,
    setUp: () {
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => Settings(
                id: 1,
                mosqueName: 'Test',
                latitude: -6.2088,
                longitude: 106.8456,
              ));
    },
    act: (cubit) => cubit.loadSettings(),
    expect: () => [
      const SettingsLoading(),
      isA<SettingsSuccess>(),
    ],
  );
  
  blocTest<SettingsCubit, SettingsState>(
    'updateMosqueIdentity validates empty name',
    build: () => cubit,
    act: (cubit) => cubit.updateMosqueIdentity(
      name: '',
      address: 'Test Address',
    ),
    expect: () => [
      const SettingsValidationError(
        message: 'Nama masjid tidak boleh kosong',
      ),
    ],
  );
});
```

---

## Quick Reference - Pattern Selection

| Scenario | Pattern to Use |
|----------|---------------|
| Display state transitions | State Machine Pattern |
| Calculate prayer times | Prayer Time Calculation Pattern |
| Store/retrieve data | Offline-First Data Pattern (SQLite) |
| Countdown timers | Timer Management Pattern |
| First-run setup | Setup Wizard Pattern |
| State management | Cubit Pattern untuk MKT |
| Remote navigation | D-Pad Navigation Pattern |
| Auto state changes | UI State Transition Pattern |

---

**Last Updated**: February 17, 2026
**Version**: 2.0.0
**Project**: Miqotul Khoir TV (MKT)
**Platform**: Android TV
**Related Docs**: [AGENTS.md](../AGENTS.md), [Product_Requirement_Document.md](../Product_Requirement_Document.md)
