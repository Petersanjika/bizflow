import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/format_utils.dart';
import '../../database/bizflow_db.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final String purchaseId;
  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchaseDetail(widget.purchaseId);
      context.read<SupplierProvider>().loadSuppliers();
      context.read<ProductProvider>().loadProducts();
    });
  }

  String _supplierName(String? supplierId, List<Supplier> suppliers) {
    if (supplierId == null) return 'Walk-in';
    final supplier = suppliers.where((s) => s.id == supplierId).firstOrNull;
    return supplier?.name ?? 'Walk-in';
  }

  String _productName(String productId, List<Product> products) {
    final product = products.where((p) => p.id == productId).firstOrNull;
    return product?.name ?? 'Unknown';
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purchase'),
        content: const Text('This will revert stock changes. Continue?'),
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
    if (confirmed == true && mounted) {
      await context.read<PurchaseProvider>().deletePurchase(widget.purchaseId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: Consumer3<PurchaseProvider, SupplierProvider, ProductProvider>(
        builder: (context, purchaseProvider, supplierProvider, productProvider, _) {
          final purchase = purchaseProvider.selectedPurchase;
          if (purchase == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = purchaseProvider.selectedPurchaseItems;
          final expenses = purchaseProvider.selectedExpenses;

          double itemsTotal = items.fold(0, (sum, i) => sum + (i.quantity * i.unitPrice));
          double expensesTotal = expenses.fold(0, (sum, e) => sum + e.amount);
          double grandTotal = itemsTotal + expensesTotal;

          return RefreshIndicator(
            onRefresh: () => purchaseProvider.loadPurchaseDetail(widget.purchaseId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _row('Date', FormatUtils.date(purchase.purchaseDate)),
                          _row('Supplier', _supplierName(purchase.supplierId, supplierProvider.suppliers)),
                          if (purchase.notes != null) _row('Notes', purchase.notes!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Items', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (items.isEmpty)
                            const Text('No items', style: TextStyle(color: Colors.grey))
                          else
                            ...items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(_productName(item.productId, productProvider.products)),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text('x${item.quantity}', textAlign: TextAlign.center),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(FormatUtils.currency(item.unitPrice), textAlign: TextAlign.right),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      FormatUtils.currency(item.quantity * item.unitPrice),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(FormatUtils.currency(itemsTotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expenses', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          if (expenses.isEmpty)
                            const Text('No expenses', style: TextStyle(color: Colors.grey))
                          else
                            ...expenses.map((exp) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(exp.category)),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      FormatUtils.currency(exp.amount),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          if (expenses.isNotEmpty) ...[
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(FormatUtils.currency(expensesTotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _totalRow('Items', FormatUtils.currency(itemsTotal)),
                          const SizedBox(height: 4),
                          _totalRow('Expenses', FormatUtils.currency(expensesTotal)),
                          const Divider(thickness: 2),
                          _totalRow('GRAND TOTAL', FormatUtils.currency(grandTotal)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Delete Purchase', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
