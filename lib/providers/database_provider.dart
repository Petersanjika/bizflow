import 'package:flutter/foundation.dart';
import '../database/bizflow_db.dart';

class DatabaseProvider extends ChangeNotifier {
  late final BizflowDb _db;
  bool _initialized = false;

  BizflowDb get db => _db;
  bool get initialized => _initialized;

  Future<void> init() async {
    _db = BizflowDb();
    _initialized = true;
    notifyListeners();
  }
}
