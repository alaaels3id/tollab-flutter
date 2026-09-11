import '../../../core/constants/payment_status.dart';
import '../../../core/database/database_helper.dart';
import '../../payments/data/payment_repository.dart';
import '../../payments/models/monthly_payment_model.dart';
import '../models/archive_model.dart';

class ArchiveRepository {
  final DatabaseHelper _dbHelper;
  final PaymentRepository _paymentRepo;

  ArchiveRepository({DatabaseHelper? dbHelper, PaymentRepository? paymentRepo})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _paymentRepo = paymentRepo ?? PaymentRepository(dbHelper: dbHelper);

  /// Fetch all historical periods that have records
  Future<List<Map<String, int>>> getAvailablePeriods() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT month, year 
      FROM monthly_periods 
      ORDER BY year DESC, month DESC
    ''');

    return rows.map((r) => {
      'month': r['month'] as int,
      'year': r['year'] as int,
    }).toList();
  }

  /// Fetch full archive summary for a specific month and year
  Future<MonthArchiveSummary> getMonthArchive(int month, int year) async {
    final db = await _dbHelper.database;
    await _paymentRepo.generateMonthlyRecords(month, year);
    final periodId = await _paymentRepo.ensureMonthlyPeriod(month, year);
    await _paymentRepo.refreshOverdueStatuses(periodId);

    final rows = await db.rawQuery('''
      SELECT 
        mp.*,
        s.student_code
      FROM monthly_payments mp
      JOIN students s ON mp.student_id = s.id
      WHERE mp.monthly_period_id = ?
      ORDER BY mp.group_name_snapshot ASC, mp.student_name_snapshot ASC
    ''', [periodId]);

    final Map<int, GroupMonthlyArchiveSummary> groupMap = {};

    int expectedTotal = 0;
    int collectedTotal = 0;
    int paidTotal = 0;
    int partialTotal = 0;
    int pendingTotal = 0;
    int overdueTotal = 0;

    for (final r in rows) {
      final payment = MonthlyPaymentModel.fromMap(r);
      final due = payment.amountDueCents;
      final paid = payment.amountPaidCents;
      final status = payment.status;

      expectedTotal += due;
      collectedTotal += paid;

      switch (status) {
        case PaymentStatus.paid:
          paidTotal++;
          break;
        case PaymentStatus.partial:
          partialTotal++;
          break;
        case PaymentStatus.pending:
          pendingTotal++;
          break;
        case PaymentStatus.overdue:
          overdueTotal++;
          break;
      }

      final gid = payment.groupId;
      if (!groupMap.containsKey(gid)) {
        groupMap[gid] = GroupMonthlyArchiveSummary(
          groupId: gid,
          groupName: payment.groupNameSnapshot,
          studentCount: 0,
          feeCents: due,
          expectedCents: 0,
          collectedCents: 0,
          outstandingCents: 0,
          paidCount: 0,
          partialCount: 0,
          pendingCount: 0,
          overdueCount: 0,
          payments: [],
        );
      }

      final cur = groupMap[gid]!;
      cur.payments.add(payment);
      groupMap[gid] = GroupMonthlyArchiveSummary(
        groupId: cur.groupId,
        groupName: cur.groupName,
        studentCount: cur.studentCount + 1,
        feeCents: cur.feeCents,
        expectedCents: cur.expectedCents + due,
        collectedCents: cur.collectedCents + paid,
        outstandingCents: (cur.expectedCents + due - (cur.collectedCents + paid)) > 0
            ? (cur.expectedCents + due - (cur.collectedCents + paid))
            : 0,
        paidCount: cur.paidCount + (status == PaymentStatus.paid ? 1 : 0),
        partialCount: cur.partialCount + (status == PaymentStatus.partial ? 1 : 0),
        pendingCount: cur.pendingCount + (status == PaymentStatus.pending ? 1 : 0),
        overdueCount: cur.overdueCount + (status == PaymentStatus.overdue ? 1 : 0),
        payments: cur.payments,
      );
    }

    final outstandingTotal = (expectedTotal - collectedTotal) > 0 ? (expectedTotal - collectedTotal) : 0;

    return MonthArchiveSummary(
      month: month,
      year: year,
      totalGroups: groupMap.length,
      totalStudents: rows.length,
      expectedTotalCents: expectedTotal,
      collectedTotalCents: collectedTotal,
      outstandingTotalCents: outstandingTotal,
      paidCount: paidTotal,
      partialCount: partialTotal,
      pendingCount: pendingTotal,
      overdueCount: overdueTotal,
      groups: groupMap.values.toList(),
    );
  }
}
