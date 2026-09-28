import 'package:drift/drift.dart';

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().nullable()();
  DateTimeColumn get saleDate => dateTime()();
  TextColumn get saleType => text()(); // cash / credit
  RealColumn get totalAmount => real()();
  RealColumn get deposit => real().withDefault(const Constant(0))();
  RealColumn get balance => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
