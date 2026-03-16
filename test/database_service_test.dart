
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fintrack/core/database/database_service.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Initialize FFI for local SQLite testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    // Override the getDatabasesPath to use a temporary directory for tests
    // However, the cleanest way is just to let sqflite FFI use in-memory 
    // but our app expects a file via AppConstants.databaseName.
  });

  testWidgets('Database Service initializes, executes schema, and seeds data', (WidgetTester tester) async {
    // 1. We must mock the rootBundle so the DatabaseService can read 'assets/database/db.sql' in a test environment.
    // In widget tests, we can load assets from the project folder if we declare them.
    final dbSql = await File('assets/database/db.sql').readAsString();
    
    // We mock the DefaultAssetBundle
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        return ByteData.view(
          Uint8List.fromList(dbSql.codeUnits).buffer,
        );
      },
    );

    // Initialize database
    final dbService = DatabaseService();
    final db = await dbService.database;

    // Verify tables exist
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final tableNames = tables.map((row) => row['name'] as String).toList();
    
    expect(tableNames, contains('category'));
    expect(tableNames, contains('account'));
    expect(tableNames, contains('transaction'));

    // Verify seeding - Check if 'category' table has rows
    final categories = await db.query('category');
    expect(categories.isNotEmpty, isTrue);
    expect(categories.length, equals(15)); // we seeded exactly 15 categories
    
    // Verify seeding - Check 'budget'
    final budgets = await db.query('budget');
    expect(budgets.length, equals(9));

    // Cleanup
    await dbService.close();
    
    // Delete test database file
    final dbPath = await getDatabasesPath();
    final file = File('$dbPath/fintrack.db');
    if (await file.exists()) {
      await file.delete();
    }
  });
}
