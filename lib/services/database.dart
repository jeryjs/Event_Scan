import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';

class Database {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> _getCollection() async {
    var settings = await getSettings();
    return settings['collectionName'] ?? 'FDP_2024';
  }

  static Future<Map<String, dynamic>> getSettings() async {
    var snapshot = await _firestore.collection('settings').doc('config').get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    }
    return {};
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('settings').doc('config').set(settings, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> checkBarcode(String barcode, String category) async {
    var settings = await getSettings();
    final collection = settings['collectionName'] ?? 'FDP_2024';
    final startDate = (settings['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final currentDay = DateTime.now().difference(startDate).inDays + 1;

    var doc = await _firestore.collection(collection).doc(barcode).get();

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      var scanned = (data['scanned'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as List).map((e) => e as int).toList()),
      );
      final isScanned = scanned[category]?.contains(currentDay) ?? false;

      if (!isScanned) {
        scanned[category] = (scanned[category] ?? [])..add(currentDay);
        _firestore.collection(collection).doc(barcode).update({
          'scanned': scanned,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      return {
        'name': data['name'],
        'code': data['code'],
        'email': data['email'],
        'phone': data['phone'],
        'institute': data['institute'],
        'state': data['state'],
        'designation': data['designation'],
        'scanned': scanned,
        'isScanned': isScanned,
      };
    }
    return null;
  }

  static Future<Stream<QuerySnapshot>> getBarcodes({required String category, required bool isScanned, required int selectedDay}) async {
    final collection = await _getCollection();
    if (isScanned) {
      return _firestore
          .collection(collection)
          .where('scanned.$category', arrayContains: selectedDay)
          .snapshots();
    } else {
      return _firestore
          .collection(collection)
          .snapshots();
    }
  }

  static Future<void> resetBarcode(String barcode, String category) async {
    final collection = await _getCollection();
    var docRef = _firestore.collection(collection).doc(barcode);
    var doc = await docRef.get();

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      var scanned = Map<String, List<int>>.from(data['scanned'] ?? {});
      scanned.remove(category);

      await docRef.update({
        'scanned': scanned,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(0),
      });
    }
  }

  static Future<void> setUpBarcodes(String path, String type) async {
    if (!kDebugMode) return;

    final batch = _firestore.batch();
    final collection = await _getCollection();

    final fileString = await rootBundle.loadString(path);
    final barcodes = fileString.split("\n").map((line) => line.trim()).toList();
    
    for (var barcode in barcodes) {
      final docRef = _firestore.collection(collection).doc(barcode);
      batch.set(docRef, {
        'scanned': {},
        'timestamp': DateTime.fromMillisecondsSinceEpoch(0),
        'type': type,
      });
    }

    try {
      await batch.commit();
    } catch (error) {
      debugPrint(error.toString());
    }
  }


  static Future<int> calculateMaxDay() async {
    // Fetch and calculate the maximum day from the data
    int maxDay = 1;
    QuerySnapshot snapshot = await getUsers();
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      var scanned = data['scanned'] as Map<String, dynamic>? ?? {};
      for (var days in scanned.values) {
        for (var day in days) {
          if (day > maxDay) {
            maxDay = day;
          }
        }
      }
    }
    return maxDay;
  }

  static Future<List<CategoryModel>> getCategories() async {
    final categoryName = await _getCollection();
    var snapshot = await _firestore.collection('settings').doc('categories').get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      var categoriesData = List<Map<String, dynamic>>.from(data[categoryName] ?? []);
      return categoriesData.map((catData) => CategoryModel.fromMap(catData)).toList();
    }
    return [];
  }

  static Future<void> addCategory(CategoryModel category) async {
    final categoryName = await _getCollection();
    var categories = await getCategories();
    categories.add(category);
    await _firestore.collection('settings').doc('categories').set({
      categoryName: categories.map((cat) => cat.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteCategory(String categoryName) async {
    final categoryName = await _getCollection();
    var categories = await getCategories();
    categories.removeWhere((cat) => cat.name == categoryName);
    await _firestore.collection('settings').doc('categories').set({
      categoryName: categories.map((cat) => cat.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  static Future<Stream<QuerySnapshot<Object?>>> getBarcodesStream() async {
    return _firestore
        .collection(await _getCollection())
        .snapshots();
  }

  static Stream<DocumentSnapshot> getSettingsStream() {
    return _firestore.collection('settings').doc('config').snapshots();
  }

  static Future<void> updateUsers(List<Map<String, dynamic>> usersData) async {
    final batch = _firestore.batch();
    final collection = await _getCollection();

    for (var userData in usersData) {
      final docRef = _firestore.collection(collection).doc(userData['code']);
      batch.set(docRef, {
        'code': userData['code'],
        'name': userData['name'],
        'email': userData['email'],
        'phone': userData['phone'],
        'institute': userData['institute'],
        'state': userData['state'],
        'designation': userData['designation'],
      }, SetOptions(merge: true));
    }

    try {
      await batch.commit();
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  static Future<QuerySnapshot> getUsers() async {
    final collection = await _getCollection();
    return _firestore.collection(collection).get();
  }

  static Future<void> deleteUser(String id) async {
    return _firestore.collection(await _getCollection()).doc(id).delete();
  }
}
