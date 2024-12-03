import 'package:flutter/material.dart';
import '../models/barcode_model.dart';
import '../services/database.dart';

class BarcodeRow extends StatelessWidget {
  final BarcodeModel barcode;

  const BarcodeRow({super.key, required this.barcode});

  @override
  Widget build(BuildContext context) {
    final isScanned = barcode.scanned.isNotEmpty;
    final subtitle = barcode.timestamp.toDate().toString();

    return Card(
      child: ListTile(
        title: Text('${barcode.name} (${barcode.code})'),
        subtitle: Text(subtitle),
        trailing: CircleAvatar(
          backgroundColor: isScanned ? Colors.green : Colors.blueGrey,
          child: Icon(isScanned ? Icons.check : Icons.more_horiz),
        ),
        onLongPress: () => _showResetDialog(context),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    final scannedCategories = barcode.scanned;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Reset"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select categories to reset:"),
              Wrap(
                spacing: 10,
                children: scannedCategories.map((category) {
                  return FilterChip(
                    label: Text(category),
                    selected: true,
                    onSelected: (_) {},
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Confirm"),
              onPressed: () {
                for (var category in scannedCategories) {
                  Database.resetBarcode(barcode.code, category);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
