import '../models/transaction.dart';
import 'base_repository.dart';

class TransactionRepository extends BaseRepository<Transaction> {
  @override
  String get tableName => '"transaction"';

  @override
  String get primaryKey => 'transaction_id';

  @override
  Transaction fromMap(Map<String, dynamic> map) => Transaction.fromMap(map);

  /// Get all transactions sorted by date descending.
  Future<List<Transaction>> getAllSorted() =>
      getAll(orderBy: 'transaction_date DESC, created_time DESC');

  /// Get transactions within a date range.
  Future<List<Transaction>> getByDateRange(String startDate, String endDate) =>
      query(
        where: 'transaction_date >= ? AND transaction_date <= ?',
        whereArgs: [startDate, endDate],
        orderBy: 'transaction_date DESC',
      );

  /// Get transactions filtered by multiple optional criteria.
  Future<List<Transaction>> getFiltered({
    String? startDate,
    String? endDate,
    String? transactionType,
    int? categoryId,
    int? subcategoryId,
    int? accountId,
    int? cardId,
    int? merchantId,
    int? paymentMethodId,
    int? purposeId,
    int? expenseSourceId,
    bool? labeled,
    bool? isAutoLabeled,
    String? nature,
    int? month,
    int? year,
    String? orderBy,
    int? limit,
    int? goalId,
  }) async {
    final conditions = <String>[];
    final args = <Object?>[];

    if (startDate != null) {
      conditions.add('transaction_date >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      conditions.add('transaction_date <= ?');
      args.add(endDate);
    }
    if (transactionType != null) {
      conditions.add('transaction_type = ?');
      args.add(transactionType);
    }
    if (nature != null) {
      conditions.add('nature = ?');
      args.add(nature);
    }
    if (categoryId != null) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }
    if (subcategoryId != null) {
      conditions.add('subcategory_id = ?');
      args.add(subcategoryId);
    }
    if (accountId != null) {
      conditions.add('account_id = ?');
      args.add(accountId);
    }
    if (cardId != null) {
      conditions.add('card_id = ?');
      args.add(cardId);
    }
    if (merchantId != null) {
      conditions.add('merchant_id = ?');
      args.add(merchantId);
    }
    if (paymentMethodId != null) {
      conditions.add('payment_method_id = ?');
      args.add(paymentMethodId);
    }
    if (purposeId != null) {
      conditions.add('purpose_id = ?');
      args.add(purposeId);
    }
    if (expenseSourceId != null) {
      conditions.add('expense_source_id = ?');
      args.add(expenseSourceId);
    }
    if (labeled != null) {
      conditions.add('labeled = ?');
      args.add(labeled ? 1 : 0);
    }
    if (isAutoLabeled != null) {
      conditions.add('is_auto_labeled = ?');
      args.add(isAutoLabeled ? 1 : 0);
    }
    if (month != null) {
      conditions.add("CAST(substr(transaction_date, 6, 2) AS INTEGER) = ?");
      args.add(month);
    }
    if (year != null) {
      conditions.add("CAST(substr(transaction_date, 1, 4) AS INTEGER) = ?");
      args.add(year);
    }
    if (goalId != null) {
      conditions.add('goal_id = ?');
      args.add(goalId);
    }

    return query(
      where: conditions.isNotEmpty ? conditions.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: orderBy ?? 'transaction_date DESC, created_time DESC',
      limit: limit,
    );
  }

  Future<int> insertTransaction(Transaction transaction) =>
      insert(transaction.toMap());

  Future<int> updateTransaction(Transaction transaction) =>
      update(transaction.id!, transaction.toMap());

  Future<int> deleteTransaction(int id) => delete(id);

