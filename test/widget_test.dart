// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:miqotul_khoir_tv/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MiqotulKhoirApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    // Verify that the app starts and shows the splash screen.
    expect(find.text('Miqotul Khoir TV'), findsOneWidget);
    expect(find.text('Memuat pengaturan...'), findsOneWidget);
  });
}
