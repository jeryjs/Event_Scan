import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:event_scan/models/category_model.dart';
import '../../services/database.dart';
import '../../components/barcode_list.dart';

class DraggableSheet extends StatefulWidget {
  final int index;
  final CategoryModel category;
  final List<CategoryModel> categories;
  final int selectedDay;

  const DraggableSheet({super.key, required this.index, required this.category, required this.categories, required this.selectedDay});

  @override
  State<DraggableSheet> createState() => _DraggableSheetState();
}

class _DraggableSheetState extends State<DraggableSheet> {
  late Future<Stream<QuerySnapshot>> scannedStream;
  late Future<Stream<QuerySnapshot>> pendingStream;

  @override
  void initState() {
    super.initState();
    scannedStream = Database.getBarcodes(category: widget.category.name, isScanned: true, selectedDay: widget.selectedDay);
    pendingStream = Database.getBarcodes(category: widget.category.name, isScanned: false, selectedDay: widget.selectedDay);
  }

  Widget buildTabView(Future<Stream<QuerySnapshot>> stream, bool isScanned) {
    return FutureBuilder<Stream<QuerySnapshot>>(
      future: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        } else {
          return BarcodeList(
            stream: snapshot.data!,
            scrollController: ScrollController(),
            category: widget.category.name,
            isScanned: isScanned,
            categories: widget.categories,
          );
        }
      },
    );
  }

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
          initialIndex: widget.index,
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
                buildTabView(scannedStream, true),
                buildTabView(pendingStream, false),
              ],
            ),
          ),
        );
      },
    );
  }
}
