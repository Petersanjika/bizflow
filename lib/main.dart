import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/database_provider.dart';
import 'providers/business_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/product_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/category_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/expense_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbProvider = DatabaseProvider();
  await dbProvider.init();
  runApp(BizflowApp(dbProvider: dbProvider));
}

class BizflowApp extends StatelessWidget {
  final DatabaseProvider dbProvider;
  const BizflowApp({super.key, required this.dbProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dbProvider),
        ChangeNotifierProvider(create: (_) => BusinessProvider(dbProvider.db)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(dbProvider.db)),
        ChangeNotifierProvider(create: (_) => ProductProvider(dbProvider.db)),
        ChangeNotifierProvider(create: (_) => CustomerProvider(dbProvider.db)),
        ChangeNotifierProvider(create: (_) => SupplierProvider(dbProvider.db)),
        ChangeNotifierProvider(create: (_) => CategoryProvider(dbProvider.db)),
        ChangeNotifierProvider(create: (_) => PurchaseProvider(dbProvider.db)),
        ChangeNotifierProvider(create: (_) => SaleProvider(dbProvider.db)),
        ChangeNotifierProvider(create: (_) => PaymentProvider(dbProvider.db)),
        ChangeNotifierProvider(create: (_) => ExpenseProvider(dbProvider.db)),
      ],
      child: MaterialApp(
        title: 'Bizflow',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AppShell(),
      ),
    );
  }
}
