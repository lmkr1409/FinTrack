import '../models/sub_category.dart';
import 'base_repository.dart';

class SubCategoryRepository extends BaseRepository<SubCategory> {
  @override
  String get tableName => 'sub_category';

  @override
  String get primaryKey => 'subcategory_id';

  @override
  SubCategory fromMap(Map<String, dynamic> map) => SubCategory.fromMap(map);

  Future<List<SubCategory>> getAllSorted() =>
      getAll(orderBy: 'priority ASC, subcategory_name ASC');

  Future<List<SubCategory>> getByCategoryId(int categoryId) =>
      query(where: 'category_id = ?', whereArgs: [categoryId], orderBy: 'priority ASC');

  Future<int> insertSubCategory(SubCategory subCategory) =>
      insert(subCategory.toMap());

  Future<int> updateSubCategory(SubCategory subCategory) =>
      update(subCategory.id!, subCategory.toMap());

  Future<int> deleteSubCategory(int id) => delete(id);
}
