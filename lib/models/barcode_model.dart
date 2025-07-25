import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExtraField {
  final String key;
  final String value;
  final IconData? icon;

  ExtraField({required this.key, required this.value, this.icon});

  factory ExtraField.fromEntry(String key, dynamic data) {
    if (data is Map<String, dynamic>) {
      final iconCode = data['icon'];
      return ExtraField(
        key: key,
        value: data['value']?.toString() ?? '',
        icon: iconCode != null ? IconData(iconCode, fontFamily: 'MaterialIcons') : null,
      );
    }
    return ExtraField(key: key, value: data?.toString() ?? '');
  }

  Map<String, dynamic> toMap() => icon != null 
      ? {'value': value, 'icon': icon!.codePoint}
      : {'value': value};

  ExtraField copyWith({String? key, String? value, IconData? icon}) =>
      ExtraField(key: key ?? this.key, value: value ?? this.value, icon: icon ?? this.icon);
}

class BarcodeModel {
  final String code;
  final String title; // formerly 'name'
  final String subtitle; // formerly 'designation'
  final List<ExtraField> extras; // new list to store any other user fields
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
    final extrasData = data?['extras'] as Map<String, dynamic>? ?? {};
    
    return BarcodeModel(
      code: data?['code'] ?? '',
      title: data?['title'] ?? '',
      subtitle: data?['subtitle'] ?? '',
      extras: extrasData.entries.map((e) => ExtraField.fromEntry(e.key, e.value)).toList(),
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
      'extras': {for (var field in extras) field.key: field.toMap()},
      'scanned': scanned,
      'timestamp': timestamp,
    };
  }

  bool query(String searchTerm) {
    return code.toLowerCase().contains(searchTerm) ||
           title.toLowerCase().contains(searchTerm) ||
           subtitle.toLowerCase().contains(searchTerm) ||
           extras.map((f) => f.value).any((v) => v.toString().toLowerCase().contains(searchTerm)) ||
           timestamp.toDate().toString().contains(searchTerm);
  }
}
