import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../payments/data/payment_repository.dart';
import '../../payments/models/monthly_payment_model.dart';
import '../models/dashboard_stats_model.dart';

class DashboardRepository {
  final DatabaseHelper _dbHelper;
  final PaymentRepository _paymentRepo;

  DashboardRepository({DatabaseHelper? dbHelper, PaymentRepository? paymentRepo})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _paymentRepo = paymentRepo ?? PaymentRepository(dbHelper: dbHelper);

  Future<DashboardStatsModel> getStats({int? month, int? year}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final m = month ?? now.month;
    final y = year ?? now.year;

    // Ensure records are generated for this month
    await _paymentRepo.generateMonthlyRecords(m, y);
    final periodId = await _paymentRepo.ensureMonthlyPeriod(m, y);
    await _paymentRepo.refreshOverdueStatuses(periodId);

    // Active counts
    final activeStudentsCount = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM students WHERE status = 'active'"),
        ) ??
        0;

    final activeGroupsCount = Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM groups WHERE status = 'active'"),
        ) ??
        0;

    // Sums and counts from monthly_payments
    final payments = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(amount_due_cents), 0) AS expected,
        COALESCE(SUM(amount_paid_cents), 0) AS collected,
        SUM(CASE WHEN status = 'paid' THEN 1 ELSE 0 END) AS paid_count,
        SUM(CASE WHEN status = 'partial' THEN 1 ELSE 0 END) AS partial_count,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending_count,
        SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END) AS overdue_count
      FROM monthly_payments
      WHERE monthly_period_id = ?
    ''', [periodId]);

    final pRow = payments.first;
    final expected = (pRow['expected'] as num?)?.toInt() ?? 0;
    final collected = (pRow['collected'] as num?)?.toInt() ?? 0;
    final outstanding = (expected - collected) > 0 ? (expected - collected) : 0;
    final paidCount = (pRow['paid_count'] as num?)?.toInt() ?? 0;
    final partialCount = (pRow['partial_count'] as num?)?.toInt() ?? 0;
    final pendingCount = (pRow['pending_count'] as num?)?.toInt() ?? 0;
    final overdueCount = (pRow['overdue_count'] as num?)?.toInt() ?? 0;

    // Upcoming groups (due day >= today day and within next 7 days, or active groups)
    final todayDay = now.day;
    final upcomingRows = await db.rawQuery('''
      SELECT 
        g.id AS group_id,
        g.name AS group_name,
        g.due_day,
        g.monthly_fee_cents,
        COUNT(s.id) AS student_count
      FROM groups g
      LEFT JOIN students s ON s.group_id = g.id AND s.status = 'active'
      WHERE g.status = 'active' AND g.due_day >= ? AND g.due_day <= ?
      GROUP BY g.id
      ORDER BY g.due_day ASC
    ''', [todayDay, todayDay + 7]);

    final upcomingDueGroups = upcomingRows.map((r) => UpcomingDueGroup(
      groupId: r['group_id'] as int,
      groupName: r['group_name'] as String,
      dueDay: r['due_day'] as int,
      feeCents: r['monthly_fee_cents'] as int,
      studentCount: (r['student_count'] as num?)?.toInt() ?? 0,
    )).toList();

    // Overdue payments (up to 10)
    final overdueRows = await db.rawQuery('''
      SELECT mp.*, s.student_code
      FROM monthly_payments mp
      JOIN students s ON mp.student_id = s.id
      WHERE mp.monthly_period_id = ? AND mp.status = 'overdue'
      ORDER BY mp.due_date ASC
      LIMIT 10
    ''', [periodId]);
    final overduePayments = overdueRows.map((r) => MonthlyPaymentModel.fromMap(r)).toList();

    // Recent payments (up to 5)
    final recentRows = await db.rawQuery('''
      SELECT mp.*, s.student_code
      FROM monthly_payments mp
      JOIN students s ON mp.student_id = s.id
      WHERE mp.paid_at IS NOT NULL
      ORDER BY mp.paid_at DESC
      LIMIT 5
    ''');
    final recentPayments = recentRows.map((r) => MonthlyPaymentModel.fromMap(r)).toList();

    return DashboardStatsModel(
      month: m,
      year: y,
      activeStudents: activeStudentsCount,
      activeGroups: activeGroupsCount,
      expectedRevenueCents: expected,
      collectedRevenueCents: collected,
      outstandingRevenueCents: outstanding,
      paidCount: paidCount,
      pendingCount: pendingCount,
      partialCount: partialCount,
      overdueCount: overdueCount,
      upcomingDueGroups: upcomingDueGroups,
      overduePayments: overduePayments,
      recentPayments: recentPayments,
    );
  }
}
