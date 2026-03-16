import '../models/payment_method.dart';
import 'base_repository.dart';

class PaymentMethodRepository extends BaseRepository<PaymentMethod> {
  @override
  String get tableName => 'payment_method';

  @override
  String get primaryKey => 'payment_method_id';

  @override
  PaymentMethod fromMap(Map<String, dynamic> map) =>
      PaymentMethod.fromMap(map);

  Future<List<PaymentMethod>> getAllSorted() =>
      getAll(orderBy: 'priority ASC, payment_method_name ASC');

  Future<int> insertPaymentMethod(PaymentMethod method) =>
      insert(method.toMap());

  Future<int> updatePaymentMethod(PaymentMethod method) =>
      update(method.id!, method.toMap());

  Future<int> deletePaymentMethod(int id) => delete(id);
}
