import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/student_model.dart';

class StudentRepository {
  final DatabaseHelper _dbHelper;
  StudentRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Generates human-readable unique student code: STD-000001, STD-000002, etc.
  Future<String> generateNextStudentCode() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT student_code FROM students 
      ORDER BY id DESC LIMIT 1
    ''');

    int nextNum = 1;
    if (rows.isNotEmpty && rows.first['student_code'] != null) {
      final lastCode = rows.first['student_code'] as String;
      final match = RegExp(r'STD-(\d+)').firstMatch(lastCode);
      if (match != null) {
        nextNum = int.parse(match.group(1)!) + 1;
      } else {
        final countRows = await db.rawQuery('SELECT COUNT(*) as count FROM students');
        nextNum = (Sqflite.firstIntValue(countRows) ?? 0) + 1;
      }
    }

    // Ensure uniqueness in case of deleted gaps
    while (true) {
      final code = 'STD-${nextNum.toString().padLeft(6, '0')}';
      final existing = await db.rawQuery('SELECT id FROM students WHERE student_code = ?', [code]);
      if (existing.isEmpty) {
        return code;
      }
      nextNum++;
    }
  }

  Future<List<StudentModel>> getAllStudents({
    String? query,
    int? groupId,
    String? status,
  }) async {
    final db = await _dbHelper.database;
    String sql = '''
      SELECT 
        s.id,
        s.student_code,
        s.name,
        s.phone,
        s.group_id,
        s.status,
        s.notes,
        s.created_at,
        s.updated_at,
        g.name AS group_name,
        g.monthly_fee_cents,
        g.due_day
      FROM students s
      JOIN groups g ON s.group_id = g.id
      WHERE 1=1
    ''';
    final List<dynamic> args = [];

    if (groupId != null && groupId > 0) {
      sql += ' AND s.group_id = ?';
      args.push(groupId);
    }

    if (status != null && status.isNotEmpty) {
      sql += ' AND s.status = ?';
      args.push(status);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      sql += ' AND (s.name LIKE ? OR s.student_code LIKE ? OR s.phone LIKE ?)';
      args.addAll([q, q, q]);
    }

    sql += ' ORDER BY s.id DESC';

    final rows = await db.rawQuery(sql, args);
    return rows.map((r) => StudentModel.fromMap(r)).toList();
  }

  Future<StudentModel?> getStudentById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT 
        s.id,
        s.student_code,
        s.name,
        s.phone,
        s.group_id,
        s.status,
        s.notes,
        s.created_at,
        s.updated_at,
        g.name AS group_name,
        g.monthly_fee_cents,
        g.due_day
      FROM students s
      JOIN groups g ON s.group_id = g.id
      WHERE s.id = ?
    ''', [id]);

    if (rows.isEmpty) return null;
    return StudentModel.fromMap(rows.first);
  }

  Future<int> createStudent({
    required String name,
    required int groupId,
    String? phone,
    String? notes,
    String status = 'active',
  }) async {
    final db = await _dbHelper.database;

    // Validate group exists
    final groupRows = await db.rawQuery('SELECT id FROM groups WHERE id = ?', [groupId]);
    if (groupRows.isEmpty) {
      throw Exception('المجموعة المحددة غير موجودة');
    }

    final studentCode = await generateNextStudentCode();
    final now = DateTime.now().toIso8601String();

    return await db.insert('students', {
      'student_code': studentCode,
      'name': name.trim(),
      'phone': phone?.trim(),
      'group_id': groupId,
      'status': status,
      'notes': notes?.trim(),
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'students',
      {
        'name': student.name.trim(),
        'phone': student.phone?.trim(),
        'group_id': student.groupId,
        'status': student.status,
        'notes': student.notes?.trim(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  /// Move student to another group. PRD: Historical monthly records remain unchanged.
  Future<void> moveStudentGroup(int studentId, int newGroupId) async {
    final db = await _dbHelper.database;

    // Verify new group exists
    final groupRows = await db.rawQuery('SELECT id FROM groups WHERE id = ?', [newGroupId]);
    if (groupRows.isEmpty) {
      throw Exception('المجموعة الجديدة غير موجودة');
    }

    final now = DateTime.now().toIso8601String();
    await db.update(
      'students',
      {
        'group_id': newGroupId,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }

  Future<void> toggleStudentStatus(int id, bool active) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'students',
      {
        'status': active ? 'active' : 'inactive',
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getStudentPaymentCount(int id) async {
    final db = await _dbHelper.database;
    final paymentRows = await db.rawQuery('SELECT COUNT(*) as count FROM monthly_payments WHERE student_id = ?', [id]);
    return Sqflite.firstIntValue(paymentRows) ?? 0;
  }

  Future<void> deleteStudent(int id, {bool force = false}) async {
    final db = await _dbHelper.database;
    final count = await getStudentPaymentCount(id);
    if (count > 0 && !force) {
      throw Exception('لا يمكن حذف الطالب لوجود سجلات اشتراكات سابقة مرتبطة به ($count سجل). يمكنك استخدام الحذف الإجباري لمسحه مع كافة سجلاته.');
    }

    if (force) {
      await db.transaction((txn) async {
        await txn.delete('monthly_payments', where: 'student_id = ?', whereArgs: [id]);
        await txn.delete('students', where: 'id = ?', whereArgs: [id]);
      });
    } else {
      await db.delete('students', where: 'id = ?', whereArgs: [id]);
    }
  }
}

extension on List {
  void push(dynamic item) => add(item);
}
