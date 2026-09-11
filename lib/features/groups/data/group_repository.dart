import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/group_model.dart';

class GroupRepository {
  final DatabaseHelper _dbHelper;
  GroupRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<GroupModel>> getAllGroups({bool activeOnly = false}) async {
    final db = await _dbHelper.database;
    String sql = '''
      SELECT 
        g.*,
        COUNT(s.id) as student_count
      FROM groups g
      LEFT JOIN students s ON s.group_id = g.id AND s.status = 'active'
    ''';
    if (activeOnly) {
      sql += " WHERE g.status = 'active'";
    }
    sql += ' GROUP BY g.id ORDER BY g.name ASC';

    final rows = await db.rawQuery(sql);
    return rows.map((r) => GroupModel.fromMap(r)).toList();
  }

  Future<GroupModel?> getGroupById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT 
        g.*,
        COUNT(s.id) as student_count
      FROM groups g
      LEFT JOIN students s ON s.group_id = g.id AND s.status = 'active'
      WHERE g.id = ?
      GROUP BY g.id
    ''', [id]);

    if (rows.isEmpty) return null;
    return GroupModel.fromMap(rows.first);
  }

  Future<int> createGroup({
    required String name,
    required int monthlyFeeCents,
    required int dueDay,
    String? description,
    String status = 'active',
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('groups', {
      'name': name.trim(),
      'monthly_fee_cents': monthlyFeeCents,
      'due_day': dueDay,
      'description': description?.trim(),
      'status': status,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateGroup(GroupModel group) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'groups',
      {
        'name': group.name.trim(),
        'monthly_fee_cents': group.monthlyFeeCents,
        'due_day': group.dueDay,
        'description': group.description?.trim(),
        'status': group.status,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> toggleGroupStatus(int id, bool active) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'groups',
      {
        'status': active ? 'active' : 'inactive',
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<({int studentCount, int paymentCount})> getGroupDependenciesCount(int id) async {
    final db = await _dbHelper.database;
    final countRows = await db.rawQuery('SELECT COUNT(*) as count FROM students WHERE group_id = ?', [id]);
    final studentCount = Sqflite.firstIntValue(countRows) ?? 0;

    final paymentRows = await db.rawQuery('SELECT COUNT(*) as count FROM monthly_payments WHERE group_id = ?', [id]);
    final paymentCount = Sqflite.firstIntValue(paymentRows) ?? 0;

    return (studentCount: studentCount, paymentCount: paymentCount);
  }

  Future<void> deleteGroup(int id, {bool force = false}) async {
    final db = await _dbHelper.database;
    final counts = await getGroupDependenciesCount(id);

    if ((counts.studentCount > 0 || counts.paymentCount > 0) && !force) {
      final List<String> reasons = [];
      if (counts.studentCount > 0) reasons.add('${counts.studentCount} طالب');
      if (counts.paymentCount > 0) reasons.add('${counts.paymentCount} سجل اشتراك');
      throw Exception('لا يمكن حذف المجموعة لوجود بيانات مرتبطة بها (${reasons.join(' و ')}). يمكنك استخدام الحذف الإجباري لمسحها مع كافة طلابها وسجلاتها.');
    }

    if (force) {
      await db.transaction((txn) async {
        // Find all student IDs in this group
        final studentRows = await txn.rawQuery('SELECT id FROM students WHERE group_id = ?', [id]);
        final studentIds = studentRows.map((r) => r['id'] as int).toList();

        // Delete all monthly payments tied to this group
        await txn.delete('monthly_payments', where: 'group_id = ?', whereArgs: [id]);
        if (studentIds.isNotEmpty) {
          final placeholders = List.filled(studentIds.length, '?').join(',');
          await txn.delete('monthly_payments', where: 'student_id IN ($placeholders)', whereArgs: studentIds);
        }

        // Delete notification logs
        await txn.delete('notification_logs', where: 'group_id = ?', whereArgs: [id]);

        // Delete students in this group
        await txn.delete('students', where: 'group_id = ?', whereArgs: [id]);

        // Delete group
        await txn.delete('groups', where: 'id = ?', whereArgs: [id]);
      });
    } else {
      await db.delete('groups', where: 'id = ?', whereArgs: [id]);
    }
  }
}
