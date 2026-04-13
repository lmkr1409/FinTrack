import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/database_service.dart';
import '../models/strategy_models.dart';

/// Service providing analytics queries for dashboards, trends, and top-N reports.
class AnalyticsService {
  final DatabaseService _db = DatabaseService();

  Future<Database> get database => _db.database;

  Future<Map<String, String>> _getGeneralSettings() async {
    final db = await database;
    final maps = await db.query('general_settings');
    return {
      for (var m in maps) m['setting_key'] as String: m['setting_value'] as String
    };
  }

  // ─── Summary totals ─────────────────────────────────────

  Future<double> totalByNatureAndType(String nature, String? transactionType, String start, String end, {String? widgetKey}) async {
    final db = await _db.database;
    String query = 'SELECT COALESCE(SUM(amount),0) as total FROM "transaction" WHERE nature=? AND transaction_date>=? AND transaction_date<=?';
    List<Object?> args = [nature, start, end];
    if (transactionType != null) {
      query += ' AND transaction_type=?';
      args.add(transactionType);
    }
    
    if (widgetKey != null) {
      query += await _getFilterSnippet(widgetKey);
    }

    final r = await db.rawQuery(query, args);
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<int> transactionCount(String start, String end, {String? widgetKey}) async {
    final db = await _db.database;
    String query = 'SELECT COUNT(*) as count FROM "transaction" WHERE nature=\'TRANSACTIONS\' AND transaction_date>=? AND transaction_date<=?';
    if (widgetKey != null) {
      query += await _getFilterSnippet(widgetKey);
    }
    final r = await db.rawQuery(query, [start, end]);
    return (r.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<double> largestExpense(String start, String end, {String? widgetKey}) async {
    final db = await _db.database;
    String query = 'SELECT COALESCE(MAX(amount),0) as max_amount FROM "transaction" WHERE nature=\'TRANSACTIONS\' AND transaction_type=\'DEBIT\' AND transaction_date>=? AND transaction_date<=?';
    if (widgetKey != null) {
      query += await _getFilterSnippet(widgetKey);
    }
    final r = await db.rawQuery(query, [start, end]);
    return (r.first['max_amount'] as num?)?.toDouble() ?? 0;
  }

  // ─── Top-N queries ──────────────────────────────────────

  Future<List<Map<String, dynamic>>> topCategories(String start, String end, {int limit = 5, String? widgetKey}) async {
    final db = await _db.database;
    String filter = '';
    if (widgetKey != null) {
      filter = await _getFilterSnippet(widgetKey, tableAlias: 't.');
    }
    return db.rawQuery(
      'SELECT c.category_id, c.category_name, c.icon, c.icon_color, '
      'COALESCE(SUM(t.amount),0) as total '
      'FROM "transaction" t JOIN category c ON t.category_id=c.category_id '
      'WHERE t.nature=\'TRANSACTIONS\' AND t.transaction_type=\'DEBIT\' AND t.transaction_date>=? AND t.transaction_date<=? $filter '
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
      'WHERE t.nature=\'TRANSACTIONS\' AND t.transaction_type=\'DEBIT\' AND substr(t.transaction_date, 1, 10)>=? AND substr(t.transaction_date, 1, 10)<=? '
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
      'WHERE t.nature=\'TRANSACTIONS\' AND t.transaction_type=\'DEBIT\' AND substr(t.transaction_date, 1, 10)>=? AND substr(t.transaction_date, 1, 10)<=? '
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
      'WHERE t.nature=\'TRANSACTIONS\' AND t.transaction_type=\'DEBIT\' AND substr(t.transaction_date, 1, 10)>=? AND substr(t.transaction_date, 1, 10)<=? '
      'GROUP BY p.purpose_id ORDER BY total DESC LIMIT ?',
      [start, end, limit],
    );
  }

  Future<List<Map<String, dynamic>>> topCards(String start, String end, {int limit = 5}) async {
    final db = await _db.database;
    return db.rawQuery(
      'SELECT c.card_id, c.card_name, c.icon, c.icon_color, '
      'COALESCE(SUM(t.amount),0) as total '
      'FROM "transaction" t JOIN cards c ON t.card_id=c.card_id '
      'WHERE t.nature=\'TRANSACTIONS\' AND t.transaction_type=\'DEBIT\' AND substr(t.transaction_date, 1, 10)>=? AND substr(t.transaction_date, 1, 10)<=? '
      'GROUP BY c.card_id ORDER BY total DESC LIMIT ?',
      [start, end, limit],
    );
  }

  // ─── Trends ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> expensePerDay(String start, String end, {String? widgetKey}) async {
    final db = await _db.database;
    String query = 'SELECT substr(transaction_date, 1, 10) as period, COALESCE(SUM(amount),0) as total '
                   'FROM "transaction" WHERE nature=\'TRANSACTIONS\' AND transaction_type=\'DEBIT\' '
                   'AND transaction_date>=? AND transaction_date<=? ';
    if (widgetKey != null) {
      query += await _getFilterSnippet(widgetKey);
    }
    query += 'GROUP BY period ORDER BY period';
    return db.rawQuery(query, [start, end]);
  }

  Future<List<Map<String, dynamic>>> expensePerMonth(String start, String end) async {
    final db = await _db.database;
    return db.rawQuery(
      'SELECT substr(transaction_date,1,7) as period, COALESCE(SUM(amount),0) as total '
      'FROM "transaction" WHERE nature=\'TRANSACTIONS\' AND transaction_type=\'DEBIT\' '
      'AND transaction_date>=? AND transaction_date<=? '
      'GROUP BY period ORDER BY period',
      [start, end],
    );
  }

  Future<List<Map<String, dynamic>>> incomeVsExpenseLast12Months({String? widgetKey}) async {
    final db = await _db.database;
    final now = DateTime.now();
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final twelveMonthsAgo = DateTime(startOfCurrentMonth.year, startOfCurrentMonth.month - 11, 1);
    
    final startStr = '${twelveMonthsAgo.year}-${twelveMonthsAgo.month.toString().padLeft(2, '0')}-01';
    
    String filter = '';
    if (widgetKey != null) {
      filter = await _getFilterSnippet(widgetKey);
    }

    final result = await db.rawQuery('''
      SELECT 
        substr(transaction_date, 1, 7) as period, 
        COALESCE(SUM(CASE WHEN nature = 'TRANSACTIONS' AND transaction_type = 'CREDIT' THEN amount ELSE 0 END), 0) as income,
        COALESCE(SUM(CASE WHEN nature = 'TRANSACTIONS' AND transaction_type = 'DEBIT' THEN amount ELSE 0 END), 0) as expense
      FROM "transaction" 
      WHERE transaction_date >= ? $filter
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

  Future<List<Map<String, dynamic>>> netInvestmentsLast12Months({String? widgetKey}) async {
    final db = await _db.database;
    final now = DateTime.now();
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final twelveMonthsAgo = DateTime(startOfCurrentMonth.year, startOfCurrentMonth.month - 11, 1);
    final startStr = '${twelveMonthsAgo.year}-${twelveMonthsAgo.month.toString().padLeft(2, '0')}-01';

    String filter = '';
    if (widgetKey != null) {
      filter = await _getFilterSnippet(widgetKey);
    }

    final result = await db.rawQuery('''
      SELECT
        substr(transaction_date, 1, 7) as period,
        COALESCE(SUM(CASE WHEN transaction_type = 'DEBIT'  THEN amount ELSE 0 END), 0)
        - COALESCE(SUM(CASE WHEN transaction_type = 'CREDIT' THEN amount ELSE 0 END), 0) as net_investment
      FROM "transaction"
      WHERE nature = 'INVESTMENTS'
        AND transaction_date >= ? $filter
      GROUP BY period
      ORDER BY period ASC
    ''', [startStr]);

    final resultMap = {for (var row in result) row['period'] as String: row};

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
        paddedResult.add({'period': period, 'net_investment': 0.0});
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
      WHERE nature='TRANSACTIONS' AND transaction_type='DEBIT' AND transaction_date >= ?
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

  Future<List<Map<String, dynamic>>> budgetVsActual(int month, int year, {List<String> categoryTypes = const ['TRANSACTIONS'], String? widgetKey}) async {
    final db = await _db.database;
    final start = '$year-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final end = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    final placeholders = categoryTypes.map((_) => '?').join(', ');

    final result = await db.rawQuery('''
      SELECT 
        c.category_id, 
        c.category_name, 
        c.icon, 
        c.icon_color, 
        c.category_type,
        COALESCE(bm.budget_amount, 0) as budget_amount, -- Monthly
        COALESCE(ba.budget_amount, 0) as budget_amount_annual, -- Yearly
        COALESCE((
          SELECT SUM(CASE 
            WHEN t.nature = 'TRANSACTIONS' AND t.transaction_type = 'DEBIT' THEN t.amount 
            WHEN t.nature = 'INVESTMENTS' AND t.transaction_type = 'DEBIT' THEN t.amount
            WHEN t.nature = 'INVESTMENTS' AND t.transaction_type = 'CREDIT' THEN -t.amount
            ELSE 0 END) 
          FROM "transaction" t 
          WHERE t.category_id = c.category_id 
          AND t.transaction_date >= ? AND t.transaction_date < ?
          ${widgetKey != null ? await _getFilterSnippet(widgetKey) : ''}
        ), 0) as actual
      FROM category c
      LEFT JOIN budget bm ON c.category_id = bm.category_id 
        AND bm.budget_frequency = 'MONTHLY' AND bm.month = ? AND bm.year = ?
      LEFT JOIN budget ba ON c.category_id = ba.category_id 
        AND ba.budget_frequency = 'ANNUAL' AND ba.year = ?
      WHERE c.category_type IN ($placeholders)
    ''', [start, end, month, year, year, ...categoryTypes]);

    // Convert to mutable maps to add global budget info if needed
    final list = List<Map<String, dynamic>>.from(result.map((e) => Map<String, dynamic>.from(e)));

    // Ensure actual is not negative (especially for investments)
    for (var item in list) {
      if ((item['actual'] as num).toDouble() < 0) {
        item['actual'] = 0.0;
      }
    }

    if (categoryTypes.contains('TRANSACTIONS')) {
      // Add Global Budget as a special entry with category_id = null
      final globalBudget = await db.rawQuery(
        'SELECT budget_amount FROM budget_total WHERE budget_frequency = \'MONTHLY\' AND month = ? AND year = ?',
        [month, year]
      );
      if (globalBudget.isNotEmpty) {
        // We calculate total actual outflows (Expenses + Net Investments) for the month
        final totalActual = await db.rawQuery('''
          SELECT SUM(CASE 
            WHEN nature = 'TRANSACTIONS' AND transaction_type = 'DEBIT' THEN amount 
            WHEN nature = 'INVESTMENTS' AND transaction_type = 'DEBIT' THEN amount
            WHEN nature = 'INVESTMENTS' AND transaction_type = 'CREDIT' THEN -amount
            ELSE 0 END) as total 
          FROM "transaction" 
          WHERE transaction_date >= ? AND transaction_date < ?
        ''', [start, end]);

        list.add({
          'category_id': null,
          'category_name': 'Total Budget',
          'budget_amount': (globalBudget.first['budget_amount'] as num).toDouble(),
          'actual': (totalActual.first['total'] as num?)?.toDouble().clamp(0, double.infinity) ?? 0.0,
          'category_type': 'TRANSACTIONS',
        });
      }
    }

    return list;
  }

  // ─── Expense Breakdowns (Pie Charts) ────────────────────

  Future<List<Map<String, dynamic>>> expensesByCategory(String start, String end, {String? widgetKey}) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT 
        c.category_id as id,
        COALESCE(c.category_name, 'Uncategorized') as name,
        COALESCE(c.icon_color, '#9E9E9E') as color,
        SUM(t.amount) as value
      FROM "transaction" t
      LEFT JOIN category c ON t.category_id = c.category_id
      WHERE t.nature='TRANSACTIONS' AND t.transaction_type='DEBIT' AND t.transaction_date >= ? AND t.transaction_date <= ?
      ${widgetKey != null ? await _getFilterSnippet(widgetKey, tableAlias: 't.') : ''}
      GROUP BY c.category_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end]);
  }

  Future<List<Map<String, dynamic>>> expensesByPaymentMethod(String start, String end) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT 
        COALESCE(p.payment_method_name, 'Unknown Method') as name,
        COALESCE(p.icon_color, '#607D8B') as color,
        SUM(t.amount) as value
      FROM "transaction" t
      LEFT JOIN payment_method p ON t.payment_method_id = p.payment_method_id
      WHERE t.nature='TRANSACTIONS' AND t.transaction_type='DEBIT' AND t.transaction_date >= ? AND t.transaction_date <= ?
      GROUP BY p.payment_method_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end]);
  }

  Future<List<Map<String, dynamic>>> expensesByAccount(String start, String end) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT 
        COALESCE(a.account_name, 'Unknown Account') as name,
        COALESCE(a.icon_color, '#1E88E5') as color,
        SUM(t.amount) as value
      FROM "transaction" t
      LEFT JOIN account a ON t.account_id = a.account_id
      WHERE t.nature='TRANSACTIONS' AND t.transaction_type='DEBIT' AND t.transaction_date >= ? AND t.transaction_date <= ?
      GROUP BY a.account_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end]);
  }

  Future<List<Map<String, dynamic>>> expensesByCard(String start, String end) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT 
        COALESCE(c.card_name, 'Unknown Card') as name,
        COALESCE(c.icon_color, '#FF9800') as color,
        SUM(t.amount) as value
      FROM "transaction" t
      LEFT JOIN cards c ON t.card_id = c.card_id
      WHERE t.nature='TRANSACTIONS' AND t.transaction_type='DEBIT' AND t.transaction_date >= ? AND t.transaction_date <= ?
      GROUP BY c.card_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end]);
  }

  Future<List<Map<String, dynamic>>> expensesBySubCategory(String start, String end, int categoryId, {String? widgetKey}) async {
    final db = await _db.database;
    return db.rawQuery('''
      SELECT 
        COALESCE(s.subcategory_name, 'Uncategorized') as name,
        COALESCE(s.icon_color, '#9E9E9E') as color,
        SUM(t.amount) as value
      FROM "transaction" t
      LEFT JOIN sub_category s ON t.subcategory_id = s.subcategory_id
      WHERE t.nature='TRANSACTIONS' AND t.transaction_type='DEBIT' AND t.transaction_date >= ? AND t.transaction_date <= ? AND t.category_id = ?
      ${widgetKey != null ? await _getFilterSnippet(widgetKey, tableAlias: 't.') : ''}
      GROUP BY s.subcategory_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end, categoryId]);
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
      WHERE t.nature='TRANSACTIONS' AND t.transaction_type='DEBIT' AND t.transaction_date >= ? AND t.transaction_date <= ?
      GROUP BY p.purpose_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end]);
  }

  Future<List<Map<String, dynamic>>> investmentsByCategory(String start, String end, {String? widgetKey}) async {
    final db = await _db.database;
    String filter = '';
    if (widgetKey != null) {
      filter = await _getFilterSnippet(widgetKey, tableAlias: 't.');
    }
    return db.rawQuery('''
      SELECT 
        c.category_id as id,
        COALESCE(c.category_name, 'Uncategorized') as name,
        COALESCE(c.icon_color, '#FFC107') as color,
        (
          COALESCE(SUM(CASE WHEN t.transaction_type = 'DEBIT' THEN t.amount ELSE 0 END), 0)
          - COALESCE(SUM(CASE WHEN t.transaction_type = 'CREDIT' THEN t.amount ELSE 0 END), 0)
        ) as value
      FROM "transaction" t
      LEFT JOIN category c ON t.category_id = c.category_id
      WHERE t.nature = 'INVESTMENTS'
        AND t.transaction_date >= ?
        AND t.transaction_date <= ?
        $filter
      GROUP BY c.category_id
      HAVING value > 0
      ORDER BY value DESC
    ''', [start, end]);
  }

  // ─── Investment Goals ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGoalProgress(int month, int year) async {
    final db = await _db.database;
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final endStr = '$endYear-${endMonth.toString().padLeft(2, '0')}-01';

    return db.rawQuery('''
      SELECT 
        g.goal_id,
        g.goal_name,
        g.target_amount,
        g.category_id,
        g.subcategory_id,
        g.purpose_id,
        c.category_name,
        c.icon,
        c.icon_color,
        COALESCE((
          SELECT 
            COALESCE(SUM(CASE WHEN t.transaction_type = 'DEBIT' THEN t.amount ELSE 0 END), 0)
            - COALESCE(SUM(CASE WHEN t.transaction_type = 'CREDIT' THEN t.amount ELSE 0 END), 0)
          FROM "transaction" t 
          WHERE t.nature = 'INVESTMENTS'
            AND t.goal_id = g.goal_id
            AND t.transaction_date < ?
        ), 0) as saved_amount
      FROM investment_goal g
      JOIN category c ON g.category_id = c.category_id
      ORDER BY g.created_time DESC
    ''', [endStr]);
  }

  Future<Map<String, double>> getIncomeAllocation({
    required DateTime start,
    required DateTime end,
    bool? usePrevMonthSalary,
    String? widgetKey,
  }) async {
    final settings = await _getGeneralSettings();
    final prefix = widgetKey == 'monthly_budget' ? 'budget_' : 
                   widgetKey == 'strategic_planner' ? 'strategy_' : 
                   widgetKey == 'financial_flow' ? 'flow_' : 'allocation_';

    final salaryMode = settings['${prefix}salary_mode'] ?? 'CURRENT';
    final otherMode = settings['${prefix}other_mode'] ?? 'CURRENT';

    final actualUsePrevSalary = usePrevMonthSalary ?? (salaryMode == 'PREV');

    double income;
    if (actualUsePrevSalary || otherMode == 'PREV') {
      final prevMonthStart = DateTime(start.year, start.month - 1, 1);
      final prevMonthEnd = DateTime(start.year, start.month, 0, 23, 59, 59);

      double salaryValue = 0;
      double otherValue = 0;

      // Salary Part
      if (actualUsePrevSalary) {
        salaryValue = await _getIncomeForCategory(prevMonthStart, prevMonthEnd, isSalary: true, widgetKey: widgetKey);
      } else {
        salaryValue = await _getIncomeForCategory(start, end, isSalary: true, widgetKey: widgetKey);
      }

      // Other Part
      if (otherMode == 'PREV') {
        otherValue = await _getIncomeForCategory(prevMonthStart, prevMonthEnd, isSalary: false, widgetKey: widgetKey);
      } else {
        otherValue = await _getIncomeForCategory(start, end, isSalary: false, widgetKey: widgetKey);
      }
      income = salaryValue + otherValue;
    } else {
      // Simple mode: all income from current month
      final db = await _db.database;
      String filter = widgetKey != null ? await _getFilterSnippet(widgetKey) : '';
      final incomeQuery = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM "transaction" WHERE nature=\'TRANSACTIONS\' AND transaction_type=\'CREDIT\' AND transaction_date >= ? AND transaction_date <= ? $filter',
        [start.toIso8601String(), end.toIso8601String()],
      );
      income = (incomeQuery.first['total'] as num).toDouble();
    }

    // Expenses — always current month
    final db = await _db.database;
    String expenseFilter = widgetKey != null ? await _getFilterSnippet(widgetKey) : '';
    final expenseQuery = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM "transaction" WHERE nature=\'TRANSACTIONS\' AND transaction_type=\'DEBIT\' AND transaction_date >= ? AND transaction_date <= ? $expenseFilter',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final expenses = (expenseQuery.first['total'] as num).toDouble();

    // Net investments — DEBIT minus CREDIT (no category filter — always raw total)
    // Use substr normalization to handle both space and T date separators consistently
    final startDate = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endDate = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
    final invDebitQuery = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM "transaction" WHERE nature=\'INVESTMENTS\' AND transaction_type=\'DEBIT\' AND substr(transaction_date,1,10) >= ? AND substr(transaction_date,1,10) <= ?',
      [startDate, endDate],
    );
    final invCreditQuery = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM "transaction" WHERE nature=\'INVESTMENTS\' AND transaction_type=\'CREDIT\' AND substr(transaction_date,1,10) >= ? AND substr(transaction_date,1,10) <= ?',
      [startDate, endDate],
    );
    final invDebit = (invDebitQuery.first['total'] as num?)?.toDouble() ?? 0.0;
    final invCredit = (invCreditQuery.first['total'] as num?)?.toDouble() ?? 0.0;
    final investments = (invDebit - invCredit).clamp(0.0, double.infinity);

    return {
      'income': income,
      'expenses': expenses,
      'investments': investments,
    };
  }

  Future<double> _getIncomeForCategory(DateTime start, DateTime end, {required bool isSalary, String? widgetKey}) async {
    final db = await _db.database;
    String filter = widgetKey != null ? await _getFilterSnippet(widgetKey, tableAlias: 't.') : '';
    
    String query = '''
      SELECT SUM(t.amount) as total 
      FROM "transaction" t
      LEFT JOIN sub_category sc ON t.subcategory_id = sc.subcategory_id
      WHERE t.nature = 'TRANSACTIONS' 
      AND t.transaction_type = 'CREDIT'
      AND t.transaction_date BETWEEN ? AND ?
      $filter
    ''';

    if (isSalary) {
      query += " AND LOWER(COALESCE(sc.subcategory_name, '')) = 'salary'";
    } else {
      query += " AND LOWER(COALESCE(sc.subcategory_name, '')) != 'salary'";
    }

    final results = await db.rawQuery(query, [start.toIso8601String(), end.toIso8601String()]);
    return (results.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ─── Strategic Planner (Heuristics) ────────────────────

  Future<List<BucketProgress>> getStrategyProgress(DateTime date, {String? widgetKey}) async {
    final db = await _db.database;
    final start = DateFormat('yyyy-MM-dd').format(DateTime(date.year, date.month, 1));
    final end = DateFormat('yyyy-MM-dd').format(DateTime(date.year, date.month + 1, 0));

    // 1. Get Active Framework
    final frameworks = await db.query('budget_framework', where: 'is_active = 1');
    if (frameworks.isEmpty) return [];
    final framework = BudgetFramework.fromMap(frameworks.first);

    // 2. Get Buckets
    final buckets = await db.query('budget_bucket', where: 'framework_id = ?', whereArgs: [framework.id]);
    final bucketModels = buckets.map((b) => BudgetBucket.fromMap(b)).toList();

    // 3. Determine Baseline Salary
    final baseline = await getStrategyBaseline(date, widgetKey: widgetKey);

    // 4. Get Mappings
    final mappings = await db.query('category_bucket_mapping', where: 'framework_id = ?', whereArgs: [framework.id]);
    final catToBucket = <int, int>{};
    for (final m in mappings) {
      catToBucket[m['category_id'] as int] = m['bucket_id'] as int;
    }

    // 5. Calculate Actuals per Bucket
    final bucketActuals = <int, double>{};
    for (final bucket in bucketModels) bucketActuals[bucket.id!] = 0.0;

    final catTotals = await db.rawQuery('''
      SELECT 
        category_id,
        SUM(CASE 
          WHEN nature = 'TRANSACTIONS' AND transaction_type = 'DEBIT' THEN amount
          WHEN nature = 'INVESTMENTS' AND transaction_type = 'DEBIT' THEN amount
          WHEN nature = 'INVESTMENTS' AND transaction_type = 'CREDIT' THEN -amount
          ELSE 0 END) as total
      FROM "transaction"
      WHERE transaction_date >= ? AND transaction_date <= ?
      ${widgetKey != null ? await _getFilterSnippet(widgetKey) : ""}
      GROUP BY category_id
    ''', [start, end]);

    for (final row in catTotals) {
      final catId = row['category_id'] as int?;
      if (catId != null && catToBucket.containsKey(catId)) {
        final bucketId = catToBucket[catId]!;
        bucketActuals[bucketId] = (bucketActuals[bucketId] ?? 0) + (row['total'] as num).toDouble();
      }
    }

    // 6. Assemble Progress
    return bucketModels.map((bucket) {
      final target = baseline * (bucket.percentage / 100);
      final actual = bucketActuals[bucket.id!] ?? 0.0;
      return BucketProgress(
        bucket: bucket,
        targetAmount: target,
        actualAmount: actual,
      );
    }).toList();
  }

  Future<double> getStrategyBaseline(DateTime date, {String? widgetKey}) async {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    final prevMonthStart = DateTime(date.year, date.month - 1, 1);
    final prevMonthEnd = DateTime(date.year, date.month, 0, 23, 59, 59);

    final settings = await _getGeneralSettings();
    final prefix = widgetKey == 'monthly_budget' ? 'budget_' : 
                   widgetKey == 'income_allocation' ? 'allocation_' : 
                   widgetKey == 'financial_flow' ? 'flow_' : 'strategy_';

    final salaryMode = settings['${prefix}salary_mode'] ?? 'CURRENT';
    final otherMode = settings['${prefix}other_mode'] ?? 'CURRENT';

    final sStart = salaryMode == 'PREV' ? prevMonthStart : start;
    final sEnd = salaryMode == 'PREV' ? prevMonthEnd : end;
    double baselineIncome = await _getIncomeForCategory(sStart, sEnd, isSalary: true, widgetKey: widgetKey);

    // Add other income if needed
    final oStart = otherMode == 'PREV' ? prevMonthStart : start;
    final oEnd = otherMode == 'PREV' ? prevMonthEnd : end;
    baselineIncome += await _getIncomeForCategory(oStart, oEnd, isSalary: false, widgetKey: widgetKey);

    return baselineIncome;
  }

  // ─── Filter Helpers ─────────────────────────────────────

  Future<String> _getFilterSnippet(String widgetKey, {String tableAlias = ''}) async {
    final db = await _db.database;
    final filters = await db.query('widget_filter', where: 'widget_key = ?', whereArgs: [widgetKey]);
    if (filters.isEmpty) return '';

    final excludedCategories = filters
        .where((f) => f['filter_type'] == 'EXCLUDE' && f['target_type'] == 'CATEGORY')
        .map((f) => f['target_id'])
        .toList();
    
    final excludedSubcats = filters
        .where((f) => f['filter_type'] == 'EXCLUDE' && f['target_type'] == 'SUBCATEGORY')
        .map((f) => f['target_id'])
        .toList();

    String snippet = '';
    if (excludedCategories.isNotEmpty) {
      snippet += ' AND ${tableAlias}category_id NOT IN (${excludedCategories.join(",")})';
    }
    if (excludedSubcats.isNotEmpty) {
      snippet += ' AND ${tableAlias}subcategory_id NOT IN (${excludedSubcats.join(",")})';
    }
    
    final includedCategories = filters
        .where((f) => f['filter_type'] == 'INCLUDE' && f['target_type'] == 'CATEGORY')
        .map((f) => f['target_id'])
        .toList();
    
    if (includedCategories.isNotEmpty) {
       snippet += ' AND ${tableAlias}category_id IN (${includedCategories.join(",")})';
    }
    
    final includedSubcats = filters
        .where((f) => f['filter_type'] == 'INCLUDE' && f['target_type'] == 'SUBCATEGORY')
        .map((f) => f['target_id'])
        .toList();
    
    if (includedSubcats.isNotEmpty) {
       snippet += ' AND ${tableAlias}subcategory_id IN (${includedSubcats.join(",")})';
    }

    return snippet;
  }
}
