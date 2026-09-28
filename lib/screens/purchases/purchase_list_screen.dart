import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/format_utils.dart';
import '../../database/bizflow_db.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/supplier_provider.dart';
import 'purchase_form_screen.dart';
import 'purchase_detail_screen.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  String _supplierName(String? supplierId, List<Supplier> suppliers) {
    if (supplierId == null) return 'Walk-in';
    final supplier = suppliers.where((s) => s.id == supplierId).firstOrNull;
    return supplier?.name ?? 'Walk-in';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History')),
      body: Consumer2<PurchaseProvider, SupplierProvider>(
        builder: (context, purchaseProvider, supplierProvider, _) {
          if (purchaseProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final purchases = purchaseProvider.purchases;
          if (purchases.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => purchaseProvider.loadPurchases(),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.add_shopping_cart, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No purchases yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        Text('Tap + to create a purchase', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => purchaseProvider.loadPurchases(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final purchase = purchases[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(_supplierName(purchase.supplierId, supplierProvider.suppliers)),
                    subtitle: Text(FormatUtils.date(purchase.purchaseDate)),
                    trailing: Text(
                      FormatUtils.currency(purchase.totalCost),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PurchaseDetailScreen(purchaseId: purchase.id),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseFormScreen()),
          );
          if (result == true && mounted) {
            context.read<PurchaseProvider>().loadPurchases();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
