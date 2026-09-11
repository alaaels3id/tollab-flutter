import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tollab/core/constants/payment_status.dart';
import 'package:tollab/core/database/database_helper.dart';
import 'package:tollab/core/utils/currency_formatter.dart';
import 'package:tollab/core/utils/date_formatter.dart';
import 'package:tollab/features/archive/data/archive_repository.dart';
import 'package:tollab/features/dashboard/data/dashboard_repository.dart';
import 'package:tollab/features/groups/data/group_repository.dart';
import 'package:tollab/features/payments/data/payment_repository.dart';
import 'package:tollab/features/students/data/student_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Date & Due Day Clamping Tests', () {
    test('Clamps due day 31 in February 2026 (non-leap) to 28', () {
      final dueDate = DateFormatter.calculateDueDate(2026, 2, 31);
      expect(dueDate, '2026-02-28');
    });

    test('Clamps due day 31 in February 2024 (leap year) to 29', () {
      final dueDate = DateFormatter.calculateDueDate(2024, 2, 31);
      expect(dueDate, '2024-02-29');
    });

    test('Clamps due day 31 in April to 30', () {
      final dueDate = DateFormatter.calculateDueDate(2026, 4, 31);
      expect(dueDate, '2026-04-30');
    });

    test('Valid due day within month remains unchanged', () {
      final dueDate = DateFormatter.calculateDueDate(2026, 9, 15);
      expect(dueDate, '2026-09-15');
    });

    test('Arabic month names are correct', () {
      expect(DateFormatter.getArabicMonthName(1), 'يناير');
      expect(DateFormatter.getArabicMonthName(9), 'سبتمبر');
      expect(DateFormatter.getArabicMonthName(12), 'ديسمبر');
    });
  });

  group('Currency Formatter Tests', () {
    test('Exact integer arithmetic with piastres/cents', () {
      expect(CurrencyFormatter.egpToCents(300), 30000);
      expect(CurrencyFormatter.egpToCents(150.50), 15050);
      expect(CurrencyFormatter.centsToEgp(30000), 300.0);
    });

    test('Arabic currency formatting', () {
      final formatted = CurrencyFormatter.formatEgp(30000);
      expect(formatted.contains('ج.م'), isTrue);
    });
  });

  group('Database & Core Business Rules Tests', () {
    late Database testDb;
    late GroupRepository groupRepo;
    late StudentRepository studentRepo;
    late PaymentRepository paymentRepo;
    late DashboardRepository dashboardRepo;
    late ArchiveRepository archiveRepo;

    setUp(() async {
      // In-memory isolated database for tests
      testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await testDb.execute('PRAGMA foreign_keys = ON;');

      // Create schema
      await testDb.execute('''
        CREATE TABLE groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          monthly_fee_cents INTEGER NOT NULL CHECK (monthly_fee_cents >= 0),
          due_day INTEGER NOT NULL CHECK (due_day >= 1 AND due_day <= 31),
          description TEXT,
          status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');

      await testDb.execute('''
        CREATE TABLE students (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          student_code TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          phone TEXT,
          group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE RESTRICT,
          status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');

      await testDb.execute('''
        CREATE TABLE monthly_periods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
          year INTEGER NOT NULL CHECK (year >= 2000 AND year <= 2100),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(month, year)
        );
      ''');

      await testDb.execute('''
        CREATE TABLE monthly_payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          monthly_period_id INTEGER NOT NULL REFERENCES monthly_periods(id) ON DELETE RESTRICT,
          student_id INTEGER NOT NULL REFERENCES students(id) ON DELETE RESTRICT,
          group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE RESTRICT,
          student_name_snapshot TEXT NOT NULL,
          group_name_snapshot TEXT NOT NULL,
          amount_due_cents INTEGER NOT NULL CHECK (amount_due_cents >= 0),
          amount_paid_cents INTEGER NOT NULL DEFAULT 0 CHECK (amount_paid_cents >= 0),
          due_date TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'partial', 'overdue')),
          paid_at TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(monthly_period_id, student_id)
        );
      ''');

      await testDb.execute('''
        CREATE TABLE notification_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          monthly_period_id INTEGER NOT NULL REFERENCES monthly_periods(id) ON DELETE CASCADE,
          group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
          notification_type TEXT NOT NULL CHECK (notification_type IN ('one_day_before', 'due_day', 'overdue')),
          sent_at TEXT NOT NULL,
          UNIQUE(monthly_period_id, group_id, notification_type)
        );
      ''');

      await testDb.execute('''
        CREATE TABLE settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
      ''');

      DatabaseHelper.instance.setDatabaseForTesting(testDb);

      groupRepo = GroupRepository();
      studentRepo = StudentRepository();
      paymentRepo = PaymentRepository();
      dashboardRepo = DashboardRepository();
      archiveRepo = ArchiveRepository();
    });

    tearDown(() async {
      await testDb.close();
    });

    test('Groups CRUD and validations', () async {
      final gId = await groupRepo.createGroup(
        name: 'مجموعة أ',
        monthlyFeeCents: 30000,
        dueDay: 15,
        description: 'شرح مادة الرياضيات',
      );
      expect(gId, greaterThan(0));

      final group = await groupRepo.getGroupById(gId);
      expect(group, isNotNull);
      expect(group!.name, 'مجموعة أ');
      expect(group.monthlyFeeCents, 30000);
      expect(group.dueDay, 15);
      expect(group.isActive, isTrue);

      // Deactivate
      await groupRepo.toggleGroupStatus(gId, false);
      final updated = await groupRepo.getGroupById(gId);
      expect(updated!.isActive, isFalse);
    });

    test('Student creation generates unique sequential codes (STD-000001, STD-000002)', () async {
      final gId = await groupRepo.createGroup(
        name: 'مجموعة 1',
        monthlyFeeCents: 20000,
        dueDay: 10,
      );

      final s1Id = await studentRepo.createStudent(
        name: 'محمد أحمد',
        groupId: gId,
        phone: '01000000001',
      );
      final s2Id = await studentRepo.createStudent(
        name: 'علي حسن',
        groupId: gId,
        phone: '01000000002',
      );

      final s1 = await studentRepo.getStudentById(s1Id);
      final s2 = await studentRepo.getStudentById(s2Id);

      expect(s1!.studentCode, 'STD-000001');
      expect(s2!.studentCode, 'STD-000002');
    });

    test('Monthly payment record generation with snapshots and duplicate prevention', () async {
      final gId = await groupRepo.createGroup(
        name: 'مجموعة الفيزياء',
        monthlyFeeCents: 40000,
        dueDay: 20,
      );

      final sId = await studentRepo.createStudent(
        name: 'سارة خالد',
        groupId: gId,
      );

      // Generate for September 2026
      await paymentRepo.generateMonthlyRecords(9, 2026);

      final payments = await paymentRepo.getMonthlyPayments(9, 2026);
      expect(payments.length, 1);
      expect(payments.first.studentId, sId);
      expect(payments.first.studentNameSnapshot, 'سارة خالد');
      expect(payments.first.groupNameSnapshot, 'مجموعة الفيزياء');
      expect(payments.first.amountDueCents, 40000);
      expect(payments.first.amountPaidCents, 0);
      expect(payments.first.dueDate, '2026-09-20');

      // Calling generateMonthlyRecords again must NOT duplicate records
      await paymentRepo.generateMonthlyRecords(9, 2026);
      final paymentsAfter = await paymentRepo.getMonthlyPayments(9, 2026);
      expect(paymentsAfter.length, 1);
    });

    test('Recording partial and full payments changes status accurately', () async {
      final gId = await groupRepo.createGroup(name: 'مجموعة لغات', monthlyFeeCents: 50000, dueDay: 25);
      final sId = await studentRepo.createStudent(name: 'كريم محمود', groupId: gId);

      await paymentRepo.generateMonthlyRecords(9, 2026);
      final payments = await paymentRepo.getMonthlyPayments(9, 2026);
      final payment = payments.first;
      expect(payment.studentId, sId);

      // Partial payment (200 EGP = 20000 cents)
      final partial = await paymentRepo.recordPayment(
        paymentId: payment.id,
        amountPaidCents: 20000,
      );
      expect(partial.status, PaymentStatus.partial);
      expect(partial.amountPaidCents, 20000);
      expect(partial.remainingCents, 30000);

      // Full payment (500 EGP = 50000 cents)
      final full = await paymentRepo.recordPayment(
        paymentId: payment.id,
        amountPaidCents: 50000,
      );
      expect(full.status, PaymentStatus.paid);
      expect(full.remainingCents, 0);
    });

    test('Historical Snapshot Integrity: Moving student does not modify past records', () async {
      final g1Id = await groupRepo.createGroup(name: 'المجموعة الأولى', monthlyFeeCents: 30000, dueDay: 5);
      final g2Id = await groupRepo.createGroup(name: 'المجموعة الثانية', monthlyFeeCents: 45000, dueDay: 15);

      final sId = await studentRepo.createStudent(name: 'عمر شريف', groupId: g1Id);

      // Generate September records (in Group 1)
      await paymentRepo.generateMonthlyRecords(9, 2026);
      final sepPayments = await paymentRepo.getMonthlyPayments(9, 2026);
      expect(sepPayments.first.groupNameSnapshot, 'المجموعة الأولى');
      expect(sepPayments.first.amountDueCents, 30000);

      // Move student to Group 2
      await studentRepo.moveStudentGroup(sId, g2Id);

      // Check that September records still reflect Group 1 snapshots
      final sepPaymentsCheck = await paymentRepo.getMonthlyPayments(9, 2026);
      expect(sepPaymentsCheck.first.groupNameSnapshot, 'المجموعة الأولى');
      expect(sepPaymentsCheck.first.amountDueCents, 30000);

      // Generate October records (must reflect new Group 2)
      await paymentRepo.generateMonthlyRecords(10, 2026);
      final octPayments = await paymentRepo.getMonthlyPayments(10, 2026);
      expect(octPayments.first.groupNameSnapshot, 'المجموعة الثانية');
      expect(octPayments.first.amountDueCents, 45000);
    });

    test('Dashboard and Archive financial aggregations match exact totals', () async {
      final gId = await groupRepo.createGroup(name: 'مجموعة الرياضيات', monthlyFeeCents: 30000, dueDay: 10);
      await studentRepo.createStudent(name: 'طالب 1', groupId: gId);
      await studentRepo.createStudent(name: 'طالب 2', groupId: gId);

      await paymentRepo.generateMonthlyRecords(9, 2026);
      final payments = await paymentRepo.getMonthlyPayments(9, 2026);

      // Student 1 pays in full
      await paymentRepo.recordPayment(paymentId: payments[0].id, amountPaidCents: 30000);
      // Student 2 pays partially (100 EGP)
      await paymentRepo.recordPayment(paymentId: payments[1].id, amountPaidCents: 10000);

      // Dashboard stats
      final stats = await dashboardRepo.getStats(month: 9, year: 2026);
      expect(stats.expectedRevenueCents, 60000);
      expect(stats.collectedRevenueCents, 40000);
      expect(stats.outstandingRevenueCents, 20000);
      expect(stats.paidCount, 1);
      expect(stats.partialCount, 1);

      // Archive summary
      final archive = await archiveRepo.getMonthArchive(9, 2026);
      expect(archive.expectedTotalCents, 60000);
      expect(archive.collectedTotalCents, 40000);
      expect(archive.outstandingTotalCents, 20000);
      expect(archive.groups.length, 1);
      expect(archive.groups.first.collectedCents, 40000);
    });

    test('Force delete student removes student and cascades linked payments', () async {
      final gId = await groupRepo.createGroup(name: 'مجموعة مؤقتة', monthlyFeeCents: 20000, dueDay: 15);
      final sId = await studentRepo.createStudent(name: 'طالب سيحذف إجباريا', groupId: gId);

      await paymentRepo.generateMonthlyRecords(9, 2026);
      final payments = await paymentRepo.getMonthlyPayments(9, 2026);
      expect(payments.any((p) => p.studentId == sId), isTrue);

      // Normal delete should throw
      expect(
        () async => await studentRepo.deleteStudent(sId),
        throwsA(isA<Exception>()),
      );

      // Force delete should succeed
      await studentRepo.deleteStudent(sId, force: true);

      final student = await studentRepo.getStudentById(sId);
      expect(student, isNull);

      final paymentsAfter = await paymentRepo.getMonthlyPayments(9, 2026);
      expect(paymentsAfter.any((p) => p.studentId == sId), isFalse);
    });

    test('Force delete group removes group, its students, and all associated payments', () async {
      final gId = await groupRepo.createGroup(name: 'مجموعة سيتم مسحها بالكامل', monthlyFeeCents: 25000, dueDay: 5);
      final sId1 = await studentRepo.createStudent(name: 'طالب أ', groupId: gId);
      final sId2 = await studentRepo.createStudent(name: 'طالب ب', groupId: gId);

      await paymentRepo.generateMonthlyRecords(9, 2026);
      final payments = await paymentRepo.getMonthlyPayments(9, 2026);
      expect(payments.where((p) => p.groupId == gId).length, 2);

      // Normal delete should throw because students and payments exist
      expect(
        () async => await groupRepo.deleteGroup(gId),
        throwsA(isA<Exception>()),
      );

      // Force delete should succeed
      await groupRepo.deleteGroup(gId, force: true);

      final group = await groupRepo.getGroupById(gId);
      expect(group, isNull);

      final student1 = await studentRepo.getStudentById(sId1);
      final student2 = await studentRepo.getStudentById(sId2);
      expect(student1, isNull);
      expect(student2, isNull);

      final paymentsAfter = await paymentRepo.getMonthlyPayments(9, 2026);
      expect(paymentsAfter.where((p) => p.groupId == gId).isEmpty, isTrue);
    });
  });
}
