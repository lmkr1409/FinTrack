import '../models/category.dart';
import 'base_repository.dart';

class CategoryRepository extends BaseRepository<Category> {
  @override
  String get tableName => 'category';

  @override
  String get primaryKey => 'category_id';

  @override
  Category fromMap(Map<String, dynamic> map) => Category.fromMap(map);

  Future<List<Category>> getAllSorted() =>
      getAll(orderBy: 'priority ASC, category_name ASC');

  Future<int> insertCategory(Category category) => insert(category.toMap());

  Future<int> updateCategory(Category category) =>
      update(category.id!, category.toMap());

  Future<int> deleteCategory(int id) => delete(id);
}
