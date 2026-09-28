import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import '../../database/bizflow_db.dart';
import '../../providers/database_provider.dart';
import '../../providers/customer_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../screens/payments/payment_form_screen.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _customer;
  List<Payment> _payments = [];
  List<CreditAccount> _creditAccounts = [];
  bool _loading = true;

  BizflowDb get _db => context.read<DatabaseProvider>().db;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final db = _db;
      final customerResults = await (db.select(db.customers)
        ..where((c) => c.id.equals(widget.customerId))).get();
      final payments = await (db.select(db.payments)
        ..where((p) => p.customerId.equals(widget.customerId))
        ..orderBy([(p) => OrderingTerm(expression: p.paymentDate, mode: OrderingMode.desc)])
      ).get();
      final creditAccounts = await (db.select(db.creditAccounts)
        ..where((ca) => ca.customerId.equals(widget.customerId) & ca.status.equals('active'))
      ).get();

      if (mounted) {
        setState(() {
          _customer = customerResults.isNotEmpty ? customerResults.first : null;
          _payments = payments;
          _creditAccounts = creditAccounts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _outstandingBalance =>
      _creditAccounts.fold<double>(0, (sum, ca) => sum + ca.balance);

  Future<void> _deleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Delete ${_customer?.name ?? 'this customer'}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<CustomerProvider>().deleteCustomer(widget.customerId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?.name ?? 'Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: _customer)),
              );
              if (mounted) _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _customer != null ? _deleteCustomer : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _customer == null
              ? const Center(child: Text('Customer not found'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildCustomerCard(),
                      const SizedBox(height: 12),
                      _buildBalanceCard(),
                      const SizedBox(height: 20),
                      if (_creditAccounts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Credit Accounts', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        ..._creditAccounts.map(_buildCreditAccountCard),
                        const SizedBox(height: 16),
                      ],
                      if (_payments.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Recent Payments', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        ..._payments.take(5).map(_buildPaymentCard),
                      ],
                      if (_payments.isEmpty && _creditAccounts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('No credit or payment history yet', style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creditAccounts.isNotEmpty
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentFormScreen(customerId: widget.customerId)),
              ).then((_) => _loadData())
            : null,
        icon: const Icon(Icons.payments),
        label: const Text('Record Payment'),
      ),
    );
  }

  Widget _buildCustomerCard() {
    final c = _customer!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryColor.withAlpha(30),
              backgroundImage: c.imagePath != null ? FileImage(File(c.imagePath!)) : null,
              child: c.imagePath == null
                  ? Text(c.name[0].toUpperCase(),
                      style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 22))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(c.phone, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ]),
                  if (c.address != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(child: Text(c.address!, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      color: _outstandingBalance > 0
          ? AppTheme.warningColor.withAlpha(20)
          : AppTheme.successColor.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(
              _outstandingBalance > 0 ? Icons.warning_amber_rounded : Icons.check_circle,
              color: _outstandingBalance > 0 ? AppTheme.warningColor : AppTheme.successColor,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outstanding Balance',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(
                    FormatUtils.currency(_outstandingBalance),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _outstandingBalance > 0 ? AppTheme.warningColor : AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditAccountCard(CreditAccount ca) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text('Balance: ${FormatUtils.currency(ca.balance)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Text('${FormatUtils.currency(ca.installmentAmount)} / ${ca.paymentFrequency}'),
        trailing: Chip(
          label: Text(ca.status.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white)),
          backgroundColor: ca.status == 'active' ? AppTheme.infoColor : AppTheme.successColor,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.successColor.withAlpha(30),
          child: const Icon(Icons.payments, color: AppTheme.successColor, size: 16),
        ),
        title: Text(FormatUtils.currency(p.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(FormatUtils.date(p.paymentDate), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ),
    );
  }
}
