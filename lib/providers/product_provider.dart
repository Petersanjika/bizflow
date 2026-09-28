import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../core/utils/id_generator.dart';
import '../database/bizflow_db.dart';

class ProductProvider extends ChangeNotifier {
  final BizflowDb _db;
  List<Product> _products = [];
  Product? _selectedProduct;
  bool _loading = true;
  final Map<String, double> _allocatedExpenses = {};

  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  bool get loading => _loading;
  bool get hasProducts => _products.isNotEmpty;

  double trueCost(Product product) {
    final allocated = _allocatedExpenses[product.id] ?? 0;
    return product.purchasePrice + allocated;
  }

  ProductProvider(this._db);

  Future<void> loadProducts() async {
    _loading = true;
    notifyListeners();
    _products = await _db.select(_db.products).get();
    _loading = false;
    notifyListeners();
  }

  Future<void> createProduct({
    required String name,
    String? categoryId,
    String? brand,
    String? model,
    String? serialImei,
    required double purchasePrice,
    required double cashPrice,
    required double creditPrice,
    int currentStock = 0,
    List<String>? images,
    String? supplierId,
    DateTime? purchaseDate,
    String status = 'active',
  }) async {
    final id = IdGenerator.newId();
    final product = ProductsCompanion.insert(
      id: id,
      name: name,
      categoryId: Value<String?>(categoryId),
      brand: Value<String?>(brand),
      model: Value<String?>(model),
      serialImei: Value<String?>(serialImei),
      purchasePrice: purchasePrice,
      cashPrice: cashPrice,
      creditPrice: creditPrice,
      currentStock: Value(currentStock),
      imagesPath: Value<String?>(images != null ? images.join('||') : null),
      supplierId: Value<String?>(supplierId),
      purchaseDate: Value<DateTime?>(purchaseDate),
      status: Value(status),
    );
    await _db.into(_db.products).insert(product);
    await loadProducts();
  }

  Future<void> updateProduct(
    Product product, {
    String? name,
    String? categoryId,
    String? brand,
    String? model,
    String? serialImei,
    double? purchasePrice,
    double? cashPrice,
    double? creditPrice,
    int? currentStock,
    List<String>? images,
    String? supplierId,
    DateTime? purchaseDate,
    String? status,
  }) async {
    await _db.update(_db.products).replace(
      product.copyWith(
        name: name,
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
        brand: brand != null ? Value(brand) : const Value.absent(),
        model: model != null ? Value(model) : const Value.absent(),
        serialImei: serialImei != null ? Value(serialImei) : const Value.absent(),
        purchasePrice: purchasePrice,
        cashPrice: cashPrice,
        creditPrice: creditPrice,
        currentStock: currentStock,
        imagesPath: images != null ? Value(images.join('||')) : const Value.absent(),
        supplierId: supplierId != null ? Value(supplierId) : const Value.absent(),
        purchaseDate: purchaseDate != null ? Value(purchaseDate) : const Value.absent(),
        status: status,
      ),
    );
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await (_db.delete(_db.products)..where((p) => p.id.equals(id))).go();
    await loadProducts();
  }

  Future<Product?> getProduct(String id) async {
    _loading = true;
    notifyListeners();
    final query = _db.select(_db.products)..where((p) => p.id.equals(id));
    _selectedProduct = await query.getSingleOrNull();
    _loading = false;
    notifyListeners();
    return _selectedProduct;
  }

  Future<List<Product>> searchProducts(String query) async {
    final pattern = '%$query%';
    return await (_db.select(_db.products)
      ..where((p) =>
          p.name.like(pattern) |
          p.brand.like(pattern) |
          p.model.like(pattern) |
          p.serialImei.like(pattern)))
        .get();
  }

  void setAllocatedExpenses(String productId, double amount) {
    _allocatedExpenses[productId] = amount;
    notifyListeners();
  }
}
