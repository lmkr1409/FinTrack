import 'package:sqflite/sqflite.dart';
import '../core/database/database_service.dart';

/// Base repository providing common CRUD operations.
abstract class BaseRepository<T> {
  final DatabaseService _dbService = DatabaseService();

  /// The table name this repository operates on.
  String get tableName;

  /// The primary key column name.
  String get primaryKey;

  /// Converts a database row map into a model instance.
  T fromMap(Map<String, dynamic> map);

  /// Returns the underlying database instance.
  Future<Database> get db => _dbService.database;

  /// Retrieves all rows, optionally ordered.
  Future<List<T>> getAll({String? orderBy}) async {
    final database = await db;
    final results = await database.query(
      tableName,
      orderBy: orderBy,
    );
    return results.map(fromMap).toList();
  }

  /// Retrieves a single row by its primary key.
  Future<T?> getById(int id) async {
    final database = await db;
    final results = await database.query(
      tableName,
      where: '$primaryKey = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return fromMap(results.first);
  }

  /// Inserts a new row and returns the generated ID.
  Future<int> insert(Map<String, dynamic> data, {ConflictAlgorithm? conflictAlgorithm}) async {
    final database = await db;
    return await database.insert(
      tableName,
      data,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Updates a row by its primary key. Returns the number of rows affected.
  Future<int> update(int id, Map<String, dynamic> data) async {
    final database = await db;
    return await database.update(
      tableName,
      data,
      where: '$primaryKey = ?',
      whereArgs: [id],
    );
  }

  /// Deletes a row by its primary key. Returns the number of rows affected.
  Future<int> delete(int id) async {
    final database = await db;
    return await database.delete(
      tableName,
      where: '$primaryKey = ?',
      whereArgs: [id],
    );
  }

  /// Runs a custom query and returns mapped results.
  Future<List<T>> query({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final database = await db;
    final results = await database.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
    return results.map(fromMap).toList();
  }

  /// Runs a raw SQL query and returns the raw map results.
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    final database = await db;
    return await database.rawQuery(sql, arguments);
  }
}
