import 'package:sqflite/sqflite.dart';
import '../models/merchant_rule.dart';
import '../core/database/database_service.dart';

class MerchantRuleRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await _databaseService.database;
    return await db.insert('merchant_rule', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MerchantRule>> getAll() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('merchant_rule');
    return maps.map((e) => MerchantRule.fromMap(e)).toList();
  }

  Future<List<MerchantRule>> getAllSorted() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('merchant_rule', orderBy: 'rule_id DESC');
    return maps.map((e) => MerchantRule.fromMap(e)).toList();
  }

  Future<MerchantRule?> getById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'merchant_rule',
      where: 'rule_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return MerchantRule.fromMap(maps.first);
    return null;
  }

  Future<int> update(int id, Map<String, dynamic> row) async {
    final db = await _databaseService.database;
    return await db.update(
      'merchant_rule',
      row,
      where: 'rule_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'merchant_rule',
      where: 'rule_id = ?',
      whereArgs: [id],
    );
  }
}
