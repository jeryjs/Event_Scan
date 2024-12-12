import 'package:flutter/material.dart';
import 'package:party_scan/models/category_model.dart';
import '../../services/database.dart';
import '../../components/barcode_list.dart';

class DraggableSheet extends StatelessWidget {
  final int index;
  final CategoryModel category;
  final List<CategoryModel> categories;
  final int selectedDay;

  const DraggableSheet({super.key, required this.index, required this.category, required this.categories, required this.selectedDay});

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
                  stream: Database.getBarcodes(category: category.name, isScanned: true, selectedDay: selectedDay),
                  scrollController: scrollController,
                  category: category.name,
                  isScanned: true,
                  categories: categories,
                ),
                BarcodeList(
                  stream: Database.getBarcodes(category: category.name, isScanned: false, selectedDay: selectedDay),
                  scrollController: scrollController,
                  category: category.name,
                  isScanned: false,
                  categories: categories,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
