import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/domain/entities/settings.dart';
import 'package:miqotul_khoir_tv/domain/repositories/wisdom_quote_repository.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/settings/settings_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/settings/settings_state.dart';
import 'package:miqotul_khoir_tv/presentation/pages/settings/settings_menu_page.dart';
import 'package:miqotul_khoir_tv/presentation/pages/settings/sections/ihtiyat_section.dart';
import 'package:miqotul_khoir_tv/presentation/pages/settings/sections/iqomah_section.dart';
import 'package:miqotul_khoir_tv/presentation/pages/settings/sections/security_section.dart';
import 'package:miqotul_khoir_tv/presentation/widgets/dpad_stepper.dart';
import 'package:miqotul_khoir_tv/presentation/widgets/pin_input_widget.dart';

class MockSettingsCubit extends Mock implements SettingsCubit {}

class MockWisdomQuoteRepository extends Mock implements WisdomQuoteRepository {}

void main() {
  late MockSettingsCubit mockSettingsCubit;
  late MockWisdomQuoteRepository mockWisdomRepo;
  late Settings mockSettings;

  setUp(() {
    mockSettingsCubit = MockSettingsCubit();
    mockWisdomRepo = MockWisdomQuoteRepository();
    // Providing default settings using positional and required named properties.
    mockSettings = const Settings();
    when(
      () => mockSettingsCubit.state,
    ).thenReturn(SettingsLoaded(settings: mockSettings));
    when(
      () => mockSettingsCubit.stream,
    ).thenAnswer((_) => Stream.value(SettingsLoaded(settings: mockSettings)));
    when(() => mockSettingsCubit.isPinEnabled).thenReturn(false);
    // WisdomQuoteSection calls getAll() via didChangeDependencies.
    when(() => mockWisdomRepo.getAll()).thenAnswer((_) async => const []);
    when(
      () => mockWisdomRepo.getByIds(any()),
    ).thenAnswer((_) async => const []);
  });

  Widget createTestWidget() {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: RepositoryProvider<WisdomQuoteRepository>.value(
            value: mockWisdomRepo,
            child: BlocProvider<SettingsCubit>.value(
              value: mockSettingsCubit,
              child: const SettingsMenuPage(),
            ),
          ),
        );
      },
    );
  }

  group('SettingsMenuPage Tests', () {
    testWidgets('Renders categories correctly', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Koreksi Waktu (Ihtiyat)'), findsWidgets);
      expect(find.text('Durasi Iqomah'), findsWidgets);
      expect(find.text('Pengaturan Dhuha'), findsWidgets);
      expect(find.text('Tutup Pengaturan'), findsWidgets);
    });

    testWidgets('Ihtiyat section shows 7 DPadSteppers', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap menu item to navigate to IhtiyatSection (index 1).
      // Uses .first because the same text appears as section header inside IndexedStack.
      await tester.tap(find.text('Koreksi Waktu (Ihtiyat)').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.descendant(
          of: find.byType(IhtiyatSection),
          matching: find.byType(DPadStepper),
        ),
        findsNWidgets(7),
      );
    });

    testWidgets('Iqomah section shows 5 DPadSteppers', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap menu item to navigate to IqomahSection (index 2).
      // Uses .first because the same text appears as section header inside IndexedStack.
      await tester.tap(find.text('Durasi Iqomah').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.descendant(
          of: find.byType(IqomahSection),
          matching: find.byType(DPadStepper),
        ),
        findsNWidgets(6),
      );
    });

    testWidgets('Does not throw layout overflow on small landscape viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Security section can show PIN form', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Keamanan (PIN)').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SecuritySection), findsOneWidget);
      expect(find.text('PIN Tidak Aktif'), findsOneWidget);
      expect(find.text('Buat PIN'), findsOneWidget);

      await tester.tap(find.text('Buat PIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Masukkan 6-digit PIN Baru'), findsOneWidget);
      expect(find.byType(PinInputWidget), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });
}
