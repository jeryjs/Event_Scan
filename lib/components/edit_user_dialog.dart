import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scan/models/barcode_model.dart';
import 'package:event_scan/services/database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

class EditUserDialog extends StatefulWidget {
  final List<BarcodeModel> usersData;
  final bool canEditMultiple;

  const EditUserDialog({super.key, required this.usersData, required this.canEditMultiple});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

dynamic _customEncoder(dynamic item) {
  if (item is BarcodeModel) return item.toMap();
  if (item is Timestamp) return item.millisecondsSinceEpoch;
  if (item is IconPickerIcon) return serializeIcon(item); // Not used, but kept for reference
  if (item is ExtraField) return item.toMap();
  return item;
}

class _EditUserDialogState extends State<EditUserDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  late List<BarcodeModel> _usersData;
  late List<BarcodeModel> _originalUsersData;
  bool _isJsonMode = false;
  late TextEditingController _jsonController;
  String? _jsonError;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _usersData = widget.usersData;
    _originalUsersData = List.from(widget.usersData);
    _tabController = TabController(length: _usersData.length, vsync: this);
    _jsonController = TextEditingController(text: jsonEncode(_usersData, toEncodable: _customEncoder));
  }

  @override
  void dispose() {
    _newKeyController.dispose();
    _newKeyFocus.dispose();
    super.dispose();
  }

  void _updateBarcodeData(int userIndex, dynamic data) {
    _usersData[userIndex] = _usersData[userIndex].copyWith(data);
  }

  void _startAddingField() {
    setState(() {
      _isAddingField = true;
      _newKeyController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newKeyFocus.requestFocus();
    });
  }

  void _cancelAddingField() {
    setState(() {
      _isAddingField = false;
    });
  }

  void _submitNewKey(int userIndex) {
    final key = _newKeyController.text.trim();
    if (key.isEmpty) {
      _cancelAddingField();
      return;
    }
    final extras = ExtraField.fromDynamic(_usersData[userIndex].extras);
    if (extras.any((field) => field.key == key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Key "$key" already exists')),
      );
      return;
    }
    setState(() {
      extras.add(ExtraField(key: key, value: ''));
      _updateBarcodeData(userIndex, {'extras': extras});
      _isAddingField = false;
    });
  }

  void _toggleMode() {
    setState(() {
      if (_isJsonMode) {
        // Switching from JSON to UI mode - validate first
        try {
          final decoded = jsonDecode(_jsonController.text) as List;
          _usersData = decoded.map((e) => BarcodeModel.from(e, strict: true)).toList();
          _tabController = TabController(length: _usersData.length, vsync: this);
          _jsonError = null;
          _isJsonMode = false;
        } catch (error) {
          _jsonError = 'Invalid JSON format:\n$error';
          // Don't toggle mode, stay in JSON mode
        }
      } else {
        // Switching from UI to JSON mode
        _jsonController.text = jsonEncode(_usersData, toEncodable: _customEncoder);
        _isJsonMode = true;
      }
    });
  }

  Future<void> _loadJsonFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null) {
      final file = result.files.single;
      final content = file.bytes != null 
        ? String.fromCharCodes(file.bytes!) 
        : await File(file.path!).readAsString();
      setState(() => _jsonController.text = content);
    }
  }

  bool _isAddingField = false;
  final TextEditingController _newKeyController = TextEditingController();
  final FocusNode _newKeyFocus = FocusNode();

  void _addNewUser() {
    setState(() {
      final newUser = BarcodeModel.empty();
      // Pre-populate with existing keys
      if (_usersData.isNotEmpty) {
        final existingExtras = _usersData.first.extras;
        for (var field in existingExtras) {
          newUser.extras.add(ExtraField(key: field.key, value: '', icon: field.icon));
        }
      }
      _usersData.add(newUser);
      _tabController = TabController(length: _usersData.length, vsync: this);
      _tabController.animateTo(_usersData.length - 1);
    });
  }

  void _removeUser(int index) {
    if (_usersData.length <= 1) return; // Don't allow removing the last user
    
    setState(() {
      _usersData.removeAt(index);
      final newTabController = TabController(length: _usersData.length, vsync: this);
      
      // Adjust current tab index if needed
      if (_tabController.index >= _usersData.length) {
        newTabController.index = _usersData.length - 1;
      } else if (_tabController.index > index) {
        newTabController.index = _tabController.index - 1;
      } else {
        newTabController.index = _tabController.index;
      }
      
      _tabController = newTabController;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      if (_isJsonMode) {
        try {
          final decoded = jsonDecode(_jsonController.text) as List;
          _usersData = decoded.map((e) => BarcodeModel.from(e, strict: true)).toList();
          _jsonError = null;
        } catch (error) {
          return setState(() => _jsonError = 'Invalid JSON format:\n$error');
        }
      }

      // Check for duplicate codes
      final codes = <String>[];
      final duplicates = <String>[];
      for (var user in _usersData) {
        if (user.code.trim().isEmpty) return setState(() {
          _saveError = 'All users must have a code';
          _isSaving = false;
        });
        if (codes.contains(user.code)) duplicates.add(user.code); else codes.add(user.code);
      }
      // if (duplicates.isNotEmpty) return setState(() {
      //   _saveError = 'Duplicate codes found: ${duplicates.join(', ')}';
      //   _isSaving = false;
      // });

      await Database.updateUsers(_usersData);
      
      if (mounted) Navigator.of(context).pop(_usersData);
    } catch (error) {
      setState(() {
        _saveError = 'Failed to save: $error';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Attendees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_isJsonMode)
                  IconButton(icon: Icon(Icons.upload_file_outlined), tooltip: "Load from JSON File", onPressed: _loadJsonFile),
                IconButton(
                  icon: Icon(_isJsonMode ? Icons.view_compact : Icons.code),
                  onPressed: _toggleMode,
                ),
              ],
            ),
            Flexible(
              child: _isJsonMode
                  ? SingleChildScrollView(
                      child: TextField(
                        controller: _jsonController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Enter JSON data here',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.canEditMultiple)
                        Row(
                          children: [
                            Expanded(
                              child: TabBar(
                                controller: _tabController,
                                isScrollable: true,
                                onTap: (index) => setState(() {}), // Refresh to update delete button visibility
                                tabs: List.generate(_usersData.length, 
                                  (index) => Tab(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_usersData.length > 3 ? '${index + 1}' : 'Attendee ${index + 1}'),
                                        if (_usersData.length > 1 && _tabController.index == index) ...[
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _removeUser(index),
                                            child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                ),
                              ),
                            ),
                              IconButton(
                                icon: const Icon(Icons.add_circle),
                                onPressed: _addNewUser,
                                tooltip: 'Add Attendee',
                              ),
                          ],
                        ),
                        Flexible(
                          child: TabBarView(
                            controller: _tabController,
                            children: _usersData.map((userData) {
                              int userIndex = _usersData.indexOf(userData);
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: LinearGradient(
                                          colors: [Colors.blue[100]!.withValues(alpha: 0.1), Colors.blue[600]!.withValues(alpha: 0.1)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.qr_code, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 200,
                                            child: TextField(
                                              readOnly: userIndex < _originalUsersData.length && _originalUsersData[userIndex].code.isNotEmpty ,
                                              onChanged: (value) => _updateBarcodeData(userIndex, {'code': value}),
                                              decoration: const InputDecoration(
                                                labelText: 'Code',
                                                border: InputBorder.none,
                                              ),
                                              controller: TextEditingController(text: userData.code),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    TextField(
                                      onChanged: (value) => _updateBarcodeData(userIndex, {'title': value}),
                                      decoration: InputDecoration(
                                        labelText: 'Title',
                                        prefixIcon: const Icon(Icons.title),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      controller: TextEditingController(text: userData.title),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      onChanged: (value) => _updateBarcodeData(userIndex, {'subtitle': value}),
                                      decoration: InputDecoration(
                                        labelText: 'Subtitle',
                                        prefixIcon: const Icon(Icons.subtitles),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      controller: TextEditingController(text: userData.subtitle),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildExtrasFields(userData, userIndex),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
            ),
            if (_isJsonMode && _jsonError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _jsonError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_saveError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_saveError!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isJsonMode)
                  IconButton.outlined(icon: Icon(Icons.auto_fix_high), tooltip: "Format JSON", visualDensity: VisualDensity.compact, 
                    onPressed: () => _jsonController.text = JsonEncoder.withIndent('  ').convert(jsonDecode(_jsonController.text)),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveChanges,
                  icon: _isSaving ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ) : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtrasFields(BarcodeModel userData, int userIndex) {
    final extras = ExtraField.fromDynamic(userData.extras);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // if (extras.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Custom Fields', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
        // ],
        for (int i = 0; i < extras.length; i++) ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              TextField(
                onChanged: (value) => _updateFieldValue(i, value, userIndex),
                decoration: InputDecoration(
                  labelText: extras[i].key,
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  prefixIcon: GestureDetector(
                    onTap: () => _pickIconForField(i, userIndex),
                    child: Icon(extras[i].icon ?? Icons.category_outlined),
                  )
                ),
                controller: TextEditingController(text: extras[i].value),
              ),
              if (extras[i].value.isEmpty)
                Positioned(
                  right: -20,
                  child: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () => setState(() {
                      extras.removeAt(i);
                      _updateBarcodeData(userIndex, {'extras': extras});
                    }),
                    tooltip: 'Remove field',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_isAddingField) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newKeyController,
                  focusNode: _newKeyFocus,
                  onSubmitted: (_) => _submitNewKey(userIndex),
                  decoration: InputDecoration(labelText: 'Enter key name'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelAddingField,
                tooltip: 'Cancel',
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextButton.icon(
          onPressed: _isAddingField ? null : () => _startAddingField(),
          icon: const Icon(Icons.add),
          label: const Text('Add Field'),
        ),
      ],
    );
  }

  Future<void> _pickIconForField(int fieldIndex, int userIndex) async {
    IconPickerIcon? icon = await showIconPicker(
      context,
      configuration: const SinglePickerConfiguration(
        iconPackModes: [IconPack.material],
      ),
    );
    if (icon != null) {
      setState(() {
        final userData = _usersData[userIndex];
        final extras = ExtraField.fromDynamic(userData.extras);
        
        if (fieldIndex < extras.length) {
          final field = extras[fieldIndex];
          extras[fieldIndex] = field.copyWith(icon: IconData(icon.data.codePoint, fontFamily: 'MaterialIcons'));
          _updateBarcodeData(userIndex, {'extras': extras});
        }
      });
    }
  }

  void _updateFieldValue(int fieldIndex, String value, int userIndex) {
    final userData = _usersData[userIndex];
    final extras = ExtraField.fromDynamic(userData.extras);
    
    if (fieldIndex < extras.length) {
      final field = extras[fieldIndex];
      extras[fieldIndex] = field.copyWith(value: value);
      _updateBarcodeData(userIndex, {'extras': extras});
    }
  }
}

Future<List<BarcodeModel>?> showEditUserDialog(BuildContext context, List<BarcodeModel> usersData, {
  bool canEditMultiple = true,
}) async {
  if (usersData.isEmpty) usersData = [BarcodeModel.empty()];
  return await showDialog<List<BarcodeModel>>(
    context: context,
    builder: (context) => EditUserDialog(usersData: usersData, canEditMultiple: canEditMultiple),
  );
}
