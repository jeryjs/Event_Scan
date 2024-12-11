import 'package:cloud_firestore/cloud_firestore.dart';

class BarcodeModel {
  final String code;
  final String name;
  final String email;
  final String phone;
  final Map<String, List<int>> scanned;
  final Timestamp timestamp;

  BarcodeModel({
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.scanned,
    required this.timestamp,
  });

  factory BarcodeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return BarcodeModel(
      code: data?['code'] ?? '',
      name: data?['name'] ?? '',
      email: data?['email'] ?? '',
      phone: data?['phone'] ?? '',
      scanned: (data?['scanned'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(
          key,
          (value as List).map((e) => e as int).toList(),
        ),
      ),
      timestamp: data?['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'email': email,
      'phone': phone,
      'scanned': scanned,
      'timestamp': timestamp,
    };
  }
}
