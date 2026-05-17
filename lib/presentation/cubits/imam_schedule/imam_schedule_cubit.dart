import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:miqotul_khoir_tv/domain/entities/imam.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule_display.dart';
import 'package:miqotul_khoir_tv/domain/repositories/imam_repository.dart';
import 'package:miqotul_khoir_tv/domain/repositories/imam_schedule_repository.dart';
import 'imam_schedule_state.dart';
import '../display_state/display_state_cubit.dart';

/// Cubit yang mengelola data master imam dan jadwal imam mingguan
/// dari Settings UI.
///
/// Bertanggung jawab atas:
/// - Memuat semua imam dan membangun jadwal mingguan 7 hari × 5 slot
///   ([loadAll]).
/// - Operasi CRUD imam: tambah ([addImam]), ubah ([updateImam]),
///   hapus ([deleteImam]).
/// - Operasi jadwal: isi/ubah satu slot ([setSchedule]), kosongkan
///   seluruh hari ([clearDay]).
/// - Sinkronisasi layar utama via [DisplayStateCubit.onSettingsChanged]
///   setelah setiap mutasi yang mempengaruhi tampilan.
///
/// **PAT-006**: Mutasi yang mempengaruhi tampilan layar utama
/// (`updateImam`, `deleteImam`, `setSchedule`, `clearDay`) wajib
/// memanggil [_displayStateCubit?.onSettingsChanged()] setelah reload.
///
/// **GUD-005**: [addImam] TIDAK memanggil [onSettingsChanged] karena
/// imam baru belum terpasang di jadwal, sehingga tidak mempengaruhi
/// tampilan layar utama.
///
/// Ref: TASK-025, TASK-026 (Phase 6 — Jadwal Imam Sholat Berjamaah)
class ImamScheduleCubit extends Cubit<ImamScheduleState> {
  final ImamRepository _imamRepository;
  final ImamScheduleRepository _scheduleRepository;
  final DisplayStateCubit? _displayStateCubit;

  ImamScheduleCubit({
    required ImamRepository imamRepository,
    required ImamScheduleRepository scheduleRepository,
    DisplayStateCubit? displayStateCubit,
  }) : _imamRepository = imamRepository,
       _scheduleRepository = scheduleRepository,
       _displayStateCubit = displayStateCubit,
       super(const ImamScheduleInitial());

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  /// Urutan prayer key untuk hari reguler (Senin–Kamis, Sabtu–Minggu).
  static const _regularPrayerKeys = [
    'subuh',
    'dzuhur',
    'ashar',
    'maghrib',
    'isya',
  ];

  /// Urutan prayer key untuk hari Jumat (dzuhur diganti jumat).
  static const _fridayPrayerKeys = [
    'subuh',
    'jumat',
    'ashar',
    'maghrib',
    'isya',
  ];

