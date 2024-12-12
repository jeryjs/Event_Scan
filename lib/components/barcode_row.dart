import 'package:flutter/material.dart';
import '../constants/day_colors.dart';
import '../models/barcode_model.dart';
import '../models/category_model.dart';

class BarcodeRow extends StatelessWidget {
  final BarcodeModel barcode;
  final List<CategoryModel> categories;

  const BarcodeRow({super.key, required this.barcode, required this.categories});

  @override
  Widget build(BuildContext context) {
    final lastThreeDigits = barcode.code.length >= 3
        ? barcode.code.substring(barcode.code.length - 3)
        : barcode.code;

    return Hero(
      tag: 'barcode-${barcode.code}',
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
        shadowColor: Colors.grey.withOpacity(0.5),
        child: InkWell(
          onTap: () => _showDetailDialog(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(lastThreeDigits),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            barcode.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Code: ${barcode.code}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            barcode.designation,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (barcode.scanned.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildCategoryIcons(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String lastThreeDigits) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          lastThreeDigits,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcons(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: barcode.scanned.entries.map((entry) {
          CategoryModel category;
          try { category = categories.firstWhere((cat) => cat.name == entry.key); } catch (e) { return Container(); }
          return Row(
            children: entry.value.map((day) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: '${category.name} - Day $day',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Color(category.colorValue).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          category.icon.data,
                          size: 16,
                          color: Color(category.colorValue),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$day',
                          style: TextStyle(
                            color: Color(category.colorValue),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  void _showDetailDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailHeader(),
                    const Divider(height: 32),
                    _buildDetailRow(Icons.email, barcode.email),
                    _buildDetailRow(Icons.phone, barcode.phone),
                    _buildDetailRow(Icons.access_time, barcode.timestamp.toDate().toString()),
                    const SizedBox(height: 16),
                    _buildScannedCategories(context),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Close"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildDetailHeader() {
    return Column(
      children: [
        Text(
          barcode.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          barcode.code,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedCategories(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: barcode.scanned.entries.indexed.map((entry) {
        CategoryModel category;
        try { category = categories.firstWhere((cat) => cat.name == entry.$2.key); } catch (e) { return Container(); }
        final dayColor = dayColors[entry.$1+1];
        return Chip(
          avatar: Icon(category.icon.data, color: dayColor),
          label: Text('${entry.$2.key} - Day ${entry.$2.value}'),
          backgroundColor: dayColor.withOpacity(0.1),
        );
      }).toList(),
    );
  }
}
