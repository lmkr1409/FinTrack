import '../models/budget_total.dart';
import 'base_repository.dart';

class BudgetTotalRepository extends BaseRepository<BudgetTotal> {
  @override
  String get tableName => 'budget_total';

  @override
  String get primaryKey => 'total_id';

  @override
  BudgetTotal fromMap(Map<String, dynamic> map) => BudgetTotal.fromMap(map);

  Future<BudgetTotal?> getMonthlyTotal(int month, int year) async {
    final list = await query(
      where: 'budget_frequency = ? AND month = ? AND year = ?',
      whereArgs: ['MONTHLY', month, year],
    );
    return list.isNotEmpty ? list.first : null;
  }

  Future<BudgetTotal?> getAnnualTotal(int year) async {
    final list = await query(
      where: 'budget_frequency = ? AND year = ?',
      whereArgs: ['ANNUAL', year],
    );
    return list.isNotEmpty ? list.first : null;
  }

  Future<int> insertTotal(BudgetTotal total) => insert(total.toMap());

  Future<int> updateTotal(BudgetTotal total) =>
      update(total.id!, total.toMap());

  Future<int> deleteTotal(int id) => delete(id);
}
