import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:event_scan/constants/day_colors.dart';
import 'package:event_scan/services/database.dart';
import 'package:event_scan/models/barcode_model.dart';
import '../../components/edit_user_dialog.dart';
import '../../models/category_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

class ReportScreen extends StatefulWidget {
  final List<BarcodeModel> users;
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
  bool _isFabExpanded = false;
  final Map<String, dynamic> _filters = {};
  
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
                      hintText: 'Search Attendees...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: Icon(_filters.isEmpty ? Icons.filter_list : Icons.filter_list_off),
                        color: _filters.isEmpty ? Colors.white70 : Colors.amber,
                        tooltip: 'Filter Attendees',
                        onPressed: _showFilterDialog,
                        onLongPress: () => setState(() => _filters.clear()),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.blue.withValues(alpha: 0.1),
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
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
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
              const Text('No attendees found'),
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

  Widget _buildUserCard(BarcodeModel user) {
    var codeStr = user.code;
    var codeLast3 = codeStr.substring(codeStr.length - 3);
    var scanned = user.scanned;

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
              backgroundColor: dayColors[widget.selectedDay].withValues(alpha: 0.3),
              child: Text(codeLast3, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            trailing: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.withValues(alpha: 0.1),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: _buildCategoryIcons(scanned.keys.toList()),
              ),
            ),
            title: Text(
              user.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user.subtitle),
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

