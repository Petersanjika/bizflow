import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../core/utils/id_generator.dart';
import '../database/bizflow_db.dart';

class PaymentProvider extends ChangeNotifier {
  final BizflowDb _db;
  List<Payment> _payments = [];
  List<PaymentSchedule> _schedules = [];
  List<CreditAccount> _creditAccounts = [];
  CreditAccount? _selectedCreditAccount;
  bool _loading = true;

  List<Payment> get payments => _payments;
  List<PaymentSchedule> get schedules => _schedules;
  List<CreditAccount> get creditAccounts => _creditAccounts;
  CreditAccount? get selectedCreditAccount => _selectedCreditAccount;
  bool get loading => _loading;

  PaymentProvider(this._db);

  Future<void> loadPayments() async {
    _loading = true;
    notifyListeners();
    _payments = await (_db.select(_db.payments)
      ..orderBy([(p) => OrderingTerm(expression: p.paymentDate, mode: OrderingMode.desc)])
    ).get();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadPaymentsForCustomer(String customerId) async {
    _loading = true;
    notifyListeners();
    _payments = await ((_db.select(_db.payments)
      ..where((p) => p.customerId.equals(customerId))
      ..orderBy([(p) => OrderingTerm(expression: p.paymentDate, mode: OrderingMode.desc)])
    )).get();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadPaymentSchedule(String creditAccountId) async {
    _loading = true;
    notifyListeners();
    _schedules = await ((_db.select(_db.paymentSchedules)
      ..where((s) => s.creditAccountId.equals(creditAccountId))
      ..orderBy([(s) => OrderingTerm(expression: s.dueDate, mode: OrderingMode.asc)])
    )).get();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadCreditAccounts() async {
    _loading = true;
    notifyListeners();
    _creditAccounts = await _db.select(_db.creditAccounts).get();
    _loading = false;
    notifyListeners();
  }

  Future<void> recordPayment({
    required String customerId,
    required String creditAccountId,
    required double amount,
    required DateTime paymentDate,
    double? expectedAmount,
    String? notes,
  }) async {
    final paymentId = IdGenerator.newId();
    final payment = PaymentsCompanion.insert(
      id: paymentId,
      customerId: customerId,
      creditAccountId: const Value.absent(),
      amount: amount,
      paymentDate: paymentDate,
      expectedAmount: expectedAmount != null ? Value(expectedAmount) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
    );
    await _db.into(_db.payments).insert(payment);

    final account = await (_db.select(_db.creditAccounts)
      ..where((c) => c.id.equals(creditAccountId))
    ).getSingle();

    final newBalance = account.balance - amount;
    final newStatus = newBalance <= 0 ? 'completed' : account.status;

    await (_db.update(_db.creditAccounts)
      ..where((c) => c.id.equals(creditAccountId))
    ).write(CreditAccountsCompanion(
      balance: Value(newBalance),
      status: Value(newStatus),
    ));

    final upcoming = await ((_db.select(_db.paymentSchedules)
      ..where((s) => s.creditAccountId.equals(creditAccountId) & s.status.equals('upcoming'))
      ..orderBy([(s) => OrderingTerm(expression: s.dueDate, mode: OrderingMode.asc)])
      ..limit(1)
    )).get();

    if (upcoming.isNotEmpty) {
      await (_db.update(_db.paymentSchedules)
        ..where((s) => s.id.equals(upcoming.first.id))
      ).write(PaymentSchedulesCompanion(
        status: Value('paid'),
      ));
    }

    final txnId = IdGenerator.newId();
    await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
      id: txnId,
      type: 'payment',
      referenceId: Value<String?>(creditAccountId),
      amount: amount,
      date: paymentDate,
      description: Value<String?>('Payment recorded for credit account $creditAccountId'),
    ));

    await loadPaymentsForCustomer(customerId);
    await loadPaymentSchedule(creditAccountId);
    await loadCreditAccounts();

    notifyListeners();
  }

  Future<CreditAccount?> getCreditAccountStatus(String creditAccountId) async {
    final results = await ((_db.select(_db.creditAccounts)
      ..where((c) => c.id.equals(creditAccountId))
    )).get();
    _selectedCreditAccount = results.isNotEmpty ? results.first : null;
    notifyListeners();
    return _selectedCreditAccount;
  }

  Future<List<PaymentSchedule>> getScheduleStatus(String creditAccountId) async {
    final results = await ((_db.select(_db.paymentSchedules)
      ..where((s) => s.creditAccountId.equals(creditAccountId))
      ..orderBy([(s) => OrderingTerm(expression: s.dueDate, mode: OrderingMode.asc)])
    )).get();
    _schedules = results;
    notifyListeners();
    return _schedules;
  }

  Future<void> checkOverduePayments() async {
    final now = DateTime.now();
    final upcoming = await (_db.select(_db.paymentSchedules)
      ..where((s) => s.status.equals('upcoming'))
    ).get();
    final overdue = upcoming.where((s) => s.dueDate.isBefore(now)).toList();

    for (final schedule in overdue) {
      await (_db.update(_db.paymentSchedules)
        ..where((s) => s.id.equals(schedule.id))
      ).write(PaymentSchedulesCompanion(
        status: Value('overdue'),
      ));
    }

    if (overdue.isNotEmpty) {
      notifyListeners();
    }
  }
}
