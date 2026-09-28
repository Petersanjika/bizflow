import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialImei => text().nullable()();
  RealColumn get purchasePrice => real()();
  RealColumn get cashPrice => real()();
  RealColumn get creditPrice => real()();
  IntColumn get currentStock => integer().withDefault(const Constant(0))();
  TextColumn get imagesPath => text().nullable()();
  TextColumn get supplierId => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
