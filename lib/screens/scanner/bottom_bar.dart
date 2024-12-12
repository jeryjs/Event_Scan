import 'package:flutter/material.dart';
import 'package:party_scan/models/category_model.dart';
import 'draggable_sheet.dart';

class BottomBar extends StatelessWidget {
  final CategoryModel category;
  final List<CategoryModel> categories;
  final int selectedDay;
  
  const BottomBar({super.key, required this.category, required this.categories, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.done), label: 'Scanned'),
          BottomNavigationBarItem(icon: Icon(Icons.pending_outlined), label: 'Pending'),
        ],
        onTap: (index) {
          _showDraggableSheet(context, index);
        },
      ),
    );
  }

  void _showDraggableSheet(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableSheet(index: index, category: category, categories: categories, selectedDay: selectedDay),
    );
  }
}
