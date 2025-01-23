import 'package:cloud_firestore/cloud_firestore.dart';

class BarcodeModel {
  final String code;
  final String title; // formerly 'name'
  final String subtitle; // formerly 'designation'
  final Map<String, dynamic> extras; // new map to store any other user fields
  final Map<String, List<int>> scanned;
  final Timestamp timestamp;

  BarcodeModel({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.extras,
    required this.scanned,
    required this.timestamp,
  });

  factory BarcodeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return BarcodeModel(
      code: data?['code'] ?? '',
      title: data?['title'] ?? '',
      subtitle: data?['subtitle'] ?? '',
      extras: (data?['extras'] as Map<String, dynamic>? ?? {}),
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
      'title': title,
      'subtitle': subtitle,
      'extras': extras,
      'scanned': scanned,
      'timestamp': timestamp,
    };
  }
}
