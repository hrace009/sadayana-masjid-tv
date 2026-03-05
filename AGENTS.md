# AGENTS.md - Miqotul Khoir TV Contributor Guide

Selamat datang di repositori project **Miqotul Khoir TV (MKT)** — aplikasi jam masjid digital dan jadwal sholat berbasis Android TV untuk masjid.

File ini berisi panduan utama untuk kontributor baru dan AI assistant yang bekerja dengan project Flutter/Dart untuk platform Android TV.

**Last Updated**: February 20, 2026

<!-- markdownlint-disable -->

## Repository Overview

- **Main Application**: `lib/main.dart` — Entry point aplikasi
- **Core Layer**: `lib/core/` — Utilities, constants, dan service layer
- **Data Layer**: `lib/data/` — SQLite models, repositories, dan data sources
- **Domain Layer**: `lib/domain/` — Business logic, entities, dan use cases
- **Presentation Layer**: `lib/presentation/` — UI components, pages, dan state management (Cubit)
- **Tests**: `test/` dengan unit, widget, dan integration test directories
- **Assets**: `assets/` untuk images, fonts, dan resources lainnya
- **Specification**: `spec/` untuk technical specification documents (output @SpecificationArchitect)
- **Planning**: `plan/` untuk feature implementation plans dengan task tracking
- **Documentation**: `docs/` untuk technical specifications dan design documents
- **Database**: SQLite lokal untuk settings, city presets, dan konfigurasi

### State Management Structure

```
lib/presentation/cubits/
├── prayer_times/              # Cubit untuk kalkulasi waktu sholat
├── display_state/            # Cubit untuk state machine display
├── settings/                 # Cubit untuk pengaturan masjid
└── setup_wizard/             # Cubit untuk initial setup flow
```

**Pattern**: Cubit digunakan untuk semua state management, dengan fokus pada local data dan state transitions.

## Completed Features (Production Ready)

| Feature | Completion Date | Tests | Status |
|---------|----------------|-------|--------|
| **Database Infrastructure** (Plan 01) | 2026-02-18 | 6 unit tests ✅ | Production Ready |
| **Data Layer** (Plan 02) | 2026-02-18 | 16 unit tests ✅ (total: 22) | Production Ready |
| **Theme System** (Plan 03) | 2026-02-18 | 42 unit tests ✅ (total: 64) | Production Ready |
| **Prayer Time Logic** (Plan 05) | 2026-02-19 | Unit tests ✅ | Production Ready |
| **Prayer Time State** (Plan 06) | 2026-02-19 | Cubit tests ✅ | Production Ready |
| **Display State Logic** (Plan 07) | 2026-02-19 | Unit tests ✅ | Production Ready |
| **Display State Machine** (Plan 08) | 2026-02-19 | Cubit tests ✅ | Production Ready |
| **Setup Wizard Logic** (Plan 09) | 2026-02-20 | Cubit tests ✅ | Production Ready |
| **Setup Wizard UI** (Plan 10) | 2026-02-20 | Widget tests ✅ | Production Ready |
| **Settings Logic** (Plan 11) | 2026-02-20 | Unit tests ✅ | Production Ready |

### Plan 01 — Database Infrastructure (COMPLETED)

File yang dibuat/dimodifikasi:

| File | Keterangan |
|------|------------|
| `lib/data/datasources/database_helper.dart` | Singleton `DatabaseHelper` — schema DDL, seed, migration, testing hooks |
| `assets/data/cities.json` | 514 kota/kabupaten, 34 provinsi Indonesia (71.7 KB) |
| `tools/generate_cities.py` | Script generator dataset kota dari BPS/wilayah-indonesia |
| `test/data/datasources/database_helper_test.dart` | 6 unit tests dengan `sqflite_common_ffi` in-memory |

Dependencies yang ditambahkan:

```yaml
dependencies:
  sqflite: ^2.4.1
  path: ^1.9.1

dev_dependencies:
  sqflite_common_ffi: ^2.4.0+2
```

### Plan 02 — Data Layer (COMPLETED)

File yang dibuat:

