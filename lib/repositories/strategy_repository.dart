import 'package:sqflite/sqflite.dart';
import '../core/database/database_service.dart';
import '../models/strategy_models.dart';

class StrategyRepository {
  final _dbService = DatabaseService();

  Future<List<BudgetFramework>> getAllFrameworks() async {
    final db = await _dbService.database;
    final maps = await db.query('budget_framework');
    return maps.map((m) => BudgetFramework.fromMap(m)).toList();
  }

  Future<BudgetFramework?> getActiveFramework() async {
    final db = await _dbService.database;
    final maps = await db.query('budget_framework', where: 'is_active = 1', limit: 1);
    if (maps.isEmpty) return null;
    return BudgetFramework.fromMap(maps.first);
  }

  Future<void> setActiveFramework(int frameworkId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.update('budget_framework', {'is_active': 0});
      await txn.update('budget_framework', {'is_active': 1}, where: 'framework_id = ?', whereArgs: [frameworkId]);
    });
  }

  Future<List<BudgetBucket>> getBucketsForFramework(int frameworkId) async {
    final db = await _dbService.database;
    final maps = await db.query('budget_bucket', where: 'framework_id = ?', whereArgs: [frameworkId]);
    return maps.map((m) => BudgetBucket.fromMap(m)).toList();
  }

  Future<Map<int, int>> getCategoryMappings(int frameworkId) async {
    final db = await _dbService.database;
    final maps = await db.query('category_bucket_mapping', where: 'framework_id = ?', whereArgs: [frameworkId]);
    final result = <int, int>{};
    for (final m in maps) {
      result[m['category_id'] as int] = m['bucket_id'] as int;
    }
    return result;
  }

  Future<void> updateCategoryMapping(int categoryId, int frameworkId, int bucketId) async {
    final db = await _dbService.database;
    await db.insert('category_bucket_mapping', {
      'category_id': categoryId,
      'framework_id': frameworkId,
      'bucket_id': bucketId,
    }, conflictAlgorithm: (ConflictAlgorithm.replace));
  }

  Future<Map<String, dynamic>?> getStrategySettings(int month, int year) async {
    final db = await _dbService.database;
    final maps = await db.query('strategy_settings', where: 'month = ? AND year = ?', whereArgs: [month, year]);
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> updateSalaryOverride(int month, int year, double amount) async {
    final db = await _dbService.database;
    await db.insert('strategy_settings', {
      'month': month,
      'year': year,
      'salary_override': amount,
    }, conflictAlgorithm: (ConflictAlgorithm.replace));
  }
}
