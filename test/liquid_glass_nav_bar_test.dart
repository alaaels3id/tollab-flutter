import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tollab/features/navigation/widgets/liquid_glass_nav_bar.dart';

void main() {
  testWidgets('LiquidGlassNavBar renders items and responds to taps', (WidgetTester tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) {
              return LiquidGlassNavBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  setState(() => selectedIndex = index);
                },
                items: const [
                  LiquidGlassNavBarItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'الرئيسية',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: 'الطلاب',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups_rounded,
                    label: 'المجموعات',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                    label: 'الاشتراكات',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.archive_outlined,
                    activeIcon: Icons.archive_rounded,
                    label: 'الأرشيف',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'الإعدادات',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Initial pump
    await tester.pumpAndSettle();

    // Verify all 6 labels are rendered
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الطلاب'), findsOneWidget);
    expect(find.text('المجموعات'), findsOneWidget);
    expect(find.text('الاشتراكات'), findsOneWidget);
    expect(find.text('الأرشيف'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);

    // Tap 'الطلاب'
    await tester.tap(find.text('الطلاب'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);

    // Tap 'الإعدادات'
    await tester.tap(find.text('الإعدادات'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(selectedIndex, 5);
  });

  testWidgets('LiquidGlassNavBar correctly maps taps in RTL (Arabic)', (WidgetTester tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return LiquidGlassNavBar(
                  currentIndex: selectedIndex,
                  onTap: (index) {
                    setState(() => selectedIndex = index);
                  },
                  items: const [
                    LiquidGlassNavBarItem(
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard_rounded,
                      label: 'الرئيسية',
                    ),
                    LiquidGlassNavBarItem(
                      icon: Icons.people_outline_rounded,
                      activeIcon: Icons.people_rounded,
                      label: 'الطلاب',
                    ),
                    LiquidGlassNavBarItem(
                      icon: Icons.groups_outlined,
                      activeIcon: Icons.groups_rounded,
                      label: 'المجموعات',
                    ),
                    LiquidGlassNavBarItem(
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                      label: 'الاشتراكات',
                    ),
                    LiquidGlassNavBarItem(
                      icon: Icons.archive_outlined,
                      activeIcon: Icons.archive_rounded,
                      label: 'الأرشيف',
                    ),
                    LiquidGlassNavBarItem(
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings_rounded,
                      label: 'الإعدادات',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap 'الطلاب' (index 1) in RTL
    await tester.tap(find.text('الطلاب'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 1);

    // Tap 'الأرشيف' (index 4) in RTL
    await tester.tap(find.text('الأرشيف'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 4);

    // Tap 'المجموعات' (index 2) in RTL
    await tester.tap(find.text('المجموعات'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 2);

    // Tap 'الاشتراكات' (index 3) in RTL
    await tester.tap(find.text('الاشتراكات'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 3);

    // Tap 'الرئيسية' (index 0) in RTL
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 0);

    // Tap 'الإعدادات' (index 5) in RTL
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 5);
  });

  testWidgets('LiquidGlassNavBar responds to horizontal drag gestures', (WidgetTester tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox(),
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) {
              return LiquidGlassNavBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  setState(() => selectedIndex = index);
                },
                items: const [
                  LiquidGlassNavBarItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'الرئيسية',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: 'الطلاب',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups_rounded,
                    label: 'المجموعات',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long_rounded,
                    label: 'الاشتراكات',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.archive_outlined,
                    activeIcon: Icons.archive_rounded,
                    label: 'الأرشيف',
                  ),
                  LiquidGlassNavBarItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings_rounded,
                    label: 'الإعدادات',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Drag horizontally across the navbar
    await tester.drag(find.byType(LiquidGlassNavBar), const Offset(200, 0));
    await tester.pumpAndSettle();

    // Should update selected index
    expect(selectedIndex, isNot(0));
  });
}
