import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class LocalDatabaseService implements DatabaseService {
  final SharedPreferences _prefs;
  final String uid;

  LocalDatabaseService(this._prefs, {this.uid = 'guest'});

  String _getKey(String collection) => 'db_${uid}_$collection';

  Future<List<Map<String, dynamic>>> _getAllFromPrefs(String collection) async {
    final str = _prefs.getString(_getKey(collection));
    if (str == null) return [];
    
    final List<dynamic> decoded = jsonDecode(str);
    return decoded.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> _saveAllToPrefs(String collection, List<Map<String, dynamic>> items) async {
    await _prefs.setString(_getKey(collection), jsonEncode(items));
  }

  @override
  Future<void> create(String collection, String id, Map<String, dynamic> data) async {
    final items = await _getAllFromPrefs(collection);
    data['id'] = id;
    items.add(data);
    await _saveAllToPrefs(collection, items);
  }

  @override
  Future<List<Map<String, dynamic>>> readAll(String collection) async {
    return await _getAllFromPrefs(collection);
  }

  @override
  Future<Map<String, dynamic>?> read(String collection, String id) async {
    final items = await _getAllFromPrefs(collection);
    try {
      return items.firstWhere((element) => element['id'] == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> update(String collection, String id, Map<String, dynamic> data) async {
    final items = await _getAllFromPrefs(collection);
    final index = items.indexWhere((element) => element['id'] == id);
    
    if (index != -1) {
      // Gabungkan data lama dengan data baru
      final oldData = items[index];
      data.forEach((key, value) {
        oldData[key] = value;
      });
      items[index] = oldData;
      await _saveAllToPrefs(collection, items);
    }
  }

  @override
  Future<void> delete(String collection, String id) async {
    final items = await _getAllFromPrefs(collection);
    items.removeWhere((element) => element['id'] == id);
    await _saveAllToPrefs(collection, items);
  }
}
