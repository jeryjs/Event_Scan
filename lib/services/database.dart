import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/category_model.dart';

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

  static Future<int> _calculateCurrentDay() async {
    var snapshot = await _firestore.collection('settings').doc('config').get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      final startDate = (data['startDate'] as Timestamp).toDate();
      return DateTime.now().difference(startDate).inDays + 1;
    }
    return 1;
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
    var snapshot = await _firestore.collection('settings').doc('categories').get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      var categoriesData = List<Map<String, dynamic>>.from(data['categories'] ?? []);
      return categoriesData.map((catData) => CategoryModel.fromMap(catData)).toList();
    }
    return [];
  }

  static Future<void> addCategory(CategoryModel category) async {
    var categories = await getCategories();
    categories.add(category);
    await _firestore.collection('settings').doc('categories').set({
      'categories': categories.map((cat) => cat.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteCategory(String categoryName) async {
    var categories = await getCategories();
    categories.removeWhere((cat) => cat.name == categoryName);
    await _firestore.collection('settings').doc('categories').set({
      'categories': categories.map((cat) => cat.toMap()).toList(),
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

  static Future<String> getEventTitle() async {
    var snapshot = await _firestore.collection('settings').doc('config').get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      return data['eventTitle'] ?? 'Event Scan';
    }
    return 'Event Scan';
  }

  static Future<void> saveEventTitle(String title) async {
    await _firestore.collection('settings').doc('config').set({
      'eventTitle': title,
    }, SetOptions(merge: true));
  }
}
