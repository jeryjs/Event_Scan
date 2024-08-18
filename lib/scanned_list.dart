import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScannedList extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('barcodes').where('scanned', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final barcodes = snapshot.data!.docs;
        return ListView.builder(
          itemCount: barcodes.length,
          itemBuilder: (context, index) {
            var barcode = barcodes[index];
            return ListTile(
              title: Text(barcode.id),
              subtitle: Text('Scanned at: ${barcode['lastScanned'].toDate()}'),
              trailing: Checkbox(
                value: barcode['scanCount'] == 1,
                onChanged: null,
              ),
            );
          },
        );
      },
    );
  }
}
