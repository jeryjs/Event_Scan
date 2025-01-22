import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

class CategoryModel {
  final String name;
  final IconPickerIcon icon;
  final int colorValue;

  CategoryModel({
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> data) {
    return CategoryModel(
      name: data['name'],
      icon: deserializeIcon(data['data'])??const IconPickerIcon(name: "Category", data: Icons.category, pack: IconPack.material),
      colorValue: data['colorValue'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'data': serializeIcon(icon),
      'colorValue': colorValue,
    };
  }
}