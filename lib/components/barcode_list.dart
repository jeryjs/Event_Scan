import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:party_scan/components/barcode_row.dart';

class BarcodeList extends StatefulWidget {
  final Stream<QuerySnapshot> stream;
  final ScrollController scrollController;
  const BarcodeList({super.key, required this.stream, required this.scrollController});

  @override
  _BarcodeListState createState() => _BarcodeListState();
}

class _BarcodeListState extends State<BarcodeList> {
  String searchTerm = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by time or code',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                searchTerm = value;
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: widget.stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              final filteredDocs = docs.where((doc) {
                return doc.id.contains(searchTerm) ||
                    doc['timestamp'].toDate().toString().contains(searchTerm);
              }).toList();

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  var doc = filteredDocs[index];
                  return BarcodeRow(document: doc);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
