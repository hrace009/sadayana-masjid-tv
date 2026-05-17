import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:miqotul_khoir_tv/domain/entities/imam.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule.dart';
import 'package:miqotul_khoir_tv/domain/entities/imam_schedule_display.dart';
import 'package:miqotul_khoir_tv/domain/repositories/imam_repository.dart';
import 'package:miqotul_khoir_tv/domain/repositories/imam_schedule_repository.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/display_state/display_state_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/imam_schedule/imam_schedule_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/imam_schedule/imam_schedule_state.dart';

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class MockImamRepository extends Mock implements ImamRepository {}

class MockImamScheduleRepository extends Mock implements ImamScheduleRepository {}

class MockDisplayStateCubit extends Mock implements DisplayStateCubit {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Membuat [ImamScheduleDisplay] kosong untuk hari [dayOfWeek] dan
/// [prayerName] tertentu (imamId = null).
ImamScheduleDisplay emptySlot(int dayOfWeek, String prayerName) {
  return ImamScheduleDisplay(
    dayOfWeek: dayOfWeek,
    prayerName: prayerName,
    prayerLabel: prayerName[0].toUpperCase() + prayerName.substring(1),
    imamId: null,
    imamName: null,
    khatibId: null,
    khatibName: null,
  );
}

/// Daftar [ImamSchedule] kosong untuk satu hari (tidak ada entri di DB).
const List<ImamSchedule> emptyRaw = [];

/// Imam dummy untuk digunakan dalam test.
const tImam1 = Imam(id: 1, name: 'Ust. Ahmad', isActive: true);
const tImam2 = Imam(id: 2, name: 'Ust. Budi', isActive: true);

/// Daftar lengkap 5 slot [ImamScheduleDisplay] kosong untuk Senin (dayOfWeek=1).
List<ImamScheduleDisplay> emptyMondaySlots() => [
      emptySlot(1, 'subuh'),
      emptySlot(1, 'dzuhur'),
      emptySlot(1, 'ashar'),
      emptySlot(1, 'maghrib'),
      emptySlot(1, 'isya'),
    ];

void main() {
  late MockImamRepository mockImamRepo;
  late MockImamScheduleRepository mockScheduleRepo;
  late MockDisplayStateCubit mockDisplayCubit;

  // ---------------------------------------------------------------------------
  // setUp: stub default semua panggilan yang diperlukan oleh loadAll()
  // ---------------------------------------------------------------------------

  setUpAll(() {
    // Diperlukan oleh mocktail agar any() bisa dipakai pada parameter Imam
    registerFallbackValue(const Imam(id: 0, name: '', isActive: true));
  });

  setUp(() {
    mockImamRepo = MockImamRepository();
    mockScheduleRepo = MockImamScheduleRepository();
    mockDisplayCubit = MockDisplayStateCubit();

    // Default: getAll() mengembalikan daftar kosong
    when(() => mockImamRepo.getAll()).thenAnswer((_) async => []);

    // Default: getRawScheduleForDay(day) untuk hari 1-7 mengembalikan kosong
    for (var day = 1; day <= 7; day++) {
      when(
        () => mockScheduleRepo.getRawScheduleForDay(day),
      ).thenAnswer((_) async => emptyRaw);
    }

    // onSettingsChanged mengembalikan Future<void>
    when(
      () => mockDisplayCubit.onSettingsChanged(),
    ).thenAnswer((_) async {});
  });

  ImamScheduleCubit buildCubit({bool withDisplayCubit = true}) {
    return ImamScheduleCubit(
      imamRepository: mockImamRepo,
      scheduleRepository: mockScheduleRepo,
      displayStateCubit: withDisplayCubit ? mockDisplayCubit : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('Initial state', () {
    test('state awal adalah ImamScheduleInitial', () {
      final cubit = buildCubit();
      expect(cubit.state, isA<ImamScheduleInitial>());
      cubit.close();
    });
  });

  // ---------------------------------------------------------------------------
  // loadAll()
  // ---------------------------------------------------------------------------

  group('loadAll()', () {
    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'emits [Loading, Loaded] dengan daftar imam kosong dan jadwal kosong',
      build: buildCubit,
      act: (cubit) => cubit.loadAll(),
      expect: () => [
        isA<ImamScheduleLoading>(),
        isA<ImamScheduleLoaded>(),
      ],
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'Loaded state berisi imam dari repository',
      build: () {
        when(() => mockImamRepo.getAll()).thenAnswer(
          (_) async => [tImam1, tImam2],
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadAll(),
      verify: (cubit) {
        final loaded = cubit.state as ImamScheduleLoaded;
        expect(loaded.imams, equals([tImam1, tImam2]));
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'Loaded state memiliki weeklySchedule dengan 7 hari',
      build: buildCubit,
      act: (cubit) => cubit.loadAll(),
      verify: (cubit) {
        final loaded = cubit.state as ImamScheduleLoaded;
        expect(loaded.weeklySchedule.length, equals(7));
        // Setiap hari memiliki tepat 5 slot
        for (var day = 1; day <= 7; day++) {
          expect(
            loaded.weeklySchedule[day]?.length,
            equals(5),
            reason: 'Hari $day harus memiliki 5 slot',
          );
        }
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'Jumat (dayOfWeek=5) memiliki slot jumat, bukan dzuhur',
      build: buildCubit,
      act: (cubit) => cubit.loadAll(),
      verify: (cubit) {
        final loaded = cubit.state as ImamScheduleLoaded;
        final fridaySlots = loaded.weeklySchedule[5]!;
        final prayerNames = fridaySlots.map((s) => s.prayerName).toList();
        expect(prayerNames, contains('jumat'));
        expect(prayerNames, isNot(contains('dzuhur')));
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'emits [Error] saat getAll() melempar exception',
      build: () {
        when(() => mockImamRepo.getAll()).thenThrow(Exception('DB error'));
        return buildCubit();
      },
      act: (cubit) => cubit.loadAll(),
      expect: () => [
        isA<ImamScheduleLoading>(),
        isA<ImamScheduleError>(),
      ],
      verify: (cubit) {
        expect(
          (cubit.state as ImamScheduleError).message,
          contains('Gagal memuat data jadwal imam'),
        );
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'isLocked tetap dipertahankan dari state sebelumnya saat reload',
      build: () {
        // Pertama loadAll() → loaded dengan isLocked default false
        // Kemudian kita set isLocked true via updateLockState,
        // lalu loadAll() lagi → isLocked harus tetap true
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadAll();
        cubit.updateLockState(true);
        await cubit.loadAll(); // reload — harus pertahankan isLocked=true
      },
      verify: (cubit) {
        expect((cubit.state as ImamScheduleLoaded).isLocked, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // addImam()
  // ---------------------------------------------------------------------------

  group('addImam()', () {
    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'memanggil imamRepository.insert lalu loadAll()',
      build: () {
        when(
          () => mockImamRepo.insert(any()),
        ).thenAnswer((_) async => 1);
        return buildCubit();
      },
      act: (cubit) => cubit.addImam('Ust. Ahmad'),
      verify: (cubit) {
        verify(() => mockImamRepo.insert('Ust. Ahmad')).called(1);
        // Setelah insert, loadAll() dipanggil → state adalah Loaded
        expect(cubit.state, isA<ImamScheduleLoaded>());
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'TIDAK memanggil onSettingsChanged setelah addImam (GUD-005)',
      build: () {
        when(
          () => mockImamRepo.insert(any()),
        ).thenAnswer((_) async => 1);
        return buildCubit();
      },
      act: (cubit) => cubit.addImam('Ust. Budi'),
      verify: (_) {
        verifyNever(() => mockDisplayCubit.onSettingsChanged());
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'emits [Error] saat insert gagal',
      build: () {
        when(
          () => mockImamRepo.insert(any()),
        ).thenThrow(Exception('insert failed'));
        return buildCubit();
      },
      act: (cubit) => cubit.addImam('Ust. Error'),
      expect: () => [isA<ImamScheduleError>()],
      verify: (cubit) {
        expect(
          (cubit.state as ImamScheduleError).message,
          contains('Gagal menambah imam'),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // updateImam()
  // ---------------------------------------------------------------------------

  group('updateImam()', () {
    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'memanggil imamRepository.update lalu loadAll() lalu onSettingsChanged()',
      build: () {
        when(
          () => mockImamRepo.update(any()),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.updateImam(tImam1),
      verify: (_) {
        verify(() => mockImamRepo.update(tImam1)).called(1);
        verify(() => mockDisplayCubit.onSettingsChanged()).called(1);
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'emits [Error] saat update gagal',
      build: () {
        when(
          () => mockImamRepo.update(any()),
        ).thenThrow(Exception('update failed'));
        return buildCubit();
      },
      act: (cubit) => cubit.updateImam(tImam1),
      expect: () => [isA<ImamScheduleError>()],
    );
  });

  // ---------------------------------------------------------------------------
  // deleteImam()
  // ---------------------------------------------------------------------------

  group('deleteImam()', () {
    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'memanggil imamRepository.delete lalu loadAll() lalu onSettingsChanged()',
      build: () {
        when(
          () => mockImamRepo.delete(any()),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.deleteImam(1),
      verify: (_) {
        verify(() => mockImamRepo.delete(1)).called(1);
        verify(() => mockDisplayCubit.onSettingsChanged()).called(1);
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'emits [Error] saat delete gagal',
      build: () {
        when(
          () => mockImamRepo.delete(any()),
        ).thenThrow(Exception('delete failed'));
        return buildCubit();
      },
      act: (cubit) => cubit.deleteImam(99),
      expect: () => [isA<ImamScheduleError>()],
    );
  });

  // ---------------------------------------------------------------------------
  // setSchedule()
  // ---------------------------------------------------------------------------

  group('setSchedule()', () {
    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'memanggil scheduleRepository.setSchedule lalu loadAll() lalu onSettingsChanged()',
      build: () {
        when(
          () => mockScheduleRepo.setSchedule(
            dayOfWeek: any(named: 'dayOfWeek'),
            prayerName: any(named: 'prayerName'),
            imamId: any(named: 'imamId'),
            khatibId: any(named: 'khatibId'),
          ),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.setSchedule(
        dayOfWeek: 1,
        prayerName: 'subuh',
        imamId: 1,
      ),
      verify: (_) {
        verify(
          () => mockScheduleRepo.setSchedule(
            dayOfWeek: 1,
            prayerName: 'subuh',
            imamId: 1,
            khatibId: null,
          ),
        ).called(1);
        verify(() => mockDisplayCubit.onSettingsChanged()).called(1);
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'setSchedule dengan imamId null → mengosongkan slot',
      build: () {
        when(
          () => mockScheduleRepo.setSchedule(
            dayOfWeek: any(named: 'dayOfWeek'),
            prayerName: any(named: 'prayerName'),
            imamId: any(named: 'imamId'),
            khatibId: any(named: 'khatibId'),
          ),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.setSchedule(
        dayOfWeek: 2,
        prayerName: 'dzuhur',
        imamId: null,
      ),
      verify: (_) {
        verify(
          () => mockScheduleRepo.setSchedule(
            dayOfWeek: 2,
            prayerName: 'dzuhur',
            imamId: null,
            khatibId: null,
          ),
        ).called(1);
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'setSchedule Jumat dengan khatibId dan imamId',
      build: () {
        when(
          () => mockScheduleRepo.setSchedule(
            dayOfWeek: any(named: 'dayOfWeek'),
            prayerName: any(named: 'prayerName'),
            imamId: any(named: 'imamId'),
            khatibId: any(named: 'khatibId'),
          ),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.setSchedule(
        dayOfWeek: 5,
        prayerName: 'jumat',
        imamId: 1,
        khatibId: 2,
      ),
      verify: (_) {
        verify(
          () => mockScheduleRepo.setSchedule(
            dayOfWeek: 5,
            prayerName: 'jumat',
            imamId: 1,
            khatibId: 2,
          ),
        ).called(1);
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'emits [Error] saat setSchedule gagal',
      build: () {
        when(
          () => mockScheduleRepo.setSchedule(
            dayOfWeek: any(named: 'dayOfWeek'),
            prayerName: any(named: 'prayerName'),
            imamId: any(named: 'imamId'),
            khatibId: any(named: 'khatibId'),
          ),
        ).thenThrow(Exception('set failed'));
        return buildCubit();
      },
      act: (cubit) => cubit.setSchedule(dayOfWeek: 1, prayerName: 'subuh'),
      expect: () => [isA<ImamScheduleError>()],
    );
  });

  // ---------------------------------------------------------------------------
  // clearDay()
  // ---------------------------------------------------------------------------

  group('clearDay()', () {
    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'memanggil scheduleRepository.clearScheduleForDay lalu loadAll() lalu onSettingsChanged()',
      build: () {
        when(
          () => mockScheduleRepo.clearScheduleForDay(any()),
        ).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.clearDay(3),
      verify: (_) {
        verify(() => mockScheduleRepo.clearScheduleForDay(3)).called(1);
        verify(() => mockDisplayCubit.onSettingsChanged()).called(1);
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'emits [Error] saat clearScheduleForDay gagal',
      build: () {
        when(
          () => mockScheduleRepo.clearScheduleForDay(any()),
        ).thenThrow(Exception('clear failed'));
        return buildCubit();
      },
      act: (cubit) => cubit.clearDay(1),
      expect: () => [isA<ImamScheduleError>()],
      verify: (cubit) {
        expect(
          (cubit.state as ImamScheduleError).message,
          contains('Gagal menghapus jadwal hari ini'),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // updateLockState()
  // ---------------------------------------------------------------------------

  group('updateLockState()', () {
    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'mengubah isLocked dari false ke true tanpa reload database',
      build: buildCubit,
      act: (cubit) async {
        await cubit.loadAll(); // → Loaded(isLocked: false)
        cubit.updateLockState(true);
      },
      verify: (cubit) {
        expect((cubit.state as ImamScheduleLoaded).isLocked, isTrue);
        // getAll hanya dipanggil 1x (oleh loadAll, bukan updateLockState)
        verify(() => mockImamRepo.getAll()).called(1);
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'mengubah isLocked dari true ke false',
      build: buildCubit,
      act: (cubit) async {
        await cubit.loadAll();
        cubit.updateLockState(true);
        cubit.updateLockState(false);
      },
      verify: (cubit) {
        expect((cubit.state as ImamScheduleLoaded).isLocked, isFalse);
      },
    );

    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'updateLockState no-op jika state bukan ImamScheduleLoaded',
      build: buildCubit,
      // State awal adalah ImamScheduleInitial
      act: (cubit) => cubit.updateLockState(true),
      expect: () => [], // tidak ada state baru yang di-emit
    );
  });

  // ---------------------------------------------------------------------------
  // Tanpa DisplayStateCubit (displayStateCubit = null)
  // ---------------------------------------------------------------------------

  group('Tanpa DisplayStateCubit (null)', () {
    blocTest<ImamScheduleCubit, ImamScheduleState>(
      'deleteImam tidak crash saat displayStateCubit = null',
      build: () {
        when(() => mockImamRepo.delete(any())).thenAnswer((_) async {});
        return buildCubit(withDisplayCubit: false);
      },
      act: (cubit) => cubit.deleteImam(1),
      // Hanya verifikasi tidak ada exception — state Loaded sudah cukup
      verify: (cubit) {
        expect(cubit.state, isA<ImamScheduleLoaded>());
      },
    );
  });
}
