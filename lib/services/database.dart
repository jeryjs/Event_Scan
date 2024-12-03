import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Database {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> _getCollection() async {
    print('Fetching collection name...');
    var snapshot = await _firestore.collection('settings').doc('config').get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      print('Collection name fetched: ${data['collectionName']}');
      return data['collectionName'] ?? 'FDP_2024';
    }
    print('Using default collection name: FDP_2024');
    return 'FDP_2024';
  }

  static Future<DateTime> getStartDate() async {
    print('Fetching start date...');
    var snapshot = await _firestore.collection('settings').doc('config').get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      print('Start date fetched: ${(data['startDate'] as Timestamp).toDate()}');
      return (data['startDate'] as Timestamp).toDate();
    }
    print('Using current date as start date');
    return DateTime.now();
  }

  static Future<Map<String, dynamic>?> checkBarcode(String barcode, String category) async {
    print('Checking barcode: $barcode for category: $category');
    final collection = await _getCollection();
    var doc = await _firestore.collection(collection).doc(barcode).get();

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      var scanned = List<String>.from(data['scanned'] ?? []);
      final isScanned = scanned.contains(category);

      if (!isScanned) {
        print('Barcode not scanned for category. Updating...');
        scanned.add(category);
        _firestore.collection(collection).doc(barcode).update({
          'scanned': scanned,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        print('Barcode already scanned for category.');
      }

      return {
        'name': data['name'],
        'code': data['code'],
        'mail': data['mail'],
        'phone': data['phone'],
        'scanned': scanned,
      };
    }
    print('Barcode not found.');
    return null;
  }

  static Stream<QuerySnapshot> getBarcodes({required String category, required bool isScanned}) async* {
    print('Getting barcodes for category: $category, isScanned: $isScanned');
    final collection = await _getCollection();
    if (isScanned) {
      yield* _firestore
          .collection(collection)
          .where('scanned', arrayContains: category)
          .snapshots();
    } else {
      yield* _firestore
          .collection(collection)
          .snapshots();
    }
  }

  static Future<void> resetBarcode(String barcode, String category) async {
    print('Resetting barcode: $barcode for category: $category');
    final collection = await _getCollection();
    var docRef = _firestore.collection(collection).doc(barcode);
    var doc = await docRef.get();

    if (doc.exists) {
      var data = doc.data() as Map<String, dynamic>;
      var scanned = List<String>.from(data['scanned'] ?? []);
      scanned.remove(category);

      await docRef.update({
        'scanned': scanned,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(0),
      });
      print('Barcode reset successful.');
    } else {
      print('Barcode not found for reset.');
    }
  }

  static Future<void> setUpBarcodes(String path, String type) async {
    if (!kDebugMode) return;

    print('Setting up barcodes from path: $path with type: $type');
    final batch = _firestore.batch();
    final collection = await _getCollection();

    final fileString = await rootBundle.loadString(path);
    final barcodes = fileString.split("\n").map((line) => line.trim()).toList();
    
    for (var barcode in barcodes) {
      final docRef = _firestore.collection(collection).doc(barcode);
      batch.set(docRef, {
        'scanned': [],
        'timestamp': DateTime.fromMillisecondsSinceEpoch(0),
        'type': type,
      });
    }

    try {
      await batch.commit();
      debugPrint('Batch write successful');
    } catch (error) {
      debugPrint('Error writing batch: $error');
    }
  }

  static Future<List<Map<String, dynamic>>> getCategories() async {
    print('Fetching categories...');
    final collection = await _getCollection();
    var snapshot = await _firestore
        .collection(collection)
        .doc('categories')
        .get();

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      var categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
      print('Categories fetched: $categories');
      return categories;
    }
    print('No categories found.');
    return [];
  }

  static Future<void> addCategory(Map<String, dynamic> category) async {
    print('Adding category: $category');
    final collection = await _getCollection();
    var categories = await getCategories();
    categories.add(category);

    await _firestore
        .collection(collection)
        .doc('categories')
        .set({'categories': categories}, SetOptions(merge: true));
    print('Category added successfully.');
  }

  static Future<void> deleteCategory(String categoryName) async {
    print('Deleting category: $categoryName');
    final collection = await _getCollection();
    var categories = await getCategories();
    categories.removeWhere((cat) => cat['name'] == categoryName);

    await _firestore
        .collection(collection)
        .doc('categories')
        .set({'categories': categories}, SetOptions(merge: true));
    print('Category deleted successfully.');
  }

  static Future<Stream<QuerySnapshot<Object?>>> getBarcodesStream() async {
    print('Getting barcodes stream...');
    return _firestore
        .collection(await _getCollection())
        .snapshots();
  }

  static Stream<DocumentSnapshot> getSettingsStream() {
    return _firestore.collection('settings').doc('config').snapshots();
  }
}