| File | Keterangan |
|------|------------|
| `lib/domain/entities/settings.dart` | Immutable `Settings` entity — 27 fields, `Equatable`, `copyWith()` |
| `lib/domain/entities/city.dart` | Immutable `City` entity — 5 fields, `Equatable` |
| `lib/domain/repositories/settings_repository.dart` | Abstract `SettingsRepository` interface (zero infra imports) |
| `lib/domain/repositories/city_repository.dart` | Abstract `CityRepository` interface (zero infra imports) |
| `lib/data/models/settings_model.dart` | `SettingsModel` — `fromMap`/`toMap`, snake_case ↔ camelCase, int ↔ bool |
| `lib/data/models/city_model.dart` | `CityModel` — `fromMap`/`toMap` |
| `lib/data/datasources/settings_local_data_source.dart` | SQLite ops — transactional writes, auto `updated_at` |
| `lib/data/datasources/city_local_data_source.dart` | SQLite ops — LIKE search dengan input sanitization |
| `lib/data/repositories/settings_repository_impl.dart` | Concrete impl — SHA-256 PIN hashing via `crypto` |
| `lib/data/repositories/city_repository_impl.dart` | Concrete impl — pure delegation ke data source |
| `test/data/models/settings_model_test.dart` | 4 tests: fromMap default/custom, toMap, round-trip |
| `test/data/models/city_model_test.dart` | 3 tests: fromMap, toMap, round-trip |
| `test/data/repositories/settings_repository_impl_test.dart` | 5 tests: defaults, update, firstRun, PIN lifecycle |
| `test/data/repositories/city_repository_impl_test.dart` | 4 tests: provinces, citiesByProvince, search, getById |

Dependencies yang ditambahkan:

```yaml
dependencies:
  equatable: 2.0.8   # Value equality untuk entities
  crypto: 3.0.7      # SHA-256 PIN hashing
```

### Plan 03 — Theme System (COMPLETED)

File yang dibuat/dimodifikasi:

| File | Keterangan |
|------|------------|
| `lib/core/theme/islamic_colors.dart` | 21 color constants — Primary, Accent, Background, Text, Glass, State, Prayer |
| `lib/core/theme/islamic_typography.dart` | 7 text styles — Poppins font, `.sp` responsive, optional overrides |
| `lib/core/theme/islamic_theme.dart` | Material3 `ThemeData` — ColorScheme, TextTheme, AppBar, Card |
| `lib/core/theme/tv_safe_area.dart` | `TVSafeArea` widget — 5% margin, `ignoreSafeArea` bypass |
| `lib/main.dart` | `ScreenUtilInit` (1920×1080), landscape lock, `IslamicTheme.darkTheme()` |
| `test/core/theme/islamic_colors_test.dart` | 15 tests: hex values, opacity validation, prayer state aliases |
| `test/core/theme/islamic_typography_test.dart` | 10 tests: all 7 methods + optional parameter overrides |
| `test/core/theme/islamic_theme_test.dart` | 17 tests: Material3, ColorScheme, TextTheme, AppBar, Card |

Dependencies yang ditambahkan:

```yaml
dependencies:
  flutter_screenutil: ^5.9.3  # Responsive scaling (.sp, .w, .h, .r)
  google_fonts: ^8.0.1        # Dynamic font loading (Poppins)
```


### Plan 05 — Prayer Time Calculation (COMPLETED)

File yang dibuat:

| File | Keterangan |
|------|------------|
| `lib/domain/usecases/calculate_prayer_times_use_case.dart` | Core calculation logic |
| `lib/domain/entities/prayer_time.dart` | Entity definition |
| `test/domain/usecases/calculate_prayer_times_use_case_test.dart` | Unit tests |

Dependencies: `adhan`, `hijri`, `intl`

### Plan 06 — Prayer Time Cubit (COMPLETED)

File yang dibuat:

| File | Keterangan |
|------|------------|
| `lib/presentation/cubits/prayer_time/prayer_time_cubit.dart` | State management |
| `lib/presentation/cubits/prayer_time/prayer_time_state.dart` | State definition |
| `test/presentation/cubits/prayer_time/prayer_time_cubit_test.dart` | Cubit tests |

Dependencies: `flutter_bloc`, `bloc_test`, `mocktail`

### Plan 07 — State Evaluation (COMPLETED)

File yang dibuat:

| File | Keterangan |
|------|------------|
| `lib/domain/usecases/evaluate_display_state_use_case.dart` | Core state transition logic |
| `lib/domain/entities/display_state.dart` | Entity definition |
| `test/domain/usecases/evaluate_display_state_use_case_test.dart` | Unit tests |

