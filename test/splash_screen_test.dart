import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tollab/features/navigation/main_nav_scaffold.dart';
import 'package:tollab/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders centered title and subtitle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(
            duration: Duration(seconds: 10),
          ),
        ),
      ),
    );

    // Initial pump to start animation
    await tester.pump();

    // Verify title and subtitle are present
    expect(find.text('طُلاّب'), findsOneWidget);
    expect(find.text('إدارة المجموعات والاشتراكات الشهرية'), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Let animation settle
    await tester.pump(const Duration(milliseconds: 1000));
    expect(find.text('طُلاّب'), findsOneWidget);
  });

  testWidgets('SplashScreen navigates to MainNavScaffold after duration', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(
            duration: Duration(milliseconds: 500),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(MainNavScaffold), findsNothing);

    // Advance past duration + transition
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify navigation to MainNavScaffold occurred
    expect(find.byType(MainNavScaffold), findsOneWidget);
  });
}
