import 'package:drift/drift.dart';

class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get supplierId => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get totalCost => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
