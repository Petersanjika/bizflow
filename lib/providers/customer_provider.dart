import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../core/utils/id_generator.dart';
import '../database/bizflow_db.dart';

class CustomerProvider extends ChangeNotifier {
  final BizflowDb _db;
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _loading = true;

  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  bool get loading => _loading;

  CustomerProvider(this._db);

  Future<void> loadCustomers() async {
    _loading = true;
    notifyListeners();
    _customers = await _db.select(_db.customers).get();
    _loading = false;
    notifyListeners();
  }

  Future<void> createCustomer({
    required String name,
    required String phone,
    String? altPhone,
    String? address,
    String? idReference,
    String? imagePath,
    String? notes,
  }) async {
    final id = IdGenerator.newId();
    final customer = CustomersCompanion.insert(
      id: id,
      name: name,
      phone: phone,
      altPhone: Value<String?>(altPhone),
      address: Value<String?>(address),
      idReference: Value<String?>(idReference),
      imagePath: Value<String?>(imagePath),
      notes: Value<String?>(notes),
    );
    await _db.into(_db.customers).insert(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer({
    required String id,
    required String name,
    required String phone,
    String? altPhone,
    String? address,
    String? idReference,
    String? imagePath,
    String? notes,
  }) async {
    await (_db.update(_db.customers)..where((c) => c.id.equals(id))).write(
      CustomersCompanion(
        name: Value(name),
        phone: Value(phone),
        altPhone: Value<String?>(altPhone),
        address: Value<String?>(address),
        idReference: Value<String?>(idReference),
        imagePath: Value<String?>(imagePath),
        notes: Value<String?>(notes),
      ),
    );
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await (_db.delete(_db.customers)..where((c) => c.id.equals(id))).go();
    await loadCustomers();
  }

  Future<List<Customer>> searchCustomers(String query) async {
    return await (_db.select(_db.customers)
      ..where((c) => c.name.contains(query) | c.phone.contains(query)))
        .get();
  }
}