### Plan 08 — Display State Machine (COMPLETED)

File yang dibuat:

| File | Keterangan |
|------|------------|
| `lib/presentation/cubits/display_state/display_state_cubit.dart` | State machine implementation |
| `lib/presentation/cubits/display_state/display_state.dart` | State definition |
| `test/presentation/cubits/display_state/display_state_cubit_test.dart` | Cubit tests |

### Plan 09 — Setup Wizard Logic (COMPLETED)

File yang dibuat:

| File | Keterangan |
|------|------------|
| `lib/presentation/cubits/setup_wizard/setup_wizard_cubit.dart` | Setup flow logic |
| `lib/presentation/cubits/setup_wizard/setup_wizard_state.dart` | Wizard states |
| `test/presentation/cubits/setup_wizard/setup_wizard_cubit_test.dart` | Cubit tests |

### Plan 10 — Setup Wizard UI (COMPLETED)

File yang dibuat:

| File | Keterangan |
|------|------------|
| `lib/presentation/pages/setup_wizard/setup_wizard_page.dart` | Root container, step navigation, step indicator |
| `lib/presentation/pages/setup_wizard/steps/welcome_step.dart` | Step 1: Branding & Welcome screen |
| `lib/presentation/pages/setup_wizard/steps/identity_step.dart` | Step 2: Input Nama & Alamat Masjid |
| `lib/presentation/pages/setup_wizard/steps/location_step.dart` | Step 3: Cascading Province → City Picker |
| `lib/presentation/pages/setup_wizard/steps/preview_step.dart` | Step 4: Summary data & prayer time preview |
| `lib/presentation/widgets/step_indicator_widget.dart` | Visual progress indicator (1-4) |
| `lib/presentation/pages/splash_page.dart` | Startup logic: check `isFirstRun` → route to Wizard/Main |
| `test/presentation/pages/setup_wizard/setup_wizard_page_test.dart` | Comprehensive widget tests for all steps |

Dependencies yang digunakan:
- `flutter_bloc`: State management
- `flutter_screenutil`: Responsive layout
- `google_fonts`: Typography

### Plan 11 — Settings Logic (COMPLETED)

File yang dibuat:

| File | Keterangan |
|------|------------|
| `lib/presentation/cubits/settings/settings_cubit.dart` | `SettingsCubit` implementasi auto-save & PIN logic |
| `lib/presentation/cubits/settings/settings_state.dart` | State definitions (Initial, Loading, Loaded, Error) |
| `lib/presentation/cubits/settings/settings.dart` | Barrel export file |
| `test/presentation/cubits/settings/settings_cubit_test.dart` | Comprehensive unit tests (auto-save debounce, PIN, update logic) |

Dependencies yang digunakan:
- `flutter_bloc`: State management
- `equatable`: State comparison
- `bloc_test`: Testing utilities
- `mocktail`: Mocking dependencies

## Local Workflow

Essential commands untuk memulai development:

```bash
flutter doctor && flutter pub get    # Setup environment
dart format . && dart analyze       # Code quality check
flutter test --reporter=expanded    # Run tests (REQUIRED format)
flutter run              # Development di Android Emulator
flutter run -d windows              # Development di Windows
flutter run -d <android-tv-id>      # Deploy ke Android TV
```

Untuk comprehensive workflow termasuk testing procedures dan deployment strategies, lihat [Development Workflow Guide](docs/DEVELOPMENT_WORKFLOW.md).

## Quick Reference Guides

Untuk detailed implementation guidance, lihat dokumentasi specialized kami:

- **[Specification Overview](docs/SPECIFICATION_OVERVIEW.md)** - Overview 6 technical specs, dependency map, key design decisions, dan recommended execution order
- **[Architecture Patterns](docs/ARCHITECTURE_PATTERNS.md)** - State machine pattern, offline-first data, prayer time calculation, timer management, dan setup wizard patterns
- **[Development Workflow](docs/DEVELOPMENT_WORKFLOW.md)** - Git workflow, commit standards, testing procedures, dan code quality guidelines
- **[Execution Workflow](docs/EXECUTION_WORKFLOW.md)** - Phased execution strategy dengan checkpoint gates, testing verification, dan user approval workflow
- **[Testing Guide](docs/TESTING_GUIDE.md)** - Comprehensive testing strategies untuk SQLite, Cubit, dan widget testing
- **[UI/UX Guide](docs/UI_UX_GUIDE.md)** - Android TV design guidelines, D-Pad navigation, glassmorphism theme, dan remote-friendly UI patterns

