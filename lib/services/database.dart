import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'shared_prefs.dart';

class Database {
  static Future<bool?> checkBarcode(String barcode) async {
    final collection = await SharedPrefs.getCollectionName() as String;
    // var doc = await FirebaseFirestore.instance.collection(collection).doc(barcode).get();
    final fileString = await rootBundle.loadString("assets/barcodes_ce.txt");
    final lines = fileString.split("\n");
    final line = lines.contains(barcode)?barcode:"FP24060397"; // FP24060397

    var doc = await FirebaseFirestore.instance.collection('FreshersParty_2024').doc(line).get();

    if (doc.exists) {
      final isScanned = doc['scanned']?? false;
      // FirebaseFirestore.instance.collection(collection).doc(barcode).update({
      //   'scanned': true,
      //   'timestamp': FieldValue.serverTimestamp(),
      // });
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
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  static setUpBarcodes(String path, String type) async {
    if (!kDebugMode) return;

    final fileString = await rootBundle.loadString(path);
    final lines = fileString.split("\n");

    int index = 0;
    final notexist = [];
    Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (index >= lines.length) {
        timer.cancel();
        debugPrint("Batch committed: $type");
        debugPrint("Not exist: $notexist");
        if(type == "ce") {
          await Database.setUpBarcodes('assets/barcodes_se.txt', "se");
        } else {
          return;
        }
      }

      final line = lines[index];
      var doc = await FirebaseFirestore.instance.collection('FreshersParty_2024').doc(line).get();
      // FirebaseFirestore.instance.collection('FreshersParty_2024').doc(line).set({
      //   'scanned': false,
      //   'timestamp': DateTime.fromMillisecondsSinceEpoch(0),
      //   'type': type
      // });

      if (!doc.exists) {
        notexist.add(line);
        debugPrint("$index)\t not exists: \t $line");
      } else {
        debugPrint("$index)\t exists: \t $line");
      }
      // debugPrint("$index)\t $line");

      index++;
    });
  }
}
