import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/format_utils.dart';
import '../../database/bizflow_db.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/sale_provider.dart';

class SaleFormScreen extends StatefulWidget {
  const SaleFormScreen({super.key});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _customerId;
  late DateTime _saleDate;
  String _saleType = 'cash';
  final List<_SaleItemEntry> _items = [];

  final _depositController = TextEditingController();
  String _paymentFrequency = 'weekly';
  final _installmentController = TextEditingController();
  final _numPaymentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _saleDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _depositController.dispose();
    _installmentController.dispose();
    _numPaymentsController.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      _items.fold(0, (sum, e) => sum + e.quantity * e.unitPrice);
  double get _deposit => double.tryParse(_depositController.text) ?? 0;
  double get _installment => double.tryParse(_installmentController.text) ?? 0;
  int get _numPayments => int.tryParse(_numPaymentsController.text) ?? 0;
  double get _balance => _totalAmount - _deposit;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _saleDate = picked);
  }

  Future<void> _addItem() async {
    final productProvider = context.read<ProductProvider>();
    if (productProvider.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No products available')),
      );
      return;
    }
    Product? selectedProduct;
    int quantity = 1;
    double unitPrice = 0;
    final priceCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                value: selectedProduct,
                items: productProvider.products
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (p) {
                  setDialogState(() {
                    selectedProduct = p;
                    unitPrice = _saleType == 'cash'
                        ? p!.cashPrice
                        : p!.creditPrice;
                    priceCtrl.text = unitPrice.toStringAsFixed(0);
                  });
                },
                decoration: const InputDecoration(
                    labelText: 'Product', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final q = int.tryParse(v);
                        if (q != null && q > 0)
                          setDialogState(() => quantity = q);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final p = double.tryParse(v);
                        if (p != null && p > 0)
                          setDialogState(() => unitPrice = p);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedProduct != null && unitPrice > 0
                  ? () {
                      Navigator.pop(dialogContext);
                      setState(() {
                        _items.add(_SaleItemEntry(
                            selectedProduct!.id,
                            selectedProduct!.name,
                            quantity,
                            unitPrice));
                      });
                    }
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }
    if (_saleType == 'credit' && _customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Customer is required for credit sales')),
      );
      return;
    }

    final items =
        _items.map((e) => SaleItemInput(e.productId, e.quantity, e.unitPrice)).toList();

    try {
      if (_saleType == 'cash') {
        await context.read<SaleProvider>().createCashSale(
              customerId: _customerId,
              saleDate: _saleDate,
              items: items,
            );
      } else {
        await context.read<SaleProvider>().createCreditSale(
              customerId: _customerId!,
              saleDate: _saleDate,
              items: items,
              creditTerms: CreditTermsInput(
                  _deposit, _paymentFrequency, _installment, _numPayments),
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCustomerAndDate(),
            const SizedBox(height: 16),
            _buildTypeToggle(),
            const SizedBox(height: 16),
            _buildItemsSection(),
            if (_saleType == 'credit') ...[
              const SizedBox(height: 16),
              _buildCreditTerms(),
            ],
            const SizedBox(height: 16),
            _buildSummary(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle, size: 28),
                label: const Text('Complete Sale',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerAndDate() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Consumer<CustomerProvider>(
              builder: (context, customerProvider, _) {
                return DropdownButtonFormField<String?>(
                  value: _customerId,
                  items: [
                    if (_saleType == 'cash')
                      const DropdownMenuItem(
                          value: null, child: Text('Walk-in (no customer)')),
                    ...customerProvider.customers.map((c) =>
                        DropdownMenuItem(
                            value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _customerId = v),
                  decoration: InputDecoration(
                    labelText: 'Customer',
                    hintText: _saleType == 'credit'
                        ? 'Select customer (required)'
                        : 'Optional',
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Sale Date',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                  text: FormatUtils.date(_saleDate)),
              onTap: _selectDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sale Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _saleType = 'cash'),
                      icon: const Icon(Icons.money),
                      label: const Text('Cash'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _saleType == 'cash'
                            ? Colors.green.withAlpha(30)
                            : null,
                        side: BorderSide(
                          color: _saleType == 'cash'
                              ? Colors.green
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _saleType = 'credit'),
                      icon: const Icon(Icons.credit_card),
                      label: const Text('Credit'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _saleType == 'credit'
                            ? Colors.blue.withAlpha(30)
                            : null,
                        side: BorderSide(
                          color: _saleType == 'credit'
                              ? Colors.blue
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Product'),
                ),
              ],
            ),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No items added yet',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              ..._items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 15)),
                            Text(
                                '${item.quantity} x ${FormatUtils.currency(item.unitPrice)}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                      Text(FormatUtils.currency(item.quantity * item.unitPrice),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 22),
                        onPressed: () =>
                            setState(() => _items.removeAt(i)),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditTerms() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Credit Terms',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _depositController,
              decoration: const InputDecoration(
                labelText: 'Deposit Amount',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentFrequency,
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'biweekly', child: Text('Biweekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => _paymentFrequency = v!),
              decoration: const InputDecoration(
                labelText: 'Payment Frequency',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _installmentController,
              decoration: const InputDecoration(
                labelText: 'Installment Amount',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numPaymentsController,
              decoration: const InputDecoration(
                labelText: 'Number of Payments',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _summaryRow('Total', FormatUtils.currency(_totalAmount)),
            if (_saleType == 'credit') ...[
              const Divider(height: 16),
              _summaryRow('Deposit', FormatUtils.currency(_deposit)),
              const Divider(height: 16),
              _summaryRow('Balance', FormatUtils.currency(_balance)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SaleItemEntry {
  final String productId;
  final String productName;
  int quantity;
  double unitPrice;

  _SaleItemEntry(
      this.productId, this.productName, this.quantity, this.unitPrice);
}