## Proven Implementation Patterns

### Architecture Patterns

| Pattern | Description | When to Use |
|---------|-------------|-------------|
| **State Machine Pattern** | 5-state display transition (STANDBY → PRE-ADZAN → ADZAN → IQOMAH → SHOLAT) | Core display logic |
| **Offline-First Data** | SQLite sebagai single source of truth | Semua data persistence |
| **Prayer Time Calculation** | Astronomical calculation dengan adhan-dart + manual correction | Jadwal sholat |
| **Timer Management** | Countdown timers dengan lifecycle management | Adzan, Iqomah countdowns |
| **Setup Wizard Pattern** | Multi-step first-run configuration | Initial setup |
| **Cubit Pattern** | Simple state management tanpa events | Semua features |

### UI Patterns

| Pattern | Description | When to Use |
|---------|-------------|-------------|
| **D-Pad Navigation** | Focus traversal dengan remote control | Semua interactive UI |
| **Landscape 16:9 Layout** | Fixed orientation untuk TV display | Semua pages |
| **State-Based Display** | UI berubah otomatis berdasarkan state machine | Main display screen |
| **Countdown Timer Widget** | Large countdown dengan auto-refresh | Pre-Adzan, Iqomah states |
| **Marquee Running Text** | Scrolling text di footer | Information display |
| **Glassmorphism Card** | Semi-transparent cards dengan blur effect | Prayer time cards |
| **Screen Burn-in Prevention** | Auto-dimming dan blank screen saat sholat | SHOLAT state |
| **ScreenUtil Responsive** | Proportional scaling via `flutter_screenutil` (design size 1920×1080) | Semua sizing dan font |

## Style Notes

- Follow Effective Dart guidelines untuk code style
- Gunakan `const` constructors dimana mungkin untuk performance
- Prefer Stateless widgets over Stateful ketika state tidak diperlukan
- Gunakan meaningful names sesuai Dart naming conventions
- Implement proper error handling dengan try-catch blocks
- Gunakan `async`/`await` untuk asynchronous operations
- **Android TV Specific**: Semua interactive elements harus accessible via D-Pad

### Islamic Glassmorphism Theme

Project ini mengimplementasikan **Modern Islamic Glassmorphism** design system:

- **Primary Color**: Deep Emerald Green (`#004D40`)
- **Accent Color**: Gold / Amber (`#FFD700`)
- **Background**: Masjid image dengan dark overlay
- **Clock Font**: Digital monospace bold font
- **Text Font**: Sans-serif (Montserrat / Roboto)
- **Glass Effect**: Semi-transparent containers dengan blur backdrop

## Commit Message Format

Gunakan conventional commit format untuk consistent versioning dan changelog generation. Lihat [Development Workflow Guide](docs/DEVELOPMENT_WORKFLOW.md) untuk detailed examples dan standards.

## Git Control Policy (CRITICAL)

**DILARANG KERAS** melakukan command berikut secara otomatis tanpa izin eksplisit dari user:
- `git commit`
- `git push`

Agent harus selalu:
1. Menjelaskan perubahan yang akan di-commit
2. Meminta konfirmasi user
3. Baru melakukan commit/push setelah diizinkan

## Pull Request Expectations

PRs should include:

- **Summary**: Clear description of functionality dan perubahan UX
- **Screenshots**: Visual proof dari Android TV device atau emulator
- **Performance impact**: Frame rate dan memory usage considerations
- **Platform compatibility**: Testing pada Android TV 7.0+ (API Level 24+)
- **D-Pad navigation**: Verifikasi bahwa semua elements accessible via remote

Before submitting, ensure:

- [ ] All tests pass (`flutter test`)
- [ ] No analyzer warnings (`dart analyze`)
- [ ] Code is formatted (`dart format .`)
- [ ] App builds successfully untuk Android TV
- [ ] UI berfungsi dengan D-Pad remote control
- [ ] Tidak ada memory leaks dari timers
- [ ] Performance acceptable (60fps target)
- [ ] SQLite transactions benar dan aman

## What Reviewers Look For

