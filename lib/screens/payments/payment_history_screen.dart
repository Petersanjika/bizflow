import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/format_utils.dart';
import '../../providers/payment_provider.dart';
import '../../providers/customer_provider.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String? customerId;

  const PaymentHistoryScreen({super.key, this.customerId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final paymentProvider = context.read<PaymentProvider>();
    if (widget.customerId != null) {
      await paymentProvider.loadPaymentsForCustomer(widget.customerId!);
    } else {
      await paymentProvider.loadPayments();
    }
    context.read<CustomerProvider>().loadCustomers();
  }

  String _customerName(Map<String, String> nameMap, String id) {
    return nameMap[id] ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final customers = context.watch<CustomerProvider>().customers;
    final nameMap = <String, String>{};
    for (final c in customers) {
      nameMap[c.id] = c.name;
    }
    final payments = provider.payments;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.payments_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No payments recorded', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            _customerName(nameMap, payment.customerId),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(FormatUtils.date(payment.paymentDate)),
                          trailing: Text(
                            FormatUtils.currency(payment.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
