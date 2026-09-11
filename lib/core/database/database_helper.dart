import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Allows setting a custom Database instance (e.g. for testing with ffi)
  void setDatabaseForTesting(Database db) {
    _database = db;
  }

  Future<String> getDatabasePath() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return p.join(docsDir.path, 'tollab.db');
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasePath();
    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.transaction((txn) async {
      // 1. Groups table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS groups (
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

      // 2. Students table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS students (
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

      // 3. Monthly Periods table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS monthly_periods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
          year INTEGER NOT NULL CHECK (year >= 2000 AND year <= 2100),
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(month, year)
        );
      ''');

      // 4. Monthly Payments table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS monthly_payments (
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

      // 5. Notification logs table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS notification_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          monthly_period_id INTEGER NOT NULL REFERENCES monthly_periods(id) ON DELETE CASCADE,
          group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
          notification_type TEXT NOT NULL CHECK (notification_type IN ('one_day_before', 'due_day', 'overdue')),
          sent_at TEXT NOT NULL,
          UNIQUE(monthly_period_id, group_id, notification_type)
        );
      ''');

      // 6. Settings table
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        );
      ''');

      // Indexes
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_students_group ON students(group_id);');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_students_status ON students(status);');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_students_code ON students(student_code);');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_payments_period ON monthly_payments(monthly_period_id);');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_payments_student ON monthly_payments(student_id);');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_payments_group ON monthly_payments(group_id);');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_payments_status ON monthly_payments(status);');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_payments_due_date ON monthly_payments(due_date);');

      // Initial settings seeds
      final defaultSettings = {
        'enable_reminders': 'true',
        'notify_one_day_before': 'true',
        'notify_due_day': 'true',
        'notify_overdue': 'true',
        'overdue_frequency': 'once',
      };

      for (final entry in defaultSettings.entries) {
        await txn.insert(
          'settings',
          {'key': entry.key, 'value': entry.value},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  /// Close and reset the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Backup database to a destination file path
  Future<String> backupDatabase(String destinationPath) async {
    final db = await database;
    await db.close();
    _database = null;

    final currentPath = await getDatabasePath();
    final sourceFile = File(currentPath);
    final backupFile = await sourceFile.copy(destinationPath);

    // Reopen database
    _database = await _initDatabase();
    return backupFile.path;
  }

  /// Restore database from a source file path
  Future<bool> restoreDatabase(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) return false;

    final db = await database;
    await db.close();
    _database = null;

    final currentPath = await getDatabasePath();
    await sourceFile.copy(currentPath);

    // Reopen database
    _database = await _initDatabase();
    return true;
  }
}
