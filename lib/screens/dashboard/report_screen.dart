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
import 'package:excel/excel.dart' as excel;

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
        final filter = entry.value;
        final operator = filter['operator'];
        final value = filter['value'];
        
        String userValue = '';
        if (field == 'code') userValue = user.code;
        else if (field == 'title') userValue = user.title;
        else if (field == 'subtitle') userValue = user.subtitle;
        else userValue = user.extras.firstWhere((e) => e.key == field, orElse: () => ExtraField(key: '', value: '')).value;
        
        switch (operator) {
          case 'contains': if (!userValue.toLowerCase().contains(value.toLowerCase())) return false;
          case 'equals': if (userValue != value) return false;
          case 'in': if (!(value as List).contains(userValue)) return false;
        }
      }

      return scannedOnDay && user.query(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showFilterDialog() {
    final fields = ['code', 'title', 'subtitle', ...widget.users.expand((u) => u.extras.map((e) => e.key)).toSet()];
    showDialog(context: context, builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Filters'),
        content: SizedBox(width: 300, height: 400, child: Column(
          children: [
            CheckboxListTile(
              title: const Text('Include non-scanned users'),
              value: _filters['_includeNonScanned'] != null,
              onChanged: (val) => setDialogState(() => val! ? _filters['_includeNonScanned'] = {'operator': 'include', 'value': true} : _filters.remove('_includeNonScanned')),
            ),
            const Divider(),
            Expanded(child: ListView(
              children: fields.map((field) => ExpansionTile(
                title: Text(field),
                children: [
                  for (var op in ['contains', 'equals', 'in']) ListTile(
                    title: Text(op),
                    onTap: () => _addFilter(field, op),
                  )
                ],
              )).toList(),
            )),
            if (_filters.isNotEmpty) _buildActiveFilters(),
          ],
        )),
        actions: [
          TextButton(onPressed: () => setState(() { _filters.clear(); Navigator.pop(context); }), child: const Text('Clear')),
          TextButton(onPressed: () { setState(() {}); Navigator.pop(context); }, child: const Text('Apply')),
        ],
      ),
    ));
  }

  void _addFilter(String field, String operator) {
    Navigator.pop(context);
    final values = widget.users.map((u) => field == 'code' ? u.code : field == 'title' ? u.title : field == 'subtitle' ? u.subtitle : u.extras.firstWhere((e) => e.key == field, orElse: () => ExtraField(key: '', value: '')).value).where((v) => v.isNotEmpty).toSet().toList();
    
    if (operator == 'in' && values.length <= 50) {
      showDialog(
        context: context,
        builder: (context) {
          List<String> selected = [];
          return StatefulBuilder(
            builder: (context, setDialogState) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getFieldIcon(field),
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select ${field.toUpperCase()} Values',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${values.length} options available',
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected.isEmpty ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected.isEmpty ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected.isEmpty ? Icons.warning_amber : Icons.check_circle,
                            color: selected.isEmpty ? Colors.orange : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            selected.isEmpty 
                                ? 'Select at least one value to filter'
                                : '${selected.length} value${selected.length == 1 ? '' : 's'} selected',
                            style: TextStyle(
                              color: selected.isEmpty ? Colors.orange[700] : Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          itemCount: values.length,
                          itemBuilder: (context, index) {
                            final value = values[index];
                            final isSelected = selected.contains(value);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                  value,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? Theme.of(context).primaryColor : null,
                                  ),
                                ),
                                value: isSelected,
                                onChanged: (bool? val) => setDialogState(() => val! ? selected.add(value) : selected.remove(value)),
                                activeColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: selected.isEmpty ? null : () {
                              setState(() => _filters[field] = {'operator': operator, 'value': selected});
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.filter_alt),
                            label: const Text('Apply Filter'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          String value = '';
          final controller = TextEditingController();
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getOperatorIcon(operator),
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filter ${field.toUpperCase()}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Using "${operator}" operator',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getOperatorDescription(operator),
                            style: TextStyle(color: Colors.blue[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    onChanged: (v) => value = v,
                    decoration: InputDecoration(
                      labelText: 'Enter filter value',
                      hintText: _getOperatorHint(operator, field),
                      prefixIcon: Icon(_getFieldIcon(field)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.05),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (controller.text.trim().isNotEmpty) {
                              setState(() => _filters[field] = {'operator': operator, 'value': controller.text.trim()});
                              Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.filter_alt),
                          label: const Text('Apply Filter'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
    );
  }
}  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 4,
        children: _filters.entries.map((entry) {
          final displayText = entry.key == '_includeNonScanned' 
              ? 'Include non-scanned'
              : '${entry.key}: ${entry.value['operator']}';
          
          return Chip(
            label: Text(displayText, style: const TextStyle(fontSize: 12)),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => setState(() => _filters.remove(entry.key)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }).toList(),
      ),
    );
  }

  IconData _getFieldIcon(String field) {
    switch (field.toLowerCase()) {
      case 'code': return Icons.badge;
      case 'title': return Icons.person;
      case 'subtitle': return Icons.description;
      case 'email': return Icons.email;
      case 'phone': return Icons.phone;
      case 'department': return Icons.business;
      case 'role': return Icons.work;
      case 'location': return Icons.location_on;
      default: return Icons.label;
    }
  }

  IconData _getOperatorIcon(String operator) {
    switch (operator) {
      case 'contains': return Icons.search;
      case 'equals': return Icons.drag_handle;
      case 'in': return Icons.checklist;
      default: return Icons.filter_alt;
    }
  }

  String _getOperatorDescription(String operator) {
    switch (operator) {
      case 'contains': return 'Find records where this field contains the specified text (case-insensitive)';
      case 'equals': return 'Find records where this field exactly matches the specified value';
      case 'in': return 'Find records where this field matches any of the selected values';
      default: return 'Apply filter to this field';
    }
  }

  String _getOperatorHint(String operator, String field) {
    switch (operator) {
      case 'contains': return 'Part of ${field} to search for...';
      case 'equals': return 'Exact ${field} value...';
      default: return 'Enter ${field} value...';
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
    var excelFile = excel.Excel.createExcel();

    // Gather all extras keys
    final allExtrasKeys = widget.users.fold<Set<String>>({}, (keys, user) {
      return keys..addAll(user.extras.map((field) => field.key));
    }).toList();

    // Create "All Days" sheet with dynamic extras
    excelFile.rename("Sheet1", "All Days");
    final allDaysSheet = excelFile['All Days'];

    // Headers: code, title, subtitle, dynamic extras, attendance
    final headers = ['Code', 'Title', 'Subtitle', ...allExtrasKeys, 'Attendance'];
    for (var header in headers) {
      final headerCell = allDaysSheet.cell(excel.CellIndex.indexByColumnRow(
        columnIndex: headers.indexOf(header),
        rowIndex: 0,
      ));
      headerCell
        ..value = excel.TextCellValue(header)
        ..cellStyle = excel.CellStyle(bold: true, horizontalAlign: excel.HorizontalAlign.Center);
      allDaysSheet.setColumnAutoFit(headerCell.columnIndex);
    }

    // Fill rows
    for (final user in widget.users) {
      // Build row with code, title, subtitle, dynamic extras
      final rowValues = <excel.TextCellValue>[
        excel.TextCellValue(user.code),
        excel.TextCellValue(user.title),
        excel.TextCellValue(user.subtitle),
      ];
      for (var key in allExtrasKeys) {
        final field = user.extras.firstWhere((f) => f.key == key, orElse: () => ExtraField(key: key, value: ''));
        rowValues.add(excel.TextCellValue(field.value));
      }

      // Attendance
      final categoriesScanned = widget.categories
          .where((c) => ((user.scanned)[c.name] ?? []).isNotEmpty)
          .map((c) => '${c.name} - Days ${((user.scanned)[c.name] ?? []).join(", ")}')
          .join('\n');

      rowValues.add(excel.TextCellValue(categoriesScanned));
      allDaysSheet.appendRow(rowValues);

      // Wrap text for attendance cell
      final attendanceIndex = headers.indexOf('Attendance');
      final attendanceCell = allDaysSheet.cell(excel.CellIndex.indexByColumnRow(
        columnIndex: attendanceIndex,
        rowIndex: allDaysSheet.maxRows - 1,
      ));
      attendanceCell.cellStyle = excel.CellStyle(textWrapping: excel.TextWrapping.WrapText);
    }

    // Individual day sheets (rename "Name" -> "Title")
    var settings = await Database.getSettings();
    DateTime startDate = (settings['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    DateTime endDate = (settings['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7));
    int totalDays = endDate.difference(startDate).inDays + 1;

    for (int day = 1; day <= totalDays; day++) {
      final daySheet = excelFile['Day $day'];
      final dayHeaders = ['Code', 'Title', ...widget.categories.map((c) => c.name)];
      for (var header in dayHeaders) {
        final headerCell = daySheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: dayHeaders.indexOf(header),
          rowIndex: 0,
        ));
        headerCell
          ..value = excel.TextCellValue(header)
          ..cellStyle = excel.CellStyle(bold: true, horizontalAlign: excel.HorizontalAlign.Center);
        daySheet.setColumnAutoFit(headerCell.columnIndex);
      }
      for (final user in widget.users) {
        daySheet.appendRow([
          excel.TextCellValue(user.code),
          excel.TextCellValue(user.title),
        ]);
        for (final category in widget.categories) {
          final days = (user.scanned)[category.name] as List<dynamic>? ?? [];
          final cell = daySheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: dayHeaders.indexOf(category.name),
            rowIndex: daySheet.maxRows - 1,
          ));
          cell..value = excel.IntCellValue(days.contains(day) ? 1 : 0)
            ..cellStyle = excel.CellStyle(backgroundColorHex: (days.contains(day) ? "#c1deca" : "#e7c9c7").excelColor);
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
        bytes: Uint8List.fromList(excelFile.save(fileName: fileName) ?? []),
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
