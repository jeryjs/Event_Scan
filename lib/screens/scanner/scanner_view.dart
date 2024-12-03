import 'package:flutter/material.dart';
import 'package:party_scan/screens/scanner/bottom_bar.dart';
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
      body: Stack(children: [
        BarcodeScanner(category: category),
        BottomBar(category: category),
      ]),
    );
  }
}