- **Widget architecture**: Proper widget composition dan separation of concerns
- **State management**: Effective use of Cubit patterns dan state handling
- **Offline-first compliance**: Semua data access melalui SQLite, tidak ada network calls
- **Performance**: Efficient rendering dan memory management
- **Android TV compliance**: Following Android TV design guidelines
- **D-Pad navigation**: Proper focus management dan keyboard/remote handling
- **Code quality**: Null safety compliance dan error handling
- **Timer management**: Proper disposal dan lifecycle handling
- **SQLite safety**: Transaction management dan error handling
- **Prayer time accuracy**: Correct astronomical calculations dan manual corrections

## Common Pitfalls & Solutions

### 1. Timer Memory Leaks

**Issue**: Timers tidak di-dispose saat widget destroyed, menyebabkan memory leak.

**Problem**:
```dart
// ❌ WRONG - Timer tidak di-dispose
class ClockWidget extends StatefulWidget {
  @override
  _ClockWidgetState createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {}); // Update clock
    });
  }
  // Missing dispose()!
}
```

**Solution**:
```dart
// ✅ CORRECT - Timer di-dispose dengan benar
class _ClockWidgetState extends State<ClockWidget> {
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) { // Check mounted before setState
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel(); // Cancel timer
    _timer = null;
    super.dispose();
  }
}
```

**Why This Works**:
- Timer di-cancel sebelum widget destroyed
- `mounted` check prevents setState on unmounted widget
- Null safety dengan `_timer?`
- Prevents memory leaks dan runtime errors

**Real Case Pattern**: Semua countdown timers dan clock widgets harus implement pattern ini.

### 2. D-Pad Focus Traversal

**Issue**: UI elements tidak bisa di-navigate dengan remote control.

**Problem**:
```dart
// ❌ WRONG - No focus management
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return Card(
      child: Text(items[index]),
    );
  },
)
```

**Solution**:
```dart
// ✅ CORRECT - Proper focus management
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return Focus(
      autofocus: index == 0, // First item auto-focused
      onKey: (node, event) {
        // Handle custom key events if needed
        return KeyEventResult.ignored;
      },
      child: InkWell(
        onTap: () => _handleSelection(index),
        child: Card(
          child: Text(items[index]),
        ),
      ),
    );
  },
)
```

**Prevention**:
1. **Wrap interactive elements** dengan `Focus` widget
2. **Set autofocus** pada first item atau active item
3. **Test dengan keyboard** di desktop sebelum deploy ke TV
4. **Verify focus indicators** terlihat jelas

**Real Case Pattern**: Setup Wizard, Settings Menu, City Selector harus implement focus management.

### 3. SQLite Transaction Safety

**Issue**: Data corruption saat mati listrik mendadak karena tidak menggunakan transaction.

**Problem**:
```dart
// ❌ WRONG - No transaction, data bisa corrupt
Future<void> updateSettings(Settings settings) async {
  final db = await database;
  await db.update('settings', settings.toMap(), where: 'id = ?', whereArgs: [1]);
  await db.update('cities', cityData, where: 'id = ?', whereArgs: [settings.cityId]);
  // Jika mati listrik di sini, data inkonsisten!
}
```

**Solution**:
```dart
// ✅ CORRECT - Atomic transaction
Future<void> updateSettings(Settings settings) async {
  final db = await database;
  await db.transaction((txn) async {
    await txn.update('settings', settings.toMap(), 
      where: 'id = ?', whereArgs: [1]);
    await txn.update('cities', cityData, 
      where: 'id = ?', whereArgs: [settings.cityId]);
  });
  // Transaction ensures atomic operation
}
```

**Why This Matters**:
- **Atomic operations**: All-or-nothing guarantee
- **Data integrity**: Prevents partial updates
- **Power-safe**: Critical untuk device yang bisa mati listrik
- **Rollback support**: Automatic rollback on error

**Prevention**:
1. **Always use transactions** untuk multiple writes
2. **Test edge cases** dengan simulated interruptions
3. **Validate data** sebelum commit
4. **Handle errors** dengan proper rollback

**Real Cases**: Update settings dengan prayer time corrections, initial setup wizard data save.

### 4. Prayer Time Calculation Edge Cases

**Issue**: Prayer times incorrect pada tanggal tertentu atau lokasi ekstrem.

