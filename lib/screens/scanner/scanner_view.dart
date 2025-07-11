import 'package:flutter/material.dart';
import 'package:event_scan/models/category_model.dart';
import 'package:event_scan/screens/scanner/bottom_bar.dart';
import 'barcode_scanner.dart';

class ScannerView extends StatelessWidget {
  final CategoryModel category;
  final List<CategoryModel> categories;
  final int selectedDay;

  const ScannerView({super.key, required this.category, required this.categories, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: Stack(children: [
        BarcodeScanner(category: category, categories: categories),
        BottomBar(category: category, categories: categories, selectedDay: selectedDay),
      ]),
    );
  }
}
