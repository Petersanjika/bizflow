import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../core/utils/id_generator.dart';
import '../database/bizflow_db.dart';

class SupplierProvider extends ChangeNotifier {
  final BizflowDb _db;
  List<Supplier> _suppliers = [];
  bool _loading = true;

  List<Supplier> get suppliers => _suppliers;
  bool get loading => _loading;

  SupplierProvider(this._db);

  Future<void> loadSuppliers() async {
    _loading = true;
    notifyListeners();
    _suppliers = await _db.select(_db.suppliers).get();
    _loading = false;
    notifyListeners();
  }

  Future<void> createSupplier({
    required String name,
    String? phone,
    String? address,
  }) async {
    final id = IdGenerator.newId();
    final supplier = SuppliersCompanion.insert(
      id: id,
      name: name,
      phone: Value<String?>(phone),
      address: Value<String?>(address),
    );
    await _db.into(_db.suppliers).insert(supplier);
    await loadSuppliers();
  }

  Future<void> updateSupplier({
    required String id,
    required String name,
    String? phone,
    String? address,
  }) async {
    await (_db.update(_db.suppliers)..where((s) => s.id.equals(id))).write(
      SuppliersCompanion(
        name: Value(name),
        phone: Value<String?>(phone),
        address: Value<String?>(address),
      ),
    );
    await loadSuppliers();
  }

  Future<void> deleteSupplier(String id) async {
    await (_db.delete(_db.suppliers)..where((s) => s.id.equals(id))).go();
    await loadSuppliers();
  }
}