**Example**:
```dart
// ❌ WRONG - No validation atau error handling
PrayerTimes calculatePrayerTimes(DateTime date, Coordinates coords) {
  // ❌ No Kemenag RI params configured — menggunakan method default
  final params = CalculationMethod.other.getParameters();
  return PrayerTimes(coords, date, params);
  // Bagaimana jika coords invalid? Bagaimana di polar regions?
}
```

**Solution**:
```dart
// ✅ CORRECT - Proper validation dan fallback
PrayerTimes? calculatePrayerTimes(DateTime date, Coordinates coords) {
  // Validate coordinates
  if (coords.latitude < -90 || coords.latitude > 90) {
    debugPrint('❌ Invalid latitude: ${coords.latitude}');
    return null;
  }
  
  if (coords.longitude < -180 || coords.longitude > 180) {
    debugPrint('❌ Invalid longitude: ${coords.longitude}');
    return null;
  }
  
  try {
    // Kemenag RI (SIHAT): Subuh 20°, Isya 18°, Ihtiyat +2 menit
    final params = CalculationMethod.other.getParameters();
    params.fajrAngle = 20.0;
    params.ishaAngle = 18.0;
    params.adjustments.fajr = 2;
    params.adjustments.sunrise = -2;
    params.adjustments.dhuhr = 2;
    params.adjustments.asr = 2;
    params.adjustments.maghrib = 2;
    params.adjustments.isha = 2;
    final times = PrayerTimes(coords, date, params);
    
    // Apply manual corrections
    return _applyCorrections(times);
  } catch (e) {
    debugPrint('❌ Prayer time calculation failed: $e');
    return null;
  }
}
```

**Prevention**:
1. **Validate coordinates** sebelum calculation
2. **Handle edge cases** (polar regions, extreme latitudes)
3. **Apply manual corrections** dari database
4. **Test dengan berbagai lokasi** (equator, tropics, high latitudes)
5. **Log calculation errors** untuk debugging

**Real Case**: Setup Wizard coordinate validation, daily prayer time refresh.

### 5. Screen Burn-in Prevention

**Issue**: Static content di TV menyebabkan screen burn-in pada OLED displays.

**Problem**:
```dart
// ❌ WRONG - Static clock selalu di posisi sama
Container(
  alignment: Alignment.topRight,
  child: Text(
    currentTime,
    style: TextStyle(fontSize: 48, color: Colors.white),
  ),
)
// Jam selalu di posisi sama → burn-in risk!
```

**Solution**:
```dart
// ✅ CORRECT - Implement SHOLAT state dengan dimmed/blank screen
BlocBuilder<DisplayStateCubit, DisplayState>(
  builder: (context, state) {
    if (state is SholatState) {
      // Option 1: Blank screen
      return Container(color: Colors.black);
      
      // Option 2: Dimmed clock yang bergerak
      return _buildDimmedMovingClock();
    }
    return _buildNormalDisplay();
  },
)

Widget _buildDimmedMovingClock() {
  // Clock position berubah sedikit tiap menit
  final offset = _calculatePositionOffset();
  return Positioned(
    left: offset.dx,
    top: offset.dy,
    child: Text(
      currentTime,
      style: TextStyle(fontSize: 24, color: Colors.grey.withOpacity(0.3)),
    ),
  );
}
```

**Prevention**:
1. **Implement SHOLAT state** dengan blank/dimmed screen
2. **Vary position** untuk elements yang selalu visible
3. **Use lower brightness** saat idle
4. **Auto screen-off** setelah durasi sholat
5. **Test pada OLED devices** jika memungkinkan

**Real Case**: State machine SHOLAT state, idle timeout setelah Iqomah.

## Flutter Architecture Guidelines

- Follow Clean Architecture principles dengan clear layer separation
- Gunakan Feature-First directory structure untuk scalability
- Implement Repository pattern untuk data access abstraction
- Apply MVVM pattern dengan proper separation of concerns
- Gunakan dependency injection untuk better testability
- **Offline-First**: SQLite sebagai single source of truth, tidak ada network calls

## Widget Best Practices

- Prefer composition over inheritance untuk widget design
- Gunakan `const` constructors untuk improve performance
- Implement proper `Key` usage untuk widget identity
- Create reusable widgets dengan clear, focused responsibilities
- Gunakan `Builder` widgets untuk manage context scope appropriately
- Implement proper disposal of resources di `dispose()` methods
- **Android TV**: Ensure proper focus management untuk semua interactive widgets

## State Management

