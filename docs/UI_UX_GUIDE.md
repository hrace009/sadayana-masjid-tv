# Flutter UI/UX Guide - Miqotul Khoir TV

This guide covers Android TV UI/UX design principles, D-Pad navigation patterns, Islamic Glassmorphism theme, and accessibility best practices for the Miqotul Khoir TV Flutter application.

## Overview

Our UI/UX approach focuses on:

- **Android TV Leanback Design**: 10-foot viewing distance, large touch targets, D-Pad navigation
- **Islamic Glassmorphism Theme**: Deep Emerald Green palette with Gold/Amber accents
- **D-Pad First Navigation**: Remote control as primary input method
- **16:9 Landscape Layout**: Design size 1920x1080, adaptive ke semua resolusi TV
- **Responsive Scaling**: `flutter_screenutil` untuk scale proporsional di 720p, 1080p, 2K, 4K
- **Screen Burn-in Prevention**: OLED protection strategies
- **State-Based UI**: Different layouts for STANDBY, PRE-ADZAN, ADZAN, IQOMAH, SHOLAT states

## ScreenUtil Initialization

Aplikasi menggunakan `flutter_screenutil` untuk responsive scaling across berbagai resolusi Android TV (720p → 4K). Design size baseline: **1920×1080**.

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Design baseline: Full HD (1920x1080)
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Miqotul Khoir TV',
          home: MainDisplayPage(),
        );
      },
    );
  }
}
```

### Sizing Extensions

| Extension | Penggunaan | Contoh |
|-----------|------------|--------|
| `.w` | Width-relative sizing | `96.w` (TV-safe margin) |
| `.h` | Height-relative sizing | `60.h` (running text height) |
| `.r` | Radius (min of w/h) | `16.r` (border radius) |
| `.sp` | Font size (scalable) | `96.sp` (heading large) |

## Android TV Design Principles

### 10-Foot UI Design

Design for viewing from 10 feet (3 meters) away:

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ✅ Use large font sizes with ScreenUtil for TV viewing distance
class TVTypography {
  // Minimum sizes for readability from 10 feet (scaled via .sp)
  static double get headingLarge => 96.sp;   // Main clock, countdown
  static double get headingMedium => 48.sp;  // Prayer names, state labels
  static double get bodyLarge => 32.sp;      // Prayer time cards
  static double get bodyMedium => 24.sp;     // Running text, info labels
  static double get caption => 18.sp;        // Timestamps, meta info
}

// Usage example
Text(
  '04:30',
  style: TextStyle(
    fontSize: TVTypography.headingLarge, // 96.sp scales to any TV resolution
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
  ),
);
```

### TV-Safe Zones

Older TVs may crop edges. Use safe zones:

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ✅ Add margins to prevent edge cropping (responsive)
class TVSafeArea extends StatelessWidget {
  final Widget child;
  
  const TVSafeArea({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      // 5% safe zone, scales proportionally via .w
      padding: EdgeInsets.symmetric(
        horizontal: 96.w,  // 5% of 1920
        vertical: 54.h,    // 5% of 1080
      ),
      child: child,
    );
  }
}

// Usage
TVSafeArea(
  child: MainDisplayContent(),
)
```

### Adaptive 16:9 Landscape Layout

Design with 1920×1080 as baseline, ScreenUtil handles scaling:

```dart
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ✅ Adaptive layout — ScreenUtil scales from 1920x1080 baseline
class LandscapeLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.sw,  // Full screen width
      height: 1.sh, // Full screen height
      child: Stack(
        children: [
          // Background
          _buildBackground(),
          
          // Content layout
          Row(
            children: [
              // Left side: Clock (2/3 width)
              Expanded(
                flex: 2,
                child: _buildClock(),
              ),
              
              // Right side: Info panel (1/3 width)
              Expanded(
                flex: 1,
                child: _buildInfoPanel(),
              ),
            ],
          ),
          
          // Bottom: Prayer time cards
          Positioned(
            bottom: 120.h,
            left: 96.w,
            right: 96.w,
            child: _buildPrayerTimeCards(),
          ),
          
          // Very bottom: Running text
          Positioned(
            bottom: 48.h,
            left: 0,
            right: 0,
            child: _buildRunningText(),
          ),
        ],
      ),
    );
  }
}
```

## Islamic Glassmorphism Theme

### Color Palette

```dart
// Deep Emerald Green dengan Gold/Amber accents
class IslamicTheme {
  // Primary Colors
  static const Color deepEmeraldPrimary = Color(0xFF064E3B);    // Dark green
  static const Color emeraldSecondary = Color(0xFF047857);      // Medium green
  static const Color emeraldLight = Color(0xFF10B981);         // Light green
  
