import 'package:drift/drift.dart';

class CreditAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get customerId => text()();
  RealColumn get totalAmount => real()();
  RealColumn get deposit => real()();
  RealColumn get balance => real()();
  TextColumn get paymentFrequency => text()();
  RealColumn get installmentAmount => real()();
  IntColumn get numberOfPayments => integer()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
