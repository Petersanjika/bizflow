import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/format_utils.dart';
import '../../database/bizflow_db.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';

class _PurchaseItemInput {
  final String productId;
  String productName;
  int quantity;
  double unitPrice;
  _PurchaseItemInput({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });
  double get lineTotal => quantity * unitPrice;
}

class _ExpenseInput {
  String category;
  double amount;
  String? description;
  _ExpenseInput({
    required this.category,
    required this.amount,
    this.description,
  });
}

class PurchaseFormScreen extends StatefulWidget {
  const PurchaseFormScreen({super.key});

  @override
  State<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _supplierId;
  DateTime _purchaseDate = DateTime.now();
  final List<_PurchaseItemInput> _items = [];
  final List<_ExpenseInput> _expenses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
      context.read<ProductProvider>().loadProducts();
    });
  }

  double get _itemsTotal => _items.fold(0, (sum, i) => sum + i.lineTotal);
  double get _expensesTotal => _expenses.fold(0, (sum, e) => sum + e.amount);
  double get _grandTotal => _itemsTotal + _expensesTotal;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder: (ctx) => _ProductAddDialog(
        onAdd: (productId, productName, qty, price) {
          Navigator.pop(ctx);
          setState(() {
            _items.add(_PurchaseItemInput(
              productId: productId,
              productName: productName,
              quantity: qty,
              unitPrice: price,
            ));
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _addExpense() {
    setState(() => _expenses.add(_ExpenseInput(category: 'Transport', amount: 0)));
  }

  void _removeExpense(int index) {
    setState(() => _expenses.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<PurchaseProvider>().createPurchase(
        supplierId: _supplierId,
        purchaseDate: _purchaseDate,
        items: _items.map((i) => PurchaseItemInput(i.productId, i.quantity, i.unitPrice)).toList(),
        expenses: _expenses.map((e) => ExpenseInput(e.category, e.amount, e.description)).toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create purchase: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<SupplierProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<String>(
                    value: _supplierId,
                    decoration: const InputDecoration(
                      label: Text('Supplier'),
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Walk-in')),
                      ...provider.suppliers.map(
                        (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _supplierId = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    label: Text('Purchase Date'),
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  child: Text(FormatUtils.date(_purchaseDate)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Products', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('Subtotal: ${FormatUtils.currency(_itemsTotal)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No items added', style: TextStyle(color: Colors.grey))),
                ),
              ..._items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold))),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removeItem(idx),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: item.quantity.toString(),
                                decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final qty = int.tryParse(v);
                                  if (qty != null && qty > 0) {
                                    setState(() => item.quantity = qty);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: item.unitPrice.toStringAsFixed(0),
                                decoration: const InputDecoration(labelText: 'Unit Price', isDense: true),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final price = double.tryParse(v);
                                  if (price != null && price >= 0) {
                                    setState(() => item.unitPrice = price);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: Text(FormatUtils.currency(item.lineTotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Product'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Expenses', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('Total: ${FormatUtils.currency(_expensesTotal)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              if (_expenses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No expenses added', style: TextStyle(color: Colors.grey))),
                ),
              ..._expenses.asMap().entries.map((entry) {
                final idx = entry.key;
                final exp = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: exp.category,
                                decoration: const InputDecoration(labelText: 'Category', isDense: true),
                                items: const [
                                  DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                                  DropdownMenuItem(value: 'Food', child: Text('Food')),
                                  DropdownMenuItem(value: 'Packaging', child: Text('Packaging')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (v) => setState(() => exp.category = v ?? 'Other'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => _removeExpense(idx),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: exp.amount > 0 ? exp.amount.toStringAsFixed(0) : '',
                                decoration: const InputDecoration(labelText: 'Amount', isDense: true),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final amt = double.tryParse(v);
                                  if (amt != null && amt >= 0) {
                                    setState(() => exp.amount = amt);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: exp.description ?? '',
                                decoration: const InputDecoration(labelText: 'Description (opt)', isDense: true),
                                onChanged: (v) => exp.description = v.isNotEmpty ? v : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addExpense,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Expense'),
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Items Total', style: TextStyle(fontSize: 16)),
                  Text(FormatUtils.currency(_itemsTotal), style: const TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Expenses Total', style: TextStyle(fontSize: 16)),
                  Text(FormatUtils.currency(_expensesTotal), style: const TextStyle(fontSize: 16)),
                ],
              ),
              const Divider(thickness: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('GRAND TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(FormatUtils.currency(_grandTotal),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Save Purchase', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductAddDialog extends StatefulWidget {
  final void Function(String productId, String productName, int qty, double price) onAdd;
  const _ProductAddDialog({required this.onAdd});

  @override
  State<_ProductAddDialog> createState() => _ProductAddDialogState();
}

class _ProductAddDialogState extends State<_ProductAddDialog> {
  final _searchController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  Product? _selected;
  List<Product> _all = [];
  List<Product> _filtered = [];

  @override
  void initState() {
    super.initState();
    _all = context.read<ProductProvider>().products;
    _filtered = _all;
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _all.where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.brand?.toLowerCase().contains(q) ?? false) ||
          (p.model?.toLowerCase().contains(q) ?? false)).toList();
      if (!_filtered.contains(_selected)) _selected = null;
    });
  }

  void _submit() {
    if (_selected == null) return;
    final qty = int.tryParse(_qtyController.text);
    final price = double.tryParse(_priceController.text);
    if (qty == null || qty <= 0 || price == null || price < 0) return;
    widget.onAdd(_selected!.id, _selected!.name, qty, price);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search product...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: _filtered.isEmpty
                  ? const Center(child: Text('No products found'))
                  : ListView(
                      children: _filtered.map((p) => ListTile(
                        dense: true,
                        selected: _selected == p,
                        title: Text(p.name),
                        subtitle: Text('Stock: ${p.currentStock} | Price: ${FormatUtils.currency(p.purchasePrice)}'),
                        onTap: () {
                          setState(() {
                            _selected = p;
                            _qtyController.text = '1';
                            _priceController.text = p.purchasePrice.toStringAsFixed(0);
                          });
                        },
                      )).toList(),
                    ),
            ),
            if (_selected != null) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyController,
                      decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Unit Price', isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _selected != null ? _submit : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
