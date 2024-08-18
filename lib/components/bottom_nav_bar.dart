import 'package:flutter/material.dart';
import 'draggable_sheet.dart';

class BottomNavBar extends StatelessWidget {
  final String collectionName;
  const BottomNavBar({super.key, required this.collectionName});

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
      builder: (context) => DraggableSheet(index: index, collection: collectionName),
    );
  }
}
