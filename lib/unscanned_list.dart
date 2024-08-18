import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UnscannedList extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('barcodes').where('scanned', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        final barcodes = snapshot.data!.docs;
        return ListView.builder(
          itemCount: barcodes.length,
          itemBuilder: (context, index) {
            var barcode = barcodes[index];
            return ListTile(
              title: Text(barcode.id),
            );
          },
        );
      },
    );
  }
}
