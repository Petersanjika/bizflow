import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../database/bizflow_db.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _cashPriceCtrl = TextEditingController();
  final _creditPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _picker = ImagePicker();
  List<String> _images = [];
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _brandCtrl.text = p.brand ?? '';
      _modelCtrl.text = p.model ?? '';
      _purchasePriceCtrl.text = p.purchasePrice.toStringAsFixed(0);
      _cashPriceCtrl.text = p.cashPrice.toStringAsFixed(0);
      _creditPriceCtrl.text = p.creditPrice.toStringAsFixed(0);
      _stockCtrl.text = p.currentStock.toString();
      if (p.imagesPath != null && p.imagesPath!.isNotEmpty) {
        _images = p.imagesPath!.split('||');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _cashPriceCtrl.dispose();
    _creditPriceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    if (_images.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 photos allowed')),
        );
      }
      return;
    }

    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Photo'),
        content: const Text('Choose how to add a photo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('Take Photo'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('Choose from Gallery'),
          ),
        ],
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 600);
    if (file != null) {
      setState(() => _images.add(file.path));
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final provider = context.read<ProductProvider>();
    try {
      if (_isEditing) {
        await provider.updateProduct(
          widget.product!,
          name: _nameCtrl.text.trim(),
          brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
          model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
          purchasePrice: double.tryParse(_purchasePriceCtrl.text) ?? 0,
          cashPrice: double.tryParse(_cashPriceCtrl.text) ?? 0,
          creditPrice: double.tryParse(_creditPriceCtrl.text) ?? 0,
          currentStock: int.tryParse(_stockCtrl.text) ?? 1,
          images: _images.isNotEmpty ? _images : null,
        );
      } else {
        await provider.createProduct(
          name: _nameCtrl.text.trim(),
          brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
          model: _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim(),
          purchasePrice: double.tryParse(_purchasePriceCtrl.text) ?? 0,
          cashPrice: double.tryParse(_cashPriceCtrl.text) ?? 0,
          creditPrice: double.tryParse(_creditPriceCtrl.text) ?? 0,
          currentStock: int.tryParse(_stockCtrl.text) ?? 1,
          images: _images.isNotEmpty ? _images : null,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'New Product'),
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
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  label: const Text('Product name'),
                  hintText: 'e.g. Samsung Galaxy A15',
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter product name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandCtrl,
                decoration: InputDecoration(
                  label: const Text('Brand (optional)'),
                  hintText: 'e.g. Samsung',
                  prefixIcon: const Icon(Icons.business_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelCtrl,
                decoration: InputDecoration(
                  label: const Text('Model (optional)'),
                  hintText: 'e.g. A15',
                  prefixIcon: const Icon(Icons.tag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purchasePriceCtrl,
                decoration: InputDecoration(
                  label: const Text('Purchase Price (MK)'),
                  hintText: 'e.g. 20000',
                  prefixIcon: const Icon(Icons.shopping_cart_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter purchase price';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cashPriceCtrl,
                decoration: InputDecoration(
                  label: const Text('Cash Price (MK)'),
                  hintText: 'e.g. 28000',
                  prefixIcon: const Icon(Icons.money_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter cash price';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditPriceCtrl,
                decoration: InputDecoration(
                  label: const Text('Credit Price (MK)'),
                  hintText: 'e.g. 32000',
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter credit price';
                  if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockCtrl,
                decoration: InputDecoration(
                  label: const Text('Current Stock'),
                  hintText: 'e.g. 10',
                  prefixIcon: const Icon(Icons.inventory_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter stock quantity';
                  if (int.tryParse(v.trim()) == null) return 'Enter a whole number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text('Photos (${_images.length}/5)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == _images.length) {
                      return GestureDetector(
                        onTap: _images.length < 5 ? _addImage : null,
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: _images.length < 5 ? AppTheme.primaryColor : Colors.grey.shade300,
                            size: 32,
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(File(_images[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0, right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_isEditing ? Icons.check : Icons.inventory_2),
                  label: Text(_isEditing ? 'Save Changes' : 'Add Product', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
