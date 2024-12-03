import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'barcode_row.dart';
import '../models/barcode_model.dart';

class BarcodeList extends StatefulWidget {
  final Stream<QuerySnapshot> stream;
  final ScrollController scrollController;
  final String category;
  final bool isScanned;

  const BarcodeList({
    super.key,
    required this.stream,
    required this.scrollController,
    required this.category,
    required this.isScanned,
  });

  @override
  BarcodeListState createState() => BarcodeListState();
}

class BarcodeListState extends State<BarcodeList> {
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
                var barcode = BarcodeModel.fromDocument(doc);
                final matchesCategory = widget.category == 'all' || widget.category.isEmpty
                    ? true
                    : widget.isScanned
                        ? barcode.scanned.contains(widget.category)
                        : !barcode.scanned.contains(widget.category);

                return matchesCategory &&
                    (barcode.code.contains(searchTerm) ||
                     barcode.timestamp.toDate().toString().contains(searchTerm));
              }).toList();

              final sortedDocs = filteredDocs
                ..sort((a, b) => (b['timestamp'] as Timestamp)
                    .compareTo(a['timestamp'] as Timestamp));

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: sortedDocs.length,
                itemBuilder: (context, index) {
                  var doc = sortedDocs[index];
                  final barcode = BarcodeModel.fromDocument(doc);
                  return BarcodeRow(barcode: barcode);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
