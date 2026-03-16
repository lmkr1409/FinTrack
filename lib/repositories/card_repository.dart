import '../models/card.dart';
import 'base_repository.dart';

class CardRepository extends BaseRepository<Card> {
  @override
  String get tableName => 'cards';

  @override
  String get primaryKey => 'card_id';

  @override
  Card fromMap(Map<String, dynamic> map) => Card.fromMap(map);

  Future<List<Card>> getAllSorted() =>
      getAll(orderBy: 'priority ASC, card_name ASC');

  Future<List<Card>> getByAccountId(int accountId) =>
      query(where: 'account_id = ?', whereArgs: [accountId]);

  Future<int> insertCard(Card card) => insert(card.toMap());

  Future<int> updateCard(Card card) => update(card.id!, card.toMap());

  Future<int> deleteCard(int id) => delete(id);
}
