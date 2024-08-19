import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_scan/services/database.dart';

class BarcodeRow extends StatelessWidget {
  final DocumentSnapshot document;

  const BarcodeRow({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final isSingle = (document['type'] ?? "se") == "se";
    final subtitle = (document['timestamp'].millisecondsSinceEpoch == 0)
        ? "Not yet Scanned"
        : document['timestamp'].toDate().toString();
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          child: Icon(
            isSingle ? Icons.person : Icons.people_alt,
            color: isSingle ? Colors.blue[100] : Colors.pink[100],
          ),
        ),
        title: Text(document.id),
        subtitle: Text(subtitle),
        trailing: CircleAvatar(
          backgroundColor: document['scanned'] ? Colors.green : Colors.blueGrey,
          child: Icon(
            document['scanned'] ? Icons.check : Icons.more_horiz,
          ),
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Confirm Reset"),
                content: const Text("Are you sure you want to reset this barcode?"),
                actions: [
                  TextButton(
                    child: const Text("Cancel"),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text("Confirm"),
                    onPressed: () {
                      Database.resetBarcode(document.id);
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
