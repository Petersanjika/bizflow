import 'package:drift/drift.dart';

class PaymentSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get creditAccountId => text()();
  DateTimeColumn get dueDate => dateTime()();
  RealColumn get expectedAmount => real()();
  TextColumn get status => text().withDefault(const Constant('upcoming'))(); // paid, due, upcoming, overdue

  @override
  Set<Column> get primaryKey => {id};
}