  /// Label bahasa Indonesia untuk setiap prayer key.
  static const _prayerLabels = {
    'subuh': 'Subuh',
    'dzuhur': 'Dzuhur',
    'jumat': 'Jumat',
    'ashar': 'Ashar',
    'maghrib': 'Maghrib',
    'isya': 'Isya',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Memuat semua imam dan membangun jadwal mingguan (7 hari × 5 slot).
  ///
  /// Untuk setiap hari, slot yang belum ada di database tetap diisi
  /// sebagai slot kosong (imamId == null) sehingga UI selalu menampilkan
  /// tabel lengkap 5 baris.
  ///
  /// Nilai [isLocked] dari state sebelumnya (jika ada) dipertahankan
  /// agar reload akibat mutasi tidak mereset status kunci.
  Future<void> loadAll() async {
    final wasLocked = state is ImamScheduleLoaded
        ? (state as ImamScheduleLoaded).isLocked
        : false;

    emit(const ImamScheduleLoading());
    try {
      final imams = await _imamRepository.getAll();

      final weeklySchedule = <int, List<ImamScheduleDisplay>>{};
      for (var day = 1; day <= 7; day++) {
        final rawRows = await _scheduleRepository.getRawScheduleForDay(day);
        weeklySchedule[day] = _buildDaySchedule(day, rawRows, imams);
      }

      emit(
        ImamScheduleLoaded(
          imams: imams,
          weeklySchedule: weeklySchedule,
          isLocked: wasLocked,
        ),
      );
    } catch (e) {
      emit(ImamScheduleError('Gagal memuat data jadwal imam: ${e.toString()}'));
    }
  }

  /// Menambah imam baru dengan [name] yang diberikan.
  ///
  /// Setelah berhasil, [loadAll] dipanggil untuk memperbarui daftar imam.
  /// Tidak memanggil [onSettingsChanged] karena imam baru belum masuk
  /// jadwal (GUD-005).
  Future<void> addImam(String name) async {
    try {
      await _imamRepository.insert(name);
      await loadAll();
    } catch (e) {
      emit(ImamScheduleError('Gagal menambah imam: ${e.toString()}'));
    }
  }

  /// Memperbarui data imam (nama atau status aktif).
  ///
  /// Memanggil [onSettingsChanged] karena perubahan nama imam
  /// mempengaruhi tampilan [ImamScheduleState] di layar utama.
  Future<void> updateImam(Imam imam) async {
    try {
      await _imamRepository.update(imam);
      await loadAll();
      _displayStateCubit?.onSettingsChanged();
    } catch (e) {
      emit(ImamScheduleError('Gagal memperbarui data imam: ${e.toString()}'));
    }
  }

  /// Menghapus imam berdasarkan [id].
  ///
  /// Slot jadwal yang mengacu imam ini akan otomatis di-NULL-kan oleh
  /// database (ON DELETE SET NULL). Memanggil [onSettingsChanged] agar
  /// layar utama me-refresh tampilan jadwal yang terpengaruh.
  Future<void> deleteImam(int id) async {
    try {
      await _imamRepository.delete(id);
      await loadAll();
      _displayStateCubit?.onSettingsChanged();
    } catch (e) {
      emit(ImamScheduleError('Gagal menghapus imam: ${e.toString()}'));
    }
  }

  /// Menyimpan atau memperbarui satu slot jadwal (upsert).
  ///
  /// [dayOfWeek]: 1=Senin … 7=Minggu.
  /// [prayerName]: 'subuh' | 'dzuhur' | 'ashar' | 'maghrib' | 'isya' | 'jumat'.
  /// [imamId]: null untuk mengosongkan slot imam.
  /// [khatibId]: null untuk mengosongkan slot khatib (hanya relevan Jumat).
  Future<void> setSchedule({
    required int dayOfWeek,
    required String prayerName,
    int? imamId,
    int? khatibId,
  }) async {
    try {
      await _scheduleRepository.setSchedule(
        dayOfWeek: dayOfWeek,
        prayerName: prayerName,
        imamId: imamId,
        khatibId: khatibId,
      );
      await loadAll();
      _displayStateCubit?.onSettingsChanged();
    } catch (e) {
      emit(ImamScheduleError('Gagal menyimpan jadwal: ${e.toString()}'));
    }
  }

  /// Menghapus seluruh jadwal untuk [dayOfWeek].
  ///
  /// Semua 5 slot hari tersebut akan menjadi kosong setelah operasi ini.
  Future<void> clearDay(int dayOfWeek) async {
    try {
      await _scheduleRepository.clearScheduleForDay(dayOfWeek);
      await loadAll();
      _displayStateCubit?.onSettingsChanged();
    } catch (e) {
      emit(
        ImamScheduleError('Gagal menghapus jadwal hari ini: ${e.toString()}'),
      );
    }
  }

  /// Memperbarui nilai [isLocked] pada state yang sedang loaded
  /// tanpa melakukan reload dari database.
  ///
  /// Dipanggil oleh [ImamScheduleSection] saat [SettingsCubit] memperbarui
  /// nilai `isImamScheduleLocked` agar state Cubit ini tetap sinkron.
  void updateLockState(bool isLocked) {
    if (state is ImamScheduleLoaded) {
      emit((state as ImamScheduleLoaded).copyWith(isLocked: isLocked));
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Membangun 5 slot [ImamScheduleDisplay] untuk satu [dayOfWeek].
  ///
  /// Menggunakan [rawSchedule] sebagai sumber data (mungkin kosong atau
  /// kurang dari 5 baris). Slot yang tidak ada di [rawSchedule] diisi
  /// sebagai slot kosong. Nama imam/khatib di-resolve dari [imams].
  List<ImamScheduleDisplay> _buildDaySchedule(
    int dayOfWeek,
    List<ImamSchedule> rawSchedule,
    List<Imam> imams,
  ) {
    final isFriday = dayOfWeek == 5;
    final keys = isFriday ? _fridayPrayerKeys : _regularPrayerKeys;

    final rawByPrayer = {for (final row in rawSchedule) row.prayerName: row};

    return keys.map((prayerName) {
      final raw = rawByPrayer[prayerName];

      final imamName = raw?.imamId != null
          ? imams.where((i) => i.id == raw!.imamId).firstOrNull?.name
          : null;

      final khatibName = raw?.khatibId != null
          ? imams.where((i) => i.id == raw!.khatibId).firstOrNull?.name
          : null;

      return ImamScheduleDisplay(
        dayOfWeek: dayOfWeek,
        prayerName: prayerName,
        prayerLabel: _prayerLabels[prayerName]!,
        imamId: raw?.imamId,
        imamName: imamName,
        khatibId: raw?.khatibId,
        khatibName: khatibName,
      );
    }).toList();
  }
}
