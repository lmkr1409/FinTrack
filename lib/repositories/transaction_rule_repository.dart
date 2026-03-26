import 'package:sqflite/sqflite.dart';
import '../models/transaction_rule.dart';
import '../core/database/database_service.dart';

class TransactionRuleRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<int> insert(Map<String, dynamic> row) async {
    final db = await _databaseService.database;
    return await db.insert('transaction_rule', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TransactionRule>> getAll() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('transaction_rule');
    return maps.map((e) => TransactionRule.fromMap(e)).toList();
  }

  Future<List<TransactionRule>> getByType(String type) async {
    final db = await _databaseService.database;
    final maps = await db.query('transaction_rule', where: 'rule_type = ?', whereArgs: [type]);
    return maps.map((e) => TransactionRule.fromMap(e)).toList();
  }

  Future<List<TransactionRule>> getAllSorted() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query('transaction_rule', orderBy: 'rule_id DESC');
    return maps.map((e) => TransactionRule.fromMap(e)).toList();
  }

  Future<TransactionRule?> getById(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_rule',
      where: 'rule_id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return TransactionRule.fromMap(maps.first);
    return null;
  }

  Future<int> update(int id, Map<String, dynamic> row) async {
    final db = await _databaseService.database;
    return await db.update(
      'transaction_rule',
      row,
      where: 'rule_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'transaction_rule',
      where: 'rule_id = ?',
      whereArgs: [id],
    );
  }

  /// Returns the pattern (keyword) of the first rule matching [type] and [foreignKeyId].
  /// [foreignKeyColumn] should be one of: 'payment_method_id', 'account_id', 'card_id'.
  Future<String?> getPatternByTypeAndId(String type, String foreignKeyColumn, int foreignKeyId) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'transaction_rule',
      columns: ['pattern'],
      where: 'rule_type = ? AND $foreignKeyColumn = ?',
      whereArgs: [type, foreignKeyId],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first['pattern'] as String?;
    return null;
  }

  /// Returns the pattern of the first TRANSACTION_TYPE rule that maps to [mappedType].
  Future<String?> getTransactionTypePattern(String mappedType) async {
    final db = await _databaseService.database;
    final maps = await db.query(
      'transaction_rule',
      columns: ['pattern'],
      where: 'rule_type = ? AND mapped_type = ?',
      whereArgs: ['TRANSACTION_TYPE', mappedType],
      limit: 1,
    );
    if (maps.isNotEmpty) return maps.first['pattern'] as String?;
    return null;
  }
}