Project ini menggunakan **Flutter BLoC (Cubit)** untuk state management dengan pattern sebagai berikut:

### Cubit Pattern Guidelines

- Gunakan **Cubit** untuk semua state management (simple, no events needed)
- Apply Clean Architecture dengan SQLite repository pattern
- Gunakan **Equatable** untuk state classes untuk proper state comparison
- Implement proper dependency injection dengan BlocProvider
- **No caching needed**: SQLite sudah menjadi persistent cache
- **No retry mechanism**: Offline-first berarti tidak ada network errors

### State Management Examples

Untuk detailed implementation examples dan patterns, lihat [Architecture Patterns Guide](docs/ARCHITECTURE_PATTERNS.md).

Key patterns covered:

- **Cubit Pattern untuk MKT**: Standard state management implementation
- **State Machine Pattern**: Display state transitions
- **Timer State Pattern**: Countdown dan periodic updates
- **Settings State Pattern**: SQLite-backed configuration management

## Testing

Untuk comprehensive testing strategies termasuk SQLite testing, Cubit testing, dan widget testing, lihat [Testing Guide](docs/TESTING_GUIDE.md).

Basic testing workflow:

Semua testing commands dan detailed procedures didokumentasikan di [Development Workflow Guide](docs/DEVELOPMENT_WORKFLOW.md).

**Required**: Selalu gunakan `flutter test --reporter=expanded` untuk detailed debugging output.

### Testing Priority

1. **SQLite Operations**: Test semua CRUD operations dan transactions
2. **Prayer Time Calculations**: Test dengan berbagai coordinates dan dates
3. **State Machine Transitions**: Test semua state transitions
4. **Timer Management**: Test lifecycle dan disposal
5. **Widget Tests**: Test D-Pad navigation dan focus management

## Performance

Untuk detailed performance optimization strategies dan best practices, lihat [Performance Guide](docs/PERFORMANCE_GUIDE.md).

Key performance principles:

- Minimize `setState()` calls dalam timer callbacks
- Gunakan `const` constructors dimana mungkin
- Implement proper timer disposal untuk prevent memory leaks
- Optimize SQLite queries dengan proper indexing
- Monitor performance dengan Flutter DevTools
- **Target**: 60 FPS rendering pada Android TV devices

## UI/UX

Untuk comprehensive UI/UX design principles dan Android TV best practices, lihat [UI/UX Guide](docs/UI_UX_GUIDE.md).

Essential UI/UX guidelines:

- Follow Android TV design guidelines (Leanback library concepts)
- Implement D-Pad navigation untuk semua interactive elements
- Support remote control dengan clear focus indicators
- Gunakan Landscape 16:9 layout (1920x1080 design size, adaptive via ScreenUtil)
- Gunakan `flutter_screenutil` extensions (`.sp`, `.w`, `.h`, `.r`) untuk responsive sizing
- Implement Islamic Glassmorphism theme dengan consistency
- Ensure text readable dari jarak (min 24.sp untuk body text)

## Security & Data Integrity

Core security dan data integrity practices:

- Validate semua user inputs (coordinates, text fields)
- Gunakan SQLite transactions untuk data integrity
- Implement proper error handling dan graceful degradation
- Handle edge cases untuk prayer time calculations
- No sensitive data (karena offline-first, no authentication)
- Prevent SQL injection dengan parameterized queries

## Platform-Specific Considerations

### Android TV Requirements

- **Minimum API Level**: 24 (Android 7.0)
- **Target API Level**: Latest stable
- **Required Features**: LEANBACK, TV banner icon
- **Orientation**: Locked to Landscape
- **Navigation**: D-Pad/Remote control only (no touch)
- **Launcher**: Configured as TV launcher atau boot on startup

### Manifest Configuration

Ensure `AndroidManifest.xml` includes:
- `<uses-feature android:name="android.software.leanback" android:required="true" />`
- `<uses-feature android:name="android.hardware.touchscreen" android:required="false" />`
- `screenOrientation="landscape"` for all activities

---

**Last Updated**: February 20, 2026
**Version**: 2.0.0
**Project**: Miqotul Khoir TV (MKT)
**Platform**: Android TV
**Related Docs**: [ARCHITECTURE_PATTERNS.md](docs/ARCHITECTURE_PATTERNS.md), [Product_Requirement_Document.md](Product_Requirement_Document.md)
