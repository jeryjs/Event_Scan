import 'package:cloud_firestore/cloud_firestore.dart';

class BarcodeModel {
  final String code;
  final String name;
  final String mail;
  final String phone;
  final List<String> scanned;
  final Timestamp timestamp;

  BarcodeModel({
    required this.code,
    required this.name,
    required this.mail,
    required this.phone,
    required this.scanned,
    required this.timestamp,
  });

  factory BarcodeModel.fromDocument(DocumentSnapshot doc) {
    return BarcodeModel(
      code: doc['code'] ?? '',
      name: doc['name'] ?? '',
      mail: doc['mail'] ?? '',
      phone: doc['phone'] ?? '',
      scanned: List<String>.from(doc['scanned'] ?? []),
      timestamp: doc['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'mail': mail,
      'phone': phone,
      'scanned': scanned,
      'timestamp': timestamp,
    };
  }
}
