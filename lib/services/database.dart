import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'shared_prefs.dart';

class Database {
  static Future<bool?> checkBarcode(String barcode) async {
    final collection = await SharedPrefs.getCollectionName() as String;
    var doc = await FirebaseFirestore.instance.collection(collection).doc(barcode).get();

    if (doc.exists) {
      final isScanned = doc['scanned']?? false;
      FirebaseFirestore.instance.collection(collection).doc(barcode).update({
        'scanned': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return isScanned;
    } else {
      return null;
    }
  }

  static Stream<QuerySnapshot> getScannedBarcodes(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .where('scanned', isEqualTo: true)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getPendingBarcodes(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .where('scanned', isEqualTo: false)
        .snapshots();
  }

  static setUpBarcodes(String path, String type, collection) async {
    if (!kDebugMode) return;
    
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    final fileString = await rootBundle.loadString(path);
    fileString.split("\n").forEach((line) {
      final barcode = line.trim();  // Remove the carriage return

      final docRef = firestore.collection(collection).doc(barcode);
      batch.set(docRef, {
        'scanned': false,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(0),
        'type': type,
      });
      debugPrint(barcode);
    });

    try {
      batch.commit();
      debugPrint('Batch write successful');
    } catch (error) {
      debugPrint('Error writing batch: $error');
    }
  }
}
