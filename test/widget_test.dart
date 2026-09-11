import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tollab/core/constants/payment_status.dart';
import 'package:tollab/shared/widgets/empty_state.dart';
import 'package:tollab/shared/widgets/stat_card.dart';
import 'package:tollab/shared/widgets/status_badge.dart';

void main() {
  testWidgets('StatusBadge renders correct label and icon symbol for paid status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: PaymentStatus.paid),
        ),
      ),
    );

    expect(find.text('تم السداد'), findsOneWidget);
    expect(find.text('✓'), findsOneWidget);
  });

  testWidgets('StatusBadge renders overdue badge correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: PaymentStatus.overdue),
        ),
      ),
    );

    expect(find.text('متأخر'), findsOneWidget);
    expect(find.text('⚠'), findsOneWidget);
  });

  testWidgets('StatCard displays title, value and subtitle correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: 'إجمالي المحصل',
            value: '5,000 ج.م',
            subtitle: '15 طالب',
            icon: Icons.check_circle,
          ),
        ),
      ),
    );

    expect(find.text('إجمالي المحصل'), findsOneWidget);
    expect(find.text('5,000 ج.م'), findsOneWidget);
    expect(find.text('15 طالب'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('EmptyState displays title, subtitle and action', (WidgetTester tester) async {
    bool actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.group,
            title: 'لا توجد مجموعات',
            subtitle: 'قم بإضافة مجموعتك الأولى',
            actionLabel: 'إضافة مجموعة',
            onAction: () => actionTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('لا توجد مجموعات'), findsOneWidget);
    expect(find.text('قم بإضافة مجموعتك الأولى'), findsOneWidget);
    expect(find.text('إضافة مجموعة'), findsOneWidget);

    await tester.tap(find.text('إضافة مجموعة'));
    expect(actionTapped, isTrue);
  });
}
