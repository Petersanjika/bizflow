import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supplier_provider.dart';
import 'supplier_form_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    final suppliers = provider.suppliers;

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : suppliers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No suppliers yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first supplier', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.loadSuppliers(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: suppliers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final supplier = suppliers[index];
                      return Card(
                        child: ListTile(
                          title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: supplier.phone != null ? Text(supplier.phone!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)) : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: supplier)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SupplierFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
