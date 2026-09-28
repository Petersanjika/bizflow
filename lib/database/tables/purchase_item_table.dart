import 'package:drift/drift.dart';

class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text()();
  TextColumn get productId => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();

  @override
  Set<Column> get primaryKey => {id};
}