  // Accent Colors
  static const Color goldAccent = Color(0xFFFFD700);          // Gold
  static const Color amberAccent = Color(0xFFFFC107);         // Amber
  static const Color amberDark = Color(0xFFFF8F00);          // Dark amber
  
  // Glassmorphism
  static Color glassBackground = Colors.white.withOpacity(0.1);
  static Color glassBackgroundDark = Colors.black.withOpacity(0.2);
  
  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFE5E7EB);      // Light gray
  static const Color textTertiary = Color(0xFF9CA3AF);       // Medium gray
}
```

### Glassmorphism Card Design

```dart
// ✅ Glassmorphism card dengan blur effect
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final Color? backgroundColor;
  final Color? borderColor;
  
  const GlassmorphismCard({
    Key? key,
    required this.child,
    this.width = 300,
    this.height = 200,
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                backgroundColor ?? IslamicTheme.glassBackground,
                backgroundColor?.withOpacity(0.05) ?? 
                  IslamicTheme.glassBackground.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor ?? IslamicTheme.goldAccent.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// Usage
GlassmorphismCard(
  width: 350.w,
  height: 180.h,
  child: Padding(
    padding: EdgeInsets.all(24.r),
    child: Column(
      children: [
        Text('SUBUH', style: TextStyle(fontSize: 24.sp, color: IslamicTheme.textPrimary)),
        SizedBox(height: 16.h),
        Text('04:30', style: TextStyle(fontSize: 48.sp, fontWeight: FontWeight.bold)),
      ],
    ),
  ),
)
```

### Background Patterns

```dart
// ✅ Islamic geometric pattern background
class IslamicPatternBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 1.sh,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            IslamicTheme.deepEmeraldPrimary,
            IslamicTheme.emeraldSecondary,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Opacity(
            opacity: 0.05,
            child: Image.asset(
              'assets/images/islamic_pattern.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Gradient overlay for depth
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## D-Pad Navigation Patterns

### Focus Management

```dart
// ✅ Proper focus management untuk D-Pad navigation
class FocusableMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool autofocus;
  
  const FocusableMenuItem({
    Key? key,
    required this.label,
    required this.icon,
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
          
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              decoration: BoxDecoration(
                gradient: hasFocus
                    ? LinearGradient(
                        colors: [
                          IslamicTheme.goldAccent,
                          IslamicTheme.amberAccent,
                        ],
                      )
                    : null,
                color: hasFocus ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: hasFocus 
                    ? IslamicTheme.goldAccent 
                    : IslamicTheme.textTertiary.withOpacity(0.3),
                  width: hasFocus ? 3 : 1,
                ),
                boxShadow: hasFocus
                    ? [
                        BoxShadow(
                          color: IslamicTheme.goldAccent.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 32.sp,
                    color: hasFocus 
                      ? IslamicTheme.deepEmeraldPrimary 
                      : IslamicTheme.textPrimary,
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal,
                      color: hasFocus 
                        ? IslamicTheme.deepEmeraldPrimary 
                        : IslamicTheme.textPrimary,
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

### Focus Indicators

```dart
// ✅ Visible focus indicators untuk navigasi
class PrayerTimeCard extends StatelessWidget {
  final String name;
  final String time;
  final bool isNext;
  
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          
          return AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isNext
                    ? [IslamicTheme.goldAccent, IslamicTheme.amberAccent]
                    : [IslamicTheme.emeraldSecondary, IslamicTheme.deepEmeraldPrimary],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: hasFocus ? Colors.white : Colors.transparent,
                width: 4,
              ),
              boxShadow: hasFocus
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: isNext ? IslamicTheme.deepEmeraldPrimary : Colors.white,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isNext ? IslamicTheme.deepEmeraldPrimary : Colors.white,
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

### Directional Navigation

```dart
// ✅ Custom focus traversal order
class SettingsMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: [
          FocusTraversalOrder(
            order: NumericFocusOrder(1.0),
            child: FocusableMenuItem(
              label: 'Identitas Masjid',
              icon: Icons.mosque,
              autofocus: true,
              onTap: () => _navigateToMosqueIdentity(),
            ),
          ),
          
          FocusTraversalOrder(
            order: NumericFocusOrder(2.0),
            child: FocusableMenuItem(
              label: 'Lokasi',
              icon: Icons.location_on,
              onTap: () => _navigateToLocation(),
            ),
          ),
          
          FocusTraversalOrder(
            order: NumericFocusOrder(3.0),
            child: FocusableMenuItem(
              label: 'Koreksi Waktu Sholat',
              icon: Icons.access_time,
              onTap: () => _navigateToPrayerCorrection(),
            ),
          ),
          
          FocusTraversalOrder(
            order: NumericFocusOrder(4.0),
            child: FocusableMenuItem(
              label: 'Iqomah',
              icon: Icons.timer,
              onTap: () => _navigateToIqomah(),
            ),
          ),
        ],
      ),
    );
  }
}
```

## State-Based UI Layouts

### STANDBY Layout

```dart
// ✅ Default display dengan semua info
class StandbyLayout extends StatelessWidget {
  final StandbyState state;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IslamicPatternBackground(),
        
        TVSafeArea(
          child: Column(
            children: [
              // Header: Logo + Nama Masjid + Tanggal
              _buildHeader(state),
              
              SizedBox(height: 32.h),
              
              // Main content: Clock + Info
              Expanded(
                child: Row(
                  children: [
                    // Large digital clock (2/3)
                    Expanded(
                      flex: 2,
                      child: _buildLargeClock(state.currentTime),
                    ),
                    
                    // Info panel (1/3)
                    Expanded(
                      flex: 1,
                      child: _buildInfoPanel(state),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Prayer time cards (7 cards: Subuh→Isya)
              _buildPrayerTimeCards(state.prayerTimes),
              
              SizedBox(height: 32.h),
              
              // Running text
              _buildRunningText(state.runningText),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLargeClock(DateTime time) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Digital time
          Text(
            DateFormat('HH:mm:ss').format(time),
            style: TextStyle(
              fontSize: 180.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: IslamicTheme.textPrimary,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Date
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(time),
            style: TextStyle(
              fontSize: 36.sp,
              color: IslamicTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
```

### PRE-ADZAN Layout (Countdown)

```dart
// ✅ H-10 menit sebelum adzan
class PreAdzanLayout extends StatelessWidget {
  final PreAdzanState state;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IslamicPatternBackground(),
        
        TVSafeArea(
          child: Column(
            children: [
              _buildHeader(state),
              
              // Large countdown in center
              Expanded(
                child: Center(
                  child: GlassmorphismCard(
                    width: 800.w,
                    height: 500.h,
                    backgroundColor: IslamicTheme.glassBackgroundDark,
                    borderColor: IslamicTheme.goldAccent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Menuju ${state.nextPrayer.name}',
                          style: TextStyle(
                            fontSize: 48.sp,
                            fontWeight: FontWeight.bold,
                            color: IslamicTheme.goldAccent,
                          ),
                        ),
                        
                        SizedBox(height: 48.h),
                        
                        // Countdown timer
                        Text(
                          _formatDuration(state.remainingTime),
                          style: TextStyle(
                            fontSize: 120.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: IslamicTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Prayer time cards (highlight next)
              _buildPrayerTimeCards(
                state.prayerTimes,
                highlightedPrayer: state.nextPrayer,
              ),
              
              _buildRunningText(state.runningText),
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
```

### SHOLAT Layout (Burn-in Prevention)

```dart
// ✅ Blank/dimmed screen untuk prevent burn-in
class SholatLayout extends StatelessWidget {
  final SholatState state;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 1.sh,
      color: Colors.black,
      child: Center(
        child: Opacity(
          opacity: 0.1, // Very dim to prevent burn-in
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('HH:mm').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 48,
                  color: Colors.grey[800],
                  fontFamily: 'monospace',
                ),
              ),
              
              SizedBox(height: 24.h),
              
              Text(
                'Waktu Sholat ${state.currentPrayer.name}',
                style: TextStyle(
                  fontSize: 24.sp,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Screen Burn-in Prevention

### Dynamic Content Strategy

```dart
// ✅ Rotate static content position untuk prevent burn-in
class BurnInPreventionClock extends StatefulWidget {
  @override
  State<BurnInPreventionClock> createState() => _BurnInPreventionClockState();
}

class _BurnInPreventionClockState extends State<BurnInPreventionClock> {
  Timer? _positionTimer;
  Offset _position = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    // Move clock position every 5 minutes
    _positionTimer = Timer.periodic(Duration(minutes: 5), (_) {
      if (mounted) {
        setState(() {
          // Random small offset (±20px)
          _position = Offset(
            (Random().nextDouble() - 0.5) * 40,
            (Random().nextDouble() - 0.5) * 40,
          );
        });
      }
    });
  }
  
  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _position,
      child: ClockWidget(),
    );
  }
}
```

### Dimming During Prayer

```dart
// ✅ Automatic dimming atau blank screen saat sholat
class AutoDimmingScreen extends StatelessWidget {
  final DisplayState state;
  
  @override
  Widget build(BuildContext context) {
    // Full black screen during Sholat state
    if (state is SholatState) {
      return SholatLayout(state: state);
    }
    
    // Show normal content for other states
    return switch (state) {
      StandbyState() => StandbyLayout(state: state),
      PreAdzanState() => PreAdzanLayout(state: state),
      AdzanState() => AdzanLayout(state: state),
      IqomahState() => IqomahLayout(state: state),
      _ => Container(),
    };
  }
}
```

## Running Text (Marquee)

```dart
// ✅ Running text dengan Marquee package
import 'package:marquee/marquee.dart';

class RunningTextWidget extends StatelessWidget {
  final String text;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      color: IslamicTheme.deepEmeraldPrimary.withOpacity(0.8),
      child: Center(
        child: Marquee(
          text: text.isEmpty ? 'Selamat datang di masjid' : text,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w500,
            color: IslamicTheme.goldAccent,
          ),
          scrollAxis: Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.center,
          blankSpace: 200.0,
          velocity: 50.0,
          pauseAfterRound: Duration(seconds: 2),
          startPadding: 10.0,
          accelerationDuration: Duration(seconds: 1),
          accelerationCurve: Curves.linear,
          decelerationDuration: Duration(milliseconds: 500),
          decelerationCurve: Curves.easeOut,
        ),
      ),
    );
  }
}
```

## Accessibility Best Practices

### Screen Reader Support

```dart
// ✅ Semantics untuk screen reader
class AccessiblePrayerCard extends StatelessWidget {
  final String name;
  final String time;
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Waktu sholat $name pukul $time',
      button: false,
      focusable: true,
      child: PrayerTimeCard(name: name, time: time),
    );
  }
}
```

### High Contrast Mode

```dart
// ✅ Support high contrast mode
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  
  @override
  Widget build(BuildContext context) {
    final isHighContrast = MediaQuery.of(context).highContrast;
    
    return Text(
      text,
      style: (baseStyle ?? TextStyle()).copyWith(
        color: isHighContrast 
          ? Colors.white 
          : baseStyle?.color ?? IslamicTheme.textPrimary,
        fontWeight: isHighContrast ? FontWeight.bold : baseStyle?.fontWeight,
      ),
    );
  }
}
```

## Animation Patterns

### Smooth Transitions

```dart
// ✅ Smooth state transitions
class AnimatedStateTransition extends StatelessWidget {
  final DisplayState state;
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _buildLayoutForState(state),
    );
  }
  
  Widget _buildLayoutForState(DisplayState state) {
    return switch (state) {
      StandbyState() => StandbyLayout(key: ValueKey('standby'), state: state),
      PreAdzanState() => PreAdzanLayout(key: ValueKey('pre-adzan'), state: state),
      AdzanState() => AdzanLayout(key: ValueKey('adzan'), state: state),
      IqomahState() => IqomahLayout(key: ValueKey('iqomah'), state: state),
      SholatState() => SholatLayout(key: ValueKey('sholat'), state: state),
      _ => Container(key: ValueKey('default')),
    };
  }
}
```

## Common UI Pitfalls

### ❌ DON'T: Use small font sizes

```dart
// ❌ WRONG - Tidak terbaca dari 10 feet away
Text(
  'Subuh',
  style: TextStyle(fontSize: 14),
)

