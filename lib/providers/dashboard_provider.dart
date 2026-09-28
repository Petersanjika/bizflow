import 'package:flutter/foundation.dart';
import '../database/bizflow_db.dart';

class DashboardData {
  final double revenue;
  final double expenditure;
  final double profit;
  final double cashReceived;
  final double customersOwing;
  final double stockValue;
  final int activeCreditSales;
  final int overdueCustomers;

  DashboardData({
    this.revenue = 0,
    this.expenditure = 0,
    this.profit = 0,
    this.cashReceived = 0,
    this.customersOwing = 0,
    this.stockValue = 0,
    this.activeCreditSales = 0,
    this.overdueCustomers = 0,
  });
}

class DashboardProvider extends ChangeNotifier {
  final BizflowDb _db;
  DashboardData _data = DashboardData();
  bool _loading = true;

  DashboardData get data => _data;
  bool get loading => _loading;

  DashboardProvider(this._db);

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final transactions = await _db.select(_db.transactions).get();
      double revenue = 0;
      double expenditure = 0;
      for (final t in transactions) {
        if (t.amount > 0) {
          revenue += t.amount;
        } else {
          expenditure += t.amount.abs();
        }
      }

      final creditAccounts = await _db.select(_db.creditAccounts).get();
      double customersOwing = 0;
      int activeCount = 0;
      for (final ca in creditAccounts) {
        if (ca.status == 'active') {
          customersOwing += ca.balance;
          activeCount++;
        }
      }

      final schedules = await _db.select(_db.paymentSchedules).get();
      final overdueCount = schedules.where((s) => s.status == 'overdue').length;

      final products = await _db.select(_db.products).get();
      double stockValue = 0;
      for (final p in products) {
        stockValue += p.purchasePrice * p.currentStock;
      }

      double cashReceived = 0;
      final payments = await _db.select(_db.payments).get();
      for (final p in payments) {
        cashReceived += p.amount;
      }

      _data = DashboardData(
        revenue: revenue,
        expenditure: expenditure,
        profit: revenue - expenditure,
        cashReceived: cashReceived,
        customersOwing: customersOwing,
        stockValue: stockValue,
        activeCreditSales: activeCount,
        overdueCustomers: overdueCount,
      );
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }
}
