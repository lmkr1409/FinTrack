import '../models/expense_purpose.dart';
import 'base_repository.dart';

class ExpensePurposeRepository extends BaseRepository<ExpensePurpose> {
  @override
  String get tableName => 'expense_purpose';

  @override
  String get primaryKey => 'purpose_id';

  @override
  ExpensePurpose fromMap(Map<String, dynamic> map) =>
      ExpensePurpose.fromMap(map);

  Future<List<ExpensePurpose>> getAllSorted() =>
      getAll(orderBy: 'priority ASC, expense_for ASC');

  Future<int> insertExpensePurpose(ExpensePurpose purpose) =>
      insert(purpose.toMap());

  Future<int> updateExpensePurpose(ExpensePurpose purpose) =>
      update(purpose.id!, purpose.toMap());

  Future<int> deleteExpensePurpose(int id) => delete(id);
}
