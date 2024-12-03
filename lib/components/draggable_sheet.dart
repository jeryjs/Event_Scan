import 'package:flutter/material.dart';

import '../services/database.dart';
import 'barcode_list.dart';

class DraggableSheet extends StatelessWidget {
  final int index;
  final String collection;

  const DraggableSheet({super.key, required this.index, required this.collection});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      shouldCloseOnMinExtent: true,
      expand: false,
      builder: (context, scrollController) {
        return DefaultTabController(
          length: 2,
          initialIndex: index,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.done), text: 'Scanned'),
                  Tab(icon: Icon(Icons.pending), text: 'Pending'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                BarcodeList(
                  stream: Database.getBarcodes(category: collection, isScanned: true),
                  scrollController: scrollController,
                  category: collection,
                  isScanned: true,
                ),
                BarcodeList(
                  stream: Database.getBarcodes(category: collection, isScanned: false),
                  scrollController: scrollController,
                  category: collection,
                  isScanned: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