  /// Get total amount by transaction type within a date range.
  Future<double> getTotalByType(
      String type, String startDate, String endDate) async {
    const String query = 'SELECT COALESCE(SUM(amount), 0) as total FROM "transaction" '
        'WHERE nature = ? AND transaction_date >= ? AND transaction_date <= ?';
    final result = await rawQuery(query, [type, startDate, endDate]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Bulk-insert a list of transactions using a database batch.
  Future<void> insertBatch(List<Transaction> transactions) async {
    final database = await db;
    final batch = database.batch();
    for (final txn in transactions) {
      batch.insert('"transaction"', txn.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// Bulk-update a list of transactions using a database batch.
  Future<void> updateBatch(List<Transaction> transactions) async {
    final database = await db;
    final batch = database.batch();
    for (final txn in transactions) {
      batch.update(
        '"transaction"',
        txn.toMap(),
        where: 'transaction_id = ?',
        whereArgs: [txn.id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Delete transactions by date range and optionally account/card.
  Future<int> deleteByDateRangeAndAccount({
    required String startDate,
    required String endDate,
    int? accountId,
    int? cardId,
  }) async {
    final conditions = <String>['transaction_date >= ?', 'transaction_date <= ?'];
    final args = <Object>[startDate, endDate];
    if (accountId != null) {
      conditions.add('account_id = ?');
      args.add(accountId);
    }
    if (cardId != null) {
      conditions.add('card_id = ?');
      args.add(cardId);
    }
    final database = await db;
    return database.delete('"transaction"', where: conditions.join(' AND '), whereArgs: args);
  }

  /// Delete all transactions for a specific card.
  Future<int> deleteByCardId(int cardId) async {
    final database = await db;
    return database.delete('"transaction"', where: 'card_id = ?', whereArgs: [cardId]);
  }

  /// Delete all transactions for a specific account.
  Future<int> deleteByAccountId(int accountId) async {
    final database = await db;
    return database.delete('"transaction"', where: 'account_id = ?', whereArgs: [accountId]);
  }

  /// Delete all transactions for a specific category.
  Future<int> deleteByCategoryId(int categoryId) async {
    final database = await db;
    return database.delete('"transaction"', where: 'category_id = ?', whereArgs: [categoryId]);
  }

  /// Delete ALL transactions in the table.
  Future<int> deleteAll() async {
    final database = await db;
    return database.delete('"transaction"');
  }

  /// Apply label fields to a single transaction and mark it as labeled.
  Future<void> labelTransaction(int id, Map<String, dynamic> fields) async {
    final database = await db;
    await database.update(
      '"transaction"',
      {...fields, 'labeled': 1, 'is_auto_labeled': 0},
      where: 'transaction_id = ?',
      whereArgs: [id],
    );
  }

  /// Apply label fields to ALL unlabeled transactions with an exact matching description.
  Future<int> labelByDescription(String description, Map<String, dynamic> fields) async {
    final database = await db;
    return database.update(
      '"transaction"',
      {...fields, 'labeled': 1, 'is_auto_labeled': 0},
      where: 'description = ? AND labeled = 0',
      whereArgs: [description],
    );
  }

  /// Delete transactions within a date range.
  Future<int> deleteByDateRange(String startDate, String endDate) async {
    final database = await db;
    return database.delete(
      '"transaction"',
      where: 'transaction_date >= ? AND transaction_date <= ?',
      whereArgs: [startDate, endDate],
    );
  }

  /// Delete transactions from a given date onwards.
  Future<int> deleteFromDate(String startDate) async {
    final database = await db;
    return database.delete(
      '"transaction"',
      where: 'transaction_date >= ?',
      whereArgs: [startDate],
    );
  }

  /// Returns a map of category_id → total spent amount (DEBIT transactions).
  /// For monthly period, filters by month + year. For annual, filters by year only.
  Future<Map<int, double>> spentByCategoryForPeriod({
    int? month,
    required int year,
  }) async {
    final conditions = <String>[
      "nature = 'EXPENSE'",
      "CAST(substr(transaction_date, 1, 4) AS INTEGER) = ?",
    ];
    final args = <Object>[year];

    if (month != null) {
      conditions.add("CAST(substr(transaction_date, 6, 2) AS INTEGER) = ?");
      args.add(month);
    }

    final rows = await rawQuery(
      'SELECT category_id, COALESCE(SUM(amount), 0) as total '
      'FROM "transaction" '
      'WHERE ${conditions.join(' AND ')} AND category_id IS NOT NULL '
      'GROUP BY category_id',
      args,
    );

    return {
      for (final r in rows)
        (r['category_id'] as int): (r['total'] as num).toDouble(),
    };
  }
}
