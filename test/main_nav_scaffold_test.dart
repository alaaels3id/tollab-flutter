import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tollab/features/navigation/main_nav_scaffold.dart';

void main() {
  testWidgets('MainNavScaffold switches to matching screen when tapping tabs in RTL', (WidgetTester tester) async {
    // Set screen size to iPhone 17 dimensions
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar', 'EG'),
          supportedLocales: [Locale('ar', 'EG')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MainNavScaffold(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Initial page: Dashboard (index 0)
    expect(find.text('الرئيسية'), findsAtLeastNWidgets(1));

    // Tap 'الطلاب' (index 1)
    await tester.tap(find.text('الطلاب'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('إدارة الطلاب'), findsOneWidget);

    // Tap 'المجموعات' (index 2)
    await tester.tap(find.text('المجموعات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('إدارة المجموعات'), findsOneWidget);

    // Tap 'الإعدادات' (index 3)
    await tester.tap(find.text('الإعدادات'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('الإعدادات'), findsAtLeastNWidgets(1));

    // Verify Payments and Archive are accessible from Settings
    expect(find.text('الاشتراكات الشهرية'), findsOneWidget);
    expect(find.text('الأرشيف الشهري'), findsOneWidget);
  });
}
