import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/format_utils.dart';
import '../../database/bizflow_db.dart';
import '../../providers/customer_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/sale_provider.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saleProvider = context.read<SaleProvider>();
      await saleProvider.loadSaleDetail(widget.saleId);
      final creditAccount = saleProvider.selectedCreditAccount;
      if (creditAccount != null) {
        final paymentProvider = context.read<PaymentProvider>();
        await paymentProvider.loadPaymentSchedule(creditAccount.id);
        await paymentProvider.loadPayments();
      }
    });
  }

  Future<void> _deleteSale() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sale'),
        content: const Text(
            'Are you sure you want to delete this sale? This will restore stock and cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<SaleProvider>().deleteSale(widget.saleId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteSale,
          ),
        ],
      ),
      body: Consumer2<SaleProvider, CustomerProvider>(
        builder: (context, saleProvider, customerProvider, _) {
          if (saleProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final sale = saleProvider.selectedSale;
          if (sale == null) {
            return const Center(child: Text('Sale not found'));
          }

          final items = saleProvider.selectedSaleItems;
          final creditAccount = saleProvider.selectedCreditAccount;
          final creditAccountId = creditAccount?.id;

          final customerName = sale.customerId != null
              ? customerProvider.customers
                      .where((c) => c.id == sale.customerId)
                      .map((c) => c.name)
                      .firstOrNull ?? 'Unknown'
              : 'Walk-in';

          return RefreshIndicator(
            onRefresh: () => saleProvider.loadSaleDetail(widget.saleId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(sale, customerName),
                const SizedBox(height: 16),
                _buildItemsCard(items),
                if (creditAccount != null) ...[
                  const SizedBox(height: 16),
                  _buildCreditCard(creditAccount),
                  const SizedBox(height: 16),
                  _buildScheduleCard(),
                  const SizedBox(height: 16),
                  _buildPaymentsCard(creditAccountId!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(Sale sale, String customerName) {
    final isCash = sale.saleType == 'cash';
    final typeColor = isCash ? Colors.green : Colors.blue;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('Customer', customerName),
            const Divider(height: 16),
            _infoRow('Date', FormatUtils.date(sale.saleDate)),
            const Divider(height: 16),
            _infoRow('Type', isCash ? 'Cash' : 'Credit'),
            const Divider(height: 16),
            _infoRow('Total', FormatUtils.currency(sale.totalAmount)),
            if (sale.saleType == 'credit') ...[
              const Divider(height: 16),
              _infoRow('Deposit', FormatUtils.currency(sale.deposit)),
              const Divider(height: 16),
              _infoRow('Balance', FormatUtils.currency(sale.balance)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(List<SaleItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Item #${items.indexOf(item) + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 15)),
                          Text(
                              '${item.quantity} x ${FormatUtils.currency(item.unitPrice)}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                      Text(FormatUtils.currency(item.quantity * item.unitPrice),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(CreditAccount account) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow('Balance', FormatUtils.currency(account.balance)),
            const Divider(height: 16),
            _infoRow('Payment Frequency',
                account.paymentFrequency[0].toUpperCase() +
                    account.paymentFrequency.substring(1)),
            const Divider(height: 16),
            _infoRow('Installment', FormatUtils.currency(account.installmentAmount)),
            const Divider(height: 16),
            _infoRow('Total Payments', '${account.numberOfPayments}'),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        final schedules = paymentProvider.schedules;
        if (schedules.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No payment schedule found',
                  style: TextStyle(color: Colors.grey[600])),
            ),
          );
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment Schedule',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...schedules.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(FormatUtils.date(s.dueDate)),
                          ),
                          Text(FormatUtils.currency(s.expectedAmount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          _scheduleBadge(s.status),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _scheduleBadge(String status) {
    Color color;
    switch (status) {
      case 'paid':
        color = Colors.green;
      case 'overdue':
        color = Colors.red;
      case 'due':
        color = Colors.orange;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildPaymentsCard(String creditAccountId) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        final payments = paymentProvider.payments
            .where((p) => p.creditAccountId == creditAccountId)
            .toList();
        if (payments.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No payments received yet',
                  style: TextStyle(color: Colors.grey[600])),
            ),
          );
        }
        double totalPaid = 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payments Received',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...payments.map((p) {
                  totalPaid += p.amount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(FormatUtils.date(p.paymentDate)),
                        Text(FormatUtils.currency(p.amount),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(FormatUtils.currency(totalPaid),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
