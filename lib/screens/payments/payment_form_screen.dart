import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/format_utils.dart';
import '../../database/bizflow_db.dart';
import '../../providers/payment_provider.dart';
import '../../providers/customer_provider.dart';

class PaymentFormScreen extends StatefulWidget {
  final String? customerId;

  const PaymentFormScreen({super.key, this.customerId});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCustomerId;
  String? _selectedAccountId;
  CreditAccount? _selectedAccount;
  DateTime _paymentDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.customerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      context.read<PaymentProvider>().loadCreditAccounts();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<CreditAccount> _getAccountsForCustomer(List<CreditAccount> accounts, String? customerId) {
    if (customerId == null) return [];
    return accounts.where((a) => a.customerId == customerId).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a credit account')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<PaymentProvider>().recordPayment(
        customerId: _selectedCustomerId!,
        creditAccountId: _selectedAccountId!,
        amount: double.parse(_amountController.text.trim()),
        paymentDate: _paymentDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to record payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<CustomerProvider>().customers;
    final creditAccounts = context.watch<PaymentProvider>().creditAccounts;
    final customerAccounts = _getAccountsForCustomer(creditAccounts, _selectedCustomerId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
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
              DropdownButtonFormField<String>(
                value: _selectedCustomerId,
                decoration: const InputDecoration(
                  label: Text('Customer'),
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: customers.map((c) => DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (v) => setState(() {
                  _selectedCustomerId = v;
                  _selectedAccountId = null;
                  _selectedAccount = null;
                }),
                validator: (v) => v == null ? 'Select a customer' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: const InputDecoration(
                  label: Text('Credit Account'),
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                items: customerAccounts.map((a) {
                  final label = '${FormatUtils.currency(a.balance)} bal - ${FormatUtils.currency(a.totalAmount)} total';
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) => setState(() {
                  _selectedAccountId = v;
                  _selectedAccount = v != null
                      ? customerAccounts.firstWhere((a) => a.id == v)
                      : null;
                }),
                validator: (v) => v == null ? 'Select a credit account' : null,
                disabledHint: const Text('Select a customer first'),
              ),
              if (_selectedAccount != null) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Balance', FormatUtils.currency(_selectedAccount!.balance)),
                        _infoRow('Total', FormatUtils.currency(_selectedAccount!.totalAmount)),
                        _infoRow('Installment', FormatUtils.currency(_selectedAccount!.installmentAmount)),
                        _infoRow('Frequency', _selectedAccount!.paymentFrequency),
                        _infoRow('Status', _selectedAccount!.status),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  label: const Text('Amount (MK)'),
                  hintText: 'e.g. 5000',
                  prefixIcon: const Icon(Icons.money_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final amount = double.tryParse(v.trim());
                  if (amount == null || amount <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    label: Text('Payment Date'),
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  child: Text(FormatUtils.date(_paymentDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  label: const Text('Notes (optional)'),
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.payments),
                  label: const Text('Record Payment', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
