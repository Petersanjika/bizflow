import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../core/utils/id_generator.dart';
import '../database/bizflow_db.dart';

class BusinessProvider extends ChangeNotifier {
  final BizflowDb _db;
  BusinessesData? _business;
  bool _loading = true;

  BusinessesData? get business => _business;
  bool get loading => _loading;
  bool get hasBusiness => _business != null;

  BusinessProvider(this._db);

  Future<void> loadBusiness() async {
    _loading = true;
    notifyListeners();
    final businesses = await _db.select(_db.businesses).get();
    _business = businesses.isNotEmpty ? businesses.first : null;
    _loading = false;
    notifyListeners();
  }

  Future<void> createBusiness({
    required String name,
    String? phone,
    String? address,
    String currency = 'MWK',
  }) async {
    final id = IdGenerator.newId();
    final business = BusinessesCompanion.insert(
      id: id,
      name: name,
      phone: Value<String?>(phone),
      address: Value<String?>(address),
      currency: Value(currency),
    );
    await _db.into(_db.businesses).insert(business);
    await loadBusiness();
  }

  Future<void> updateBusiness({
    required String name,
    String? phone,
    String? address,
    String currency = 'MWK',
  }) async {
    if (_business == null) return;
    await _db.update(_db.businesses).replace(
      _business!.copyWith(
        name: name,
        phone: Value<String?>(phone),
        address: Value<String?>(address),
        currency: currency,
      ),
    );
    await loadBusiness();
  }
}
