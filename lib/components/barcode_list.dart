import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'barcode_row.dart';
import '../models/barcode_model.dart';
import '../models/category_model.dart';

class BarcodeList extends StatefulWidget {
  final Stream<QuerySnapshot> stream;
  final ScrollController scrollController;
  final String category;
  final bool isScanned;
  final List<CategoryModel> categories;

  const BarcodeList({
    super.key,
    required this.stream,
    required this.scrollController,
    required this.category,
    required this.isScanned,
    required this.categories,
  });

  @override
  BarcodeListState createState() => BarcodeListState();
}

class BarcodeListState extends State<BarcodeList> {
  String searchTerm = '';

  bool _matchesSearch(BarcodeModel barcode) {
    if (searchTerm.isEmpty) return true;
    final lowerCaseTerm = searchTerm.toLowerCase();
    return barcode.code.toLowerCase().contains(lowerCaseTerm) ||
           barcode.title.toLowerCase().contains(lowerCaseTerm) ||
           barcode.subtitle.toLowerCase().contains(lowerCaseTerm) ||
           barcode.extras.values.any((value) => value.toString().toLowerCase().contains(lowerCaseTerm)) ||
           barcode.timestamp.toDate().toString().contains(lowerCaseTerm);
  }

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
        const SizedBox(height: 8),
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
                        ? barcode.scanned[widget.category]?.isNotEmpty ?? false
                        : !(barcode.scanned[widget.category]?.isNotEmpty ?? false);

                return matchesCategory && barcode.code.isNotEmpty && _matchesSearch(barcode);
              }).toList();

                final sortedDocs = filteredDocs
                ..sort((a, b) {
                  if (!widget.isScanned) {
                  final aCode = (a.data() as Map<String, dynamic>)['code'] as String;
                  final bCode = (b.data() as Map<String, dynamic>)['code'] as String;
                  return aCode.compareTo(bCode);
                  } else {
                  final aTimestamp = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTimestamp = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  return (bTimestamp ?? Timestamp.now()).compareTo(aTimestamp ?? Timestamp.now());
                  }
                });

              if (sortedDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 100, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('No barcodes found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: sortedDocs.length,
                itemBuilder: (context, index) {
                  var doc = sortedDocs[index];
                  final barcode = BarcodeModel.fromDocument(doc);
                  return BarcodeRow(barcode: barcode, categories: widget.categories);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
