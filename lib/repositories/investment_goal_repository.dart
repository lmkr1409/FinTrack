import '../models/investment_goal.dart';
import 'base_repository.dart';

class InvestmentGoalRepository extends BaseRepository<InvestmentGoal> {
  @override
  String get tableName => 'investment_goal';

  @override
  String get primaryKey => 'goal_id';

  @override
  InvestmentGoal fromMap(Map<String, dynamic> map) => InvestmentGoal.fromMap(map);

  Future<List<InvestmentGoal>> getAllGoalsWithCategory() async {
    final database = await db;
    final List<Map<String, Object?>> maps = await database.rawQuery('''
      SELECT g.*, c.category_name, c.icon, c.icon_color
      FROM investment_goal g
      JOIN category c ON g.category_id = c.category_id
      ORDER BY g.created_time DESC
    ''');
    return maps.map((map) => fromMap(map)).toList();
  }

  Future<int> insertGoal(InvestmentGoal goal) => insert(goal.toMap());

  Future<int> updateGoal(InvestmentGoal goal) => update(goal.id!, goal.toMap());

  Future<int> deleteGoal(int id) => delete(id);
}