// ✅ CORRECT - Minimum 24.sp untuk body text
Text(
  'Subuh',
  style: TextStyle(fontSize: 24.sp),
)
```

### ❌ DON'T: Use subtle focus indicators

```dart
// ❌ WRONG - Focus indicator tidak terlihat
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey, width: 1),
  ),
)

// ✅ CORRECT - Bold dan kontras tinggi
Container(
  decoration: BoxDecoration(
    border: Border.all(color: IslamicTheme.goldAccent, width: 4),
    boxShadow: [
      BoxShadow(
        color: IslamicTheme.goldAccent.withOpacity(0.5),
        blurRadius: 20,
        spreadRadius: 5,
      ),
    ],
  ),
)
```

### ❌ DON'T: Ignore burn-in prevention

```dart
// ❌ WRONG - Static content always di posisi sama
Container(
  alignment: Alignment.topLeft,
  child: ClockWidget(),
)

// ✅ CORRECT - Rotate position atau dim saat tidak aktif
BurnInPreventionClock()
```

## Related Documentation

- [Architecture Patterns](ARCHITECTURE_PATTERNS.md) - State machine dan UI state patterns
- [Development Workflow](DEVELOPMENT_WORKFLOW.md) - Android TV deployment workflow
- [Testing Guide](TESTING_GUIDE.md) - Widget testing dan D-Pad navigation testing

---

This guide ensures consistent, accessible, and beautiful UI/UX for Miqotul Khoir TV on Android TV.
