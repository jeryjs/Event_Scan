import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BarcodeRow extends StatelessWidget {
  final DocumentSnapshot document;

  const BarcodeRow({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final subtitle =
        (document['timestamp'].millisecondsSinceEpoch == 1641031200000)
            ? "Not yet Scanned"
            : document['timestamp'].toDate().toString();
    
    return ListTile(
      title: Text(document.id),
      subtitle: Text(subtitle),
      trailing: CircleAvatar(
        backgroundColor: document['scanned'] ? Colors.green : Colors.blueGrey,
        child: Icon(
          document['scanned'] ? Icons.check : Icons.pending,
          color: Colors.white,
        ),
      ),
    );
  }
}
