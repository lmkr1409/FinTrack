import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// Service responsible for managing the local SQLite database.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Database? _database;

  /// Retrieves the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initializes the database and creates the file if it doesn't exist.
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, AppConstants.databaseName);

    // Open the database and use `onCreate` to run the initialization script.
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Called when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    await _executeSchemaScript(db);
  }

  /// Called when the database needs to be upgraded
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS investment_goal (
          goal_id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          category_id INTEGER NOT NULL,
          subcategory_id INTEGER,
          purpose_id INTEGER,
          created_time TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_time TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE RESTRICT,
          FOREIGN KEY (subcategory_id) REFERENCES sub_category(subcategory_id) ON DELETE SET NULL,
          FOREIGN KEY (purpose_id) REFERENCES expense_purpose(purpose_id) ON DELETE SET NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE "transaction" ADD COLUMN goal_id INTEGER');
    }
    if (oldVersion < 4) {
      final newSenders = [
        'SBIUPI', 'SBIN', 'ATMSBI', 'SBIOTR', 'SBIPAY',
        'ICICIS', 'ICICIP', 'ICICIV', 'ICICIA',
        'AXISPB', 'AXISCN', 'AXISRM',
        'KOTAKM', 'KOTAKN',
        'PNBBNK', 'PNBORG',
        'BOBSMS', 'CANARA', 'IDFCBK', 'INDUSB', 'INDSBK', 'YESPBT', 'UBIINB', 'UBIRES',
        'CBIINB', 'IDNBNK', 'FEDBNK', 'SIBTXT', 'RBLBNK', 'BNDHAN', 'IDBIBK', 'SCBBNK',
        'CITIBK', 'HSBCBK', 'DBSBNK', 'KVBSMS'
      ];
      for (final sender in newSenders) {
        await db.execute(
          'INSERT OR IGNORE INTO transaction_rule (rule_type, pattern) VALUES (?, ?)',
          ['BANK_SENDER', sender],
        );
      }
    }
    if (oldVersion < 5) {
      final updates = {
        'Groceries': {
          'Fruits': '#FF5252',
          'Dry Fruits': '#FB8C00',
          'Vegetables': '#4CAF50',
          'Dairy': '#03A9F4',
          'Meat': '#795548',
          'Milling': '#FDD835',
        },
        'Income': {
          'Salary': '#2E7D32',
          'Investment': '#00C853',
        },
        'Utilities': {
          'Electricity': '#FFEB3B',
          'Mobile Bill': '#EC407A',
          'Internet Bill': '#5C6BC0',
          'Gas Bill': '#FF7043',
        },
        'Transportation': {
          'Petrol': '#FF9800',
          'Bike Service': '#455A64',
          'Commute': '#0288D1',
        },
        'Housing': {
          'Rent': '#3F51B5',
          'Maintenance': '#689F38',
          'Repairs': '#F44336',
        },
        'Entertainment': {
          'Movies': '#E91E63',
          'Concerts': '#9C27B0',
        },
        'Healthcare': {
          'Doctor': '#00BCD4',
          'Medicine': '#E53935',
        },
        'Insurance': {
          'Health Insurance': '#EF5350',
          'Car Insurance': '#26A69A',
          'Bike Insurance': '#FFA726',
        },
        'Education': {
          'Books': '#5C6BC0',
          'Courses': '#26A69A',
        },
        'Shopping': {
          'Clothes': '#FF4081',
          'Electronics': '#7E57C2',
        },
        'Food': {
          'Office': '#A1887F',
          'Breakfast': '#FFB300',
          'Outside': '#FF5722',
          'Restaurant': '#D84315',
          'Snacks': '#FFCA28',
        },
        'Travel': {
          'Tour': '#009688',
          'Hotel': '#1976D2',
        },
        'Mutual Funds': {
          'SIP': '#3F51B5',
          'LumpSum': '#3949AB',
        },
        'Gifts & Donation': {
          'Gift': '#EC407A',
          'Donation': '#66BB6A',
        },
      };

      for (var entry in updates.entries) {
        final catName = entry.key;
        for (var subEntry in entry.value.entries) {
          final subName = subEntry.key;
          final color = subEntry.value;
          await db.execute('''
            UPDATE sub_category 
            SET icon_color = ? 
            WHERE subcategory_name = ? 
            AND category_id = (SELECT category_id FROM category WHERE category_name = ?)
          ''', [color, subName, catName]);
        }
      }
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_framework (
          framework_id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          is_active INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_bucket (
          bucket_id INTEGER PRIMARY KEY AUTOINCREMENT,
          framework_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          percentage REAL NOT NULL,
          bucket_type TEXT NOT NULL,
          icon TEXT,
          icon_color TEXT,
          FOREIGN KEY (framework_id) REFERENCES budget_framework(framework_id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS category_bucket_mapping (
          category_id INTEGER NOT NULL,
          framework_id INTEGER NOT NULL,
          bucket_id INTEGER NOT NULL,
          PRIMARY KEY (category_id, framework_id),
          FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE CASCADE,
          FOREIGN KEY (framework_id) REFERENCES budget_framework(framework_id) ON DELETE CASCADE,
          FOREIGN KEY (bucket_id) REFERENCES budget_bucket(bucket_id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS strategy_settings (
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          framework_id INTEGER,
          salary_override REAL,
          PRIMARY KEY (month, year)
        )
      ''');

      final f503020Id = await db.insert('budget_framework', {'name': '50/30/20 Rule', 'is_active': 1});
      final f50251510Id = await db.insert('budget_framework', {'name': '50/25/15/10 Rule', 'is_active': 0});

      await db.insert('budget_bucket', {
        'framework_id': f503020Id, 'name': 'Essentials', 'percentage': 50.0, 'bucket_type': 'SPENT', 'icon': 'fact_check_rounded', 'icon_color': '#2196F3'
      });
      await db.insert('budget_bucket', {
        'framework_id': f503020Id, 'name': 'Wants', 'percentage': 30.0, 'bucket_type': 'SPENT', 'icon': 'shopping_bag_rounded', 'icon_color': '#E91E63'
      });
      await db.insert('budget_bucket', {
        'framework_id': f503020Id, 'name': 'Savings & Investments', 'percentage': 20.0, 'bucket_type': 'SAVED', 'icon': 'trending_up_rounded', 'icon_color': '#4CAF50'
      });

      await db.insert('budget_bucket', {
        'framework_id': f50251510Id, 'name': 'Essentials', 'percentage': 50.0, 'bucket_type': 'SPENT', 'icon': 'fact_check_rounded', 'icon_color': '#2196F3'
      });
      await db.insert('budget_bucket', {
        'framework_id': f50251510Id, 'name': 'Growth', 'percentage': 25.0, 'bucket_type': 'SAVED', 'icon': 'rocket_launch_rounded', 'icon_color': '#4CAF50'
      });
      await db.insert('budget_bucket', {
        'framework_id': f50251510Id, 'name': 'Stability', 'percentage': 15.0, 'bucket_type': 'SAVED', 'icon': 'shield_rounded', 'icon_color': '#00BCD4'
      });
      await db.insert('budget_bucket', {
        'framework_id': f50251510Id, 'name': 'Rewards', 'percentage': 10.0, 'bucket_type': 'SPENT', 'icon': 'card_giftcard_rounded', 'icon_color': '#FF9800'
      });
    }

    if (oldVersion < 8) {
      final f702010Id = await db.insert('budget_framework', {'name': '70/20/10 Rule', 'is_active': 0});
      final f8020Id = await db.insert('budget_framework', {'name': '80/20 Rule', 'is_active': 0});

      // 70/20/10 Buckets
      await db.insert('budget_bucket', {
        'framework_id': f702010Id, 'name': 'Living Expenses', 'percentage': 70.0, 'bucket_type': 'SPENT', 'icon': 'home_rounded', 'icon_color': '#FF9800'
      });
      await db.insert('budget_bucket', {
        'framework_id': f702010Id, 'name': 'Savings & Investments', 'percentage': 20.0, 'bucket_type': 'SAVED', 'icon': 'trending_up_rounded', 'icon_color': '#4CAF50'
      });
      await db.insert('budget_bucket', {
        'framework_id': f702010Id, 'name': 'Debt & Giving', 'percentage': 10.0, 'bucket_type': 'SPENT', 'icon': 'volunteer_activism_rounded', 'icon_color': '#9C27B0'
      });

      // 80/20 Buckets
      await db.insert('budget_bucket', {
        'framework_id': f8020Id, 'name': 'Everyday Expenses', 'percentage': 80.0, 'bucket_type': 'SPENT', 'icon': 'shopping_bag_rounded', 'icon_color': '#2196F3'
      });
      await db.insert('budget_bucket', {
        'framework_id': f8020Id, 'name': 'Savings', 'percentage': 20.0, 'bucket_type': 'SAVED', 'icon': 'savings_rounded', 'icon_color': '#4CAF50'
      });
    }
  }

  /// Reads and executes the SQL schema/seed file from assets.
  Future<void> _executeSchemaScript(Database db) async {
    try {
      // 1. Execute Data Definition Language (Schema)
      final ddlScript = await rootBundle.loadString('assets/database/ddl.sql');
      await _runScript(db, ddlScript);

      // 2. Execute Data Manipulation Language (Configurations/Seed Data)
      final dmlScript = await rootBundle.loadString('assets/database/dml.sql');
      await _runScript(db, dmlScript);
    } catch (e) {
    }
  }

  Future<void> _runScript(Database db, String script) async {
    // Split the script by ';' to get individual statements.
    final rawStatements = script.split(';');

    final statements = <String>[];
    for (var s in rawStatements) {
      // Remove inline comments starting with --
      var cleanState = s.split('\n').where((line) => !line.trim().startsWith('--')).join('\n').trim();
      if (cleanState.isNotEmpty) {
        statements.add(cleanState);
      }
    }

    for (final statement in statements) {
      if (statement.isNotEmpty) {
        await db.execute(statement);
      }
    }
  }

  /// Closes the database.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
