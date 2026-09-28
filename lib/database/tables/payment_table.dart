import 'package:drift/drift.dart';

class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get creditAccountId => text().nullable()();
  RealColumn get amount => real()();
  DateTimeColumn get paymentDate => dateTime()();
  RealColumn get expectedAmount => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
