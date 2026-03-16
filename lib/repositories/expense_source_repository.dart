import '../models/expense_source.dart';
import 'base_repository.dart';

class ExpenseSourceRepository extends BaseRepository<ExpenseSource> {
  @override
  String get tableName => 'expense_source';

  @override
  String get primaryKey => 'expense_source_id';

  @override
  ExpenseSource fromMap(Map<String, dynamic> map) =>
      ExpenseSource.fromMap(map);

  Future<List<ExpenseSource>> getAllSorted() =>
      getAll(orderBy: 'priority ASC, expense_source_name ASC');

  Future<int> insertExpenseSource(ExpenseSource source) =>
      insert(source.toMap());

  Future<int> updateExpenseSource(ExpenseSource source) =>
      update(source.id!, source.toMap());

  Future<int> deleteExpenseSource(int id) => delete(id);
}
