import '../models/budget.dart';
import 'base_repository.dart';

class BudgetRepository extends BaseRepository<Budget> {
  @override
  String get tableName => 'budget';

  @override
  String get primaryKey => 'budget_id';

  @override
  Budget fromMap(Map<String, dynamic> map) => Budget.fromMap(map);

  Future<List<Budget>> getAllSorted() =>
      getAll(orderBy: 'year DESC, month DESC');

  Future<List<Budget>> getByMonthYear(int month, int year) => query(
        where: 'month = ? AND year = ?',
        whereArgs: [month, year],
      );

  Future<List<Budget>> getAnnualBudgets(int year) => query(
        where: "budget_frequency = 'ANNUAL' AND year = ?",
        whereArgs: [year],
      );

  Future<int> insertBudget(Budget budget) => insert(budget.toMap());

  Future<int> updateBudget(Budget budget) =>
      update(budget.id!, budget.toMap());

  Future<int> deleteBudget(int id) => delete(id);
}
