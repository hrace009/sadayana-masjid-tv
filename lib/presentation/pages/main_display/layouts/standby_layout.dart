import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/islamic_colors.dart';
import '../../../../core/theme/islamic_typography.dart';
import '../../../../domain/entities/display_state.dart';
import '../../../../domain/entities/settings.dart';
import '../../../cubits/settings/settings_cubit.dart';
import '../../../cubits/settings/settings_state.dart';
import '../../../widgets/digital_clock_widget.dart';
import '../../../widgets/glassmorphism_card.dart';
import '../../../widgets/header_widget.dart';
import '../../../widgets/prayer_cards_row.dart';
import '../../../widgets/running_text_widget.dart';
import '../../../widgets/treasury_info_widget.dart';

class StandbyLayout extends StatelessWidget {
  final StandbyState state;
  final bool isSettingsVisible;

  const StandbyLayout({
    super.key,
    required this.state,
    this.isSettingsVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        // Baca data masjid dari SettingsCubit jika sudah loaded
        String mosqueName = 'Masjid Anda';
        String mosqueAddress = '';
        String? runningText = state.runningText;

        if (settingsState is SettingsLoaded) {
          final s = settingsState.settings;
          if (s.mosqueName.isNotEmpty) mosqueName = s.mosqueName;
          mosqueAddress = s.mosqueAddress;
          // Prioritaskan runningText dari state, fallback ke settings
          runningText ??= s.runningText;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            HeaderWidget(
              mosqueName: mosqueName,
              mosqueAddress: mosqueAddress,
              hijriDate: state.hijriDate ?? '',
              currentTime: state.currentTime,
              isSettingsVisible: isSettingsVisible,
            ),

            SizedBox(height: 32.h),

            // BODY
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Kiri: Jam Besar
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: DigitalClockWidget(currentTime: state.currentTime),
                    ),
                  ),

                  // Kanan: Info Panel / Next Prayer
                  Expanded(
                    flex: 4,
                    child: _buildInfoPanel(
                      settingsState is SettingsLoaded
                          ? settingsState.settings
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // PRAYER CARDS
            if (state.dailyPrayerTimes != null)
              PrayerCardsRow(
                prayers: state.dailyPrayerTimes!.allPrayers,
                nextPrayer: state.nextPrayer,
              ),

            SizedBox(height: 24.h),

            // FOOTER / RUNNING TEXT
            if (runningText != null && runningText.isNotEmpty)
              SizedBox(
                height: 60.h,
                child: GlassmorphismCard(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Center(
                    child: RunningTextWidget(
                      text: runningText,
                      textStyle: IslamicTypography.body().copyWith(
                        color: IslamicColors.goldAmber,
                        fontSize: 28.sp,
                      ),
                      scrollSpeed: 40.0,
                    ),
                  ),
                ),
              )
            else
              SizedBox(height: 60.h),
          ],
        );
      },
    );
  }

  Widget _buildInfoPanel(Settings? settings) {
    if (state.nextPrayer == null || state.timeToNextPrayer == null) {
      return const SizedBox.shrink();
    }

    final duration = state.timeToNextPrayer!;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    String timeRemainingStr = '';
    if (hours > 0) {
      timeRemainingStr = '$hours Jam $minutes Menit';
    } else {
      timeRemainingStr = '$minutes Menit';
    }

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassmorphismCard(
            padding: EdgeInsets.all(40.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label kecil
                Text(
                  'Sholat Berikutnya',
                  style: IslamicTypography.subtitle(
                    color: IslamicColors.textSecondary,
                  ).copyWith(fontSize: 34.sp),
                ),
                SizedBox(height: 20.h),
                // Nama sholat — paling dominan
                Text(
                  state.nextPrayer!.name,
                  style: IslamicTypography.heading(
                    color: IslamicColors.goldAmber,
                    fontWeight: FontWeight.bold,
                  ).copyWith(fontSize: 84.sp),
                ),
                SizedBox(height: 12.h),
                // Countdown
                Text(
                  'Dalam waktu $timeRemainingStr',
                  style: IslamicTypography.body(
                    color: IslamicColors.textPrimary,
                  ).copyWith(fontSize: 36.sp),
                ),
                SizedBox(height: 28.h),
                // Waktu masuk
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.white, size: 32.w),
                    SizedBox(width: 10.w),
                    Text(
                      'Masuk pada ${state.nextPrayer!.formattedTime}',
                      style: IslamicTypography.body(
                        color: Colors.white,
                      ).copyWith(fontSize: 30.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (settings != null && settings.isTreasuryEnabled) ...[
            SizedBox(height: 24.h),
            TreasuryInfoWidget(
              balance: settings.treasuryBalance,
              income: settings.treasuryIncome,
              expense: settings.treasuryExpense,
            ),
          ],
        ],
      ),
    );
  }
}