  Widget _buildUserDetails(BarcodeModel user, Map<String, dynamic> scanned) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final field in user.extras) ...[
            _buildInfoRow(field.icon ?? Icons.info, '${field.key}: ${field.value}'),
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
            color: Color(category.colorValue).withValues(alpha: 0.2),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabExpanded) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('JSON', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _exportToJson,
                  child: const Icon(Icons.code),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Excel', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _exportToExcel,
                  child: const Icon(Icons.table_chart),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          FloatingActionButton.extended(
            onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
            icon: Icon(_isFabExpanded ? Icons.close : Icons.file_download),
            label: Text(_isFabExpanded ? 'Close' : 'Export'),
          ),
        ],
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

  List<BarcodeModel> _filterUsers() {
    return widget.users.where((user) {
      final scanned = user.scanned;
      bool scannedOnDay = false;
      
      // Check if including non-scanned users
      if (_filters['_includeNonScanned'] != null) {
        scannedOnDay = true; // Include everyone if this option is enabled
      } else {
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
      }

      // Apply field filters
      for (var entry in _filters.entries) {
        if (entry.key == '_includeNonScanned') continue; // Skip system filter
        final field = entry.key;
        final fieldFilters = entry.value as List<Map<String, dynamic>>;
        
        // All filters for this field must pass (AND logic within field)
        for (var filter in fieldFilters) {
          final operator = filter['operator'];
          final value = filter['value'];
          if (!user.matchesFilter(field, operator, value)) return false;
        }
      }

      return scannedOnDay && user.query(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showFilterDialog() {
    final fields = ['code', 'title', 'subtitle', ...widget.users.expand((u) => u.extras.map((e) => e.key)).toSet()];
    showDialog(context: context, builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(children: [const Icon(Icons.filter_list, size: 20), const SizedBox(width: 8), const Text('Filters')]),
        content: SizedBox(width: 320, child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: CheckboxListTile(
                dense: true,
                title: const Text('Include non-scanned users', style: TextStyle(fontSize: 14)),
                value: _filters['_includeNonScanned'] != null,
                onChanged: (val) => setDialogState(() => val! ? _filters['_includeNonScanned'] = {'operator': 'include', 'value': true} : _filters.remove('_includeNonScanned')),
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView(
                shrinkWrap: true,
                children: fields.map((field) {
                  final fieldFilters = _filters[field] as List<Map<String, dynamic>>? ?? [];
                  final isActive = fieldFilters.isNotEmpty;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    color: isActive ? Colors.green.withValues(alpha: 0.1) : null,
                    child: ExpansionTile(
                      dense: true,
                      leading: Icon(_getFieldIcon(field), size: 18),
                      title: Text(field, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      subtitle: isActive ? Text('${fieldFilters.length} filter${fieldFilters.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: Colors.green)) : null,
                      children: [
                        if (isActive) Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Wrap(
                            spacing: 4, runSpacing: 4,
                            children: fieldFilters.asMap().entries.map((entry) {
                              final index = entry.key;
                              final filter = entry.value;
                              return Chip(
                                label: Text('${filter['operator']}: ${filter['value']}', style: const TextStyle(fontSize: 10)),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => setDialogState(() {
                                  fieldFilters.removeAt(index);
                                  if (fieldFilters.isEmpty) _filters.remove(field);
                                }),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ),
                        Wrap(
                          spacing: 4, runSpacing: 4,
                          children: ['contains', 'equals', 'starts with', 'ends with', 'not contains', 'not equals', 'in'].map((op) => 
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                              onPressed: () => _addFilter(field, op),
                              child: Text(op, style: const TextStyle(fontSize: 11)),
                            )
                          ).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        )),
        actions: [
          TextButton.icon(onPressed: () => setState(() { _filters.clear(); Navigator.pop(context); }), icon: const Icon(Icons.clear_all, size: 16), label: const Text('Clear')),
          FilledButton.icon(onPressed: () { setState(() {}); Navigator.pop(context); }, icon: const Icon(Icons.check, size: 16), label: const Text('Apply')),
        ],
      ),
    ));
  }

  IconData _getFieldIcon(String field) {
    switch (field) {
      case 'code': return Icons.qr_code;
      case 'title': return Icons.person;
      case 'subtitle': return Icons.info_outline;
      default:
        // Try to find the icon from the actual ExtraField
        for (final user in widget.users) {
          final extraField = user.extras.firstWhere((e) => e.key == field, orElse: () => ExtraField(key: '', value: ''));
          if (extraField.key == field && extraField.icon != null) return extraField.icon!;
        }
        return Icons.label_outline;
    }
  }

  void _addFilter(String field, String operator) {
    Navigator.pop(context);
    final values = widget.users.map((u) => field == 'code' ? u.code : field == 'title' ? u.title : field == 'subtitle' ? u.subtitle : u.extras.firstWhere((e) => e.key == field, orElse: () => ExtraField(key: '', value: '')).value).where((v) => v.isNotEmpty).toSet().toList();
    
    void addFilterToField(String operator, dynamic value) {
      setState(() {
        final fieldFilters = _filters[field] as List<Map<String, dynamic>>? ?? [];
        fieldFilters.add({'operator': operator, 'value': value});
        _filters[field] = fieldFilters;
      });
    }
    
    if (operator == 'in' && values.length <= 50) {
      showDialog(context: context, builder: (context) {
        List<String> selected = [];
        return StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
          title: Text('Select $field values'),
          content: Column(mainAxisSize: MainAxisSize.min, children: values.map((v) => CheckboxListTile(
            title: Text(v), value: selected.contains(v), onChanged: (bool? val) => setDialogState(() => val! ? selected.add(v) : selected.remove(v))
          )).toList()),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () { addFilterToField(operator, selected); Navigator.pop(context); }, child: const Text('Apply'))],
        ));
      });
    } else {
      showDialog(context: context, builder: (context) {
        String value = '';
        return AlertDialog(
          title: Text('Filter $field'),
          content: TextField(onChanged: (v) => value = v, decoration: InputDecoration(hintText: 'Enter value')),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () { addFilterToField(operator, value); Navigator.pop(context); }, child: const Text('Apply'))],
        );
      });
    }
  }

  Future<void> _exportToJson() async {
    final jsonData = widget.users.map((user) => user.toJson()).toList();
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
    final bytes = Uint8List.fromList(jsonString.codeUnits);
    
    await FilePicker.platform.saveFile(
      dialogTitle: 'Export to JSON',
      fileName: "Event_Scan_Data-${DateTime.now()}.json",
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );
  }

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    var excel = Excel.createExcel();

    // Gather all extras keys
    final allExtrasKeys = widget.users.fold<Set<String>>({}, (keys, user) {
      return keys..addAll(user.extras.map((field) => field.key));
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
        TextCellValue(user.code),
        TextCellValue(user.title),
        TextCellValue(user.subtitle),
      ];
      for (var key in allExtrasKeys) {
        final field = user.extras.firstWhere((f) => f.key == key, orElse: () => ExtraField(key: key, value: ''));
        rowValues.add(TextCellValue(field.value));
      }

      // Attendance
      final categoriesScanned = widget.categories
          .where((c) => ((user.scanned)[c.name] ?? []).isNotEmpty)
          .map((c) => '${c.name} - Days ${((user.scanned)[c.name] ?? []).join(", ")}')
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
          TextCellValue(user.code),
          TextCellValue(user.title),
        ]);
        for (final category in widget.categories) {
          final days = (user.scanned)[category.name] as List<dynamic>? ?? [];
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
