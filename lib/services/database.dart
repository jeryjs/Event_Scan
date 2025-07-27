import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scan/models/barcode_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';
import 'collection_manager.dart';

class Database {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String _getCurrentCollection() {
    final collection = CollectionManager.currentCollection;
    if (collection == null) {
      throw Exception('No collection selected. Please select a collection first.');
    }
    return collection;
  }

  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final collection = _getCurrentCollection();
      var snapshot = await _firestore.collection(collection).doc('.config').get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      debugPrint('Error getting settings: $e');
      return {};
    }
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final collection = _getCurrentCollection();
    await CollectionManager.updateCollectionConfig(collection, settings);
  }

  static Future<BarcodeModel?> checkBarcode(String barcode, String category) async {
    final collection = _getCurrentCollection();
    var settings = await getSettings();
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

      return BarcodeModel(
        code: data['code'] ?? '',
        title: data['title'] ?? '',
        subtitle: data['subtitle'] ?? '',
        extras: ExtraField.fromDynamic(data['extras']),
        scanned: scanned,
        timestamp: data['timestamp'] ?? Timestamp.now(),
        isScanned: isScanned,
      );

      // return {
      //   'code': data['code'],
      //   'title': data['title'],
      //   'subtitle': data['subtitle'],
      //   'extras': data['extras'],
      //   'scanned': scanned,
      //   'isScanned': isScanned,
      // };
    }
    return null;
  }

  static Future<Stream<QuerySnapshot>> getBarcodes({required String category, required bool isScanned, required int selectedDay}) async {
    final collection = _getCurrentCollection();
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
    final collection = _getCurrentCollection();
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
    final collection = _getCurrentCollection();

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
    try {
      final collection = _getCurrentCollection();
      var snapshot = await _firestore.collection(collection).doc('.config').get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        var categoriesData = List<Map<String, dynamic>>.from(data['categories'] ?? []);
        return categoriesData.map((catData) => CategoryModel.fromMap(catData)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return [];
    }
  }

  static Future<void> addCategory(CategoryModel category) async {
    final collection = _getCurrentCollection();
    var categories = await getCategories();
    categories.add(category);
    await _firestore.collection(collection).doc('.config').set({
      'categories': categories.map((cat) => cat.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteCategory(String category) async {
    final collection = _getCurrentCollection();
    var categories = await getCategories();
    categories.removeWhere((cat) => cat.name == category);
    await _firestore.collection(collection).doc('.config').set({
      'categories': categories.map((cat) => cat.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  static Future<Stream<QuerySnapshot<Object?>>> getBarcodesStream() async {
    final collection = _getCurrentCollection();
    return _firestore
        .collection(collection)
        .snapshots();
  }

  static Stream<DocumentSnapshot> getSettingsStream() {
    try {
      final collection = _getCurrentCollection();
      return _firestore.collection(collection).doc('.config').snapshots();
    } catch (e) {
      debugPrint('Error getting settings stream: $e');
      // Return a stream that emits an empty document snapshot
      return const Stream.empty();
    }
  }

  static Future<void> updateUsers(List<Map<String, dynamic>> usersData) async {
    final batch = _firestore.batch();
    final collection = _getCurrentCollection();

    for (var userData in usersData) {
      final docRef = _firestore.collection(collection).doc(userData['code']);
      
      // Convert extras to proper format using ExtraField.fromDynamic
      final extras = ExtraField.fromDynamic(userData['extras']);
      final extrasData = extras.map((field) => {'key': field.key, ...field.toMap()}).toList();
      
      batch.set(docRef, {
        'code': userData['code'],
        'title': userData['title'],
        'subtitle': userData['subtitle'],
        'extras': extrasData,
        'scanned': userData['scanned'] ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    try {
      await batch.commit();
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  static Future<QuerySnapshot> getUsers() async {
    final collection = _getCurrentCollection();
    return _firestore.collection(collection).get();
  }

  static Future<void> deleteUser(String id) async {
    final collection = _getCurrentCollection();
    return _firestore.collection(collection).doc(id).delete();
  }

  static Future<bool> deleteUsers(List<String> ids) async {
    final collection = _getCurrentCollection();
    final batch = _firestore.batch();

    for (var id in ids) {
      var docRef = _firestore.collection(collection).doc(id);
      batch.delete(docRef);
    }

    try {
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting users: $e');
      return false;
    }
  }
}
