import 'package:flutter/foundation.dart' hide Category;
import 'package:drift/drift.dart';
import '../core/utils/id_generator.dart';
import '../database/bizflow_db.dart';

class CategoryProvider extends ChangeNotifier {
  final BizflowDb _db;
  List<Category> _categories = [];
  bool _loading = true;

  List<Category> get categories => _categories;
  bool get loading => _loading;

  CategoryProvider(this._db);

  Future<void> loadCategories() async {
    _loading = true;
    notifyListeners();
    _categories = await _db.select(_db.categories).get();
    _loading = false;
    notifyListeners();
  }

  Future<void> createCategory({
    required String name,
    String? description,
  }) async {
    final id = IdGenerator.newId();
    final category = CategoriesCompanion.insert(
      id: id,
      name: name,
      description: Value<String?>(description),
    );
    await _db.into(_db.categories).insert(category);
    await loadCategories();
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    String? description,
  }) async {
    final existing = _categories.where((c) => c.id == id).firstOrNull;
    if (existing == null) return;
    await _db.update(_db.categories).replace(
      existing.copyWith(
        name: name,
        description: Value<String?>(description),
      ),
    );
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
    await loadCategories();
  }
}
