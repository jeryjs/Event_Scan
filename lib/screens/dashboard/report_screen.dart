import 'package:flutter/material.dart';
import '../../constants/day_colors.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/category_model.dart';

class ReportScreen extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final int selectedDay;
  final List<CategoryModel> categories;

  const ReportScreen({
    super.key, 
    required this.users, 
    required this.selectedDay,
    required this.categories,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedCategory = 'All';
  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = ['All', ...widget.categories.map((c) => c.name)];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterOptions(),
        Expanded(child: _buildReportDataTable()),
        _buildExportButton(),
      ],
    );
  }

  Widget _buildFilterOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButton<String>(
        value: _selectedCategory,
        onChanged: (String? newValue) {
          setState(() {
            _selectedCategory = newValue!;
          });
        },
        items: _categories.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text('Category: $value'),
          );
        }).toList(),
        isExpanded: true,
      ),
    );
  }

  Widget _buildReportDataTable() {
    var filteredUsers = widget.users.where((user) {
      var scanned = user['scanned'] as Map<String, dynamic>? ?? {};
      bool scannedOnDay = false;
      if (_selectedCategory == 'All') {
        for (var days in scanned.values) {
          if (widget.selectedDay == 0 || (days as List).contains(widget.selectedDay)) {
            scannedOnDay = true;
            break;
          }
        }
      } else {
        var days = scanned[_selectedCategory] as List<dynamic>? ?? [];
        scannedOnDay = widget.selectedDay == 0 || days.contains(widget.selectedDay);
      }
      return scannedOnDay;
    }).toList();

    if (filteredUsers.isEmpty) {
      return const Center(child: Text('No data for the selected filters'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: _createColumns(),
        rows: _createRows(filteredUsers),
      ),
    );
  }

  List<DataColumn> _createColumns() {
    return [
      const DataColumn(label: Text('Code')),
      const DataColumn(label: Text('Name')),
      const DataColumn(label: Text('Categories')),
    ];
  }

  List<DataRow> _createRows(List<Map<String, dynamic>> users) {
    return users.map((user) {
      var codeStr = user['code'].toString();
      var codeLast3 = codeStr.substring(codeStr.length - 3);
      var categories = (user['scanned'] as Map<String, dynamic>? ?? {}).keys.toList();
      return DataRow(cells: [
        DataCell(
          CircleAvatar(
            backgroundColor: (dayColors[widget.selectedDay % dayColors.length]).withOpacity(0.4),
            child: Text(codeLast3),
          ),
        ),
        DataCell(Text(user['name'] ?? '')),
        DataCell(_buildCategoryIcons(categories)),
      ]);
    }).toList();
  }

  Widget _buildCategoryIcons(List<String> categoryNames) {
    return Row(
      children: categoryNames.map((name) {
        CategoryModel category;
        try { category = widget.categories.firstWhere((cat) => cat.name == name); } catch (e) { return Container(); }
        return Tooltip(
          message: name,
          child: Icon(
            category.icon.data,
            color: Color(category.colorValue),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExportButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.file_download),
        label: const Text('Export to CSV'),
        onPressed: _exportToCSV,
      ),
    );
  }

  Future<void> _exportToCSV() async {
    String csvData = 'Code,Name,Mail,Phone,Categories\n';
    var filteredUsers = widget.users.where((user) {
      var scanned = user['scanned'] as Map<String, dynamic>? ?? {};
      bool scannedOnDay = false;
      if (_selectedCategory == 'All') {
        for (var days in scanned.values) {
          if (widget.selectedDay == 0 || (days as List).contains(widget.selectedDay)) {
            scannedOnDay = true;
            break;
          }
        }
      } else {
        var days = scanned[_selectedCategory] as List<dynamic>? ?? [];
        scannedOnDay = widget.selectedDay == 0 || days.contains(widget.selectedDay);
      }
      return scannedOnDay;
    }).toList();

    for (var user in filteredUsers) {
      var categories = (user['scanned'] as Map<String, dynamic>? ?? {}).keys.join('|');
      csvData +=
          '${user['code']},${user['name']},${user['mail']},${user['phone']},$categories\n';
    }

    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/report_day_${widget.selectedDay}.csv';
      final file = File(path);
      await file.writeAsString(csvData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error exporting to CSV'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
