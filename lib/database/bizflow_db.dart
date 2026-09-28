import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/business_table.dart';
import 'tables/customer_table.dart';
import 'tables/supplier_table.dart';
import 'tables/category_table.dart';
import 'tables/product_table.dart';
import 'tables/purchase_table.dart';
import 'tables/purchase_item_table.dart';
import 'tables/expense_table.dart';
import 'tables/sale_table.dart';
import 'tables/sale_item_table.dart';
import 'tables/credit_account_table.dart';
import 'tables/payment_schedule_table.dart';
import 'tables/payment_table.dart';
import 'tables/transaction_table.dart';
import 'tables/settings_table.dart';

part 'bizflow_db.g.dart';

@DriftDatabase(
  tables: [
    Businesses,
    Customers,
    Suppliers,
    Categories,
    Products,
    Purchases,
    PurchaseItems,
    Expenses,
    Sales,
    SaleItems,
    CreditAccounts,
    PaymentSchedules,
    Payments,
    Transactions,
    AppSettings,
  ],
)
class BizflowDb extends _$BizflowDb {
  BizflowDb() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        if (from == 1) {
          await m.addColumn(customers, customers.imagePath);
        }
        if (from == 2 || (from == 1 && to >= 3)) {
          await m.addColumn(products, products.imagesPath);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    await Directory(dir.path).create(recursive: true);
    final file = File(p.join(dir.path, 'bizflow.db'));
    return NativeDatabase(file);
  });
}
