import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ExtraField {
  final String key;
  final String value;
  final IconData? icon;

  ExtraField({required this.key, this.value='', this.icon});

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

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    if (icon != null) 'icon': icon!.codePoint,
  };

  ExtraField copyWith({String? key, String? value, IconData? icon}) =>
      ExtraField(key: key ?? this.key, value: value ?? this.value, icon: icon ?? this.icon);

  static List<ExtraField> fromDynamic(dynamic data) {
    if (data is List<ExtraField>) return data;
    if (data is List) {
      return data.map((item) {
        if (item is ExtraField) return item;
        if (item is Map<String, dynamic>) {
          return ExtraField.fromEntry(item['key'] ?? '', item);
        }
        return ExtraField(key: 'Unknown', value: item?.toString() ?? '');
      }).toList();
    }
    return <ExtraField>[];
  }
}

class BarcodeModel {
  final String code;
  final String title; // formerly 'name'
  final String subtitle; // formerly 'designation'
  final List<ExtraField> extras; // new list to store any other user fields
  final Map<String, List<int>> scanned;
  final Timestamp timestamp;
  late bool? isScanned;

  BarcodeModel({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.extras,
    required this.scanned,
    required this.timestamp,
    this.isScanned,
  });

  factory BarcodeModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final extrasRaw = data?['extras'] as List? ?? [];
    
    return BarcodeModel(
      code: data?['code'] ?? '',
      title: data?['title'] ?? '',
      subtitle: data?['subtitle'] ?? '',
      extras: extrasRaw.map((item) => ExtraField.fromEntry(item['key'], item)).toList(),
      scanned: (data?['scanned'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as List).map((e) => e as int).toList()),
      ),
      timestamp: data?['timestamp'] ?? Timestamp.now(),
    );
  }

  factory BarcodeModel.from(dynamic data) {
    if (data is BarcodeModel) return data;
    if (data is Map<String, dynamic>) {
      return BarcodeModel(
        code: data['code'] ?? '',
        title: data['title'] ?? '',
        subtitle: data['subtitle'] ?? '',
        extras: ExtraField.fromDynamic(data['extras']),
        scanned: (data['scanned'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, (value as List).map((e) => e as int).toList()),
        ),
        timestamp: data['timestamp'] ?? Timestamp.now(),
      );
    }
    return BarcodeModel.empty();
  }

  factory BarcodeModel.empty() => BarcodeModel(code: '', title: '', subtitle: '', extras: [], scanned: {}, timestamp: Timestamp.now(), isScanned: null);

  BarcodeModel copyWith({
    String? code,
    String? title,
    String? subtitle,
    List<ExtraField>? extras,
    Map<String, List<int>>? scanned,
    Timestamp? timestamp,
    bool? isScanned,
  }) {
    return BarcodeModel(
      code: code ?? this.code,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      extras: extras ?? this.extras,
      scanned: scanned ?? this.scanned,
      timestamp: timestamp ?? this.timestamp,
      isScanned: isScanned ?? this.isScanned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'subtitle': subtitle,
      'extras': extras.map((field) => {'key': field.key, ...field.toMap()}).toList(),
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
