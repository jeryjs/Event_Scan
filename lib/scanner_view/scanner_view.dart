import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';
import '../scanner_view/barcode_scanner.dart';
import '../services/shared_prefs.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  _ScannerViewState createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  String collectionName = kDebugMode ? "barcodes" : "";

  @override
  void initState() {
    super.initState();
    _loadCollectionName();
  }

  Future<void> _loadCollectionName() async {
    collectionName = await SharedPrefs.getCollectionName() ?? collectionName;

    if (collectionName == "") {
      _showCollectionNameDialog();
    }

    setState(() {});
  }

  Future<void> _saveCollectionName(String name) async {
    await SharedPrefs.saveCollectionName(name);
    setState(() {
      collectionName = name;
    });
  }

  void _showCollectionNameDialog() {
    TextEditingController controller = TextEditingController(text: collectionName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Collection Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("This is a sort of private key to your tickets database. Do not modify unless you know what you are doing."),
              TextField(
                controller: controller,
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showConfirmationDialog(controller.text);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(String newName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Collection Name Change'),
          content: const Text('Are you sure you want to change the collection name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _saveCollectionName(newName);
                Navigator.pop(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Party Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showCollectionNameDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          BarcodeScanner(collectionName: collectionName),
          BottomNavBar(collectionName: collectionName,),
        ],
      ),
    );
  }
}
