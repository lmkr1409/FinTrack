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

  Future<void> _onCreate(Database db, int version) async {
    await _executeSchemaScript(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrations are consolidated into version 1 scripts (ddl.sql and dml.sql).
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
