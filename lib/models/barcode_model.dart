import 'package:cloud_firestore/cloud_firestore.dart';

class BarcodeModel {
  final String id;
  final bool scanned;
  final Timestamp timestamp;

  BarcodeModel({
    required this.id,
    required this.scanned,
    required this.timestamp,
  });

  factory BarcodeModel.fromDocument(DocumentSnapshot doc) {
    return BarcodeModel(
      id: doc.id,
      scanned: doc['scanned'] ?? false,
      timestamp: doc['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scanned': scanned,
      'timestamp': timestamp,
    };
  }
}
