import 'package:sqflite/sqflite.dart';
import '../core/database/database_service.dart';

class GeneralSettingsRepository {
  final _dbService = DatabaseService();

  Future<void> setSetting(String key, String value) async {
    final db = await _dbService.database;
    await db.insert('general_settings', {
      'setting_key': key,
      'setting_value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await _dbService.database;
    final maps = await db.query('general_settings', 
      where: 'setting_key = ?', 
      whereArgs: [key]);
    if (maps.isEmpty) return null;
    return maps.first['setting_value'] as String;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await _dbService.database;
    final maps = await db.query('general_settings');
    return {
      for (var m in maps) m['setting_key'] as String: m['setting_value'] as String
    };
  }
}
