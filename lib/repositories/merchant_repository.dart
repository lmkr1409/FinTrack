import '../models/merchant.dart';
import 'base_repository.dart';

class MerchantRepository extends BaseRepository<Merchant> {
  @override
  String get tableName => 'merchant';

  @override
  String get primaryKey => 'merchant_id';

  @override
  Merchant fromMap(Map<String, dynamic> map) => Merchant.fromMap(map);

  Future<List<Merchant>> getAllSorted() =>
      getAll(orderBy: 'merchant_name ASC');

  Future<int> insertMerchant(Merchant merchant) => insert(merchant.toMap());

  Future<int> updateMerchant(Merchant merchant) =>
      update(merchant.id!, merchant.toMap());

  Future<int> deleteMerchant(int id) => delete(id);
}
