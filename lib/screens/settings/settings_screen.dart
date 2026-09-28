import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>().business;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (business != null) ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.store)),
                title: Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(business.phone ?? ''),
                trailing: const Icon(Icons.edit),
                onTap: () {},
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup'),
                  subtitle: const Text('Backup your data'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore'),
                  subtitle: const Text('Restore from backup'),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Cloud Sync'),
                  subtitle: const Text('Coming in Phase 8'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
