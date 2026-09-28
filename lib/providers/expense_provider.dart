import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../core/utils/id_generator.dart';
import '../database/bizflow_db.dart';

class ExpenseProvider extends ChangeNotifier {
  final BizflowDb _db;
  List<Expense> _expenses = [];
  bool _loading = true;

  List<Expense> get expenses => _expenses;
  bool get loading => _loading;

  ExpenseProvider(this._db);

  Future<void> loadExpenses() async {
    _loading = true;
    notifyListeners();
    _expenses = await (_db.select(_db.expenses)
      ..orderBy([(e) => OrderingTerm.desc(e.date)]))
      .get();
    _loading = false;
    notifyListeners();
  }

  Future<void> createExpense({
    required String category,
    required double amount,
    String? description,
    required DateTime date,
  }) async {
    final id = IdGenerator.newId();
    await _db.into(_db.expenses).insert(ExpensesCompanion.insert(
      id: id,
      category: category,
      amount: amount,
      description: Value<String?>(description),
      date: date,
    ));
    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
      id: IdGenerator.newId(),
      type: 'expense',
      referenceId: Value<String?>(id),
      amount: -amount,
      date: date,
      description: Value<String?>('$category: ${description ?? ''}'),
    ));
    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await (_db.delete(_db.expenses)..where((e) => e.id.equals(id))).go();
    await (_db.delete(_db.transactions)
      ..where((t) => t.referenceId.equals(id) & t.type.equals('expense')))
      .go();
    await loadExpenses();
  }
}
