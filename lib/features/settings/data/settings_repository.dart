import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  final DatabaseHelper _dbHelper;
  SettingsRepository({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<AppSettings> getSettings() async {
    final db = await _dbHelper.database;
    final rows = await db.query('settings');
    final map = <String, String>{};
    for (final r in rows) {
      map[r['key'] as String] = r['value'] as String;
    }
    return AppSettings.fromMap(map);
  }

  Future<void> updateSettings(AppSettings settings) async {
    final db = await _dbHelper.database;
    final map = settings.toMap();
    final batch = db.batch();
    for (final entry in map.entries) {
      batch.insert(
        'settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Exports database file to a shareable path and returns the exported file path
  Future<String> exportDatabaseBackup() async {
    final tempDir = await getTemporaryDirectory();
    final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final backupPath = p.join(tempDir.path, 'tollab_backup_$dateStr.db');
    return await _dbHelper.backupDatabase(backupPath);
  }

  /// Restores database from a selected file
  Future<bool> restoreDatabase(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) return false;
    return await _dbHelper.restoreDatabase(sourcePath);
  }
}
