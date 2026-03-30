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
