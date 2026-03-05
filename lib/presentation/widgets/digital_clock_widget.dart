import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../core/theme/islamic_colors.dart';
import '../../core/theme/islamic_typography.dart';

class DigitalClockWidget extends StatelessWidget {
  final DateTime currentTime;
  final TextStyle? customStyle;

  const DigitalClockWidget({
    super.key,
    required this.currentTime,
    this.customStyle,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('HH:mm').format(currentTime);
    final secondsString = DateFormat('ss').format(currentTime);

    // Ukuran besar untuk TV 1920×1080 — jam utama 210sp, detik 105sp
    final mainStyle =
        customStyle ??
        IslamicTypography.display().copyWith(
          fontSize: 210.sp,
          fontWeight: FontWeight.w700,
          color: IslamicColors.textPrimary,
          letterSpacing: -2,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(timeString, style: mainStyle),
        Text(
          ':$secondsString',
          style: mainStyle.copyWith(
            fontSize: (mainStyle.fontSize ?? 180.sp) * 0.5,
            color: IslamicColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
