import 'package:flutter/material.dart';
import 'barcode_scanner.dart';

class ScannerView extends StatelessWidget {
  final String category;

  const ScannerView({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: BarcodeScanner(category: category),
    );
  }
}
