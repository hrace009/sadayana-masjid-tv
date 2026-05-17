import 'package:equatable/equatable.dart';

import 'package:miqotul_khoir_tv/domain/entities/imam.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule_display.dart';

/// State definitions untuk [ImamScheduleCubit].
///
/// Sealed class memastikan exhaustive matching di semua switch/if.
sealed class ImamScheduleState extends Equatable {
  const ImamScheduleState();

  @override
  List<Object?> get props => [];
}

/// State awal sebelum data pertama kali dimuat.
final class ImamScheduleInitial extends ImamScheduleState {
  const ImamScheduleInitial();
}

/// State saat data sedang dimuat dari database.
final class ImamScheduleLoading extends ImamScheduleState {
  const ImamScheduleLoading();
}

/// State saat data imam dan jadwal mingguan berhasil dimuat.
///
/// [imams] — daftar semua imam dari tabel master, diurutkan by name ASC.
///
/// [weeklySchedule] — map dayOfWeek (1=Senin … 7=Minggu) ke list
///   5 slot [ImamScheduleDisplay] yang sudah dinormalisasi.
///   Setiap hari selalu memiliki tepat 5 slot; slot kosong memiliki
///   [ImamScheduleDisplay.imamId] == null.
///
/// [isLocked] — apakah jadwal sedang dikunci dari perubahan admin.
///   Saat terkunci, operasi CRUD imam dan setSchedule seharusnya
///   diblokir atau diabaikan oleh UI.
///
/// Ref: TASK-025 (Phase 6 — ImamScheduleCubit)
final class ImamScheduleLoaded extends ImamScheduleState {
  final List<Imam> imams;
  final Map<int, List<ImamScheduleDisplay>> weeklySchedule;
  final bool isLocked;

  const ImamScheduleLoaded({
    required this.imams,
    required this.weeklySchedule,
    required this.isLocked,
  });

  ImamScheduleLoaded copyWith({
    List<Imam>? imams,
    Map<int, List<ImamScheduleDisplay>>? weeklySchedule,
    bool? isLocked,
  }) {
    return ImamScheduleLoaded(
      imams: imams ?? this.imams,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  List<Object?> get props => [imams, weeklySchedule, isLocked];
}

/// State saat terjadi error saat memuat atau memutasi data.
///
/// [message] berisi pesan deskriptif yang dapat ditampilkan ke UI.
final class ImamScheduleError extends ImamScheduleState {
  final String message;

  const ImamScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}
