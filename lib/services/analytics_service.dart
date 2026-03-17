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

  Future<int> transactionCount(String start, String end) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) as count FROM "transaction" '
      'WHERE transaction_date>=? AND transaction_date<=?',
      [start, end],
    );
    return (r.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<double> largestExpense(String start, String end) async {
    final db = await _db.database;
    final r = await db.rawQuery(
      'SELECT COALESCE(MAX(amount),0) as max_amount FROM "transaction" '
      'WHERE transaction_type=\'DEBIT\' AND transaction_date>=? AND transaction_date<=?',
      [start, end],
    );
    return (r.first['max_amount'] as num?)?.toDouble() ?? 0;
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
    final now = DateTime.now();
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final twelveMonthsAgo = DateTime(startOfCurrentMonth.year, startOfCurrentMonth.month - 11, 1);
    
    final startStr = '${twelveMonthsAgo.year}-${twelveMonthsAgo.month.toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery('''
      SELECT 
        substr(transaction_date, 1, 7) as period, 
        COALESCE(SUM(CASE WHEN transaction_type = 'CREDIT' THEN amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN transaction_type = 'DEBIT' THEN amount ELSE 0 END), 0) as expense
      FROM "transaction" 
      WHERE transaction_date >= ?
      GROUP BY period 
      ORDER BY period ASC
    ''', [startStr]);

    // Create a map for quick lookup
    final resultMap = {
      for (var row in result) row['period'] as String: row
    };

    // Pad the last 12 months so it always paints exactly 12 columns
    final paddedResult = <Map<String, dynamic>>[];
    for (int i = 0; i < 12; i++) {
      int nextMonth = twelveMonthsAgo.month + i;
      int yearOffset = (nextMonth - 1) ~/ 12;
      int m = (nextMonth - 1) % 12 + 1;
      int y = twelveMonthsAgo.year + yearOffset;
      
      final period = '$y-${m.toString().padLeft(2, '0')}';
      
      if (resultMap.containsKey(period)) {
        paddedResult.add(Map<String, dynamic>.from(resultMap[period]!));
      } else {
        paddedResult.add({
          'period': period,
          'income': 0.0,
          'expense': 0.0,
        });
      }
    }

    return paddedResult;
  }

  // ─── Budget vs Actual ───────────────────────────────────

  Future<Map<String, dynamic>> getLast12MonthsBudgetStats() async {
    final db = await _db.database;
    final now = DateTime.now();
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final twelveMonthsAgo = DateTime(startOfCurrentMonth.year, startOfCurrentMonth.month - 11, 1);
    
    // Total budget over last 12 months
    final budgetQuery = await db.rawQuery('''
      SELECT year, month, COALESCE(SUM(budget_amount), 0) as total_budget
      FROM budget
      WHERE budget_frequency='MONTHLY' 
      AND (year * 12 + month) >= ? 
      AND (year * 12 + month) <= ?
      GROUP BY year, month
    ''', [
      twelveMonthsAgo.year * 12 + twelveMonthsAgo.month, 
      startOfCurrentMonth.year * 12 + startOfCurrentMonth.month
    ]);

    Map<String, double> monthlyBudgets = {};
    for (var r in budgetQuery) {
      final y = r['year'] as int;
      final m = r['month'] as int;
      monthlyBudgets['$y-${m.toString().padLeft(2, '0')}'] = (r['total_budget'] as num).toDouble();
    }

    final startStr = '${twelveMonthsAgo.year}-${twelveMonthsAgo.month.toString().padLeft(2, '0')}-01';
    final expenseQuery = await db.rawQuery('''
      SELECT substr(transaction_date, 1, 7) as period, COALESCE(SUM(amount), 0) as total_expense
      FROM "transaction"
      WHERE transaction_type='DEBIT' AND transaction_date >= ?
      GROUP BY period
    ''', [startStr]);

    Map<String, double> monthlyExpenses = {};
    for (var r in expenseQuery) {
      monthlyExpenses[r['period'] as String] = (r['total_expense'] as num).toDouble();
    }

    double totalBudgetSum = 0;
    int overBudgetMonths = 0;
    double totalUtilizationSum = 0;
    int budgetMonthsCount = 0;

    for (int i = 0; i < 12; i++) {
        int year = twelveMonthsAgo.year + (twelveMonthsAgo.month - 1 + i) ~/ 12;
        int month = (twelveMonthsAgo.month - 1 + i) % 12 + 1;
        String period = '$year-${month.toString().padLeft(2, '0')}';

        double budget = monthlyBudgets[period] ?? 0.0;
        double expense = monthlyExpenses[period] ?? 0.0;

        totalBudgetSum += budget;
        if (budget > 0) {
            budgetMonthsCount++;
            totalUtilizationSum += (expense / budget);
            if (expense > budget) {
                overBudgetMonths++;
            }
        }
    }

    return {
        'avgMonthlyBudget': totalBudgetSum / 12,
        'overBudgetMonths': overBudgetMonths,
        'averageUtilization': budgetMonthsCount > 0 ? (totalUtilizationSum / budgetMonthsCount) * 100 : 0.0,
    };
  }

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
