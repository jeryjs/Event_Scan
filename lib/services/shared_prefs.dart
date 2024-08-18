import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static const String collectionKey = "collectionName";

  static Future<void> saveCollectionName(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(collectionKey, collectionName);
  }

  static Future<String?> getCollectionName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(collectionKey);
  }
}
