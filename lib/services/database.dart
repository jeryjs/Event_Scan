import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Database {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> _getCollection() async {
    var snapshot = await _firestore.collection('settings').doc('config').get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      return data['collectionName'] ?? 'FDP_2024';
    }
    return 'FDP_2024';
  }

  static Future<DateTime> getStartDate() async {
    var snapshot = await _firestore.collection('settings').doc('config').get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      return (data['startDate'] as Timestamp).toDate();
    }
    return DateTime.now();
  }

  static Future<Map<String, dynamic>?> checkBarcode(String barcode, String category) async {
    final collection = await _getCollection();
    var doc = await _firestore.collection(collection).doc(barcode).get();
    final currentDay = await _calculateCurrentDay();

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
        'mail': data['mail'],
        'phone': data['phone'],
        'scanned': scanned,
        'isScanned': isScanned,
      };
    }
    return null;
  }

  static Stream<QuerySnapshot> getBarcodes({required String category, required bool isScanned}) {
    // final collection = await _getCollection();
    const collection = "FDP_2024";
    if (isScanned) {
      return _firestore
          .collection(collection)
          .where('scanned.$category', isGreaterThan: [])
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

  static Future<int> _calculateCurrentDay() async {
    var snapshot = await _firestore.collection('settings').doc('config').get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      final startDate = (data['startDate'] as Timestamp).toDate();
      return DateTime.now().difference(startDate).inDays + 1;
    }
    return 1;
  }

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final collection = await _getCollection();
    var snapshot = await _firestore
        .collection(collection)
        .doc('categories')
        .get();

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      var categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
      return categories;
    }
    return [];
  }

  static Future<void> addCategory(Map<String, dynamic> category) async {
    final collection = await _getCollection();
    var categories = await getCategories();
    categories.add(category);

    await _firestore
        .collection(collection)
        .doc('categories')
        .set({'categories': categories}, SetOptions(merge: true));
  }

  static Future<void> deleteCategory(String categoryName) async {
    final collection = await _getCollection();
    var categories = await getCategories();
    categories.removeWhere((cat) => cat['name'] == categoryName);

    await _firestore
        .collection(collection)
        .doc('categories')
        .set({'categories': categories}, SetOptions(merge: true));
  }

  static Future<Stream<QuerySnapshot<Object?>>> getBarcodesStream() async {
    return _firestore
        .collection(await _getCollection())
        .snapshots();
  }

  static Stream<DocumentSnapshot> getSettingsStream() {
    return _firestore.collection('settings').doc('config').snapshots();
  }

  static Future<void> updateUser(id, String name, String mail, String phone) async {
    return _firestore.collection(await _getCollection()).doc(id).update({
      'name': name,
      'mail': mail,
      'phone': phone,
    });
  }

  static Future<QuerySnapshot> getUsers() async {
    final collection = await _getCollection();
    return _firestore.collection(collection).get();
  }
}
