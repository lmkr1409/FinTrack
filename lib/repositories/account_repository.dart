import '../models/account.dart';
import 'base_repository.dart';

class AccountRepository extends BaseRepository<Account> {
  @override
  String get tableName => 'account';

  @override
  String get primaryKey => 'account_id';

  @override
  Account fromMap(Map<String, dynamic> map) => Account.fromMap(map);

  Future<List<Account>> getAllSorted() =>
      getAll(orderBy: 'priority ASC, account_name ASC');

  Future<int> insertAccount(Account account) => insert(account.toMap());

  Future<int> updateAccount(Account account) =>
      update(account.id!, account.toMap());

  Future<int> deleteAccount(int id) => delete(id);
}
