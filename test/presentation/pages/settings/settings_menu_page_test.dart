import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/domain/entities/settings.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/settings/settings_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/settings/settings_state.dart';
import 'package:miqotul_khoir_tv/presentation/pages/settings/settings_menu_page.dart';
import 'package:miqotul_khoir_tv/presentation/pages/settings/sections/ihtiyat_section.dart';
import 'package:miqotul_khoir_tv/presentation/pages/settings/sections/iqomah_section.dart';
import 'package:miqotul_khoir_tv/presentation/widgets/dpad_stepper.dart';
import 'package:flutter/services.dart';

class MockSettingsCubit extends Mock implements SettingsCubit {}

void main() {
  late MockSettingsCubit mockSettingsCubit;
  late Settings mockSettings;

  setUp(() {
    mockSettingsCubit = MockSettingsCubit();
    // Providing default settings using positional and required named properties.
    mockSettings = const Settings();
    when(
      () => mockSettingsCubit.state,
    ).thenReturn(SettingsLoaded(settings: mockSettings));
    when(
      () => mockSettingsCubit.stream,
    ).thenAnswer((_) => Stream.value(SettingsLoaded(settings: mockSettings)));
    when(() => mockSettingsCubit.isPinEnabled).thenReturn(false);
  });

  Widget createTestWidget() {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          home: BlocProvider<SettingsCubit>.value(
            value: mockSettingsCubit,
            child: const SettingsMenuPage(),
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

      // Ihtiyat is the default selected section
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

      // Navigate to Iqomah section
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.descendant(
          of: find.byType(IqomahSection),
          matching: find.byType(DPadStepper),
        ),
        findsNWidgets(5),
      );
    });
  });
}
