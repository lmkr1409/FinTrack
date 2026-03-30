import 'base_repository.dart';
import '../models/transaction_rule.dart';

class TransactionRuleRepository extends BaseRepository<TransactionRule> {
  @override
  String get tableName => 'transaction_rule';

  @override
  String get primaryKey => 'rule_id';

  @override
  TransactionRule fromMap(Map<String, dynamic> map) => TransactionRule.fromMap(map);

  Future<List<TransactionRule>> getByType(String type) async {
    return await query(where: 'rule_type = ?', whereArgs: [type]);
  }

  Future<List<TransactionRule>> getAllSorted() async {
    return await getAll(orderBy: 'rule_id DESC');
  }

  /// Returns the pattern (keyword) of the first rule matching [type] and [foreignKeyId].
  /// [foreignKeyColumn] should be one of: 'payment_method_id', 'account_id', 'card_id'.
  Future<String?> getPatternByTypeAndId(String type, String foreignKeyColumn, int foreignKeyId) async {
    final list = await query(
      where: 'rule_type = ? AND $foreignKeyColumn = ?',
      whereArgs: [type, foreignKeyId],
      limit: 1,
    );
    if (list.isNotEmpty) return list.first.pattern;
    return null;
  }

  /// Returns the pattern of the first TRANSACTION_TYPE rule that maps to [mappedType].
  Future<String?> getTransactionTypePattern(String mappedType) async {
    final list = await query(
      where: 'rule_type = ? AND mapped_type = ?',
      whereArgs: ['TRANSACTION_TYPE', mappedType],
      limit: 1,
    );
    if (list.isNotEmpty) return list.first.pattern;
    return null;
  }
}
