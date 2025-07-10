import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:event_scan/constants/day_colors.dart';
import 'package:event_scan/services/database.dart';
import '../../components/edit_user_dialog.dart';
import '../../models/category_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

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

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'All';
  late List<String> _categories;
  String _searchQuery = '';
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _isExporting = false;
  
  @override
  void initState() {
    super.initState();
    _categories = ['All', ...widget.categories.map((c) => c.name)];
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSearchHeader(),
            _buildUsersList(),
          ],
        ),
        _buildExportFAB(),
        if (_isExporting) _buildExportingOverlay(),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return SliverAppBar(
      floating: true,
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 140,
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Hero(
                tag: 'searchBar',
                child: Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(15),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
            ),
            _buildFilterChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _categories.map((category) {
          bool isSelected = _selectedCategory == category;
          CategoryModel? categoryModel = category != 'All' 
            ? widget.categories.firstWhere((c) => c.name == category)
            : null;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: category != 'All' ? Icon(
                categoryModel!.icon.data,
                color: isSelected ? Colors.white : Color(categoryModel.colorValue),
              ) : const Icon(Icons.category),
              label: Text(category),
              onSelected: (bool selected) {
                setState(() => _selectedCategory = category);
                _animationController.reset();
                _animationController.forward();
              },
              backgroundColor: Colors.blue.withOpacity(0.1),
              selectedColor: category != 'All' 
                ? Color(categoryModel!.colorValue)
                : Theme.of(context).primaryColor,
              labelStyle: const TextStyle(
                color: Colors.white,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsersList() {
    var filteredUsers = _filterUsers();
    
    if (filteredUsers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 100,
                color: Colors.grey.shade400,
              ),
              const Text('No users found'),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(filteredUsers.length, (index) {
            final user = filteredUsers[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 300),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildUserCard(user),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    var codeStr = user['code'].toString();
    var codeLast3 = codeStr.substring(codeStr.length - 3);
    var scanned = user['scanned'] as Map<String, dynamic>? ?? {};
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => showEditUserDialog(context, [user]),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
          ],
        ),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              foregroundColor: Theme.of(context).colorScheme.primary,
              backgroundColor: dayColors[widget.selectedDay].withOpacity(0.3),
              child: Text(codeLast3, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            trailing: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.withOpacity(0.1),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: _buildCategoryIcons(scanned.keys.toList()),
              ),
            ),
            title: Text(
              user['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user['subtitle'] ?? ''),
            children: [
              _buildUserDetails(user, scanned),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryIcons(List<String> categoryNames) {
    categoryNames.sort();
    return categoryNames.map((name) {
      CategoryModel category;
      try { category = widget.categories.firstWhere((cat) => cat.name == name); } catch (e) { return Container(); }
      return Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        message: category.name,
        child: Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Icon(
            category.icon.data,
            size: 16,
            color: Color(category.colorValue),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildUserDetails(Map<String, dynamic> user, Map<String, dynamic> scanned) {
    final rawExtras = user['extras'] ?? {};
    final extras = (rawExtras is Map)
      ? rawExtras.map<String, dynamic>((k, v) => MapEntry(k.toString(), v))
      : <String, dynamic>{};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final field in extras.entries) ...[
            _buildInfoRow(Icons.info, '${field.key}: ${field.value}'),
          ],
          const Divider(),
          _buildCategoryGrid(scanned),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(Map<String, dynamic> scanned) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: scanned.length,
      itemBuilder: (context, index) {
        String categoryName = scanned.keys.elementAt(index);
        List<dynamic> days = scanned[categoryName] ?? [];
        CategoryModel category = widget.categories.firstWhere(
          (c) => c.name == categoryName,
          orElse: () => widget.categories.first,
        );
        
        return Container(
          decoration: BoxDecoration(
            color: Color(category.colorValue).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Tooltip(
            message: '${category.name}\nDays: ${days.join(", ")}',
            triggerMode: TooltipTriggerMode.tap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon.data, size: 24),
                const SizedBox(width: 4),
                Text(
                  days.join(", "),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportFAB() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: _exportToExcel,
        icon: const Icon(Icons.file_download),
        label: const Text('Export to Excel'),
      ),
    );
  }

  Widget _buildExportingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Exporting...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterUsers() {
    return widget.users.where((user) {
      final scanned = user['scanned'] as Map<String, dynamic>? ?? {};
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
        scannedOnDay = days.isNotEmpty && (widget.selectedDay == 0 || days.contains(widget.selectedDay));
      }

      final extras = user['extras'] as Map<String, dynamic>? ?? {};
      bool extrasMatch = extras.values.any((value) =>
        value?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false
      );

      return scannedOnDay && (
        (user['title']?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
        || (user['code']?.toLowerCase().contains(_searchQuery) ?? false)
        || extrasMatch
      );
    }).toList();
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    var excel = Excel.createExcel();

    // Gather all extras keys
    final allExtrasKeys = widget.users.fold<Set<String>>({}, (keys, user) {
      final extras = user['extras'] as Map<String, dynamic>? ?? {};
      return keys..addAll(extras.keys);
    }).toList();

    // Create "All Days" sheet with dynamic extras
    excel.rename("Sheet1", "All Days");
    final allDaysSheet = excel['All Days'];

    // Headers: code, title, subtitle, dynamic extras, attendance
    final headers = ['Code', 'Title', 'Subtitle', ...allExtrasKeys, 'Attendance'];
    for (var header in headers) {
      final headerCell = allDaysSheet.cell(CellIndex.indexByColumnRow(
        columnIndex: headers.indexOf(header),
        rowIndex: 0,
      ));
      headerCell
        ..value = TextCellValue(header)
        ..cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
      allDaysSheet.setColumnAutoFit(headerCell.columnIndex);
    }

    // Fill rows
    for (final user in widget.users) {
      // Build row with code, title, subtitle, dynamic extras
      final rowValues = <TextCellValue>[
        TextCellValue(user['code']?.toString() ?? ''),
        TextCellValue(user['title']?.toString() ?? ''),
        TextCellValue(user['subtitle']?.toString() ?? ''),
      ];
      final extras = user['extras'] as Map<String, dynamic>? ?? {};
      for (var key in allExtrasKeys) {
        rowValues.add(TextCellValue(extras[key]?.toString() ?? ''));
      }

      // Attendance
      final categoriesScanned = widget.categories
          .where((c) => ((user['scanned'] ?? {})[c.name] ?? []).isNotEmpty)
          .map((c) => '${c.name} - Days ${((user['scanned'] ?? {})[c.name] ?? []).join(", ")}')
          .join('\n');

      rowValues.add(TextCellValue(categoriesScanned));
      allDaysSheet.appendRow(rowValues);

      // Wrap text for attendance cell
      final attendanceIndex = headers.indexOf('Attendance');
      final attendanceCell = allDaysSheet.cell(CellIndex.indexByColumnRow(
        columnIndex: attendanceIndex,
        rowIndex: allDaysSheet.maxRows - 1,
      ));
      attendanceCell.cellStyle = CellStyle(textWrapping: TextWrapping.WrapText);
    }

    // Individual day sheets (rename "Name" -> "Title")
    var settings = await Database.getSettings();
    DateTime startDate = (settings['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    DateTime endDate = (settings['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7));
    int totalDays = endDate.difference(startDate).inDays + 1;

    for (int day = 1; day <= totalDays; day++) {
      final daySheet = excel['Day $day'];
      final dayHeaders = ['Code', 'Title', ...widget.categories.map((c) => c.name)];
      for (var header in dayHeaders) {
        final headerCell = daySheet.cell(CellIndex.indexByColumnRow(
          columnIndex: dayHeaders.indexOf(header),
          rowIndex: 0,
        ));
        headerCell
          ..value = TextCellValue(header)
          ..cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
        daySheet.setColumnAutoFit(headerCell.columnIndex);
      }
      for (final user in widget.users) {
        daySheet.appendRow([
          TextCellValue(user['code']?.toString() ?? ''),
          TextCellValue(user['title']?.toString() ?? ''),
        ]);
        for (final category in widget.categories) {
          final days = (user['scanned'] ?? {})[category.name] as List<dynamic>? ?? [];
          final cell = daySheet.cell(CellIndex.indexByColumnRow(
            columnIndex: dayHeaders.indexOf(category.name),
            rowIndex: daySheet.maxRows - 1,
          ));
          cell..value = IntCellValue(days.contains(day) ? 1 : 0)
            ..cellStyle = CellStyle(backgroundColorHex: (days.contains(day) ? "#c1deca" : "#e7c9c7").excelColor);
          daySheet.setColumnWidth(cell.columnIndex, 20);
        }
      }
    }

    try {
      var fileName = "Event_Scan_Report-${DateTime.now()}.xlsx";
      var outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export to Excel',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(excel.save(fileName: fileName) ?? []),
      );
      if (outputPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File saved to $outputPath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting to Excel: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
}
