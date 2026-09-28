import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';

Future<String?> showCategoryDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    useSafeArea: false,
    builder: (_) => const _CategoryDialog(),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog();

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _addController = TextEditingController();
  String? _selectedId;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _addController.text.trim();
    if (name.isEmpty) return;
    setState(() => _adding = true);
    try {
      await context.read<CategoryProvider>().createCategory(name: name);
      _addController.clear();
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<CategoryProvider>().deleteCategory(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select Category',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _addController,
                      decoration: const InputDecoration(
                        hintText: 'New category name',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addCategory(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: FilledButton.tonalIcon(
                    onPressed: _adding ? null : _addCategory,
                    icon: _adding
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: provider.loading
                  ? const Center(
                      child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ))
                  : provider.categories.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('No categories yet',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : ListBody(
                          children: provider.categories.map((cat) {
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                cat.id == _selectedId
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: cat.id == _selectedId
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              title: Text(cat.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20),
                                onPressed: () => _deleteCategory(cat.id),
                                style: IconButton.styleFrom(
                                    foregroundColor: Colors.red.shade400),
                              ),
                              onTap: () =>
                                  setState(() => _selectedId = cat.id),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _selectedId != null
                      ? () => Navigator.pop(context, _selectedId)
                      : null,
                  child: const Text('Select'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
