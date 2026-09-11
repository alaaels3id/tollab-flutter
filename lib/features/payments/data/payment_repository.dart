import 'package:sqflite/sqflite.dart';
import '../../../core/constants/payment_status.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/monthly_payment_model.dart';

class PaymentRepository {
  final DatabaseHelper _dbHelper;
  PaymentRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Ensures a monthly_periods entry exists for month and year and returns its ID
  Future<int> ensureMonthlyPeriod(int month, int year) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'monthly_periods',
      columns: ['id'],
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    final now = DateTime.now().toIso8601String();
    return await db.insert(
      'monthly_periods',
      {
        'month': month,
        'year': year,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Automatically generates monthly payment records with snapshots of student & group info
  Future<void> generateMonthlyRecords(int month, int year) async {
    final db = await _dbHelper.database;
    final periodId = await ensureMonthlyPeriod(month, year);
    final now = DateTime.now().toIso8601String();
    final todayStr = DateFormatter.getTodayString();

    // Fetch active students and their active group info
    final activeStudents = await db.rawQuery('''
      SELECT 
        s.id AS student_id,
        s.name AS student_name,
        g.id AS group_id,
        g.name AS group_name,
        g.monthly_fee_cents,
        g.due_day
      FROM students s
      JOIN groups g ON s.group_id = g.id
      WHERE s.status = 'active' AND g.status = 'active'
    ''');

    final batch = db.batch();
    for (final st in activeStudents) {
      final dueDay = st['due_day'] as int;
      final dueDate = DateFormatter.calculateDueDate(year, month, dueDay);
      final initialStatus = todayStr.compareTo(dueDate) > 0 ? 'overdue' : 'pending';

      batch.rawInsert('''
        INSERT OR IGNORE INTO monthly_payments (
          monthly_period_id,
          student_id,
          group_id,
          student_name_snapshot,
          group_name_snapshot,
          amount_due_cents,
          amount_paid_cents,
          due_date,
          status,
          paid_at,
          notes,
          created_at,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, 0, ?, ?, NULL, NULL, ?, ?)
      ''', [
        periodId,
        st['student_id'],
        st['group_id'],
        st['student_name'],
        st['group_name'],
        st['monthly_fee_cents'],
        dueDate,
        initialStatus,
        now,
        now,
      ]);
    }
    await batch.commit(noResult: true);

    await refreshOverdueStatuses(periodId);
  }

  /// Automatically update pending records to overdue if due date has passed
  Future<void> refreshOverdueStatuses(int periodId) async {
    final db = await _dbHelper.database;
    final todayStr = DateFormatter.getTodayString();
    final now = DateTime.now().toIso8601String();

    await db.rawUpdate('''
      UPDATE monthly_payments
      SET status = 'overdue', updated_at = ?
      WHERE monthly_period_id = ? 
        AND status = 'pending' 
        AND due_date < ?
        AND amount_paid_cents < amount_due_cents
    ''', [now, periodId, todayStr]);
  }

  /// Get monthly payments list with optional search and filters
  Future<List<MonthlyPaymentModel>> getMonthlyPayments(
    int month,
    int year, {
    int? groupId,
    String? status,
    String? query,
  }) async {
    final db = await _dbHelper.database;
    await generateMonthlyRecords(month, year);
    final periodId = await ensureMonthlyPeriod(month, year);
    await refreshOverdueStatuses(periodId);

    String sql = '''
      SELECT 
        mp.*,
        s.student_code
      FROM monthly_payments mp
      JOIN students s ON mp.student_id = s.id
      WHERE mp.monthly_period_id = ?
    ''';
    final List<dynamic> args = [periodId];

    if (groupId != null && groupId > 0) {
      sql += ' AND mp.group_id = ?';
      args.add(groupId);
    }

    if (status != null && status.isNotEmpty) {
      sql += ' AND mp.status = ?';
      args.add(status);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      sql += ' AND (mp.student_name_snapshot LIKE ? OR s.student_code LIKE ?)';
      args.addAll([q, q]);
    }

    sql += ' ORDER BY mp.status DESC, mp.group_name_snapshot ASC, mp.student_name_snapshot ASC';

    final rows = await db.rawQuery(sql, args);
    return rows.map((r) => MonthlyPaymentModel.fromMap(r)).toList();
  }

  /// Records or updates a payment (full or partial)
  Future<MonthlyPaymentModel> recordPayment({
    required int paymentId,
    required int amountPaidCents,
    PaymentStatus? customStatus,
    String? notes,
    String? paidAt,
  }) async {
    final db = await _dbHelper.database;

    final existingRows = await db.rawQuery('SELECT * FROM monthly_payments WHERE id = ?', [paymentId]);
    if (existingRows.isEmpty) {
      throw Exception('سجل الدفع غير موجود');
    }
    final existing = existingRows.first;

    final dueCents = existing['amount_due_cents'] as int;
    final todayStr = DateFormatter.getTodayString();
    final now = DateTime.now().toIso8601String();

    PaymentStatus resolvedStatus;
    String? resolvedPaidAt = existing['paid_at'] as String?;

    if (customStatus != null) {
      resolvedStatus = customStatus;
      if (resolvedStatus == PaymentStatus.paid && resolvedPaidAt == null) {
        resolvedPaidAt = paidAt ?? now;
      }
    } else {
      if (amountPaidCents >= dueCents) {
        resolvedStatus = PaymentStatus.paid;
        resolvedPaidAt = paidAt ?? now;
      } else if (amountPaidCents > 0) {
        resolvedStatus = PaymentStatus.partial;
        resolvedPaidAt = paidAt ?? now;
      } else {
        final dueDate = existing['due_date'] as String;
        resolvedStatus = dueDate.compareTo(todayStr) < 0 ? PaymentStatus.overdue : PaymentStatus.pending;
        resolvedPaidAt = null;
      }
    }

    final resolvedNotes = notes != null ? notes.trim() : existing['notes'] as String?;

    await db.update(
      'monthly_payments',
      {
        'amount_paid_cents': amountPaidCents,
        'status': resolvedStatus.dbValue,
        'paid_at': resolvedPaidAt,
        'notes': resolvedNotes,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );

    final updatedRows = await db.rawQuery('''
      SELECT 
        mp.*,
        s.student_code
      FROM monthly_payments mp
      JOIN students s ON mp.student_id = s.id
      WHERE mp.id = ?
    ''', [paymentId]);

    return MonthlyPaymentModel.fromMap(updatedRows.first);
  }
}
