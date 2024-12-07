import 'package:flutter/material.dart';

class CategoryIcon {
  final IconData icon;
  final Color color;
  final String? name;

  const CategoryIcon(this.icon, this.color, this.name);
}

final defaultCategoryIcons = [
  const CategoryIcon(Icons.app_registration, Colors.blue, "Registration"),
  const CategoryIcon(Icons.coffee, Colors.brown, "Breakfast"),
  const CategoryIcon(Icons.school, Colors.purple, "Morning Class"),
  const CategoryIcon(Icons.restaurant, Colors.orange, "Lunch"),
  const CategoryIcon(Icons.cast_for_education, Colors.indigo, "Afternoon Class"),
  const CategoryIcon(Icons.local_cafe, Colors.amber, "High Tea"),
];

CategoryIcon getCategoryIcon(int index) {
  if (index < defaultCategoryIcons.length) {
    return defaultCategoryIcons[index];
  }
  return CategoryIcon(Icons.category, Colors.grey, defaultCategoryIcons[index].name);
}

CategoryIcon getCategoryIconByName(String name) {
  return defaultCategoryIcons.firstWhere(
    (e) => e.name == name,
    orElse: () => CategoryIcon(Icons.category, Colors.grey, name),
  );
}