import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format_utils.dart';
import '../../providers/business_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../products/product_list_screen.dart';
import '../customers/customer_list_screen.dart';
import '../sales/sales_list_screen.dart';
import '../purchases/purchase_form_screen.dart';
import '../payments/payment_form_screen.dart';
import '../expenses/expense_form_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final _sections = const [
    _DashboardTab(),
    ProductListScreen(),
    CustomerListScreen(),
    SalesListScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sections[_currentIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppTheme.primaryColor,
          indicatorColor: Colors.white.withAlpha(40),
          shadowColor: Colors.transparent,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined, color: Colors.white70), selectedIcon: Icon(Icons.home, color: Colors.white), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.inventory_outlined, color: Colors.white70), selectedIcon: Icon(Icons.inventory, color: Colors.white), label: 'Stock'),
            NavigationDestination(icon: Icon(Icons.people_outline, color: Colors.white70), selectedIcon: Icon(Icons.people, color: Colors.white), label: 'Customers'),
            NavigationDestination(icon: Icon(Icons.payments_outlined, color: Colors.white70), selectedIcon: Icon(Icons.payments, color: Colors.white), label: 'Sales'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined, color: Colors.white70), selectedIcon: Icon(Icons.bar_chart, color: Colors.white), label: 'Reports'),
            NavigationDestination(icon: Icon(Icons.settings_outlined, color: Colors.white70), selectedIcon: Icon(Icons.settings, color: Colors.white), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bizflow')),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = provider.data;
          return RefreshIndicator(
            onRefresh: () => provider.load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBusinessCard(context),
                const SizedBox(height: 16),
                _buildSummaryCard(context, 'Expenditure', FormatUtils.currency(data.expenditure), Icons.trending_down, Colors.red),
                _buildSummaryCard(context, 'Actual Profit', FormatUtils.currency(data.profit), Icons.account_balance, AppTheme.primaryColor),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildSmallCard('Cash Received', FormatUtils.currency(data.cashReceived), Icons.money, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSmallCard('Owing', FormatUtils.currency(data.customersOwing), Icons.receipt_long, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSmallCard('Stock Value', FormatUtils.currency(data.stockValue), Icons.inventory, AppTheme.infoColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSmallCard('Overdue', '${data.overdueCustomers}', Icons.warning, Colors.red)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSmallCard('Active Credit Sales', '${data.activeCreditSales}', Icons.credit_card, AppTheme.accentColor),
                const SizedBox(height: 24),
                Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildQuickActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context) {
    final business = context.watch<BusinessProvider>().business;
    if (business == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.store)),
        title: Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(business.phone ?? ''),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withAlpha(30), child: Icon(icon, color: color)),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        trailing: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  Widget _buildSmallCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('New Purchase', Icons.add_shopping_cart, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseFormScreen()))),
      ('New Customer', Icons.person_add, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerListScreen()))),
      ('New Sale', Icons.point_of_sale, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesListScreen()))),
      ('Receive Payment', Icons.payments, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentFormScreen()))),
      ('Add Expense', Icons.money_off, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseFormScreen()))),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((a) => ActionChip(
        avatar: Icon(a.$2, size: 18),
        label: Text(a.$1),
        onPressed: a.$3 as VoidCallback,
      )).toList(),
    );
  }
}
