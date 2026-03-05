import 'package:equatable/equatable.dart';
import '../../../../domain/entities/daily_prayer_times.dart';

/// State dasar untuk [PrayerTimeCubit].
sealed class PrayerTimeState extends Equatable {
  const PrayerTimeState();

  @override
  List<Object?> get props => [];
}

/// State awal cubit sebelum load data.
final class PrayerTimeInitial extends PrayerTimeState {}

/// State ketika cubit sedang memuat data jadwal sholat.
final class PrayerTimeLoading extends PrayerTimeState {}

/// State ketika data jadwal sholat berhasil dimuat.
final class PrayerTimeLoaded extends PrayerTimeState {
  final DailyPrayerTimes dailyPrayerTimes;
  final DateTime lastCalculatedAt;

  const PrayerTimeLoaded({
    required this.dailyPrayerTimes,
    required this.lastCalculatedAt,
  });

  @override
  List<Object?> get props => [dailyPrayerTimes, lastCalculatedAt];
}

/// State ketika terjadi error saat memuat data.
final class PrayerTimeError extends PrayerTimeState {
  final String message;

  const PrayerTimeError(this.message);

  @override
  List<Object?> get props => [message];
}
