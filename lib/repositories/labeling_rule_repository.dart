import '../models/labeling_rule.dart';
import 'base_repository.dart';

class LabelingRuleRepository extends BaseRepository<LabelingRule> {
  @override
  String get tableName => 'labeling_rule';

  @override
  String get primaryKey => 'rule_id';

  @override
  LabelingRule fromMap(Map<String, dynamic> map) {
    return LabelingRule.fromMap(map);
  }

  // toMap removed from here because BaseRepository doesn't define it.
  
  Future<List<LabelingRule>> getAllSorted() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(tableName, orderBy: 'keyword ASC');
    return maps.map((map) => fromMap(map)).toList();
  }
}
