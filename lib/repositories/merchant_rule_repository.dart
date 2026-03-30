import 'base_repository.dart';
import '../models/merchant_rule.dart';

class MerchantRuleRepository extends BaseRepository<MerchantRule> {
  @override
  String get tableName => 'merchant_rule';

  @override
  String get primaryKey => 'rule_id';

  @override
  MerchantRule fromMap(Map<String, dynamic> map) => MerchantRule.fromMap(map);

  Future<List<MerchantRule>> getAllSorted() async {
    return await getAll(orderBy: 'rule_id DESC');
  }

  Future<MerchantRule?> getByMerchantId(int merchantId) async {
    final list = await query(
      where: 'merchant_id = ?',
      whereArgs: [merchantId],
    );
    if (list.isNotEmpty) return list.first;
    return null;
  }
}
