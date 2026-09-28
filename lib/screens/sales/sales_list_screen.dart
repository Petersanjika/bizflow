import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/format_utils.dart';
import '../../database/bizflow_db.dart';
import '../../providers/customer_provider.dart';
import '../../providers/sale_provider.dart';
import 'sale_detail_screen.dart';
import 'sale_form_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SaleFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
      ),
      body: Consumer2<SaleProvider, CustomerProvider>(
        builder: (context, saleProvider, customerProvider, _) {
          if (saleProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final sales = saleProvider.sales;
          if (sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No sales yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Tap + to create a sale',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => saleProvider.loadSales(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: sales.length,
              itemBuilder: (context, index) {
                final sale = sales[index];
                final customerName = sale.customerId != null
                    ? customerProvider.customers
                            .where((c) => c.id == sale.customerId)
                            .map((c) => c.name)
                            .firstOrNull ?? 'Unknown'
                    : 'Walk-in';
                return _SaleCard(sale: sale, customerName: customerName);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Sale sale;
  final String customerName;

  const _SaleCard({required this.sale, required this.customerName});

  @override
  Widget build(BuildContext context) {
    final isCash = sale.saleType == 'cash';
    final typeColor = isCash ? Colors.green : Colors.blue;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(customerName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(FormatUtils.date(sale.saleDate)),
        leading: CircleAvatar(
          backgroundColor: typeColor.withAlpha(30),
          child: Icon(
            isCash ? Icons.money : Icons.credit_card,
            color: typeColor,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(FormatUtils.currency(sale.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isCash ? 'Cash' : 'Credit',
                style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SaleDetailScreen(saleId: sale.id)),
        ),
      ),
    );
  }
}
