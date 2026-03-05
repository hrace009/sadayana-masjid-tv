import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/islamic_colors.dart';

/// Reusable glassmorphism container widget.
///
/// Menampilkan backdrop blur effect, semi-transparent background, dan subtle
/// border sesuai Islamic Glassmorphism design system (REQ-001).
///
/// Semua dimensi menggunakan ScreenUtil extensions (CON-001).
/// Warna diambil dari [IslamicColors] constants (CON-002).
///
/// Ref: Plan 04 TASK-003 s.d. TASK-006
class GlassmorphismCard extends StatelessWidget {
  /// Widget yang ditampilkan di dalam card.
  final Widget child;

  /// Intensitas blur backdrop filter (sigma). Default: 15.
  /// Range yang disarankan: 10–20 (GUD-002).
  final double blurIntensity;

  /// Warna background semi-transparan. Default: [IslamicColors.glassWhite].
  final Color backgroundColor;

  /// Warna border. Default: [IslamicColors.glassBorder].
  final Color borderColor;

  /// Border radius dalam logical pixels (akan di-scale via `.r`).
  /// Default: 16.
  final double borderRadius;

  /// Padding internal card. Default: `EdgeInsets.all(16.w)`.
  final EdgeInsetsGeometry? padding;

  /// Margin eksternal card. Default: null (tanpa margin).
  final EdgeInsetsGeometry? margin;

  /// Jika true, menampilkan golden glow [BoxShadow] di sekeliling card.
  /// Digunakan untuk menandai focused state (GUD-001).
  final bool isFocused;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.blurIntensity = 15,
    this.backgroundColor = IslamicColors.glassWhite,
    this.borderColor = IslamicColors.glassBorder,
    this.borderRadius = 16,
    this.padding,
    this.margin,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurIntensity,
            sigmaY: blurIntensity,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius.r),
              border: Border.all(color: borderColor, width: 1.w),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: IslamicColors.goldAmber.withValues(alpha: 0.3),
                        blurRadius: 12.r,
                        spreadRadius: 2.r,
                      ),
                    ]
                  : null,
            ),
            padding: padding ?? EdgeInsets.all(16.w),
            child: child,
          ),
        ),
      ),
    );
  }
}
