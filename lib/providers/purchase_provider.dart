import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../core/utils/id_generator.dart';
import '../database/bizflow_db.dart';

class PurchaseItemInput {
  final String productId;
  final int quantity;
  final double unitPrice;
  PurchaseItemInput(this.productId, this.quantity, this.unitPrice);
}

class ExpenseInput {
  final String category;
  final double amount;
  final String? description;
  ExpenseInput(this.category, this.amount, this.description);
}

class PurchaseProvider extends ChangeNotifier {
  final BizflowDb _db;
  List<Purchase> _purchases = [];
  Purchase? _selectedPurchase;
  List<PurchaseItem> _selectedPurchaseItems = [];
  List<Expense> _selectedExpenses = [];
  bool _loading = true;

  List<Purchase> get purchases => _purchases;
  Purchase? get selectedPurchase => _selectedPurchase;
  List<PurchaseItem> get selectedPurchaseItems => _selectedPurchaseItems;
  List<Expense> get selectedExpenses => _selectedExpenses;
  bool get loading => _loading;

  PurchaseProvider(this._db);

  Future<void> loadPurchases() async {
    _loading = true;
    notifyListeners();
    _purchases = await (_db.select(_db.purchases)
      ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
      .get();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadPurchaseDetail(String id) async {
    _selectedPurchase = await (_db.select(_db.purchases)
      ..where((p) => p.id.equals(id)))
      .getSingleOrNull();
    _selectedPurchaseItems = await (_db.select(_db.purchaseItems)
      ..where((pi) => pi.purchaseId.equals(id)))
      .get();
    _selectedExpenses = await (_db.select(_db.expenses)
      ..where((e) => e.purchaseId.equals(id)))
      .get();
    notifyListeners();
  }

  Future<void> createPurchase({
    required String? supplierId,
    required DateTime purchaseDate,
    required List<PurchaseItemInput> items,
    required List<ExpenseInput> expenses,
    String? notes,
  }) async {
    final purchaseId = IdGenerator.newId();

    double itemsTotal = 0;
    for (final item in items) {
      itemsTotal += item.quantity * item.unitPrice;
    }

    double expensesTotal = 0;
    for (final exp in expenses) {
      expensesTotal += exp.amount;
    }

    final totalCost = itemsTotal + expensesTotal;

    await _db.into(_db.purchases).insert(PurchasesCompanion.insert(
      id: purchaseId,
      supplierId: supplierId != null ? Value(supplierId) : const Value.absent(),
      purchaseDate: purchaseDate,
      totalCost: totalCost,
      notes: notes != null ? Value(notes) : const Value.absent(),
    ));

    for (final item in items) {
      await _db.into(_db.purchaseItems).insert(PurchaseItemsCompanion.insert(
        id: IdGenerator.newId(),
        purchaseId: purchaseId,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      ));

      final product = await (_db.select(_db.products)
        ..where((p) => p.id.equals(item.productId)))
        .getSingle();

      final itemValue = item.quantity * item.unitPrice;
      final allocatedExpense = itemsTotal > 0
          ? (itemValue / itemsTotal) * expensesTotal
          : 0.0;
      final costPerUnit = item.unitPrice + (allocatedExpense / item.quantity);

      await (_db.update(_db.products)
        ..where((p) => p.id.equals(item.productId)))
        .write(ProductsCompanion(
          currentStock: Value(product.currentStock + item.quantity),
          purchasePrice: Value(costPerUnit),
        ));
    }

    for (final exp in expenses) {
      await _db.into(_db.expenses).insert(ExpensesCompanion.insert(
        id: IdGenerator.newId(),
        category: exp.category,
        amount: exp.amount,
        description: Value<String?>(exp.description),
        date: purchaseDate,
        purchaseId: Value<String?>(purchaseId),
      ));
    }

    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
      id: IdGenerator.newId(),
      type: 'purchase',
      referenceId: Value<String?>(purchaseId),
      amount: -totalCost,
      date: purchaseDate,
      description: Value<String?>(notes),
    ));

    await loadPurchases();
  }

  Future<void> deletePurchase(String id) async {
    final purchase = await (_db.select(_db.purchases)
      ..where((p) => p.id.equals(id)))
      .getSingleOrNull();

    if (purchase == null) {
      await loadPurchases();
      return;
    }

    final items = await (_db.select(_db.purchaseItems)
      ..where((pi) => pi.purchaseId.equals(id)))
      .get();

    for (final item in items) {
      final product = await (_db.select(_db.products)
        ..where((p) => p.id.equals(item.productId)))
        .getSingleOrNull();

      if (product != null) {
        await (_db.update(_db.products)
          ..where((p) => p.id.equals(item.productId)))
          .write(ProductsCompanion(
            currentStock: Value(product.currentStock - item.quantity),
          ));
      }
    }

    await (_db.delete(_db.purchaseItems)
      ..where((pi) => pi.purchaseId.equals(id)))
      .go();

    await (_db.delete(_db.expenses)
      ..where((e) => e.purchaseId.equals(id)))
      .go();

    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
      id: IdGenerator.newId(),
      type: 'purchase',
      referenceId: Value<String?>(id),
      amount: purchase.totalCost,
      date: DateTime.now(),
      description: Value('Purchase deleted - $id'),
    ));

    await (_db.delete(_db.purchases)
      ..where((p) => p.id.equals(id)))
      .go();

    await loadPurchases();
  }
}
