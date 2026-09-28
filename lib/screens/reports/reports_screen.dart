import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DashboardData _data = DashboardData();
  Map<String, double> _expenseBreakdown = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReports());
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    await Future.wait([
      context.read<DashboardProvider>().load(),
      context.read<ExpenseProvider>().loadExpenses(),
    ]);
    final expenses = context.read<ExpenseProvider>().expenses;
    final breakdown = <String, double>{};
    for (final e in expenses) {
      breakdown[e.category] = (breakdown[e.category] ?? 0) + e.amount;
    }
    setState(() {
      _data = context.read<DashboardProvider>().data;
      _expenseBreakdown = breakdown;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _bigNumberCard('Total Expenditure', FormatUtils.currency(_data.expenditure), Colors.red),
                  const SizedBox(height: 8),
                  _bigNumberCard('Profit', FormatUtils.currency(_data.profit), _data.profit >= 0 ? Colors.green : Colors.red),
                  const SizedBox(height: 16),
                  if (_expenseBreakdown.isNotEmpty) ...[
                    Text('Expense Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    ..._expenseBreakdown.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _summaryCard(e.key, FormatUtils.currency(e.value), _iconForCategory(e.key)),
                    )),
                    const SizedBox(height: 16),
                  ],
                  _summaryCard('Cash Received', FormatUtils.currency(_data.cashReceived), Icons.money),
                  const SizedBox(height: 8),
                  _summaryCard('Customers Owing', FormatUtils.currency(_data.customersOwing), Icons.people),
                  const SizedBox(height: 8),
                  _summaryCard('Stock Value', FormatUtils.currency(_data.stockValue), Icons.inventory),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _statRow('Total Sales', '${_data.activeCreditSales + _data.overdueCustomers}'),
                          const Divider(height: 16),
                          _statRow('Active Credit Accounts', '${_data.activeCreditSales}'),
                          const Divider(height: 16),
                          _statRow('Overdue Customers', '${_data.overdueCustomers}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Transport':
        return Icons.local_shipping;
      case 'Food':
        return Icons.fastfood;
      case 'Packaging':
        return Icons.inventory_2;
      default:
        return Icons.receipt;
    }
  }

  Widget _bigNumberCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            ),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
