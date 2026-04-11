import 'package:sqflite/sqflite.dart';
import '../core/database/database_service.dart';
import '../models/widget_filter.dart';

class WidgetFilterRepository {
  final _dbService = DatabaseService();

  Future<List<WidgetFilter>> getFiltersForWidget(String widgetKey) async {
    final db = await _dbService.database;
    final maps = await db.query('widget_filter', where: 'widget_key = ?', whereArgs: [widgetKey]);
    return maps.map((m) => WidgetFilter.fromMap(m)).toList();
  }

  Future<void> addFilter(WidgetFilter filter) async {
    final db = await _dbService.database;
    await db.insert('widget_filter', filter.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFilter(String widgetKey, int targetId, String targetType) async {
    final db = await _dbService.database;
    await db.delete('widget_filter', 
      where: 'widget_key = ? AND target_id = ? AND target_type = ?', 
      whereArgs: [widgetKey, targetId, targetType]
    );
  }

  Future<void> setFilters(String widgetKey, List<WidgetFilter> filters) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete('widget_filter', where: 'widget_key = ?', whereArgs: [widgetKey]);
      for (final filter in filters) {
        await txn.insert('widget_filter', filter.toMap());
      }
    });
  }

  Future<Map<String, List<int>>> getExcludedIds(String widgetKey) async {
    final filters = await getFiltersForWidget(widgetKey);
    final categories = <int>[];
    final subcategories = <int>[];

    for (final f in filters) {
      if (f.filterType == 'EXCLUDE') {
        if (f.targetType == 'CATEGORY') categories.add(f.targetId);
        else subcategories.add(f.targetId);
      }
    }

    return {
      'category_ids': categories,
      'subcategory_ids': subcategories,
    };
  }
}
