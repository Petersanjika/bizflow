import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../core/utils/id_generator.dart';
import '../database/bizflow_db.dart';

class SaleItemInput {
  final String productId;
  final int quantity;
  final double unitPrice;
  SaleItemInput(this.productId, this.quantity, this.unitPrice);
}

class CreditTermsInput {
  final double deposit;
  final String paymentFrequency;
  final double installmentAmount;
  final int numberOfPayments;
  CreditTermsInput(this.deposit, this.paymentFrequency, this.installmentAmount, this.numberOfPayments);
}

class SaleProvider extends ChangeNotifier {
  final BizflowDb _db;
  List<Sale> _sales = [];
  Sale? _selectedSale;
  List<SaleItem> _selectedSaleItems = [];
  CreditAccount? _selectedCreditAccount;
  bool _loading = true;

  List<Sale> get sales => _sales;
  Sale? get selectedSale => _selectedSale;
  List<SaleItem> get selectedSaleItems => _selectedSaleItems;
  CreditAccount? get selectedCreditAccount => _selectedCreditAccount;
  bool get loading => _loading;

  SaleProvider(this._db);

  Future<void> loadSales() async {
    _loading = true;
    notifyListeners();
    final query = _db.select(_db.sales)
      ..orderBy([(s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc)]);
    _sales = await query.get();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadSaleDetail(String id) async {
    _loading = true;
    notifyListeners();

    final saleQuery = _db.select(_db.sales)..where((s) => s.id.equals(id));
    _selectedSale = await saleQuery.getSingleOrNull();

    final itemsQuery = _db.select(_db.saleItems)..where((si) => si.saleId.equals(id));
    _selectedSaleItems = await itemsQuery.get();

    final creditQuery = _db.select(_db.creditAccounts)..where((ca) => ca.saleId.equals(id));
    _selectedCreditAccount = await creditQuery.getSingleOrNull();

    _loading = false;
    notifyListeners();
  }

  Future<void> createCashSale({
    required String? customerId,
    required DateTime saleDate,
    required List<SaleItemInput> items,
  }) async {
    double totalAmount = 0;
    for (final item in items) {
      totalAmount += item.quantity * item.unitPrice;
    }

    final saleId = IdGenerator.newId();

    final sale = SalesCompanion.insert(
      id: saleId,
      customerId: customerId != null ? Value(customerId) : const Value.absent(),
      saleDate: saleDate,
      saleType: 'cash',
      totalAmount: totalAmount,
    );
    await _db.into(_db.sales).insert(sale);

    for (final item in items) {
      final saleItem = SaleItemsCompanion.insert(
        id: IdGenerator.newId(),
        saleId: saleId,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      );
      await _db.into(_db.saleItems).insert(saleItem);

      final productQuery = _db.select(_db.products)..where((p) => p.id.equals(item.productId));
      final product = await productQuery.getSingleOrNull();
      if (product != null) {
        await _db.update(_db.products).replace(
          product.copyWith(currentStock: product.currentStock - item.quantity),
        );
      }
    }

    final transaction = TransactionsCompanion.insert(
      id: IdGenerator.newId(),
      type: 'cash_sale',
      referenceId: Value<String?>(saleId),
      amount: totalAmount,
      date: saleDate,
      description: Value<String?>(null),
    );
    await _db.into(_db.transactions).insert(transaction);

    await loadSales();
  }

  Future<void> createCreditSale({
    required String customerId,
    required DateTime saleDate,
    required List<SaleItemInput> items,
    required CreditTermsInput creditTerms,
  }) async {
    double totalAmount = 0;
    for (final item in items) {
      totalAmount += item.quantity * item.unitPrice;
    }

    final balance = totalAmount - creditTerms.deposit;
    final saleId = IdGenerator.newId();

    final sale = SalesCompanion.insert(
      id: saleId,
      customerId: Value(customerId),
      saleDate: saleDate,
      saleType: 'credit',
      totalAmount: totalAmount,
      deposit: Value(creditTerms.deposit),
      balance: Value(balance),
    );
    await _db.into(_db.sales).insert(sale);

    for (final item in items) {
      final saleItem = SaleItemsCompanion.insert(
        id: IdGenerator.newId(),
        saleId: saleId,
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      );
      await _db.into(_db.saleItems).insert(saleItem);

      final productQuery = _db.select(_db.products)..where((p) => p.id.equals(item.productId));
      final product = await productQuery.getSingleOrNull();
      if (product != null) {
        await _db.update(_db.products).replace(
          product.copyWith(currentStock: product.currentStock - item.quantity),
        );
      }
    }

    final creditAccountId = IdGenerator.newId();
    final creditAccount = CreditAccountsCompanion.insert(
      id: creditAccountId,
      saleId: saleId,
      customerId: customerId,
      totalAmount: totalAmount,
      deposit: creditTerms.deposit,
      balance: balance,
      paymentFrequency: creditTerms.paymentFrequency,
      installmentAmount: creditTerms.installmentAmount,
      numberOfPayments: creditTerms.numberOfPayments,
    );
    await _db.into(_db.creditAccounts).insert(creditAccount);

    for (int i = 0; i < creditTerms.numberOfPayments; i++) {
      DateTime dueDate;
      switch (creditTerms.paymentFrequency) {
        case 'weekly':
          dueDate = saleDate.add(Duration(days: 7 * (i + 1)));
          break;
        case 'biweekly':
          dueDate = saleDate.add(Duration(days: 14 * (i + 1)));
          break;
        case 'monthly':
          dueDate = DateTime(saleDate.year, saleDate.month + (i + 1), saleDate.day);
          break;
        default:
          dueDate = saleDate.add(Duration(days: 30 * (i + 1)));
      }

      final schedule = PaymentSchedulesCompanion.insert(
        id: IdGenerator.newId(),
        creditAccountId: creditAccountId,
        dueDate: dueDate,
        expectedAmount: creditTerms.installmentAmount,
      );
      await _db.into(_db.paymentSchedules).insert(schedule);
    }

    final transaction = TransactionsCompanion.insert(
      id: IdGenerator.newId(),
      type: 'credit_sale',
      referenceId: Value<String?>(saleId),
      amount: creditTerms.deposit,
      date: saleDate,
      description: Value<String?>(null),
    );
    await _db.into(_db.transactions).insert(transaction);

    await loadSales();
  }

  Future<void> deleteSale(String id) async {
    final itemsQuery = _db.select(_db.saleItems)..where((si) => si.saleId.equals(id));
    final items = await itemsQuery.get();

    for (final item in items) {
      final productQuery = _db.select(_db.products)..where((p) => p.id.equals(item.productId));
      final product = await productQuery.getSingleOrNull();
      if (product != null) {
        await _db.update(_db.products).replace(
          product.copyWith(currentStock: product.currentStock + item.quantity),
        );
      }
    }

    final creditQuery = _db.select(_db.creditAccounts)..where((ca) => ca.saleId.equals(id));
    final creditAccount = await creditQuery.getSingleOrNull();
    if (creditAccount != null) {
      await (_db.delete(_db.paymentSchedules)
        ..where((ps) => ps.creditAccountId.equals(creditAccount.id)))
        .go();
      await (_db.delete(_db.creditAccounts)..where((ca) => ca.saleId.equals(id))).go();
    }

    await (_db.delete(_db.saleItems)..where((si) => si.saleId.equals(id))).go();
    await (_db.delete(_db.sales)..where((s) => s.id.equals(id))).go();

    await loadSales();
  }
}
