import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'scanned_list.dart';
import 'unscanned_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        final doc = await _firestore.collection('barcodes').doc(result.rawContent).get();
        if (doc.exists) {
          await _firestore.collection('barcodes').doc(result.rawContent).update({
            'scanned': true,
            'scanCount': FieldValue.increment(1),
            'lastScanned': FieldValue.serverTimestamp(),
          });
        } else {
          await _firestore.collection('barcodes').doc(result.rawContent).set({
            'scanned': true,
            'scanCount': 1,
            'lastScanned': FieldValue.serverTimestamp(),
          });
        }
        _showSnackBar('Scan successful');
      }
    } catch (e) {
      _showSnackBar('Scan failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  final List<Widget> _pages = <Widget>[
    ScannedList(),
    UnscannedList(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Scan'),
      ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        child: const Icon(Icons.camera_alt),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Scanned',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Unscanned',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
// TODO Implement this library.