import '../core/database/database_service.dart';

/// Service providing analytics queries for dashboards, trends, and top-N reports.
class AnalyticsService {
  final DatabaseService _db = DatabaseService();

  // ─── Summary totals ─────────────────────────────────────

  Future<double> totalByType(String type, String start, String end) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) as total FROM "transaction" '
      'WHERE transaction_type=? AND transaction_date>=? AND transaction_date<=?',
      [type, start, end],
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  // ─── Top-N queries ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> topCategories(String start, String end, {int limit = 5}) async {
    final db = await _db.database;
    return db.rawQuery(
      'SELECT c.category_id, c.category_name, c.icon, c.icon_color, '
      'COALESCE(SUM(t.amount),0) as total '
      'FROM "transaction" t JOIN category c ON t.category_id=c.category_id '
      'WHERE t.transaction_type=\'DEBIT\' AND t.transaction_date>=? AND t.transaction_date<=? '
      'GROUP BY c.category_id ORDER BY total DESC LIMIT ?',
      [start, end, limit],
    );
  }

  Future<List<Map<String, dynamic>>> topMerchants(String start, String end, {int limit = 5}) async {
    final db = await _db.database;
    return db.rawQuery(
      'SELECT m.merchant_id, m.merchant_name, m.icon, m.icon_color, '
      'COALESCE(SUM(t.amount),0) as total '
      'FROM "transaction" t JOIN merchant m ON t.merchant_id=m.merchant_id '
      'WHERE t.transaction_type=\'DEBIT\' AND t.transaction_date>=? AND t.transaction_date<=? '
      'GROUP BY m.merchant_id ORDER BY total DESC LIMIT ?',
      [start, end, limit],
    );
  }

  Future<List<Map<String, dynamic>>> topAccounts(String start, String end, {int limit = 5}) async {
    final db = await _db.database;
    return db.rawQuery(
      'SELECT a.account_id, a.account_name, a.icon, a.icon_color, '
      'COALESCE(SUM(t.amount),0) as total '
      'FROM "transaction" t JOIN account a ON t.account_id=a.account_id '
      'WHERE t.transaction_type=\'DEBIT\' AND t.transaction_date>=? AND t.transaction_date<=? '
      'GROUP BY a.account_id ORDER BY total DESC LIMIT ?',
      [start, end, limit],
    );
  }

  Future<List<Map<String, dynamic>>> topPurposes(String start, String end, {int limit = 5}) async {
    final db = await _db.database;
    return db.rawQuery(
      'SELECT p.purpose_id, p.expense_for, p.icon, p.icon_color, '
      'COALESCE(SUM(t.amount),0) as total '
      'FROM "transaction" t JOIN expense_purpose p ON t.purpose_id=p.purpose_id '
      'WHERE t.transaction_type=\'DEBIT\' AND t.transaction_date>=? AND t.transaction_date<=? '
      'GROUP BY p.purpose_id ORDER BY total DESC LIMIT ?',
      [start, end, limit],
    );
  }

  // ─── Trends ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> expensePerDay(String start, String end) async {
    final db = await _db.database;
    return db.rawQuery(
      'SELECT transaction_date as period, COALESCE(SUM(amount),0) as total '
      'FROM "transaction" WHERE transaction_type=\'DEBIT\' '
      'AND transaction_date>=? AND transaction_date<=? '
      'GROUP BY transaction_date ORDER BY transaction_date',
      [start, end],
    );
  }

  Future<List<Map<String, dynamic>>> expensePerMonth(String start, String end) async {
    final db = await _db.database;
    return db.rawQuery(
      'SELECT substr(transaction_date,1,7) as period, COALESCE(SUM(amount),0) as total '
      'FROM "transaction" WHERE transaction_type=\'DEBIT\' '
      'AND transaction_date>=? AND transaction_date<=? '
      'GROUP BY period ORDER BY period',
      [start, end],
    );
  }

  Future<List<Map<String, dynamic>>> incomeVsExpenseLast12Months() async {
    final db = await _db.database;
    // Get the start of the current month, then go back 11 months so we get 12 distinct months inclusive.
    // e.g. if today is 2026-03-XX, we want >= 2025-04-01
    final now = DateTime.now();
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final twelveMonthsAgo = DateTime(startOfCurrentMonth.year, startOfCurrentMonth.month - 11, 1);
    
    // Format YYYY-MM-DD
    final startStr = '${twelveMonthsAgo.year}-${twelveMonthsAgo.month.toString().padLeft(2, '0')}-01';

    return db.rawQuery('''
      SELECT 
        substr(transaction_date, 1, 7) as period, 
        COALESCE(SUM(CASE WHEN transaction_type = 'CREDIT' THEN amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN transaction_type = 'DEBIT' THEN amount ELSE 0 END), 0) as expense
      FROM "transaction" 
      WHERE transaction_date >= ?
      GROUP BY period 
      ORDER BY period ASC
    ''', [startStr]);
  }

  // ─── Budget vs Actual ───────────────────────────────────

  Future<List<Map<String, dynamic>>> budgetVsActual(int month, int year) async {
    final db = await _db.database;
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final end = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    return db.rawQuery(
      'SELECT b.budget_id, b.budget_amount, c.category_id, c.category_name, c.icon, c.icon_color, '
      'COALESCE(('
      '  SELECT SUM(t.amount) FROM "transaction" t '
      '  WHERE t.category_id=b.category_id AND t.transaction_type=\'DEBIT\' '
      '  AND t.transaction_date>=? AND t.transaction_date<? '
      '),0) as actual '
      'FROM budget b LEFT JOIN category c ON b.category_id=c.category_id '
      'WHERE b.budget_frequency=\'MONTHLY\' AND b.month=? AND b.year=?',
      [start, end, month, year],
    );
  }

  // ─── Expense Breakdowns (Pie Charts) ────────────────────

  Future<List<Map<String, dynamic>>> expensesByCategory(String start, String end) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT 
        COALESCE(c.category_name, 'Uncategorized') as name,
        COALESCE(c.icon_color, '#9E9E9E') as color,
        SUM(t.amount) as value
      FROM "transaction" t
      LEFT JOIN category c ON t.category_id = c.category_id
      WHERE t.transaction_type = 'DEBIT' AND t.transaction_date >= ? AND t.transaction_date <= ?
      GROUP BY c.category_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end]);
  }

  Future<List<Map<String, dynamic>>> expensesByPaymentMethod(String start, String end) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT 
        COALESCE(a.account_name, 'Unknown Account') as name,
        COALESCE(a.icon_color, '#607D8B') as color,
        SUM(t.amount) as value
      FROM "transaction" t
      LEFT JOIN account a ON t.account_id = a.account_id
      WHERE t.transaction_type = 'DEBIT' AND t.transaction_date >= ? AND t.transaction_date <= ?
      GROUP BY a.account_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end]);
  }

  Future<List<Map<String, dynamic>>> expensesByPurpose(String start, String end) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT 
        COALESCE(p.expense_for, 'General') as name,
        COALESCE(p.icon_color, '#9C27B0') as color,
        SUM(t.amount) as value
      FROM "transaction" t
      LEFT JOIN expense_purpose p ON t.purpose_id = p.purpose_id
      WHERE t.transaction_type = 'DEBIT' AND t.transaction_date >= ? AND t.transaction_date <= ?
      GROUP BY p.purpose_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end]);
  }
}
