import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:miqotul_khoir_tv/domain/entities/settings.dart';
import 'package:miqotul_khoir_tv/domain/repositories/wisdom_quote_repository.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/settings/settings_cubit.dart';
import 'package:miqotul_khoir_tv/presentation/cubits/settings/settings_state.dart';
import 'package:miqotul_khoir_tv/presentation/pages/settings/pin_gate_page.dart';
import 'package:miqotul_khoir_tv/presentation/pages/settings/settings_menu_page.dart';
import 'package:miqotul_khoir_tv/presentation/widgets/pin_input_widget.dart';
import 'package:flutter/services.dart';

class MockSettingsCubit extends Mock implements SettingsCubit {}

class MockWisdomQuoteRepository extends Mock implements WisdomQuoteRepository {}

void main() {
  late MockSettingsCubit mockSettingsCubit;
  late MockWisdomQuoteRepository mockWisdomRepo;

  setUp(() {
    mockSettingsCubit = MockSettingsCubit();
    mockWisdomRepo = MockWisdomQuoteRepository();
    final mockSettings = const Settings();
    when(
      () => mockSettingsCubit.state,
    ).thenReturn(SettingsLoaded(settings: mockSettings));
    when(
      () => mockSettingsCubit.stream,
    ).thenAnswer((_) => Stream.value(SettingsLoaded(settings: mockSettings)));
    // WisdomQuoteSection needs these stubs when SettingsMenuPage is pushed.
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
          builder: (context, child) =>
              RepositoryProvider<WisdomQuoteRepository>.value(
                value: mockWisdomRepo,
                child: BlocProvider<SettingsCubit>.value(
                  value: mockSettingsCubit,
                  child: child!,
                ),
              ),
          home: const PinGatePage(),
        );
      },
    );
  }

  group('PinGatePage Tests', () {
    testWidgets('Renders PIN gate UI when PIN is enabled', (tester) async {
      when(() => mockSettingsCubit.isPinEnabled).thenReturn(true);
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Masukkan PIN'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.byType(PinInputWidget), findsOneWidget);
    });

    testWidgets('Shows error text on invalid PIN', (tester) async {
      when(() => mockSettingsCubit.isPinEnabled).thenReturn(true);
      when(
        () => mockSettingsCubit.verifyPin(any()),
      ).thenAnswer((_) async => false);

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate entering 6 digits
      final pinInputFinder = find.byType(PinInputWidget);
      expect(pinInputFinder, findsOneWidget);

      // Simulate entering 6 digits via keyboard
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.pump(
        const Duration(milliseconds: 100),
      ); // allow verifyPin to resolve and error to show (before 600ms reset)

      expect(find.text('PIN yang Anda masukkan salah.'), findsOneWidget);

      // Advance clock by 600ms to clear the Future.delayed timer
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('Navigates to menu on valid PIN', (tester) async {
      when(() => mockSettingsCubit.isPinEnabled).thenReturn(true);
      when(
        () => mockSettingsCubit.verifyPin(any()),
      ).thenAnswer((_) async => true);

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate entering 6 digits via keyboard
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit6);
      await tester.pump(const Duration(milliseconds: 50));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SettingsMenuPage), findsOneWidget);
      expect(find.byType(PinGatePage), findsNothing);
    });

    testWidgets('Navigates to menu immediately if PIN is disabled', (
      tester,
    ) async {
      when(() => mockSettingsCubit.isPinEnabled).thenReturn(false);

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should automatically push Replacement
      expect(find.byType(SettingsMenuPage), findsOneWidget);
      expect(find.byType(PinGatePage), findsNothing);
    });
  });
}
