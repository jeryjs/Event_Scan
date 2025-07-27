import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:event_scan/services/database.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'dart:convert';

class EditUserDialog extends StatefulWidget {
  final List<Map<String, dynamic>> usersData;
  final bool canEditMultiple;

  const EditUserDialog({super.key, required this.usersData, required this.canEditMultiple});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

dynamic _customEncoder(dynamic item) {
  if (item is Timestamp) {
    return item.toDate().toIso8601String();
  }
  if (item is IconPickerIcon) return serializeIcon(item);
  return item;
}

class _EditUserDialogState extends State<EditUserDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  late List<Map<String, dynamic>> _usersData;
  bool _isJsonMode = false;
  late TextEditingController _jsonController;
  String? _jsonError;

  @override
  void initState() {
    super.initState();
    _usersData = widget.usersData.map((user) {
      final newUser = Map<String, dynamic>.from(user);
      // Ensure 'extras' is always a Map
      newUser['extras'] ??= {};
      return newUser;
    }).toList();
    _tabController = TabController(length: _usersData.length, vsync: this);
    _jsonController = TextEditingController(text: jsonEncode(_usersData, toEncodable: _customEncoder));
  }

  @override
  void dispose() {
    _newKeyController.dispose();
    _newKeyFocus.dispose();
    super.dispose();
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
    if (_usersData[userIndex]['extras'].containsKey(key)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Key "$key" already exists')),
      );
      return;
    }
    setState(() {
      _usersData[userIndex]['extras'][key] = '';
      _isAddingField = false;
    });
  }

  void _toggleMode() {
    setState(() {
      _isJsonMode = !_isJsonMode;
      if (_isJsonMode) {
        _jsonController.text = jsonEncode(_usersData, toEncodable: _customEncoder);
      } else {
        try {
          final decodedData = jsonDecode(_jsonController.text) as List<dynamic>;
          _usersData = decodedData.map((user) {
            final newUser = Map<String, dynamic>.from(user);
            newUser['extras'] ??= {};
            return newUser;
          }).toList();
          _tabController = TabController(length: _usersData.length, vsync: this);
          _jsonError = null;
        } catch (error) {
          _jsonError = 'Invalid JSON format';
        }
      }
    });
  }

  bool _isAddingField = false;
  final TextEditingController _newKeyController = TextEditingController();
  final FocusNode _newKeyFocus = FocusNode();

  void _addNewUser() {
    setState(() {
      final newUser = {
        'code': '',
        'title': '',
        'subtitle': '',
        'extras': {},
      };
      // Pre-populate with existing keys
      if (_usersData.isNotEmpty) {
        final existingKeys = _usersData.first['extras']?.keys ?? [];
        for (var key in existingKeys) {
          (newUser['extras'] as Map<dynamic, dynamic>)[key] = '';
        }
      }
      _usersData.add(newUser);
      _tabController = TabController(length: _usersData.length, vsync: this);
      _tabController.animateTo(_usersData.length - 1);
    });
  }

  Future<void> _saveChanges() async {
    if (_isJsonMode) {
      try {
        final decodedData = jsonDecode(_jsonController.text) as List<dynamic>;
        _usersData = decodedData.map((user) {
          final newUser = Map<String, dynamic>.from(user);
          newUser['extras'] ??= {};
          return newUser;
        }).toList();
        _jsonError = null;
      } catch (error) {
        setState(() {
          _jsonError = 'Invalid JSON format';
        });
        return;
      }
    }
    await Database.updateUsers(_usersData);
    if (mounted) { 
      Navigator.of(context).pop(_usersData);
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
                                tabs: List.generate(_usersData.length, 
                                  (index) => Tab(text: 'Attendee ${index + 1}')
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
                                              onChanged: (value) => _usersData[userIndex]['code'] = value,
                                              decoration: const InputDecoration(
                                                labelText: 'Code',
                                                border: InputBorder.none,
                                              ),
                                              controller: TextEditingController(text: userData['code']),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    TextField(
                                      onChanged: (value) => _usersData[userIndex]['title'] = value,
                                      decoration: InputDecoration(
                                        labelText: 'Title',
                                        prefixIcon: const Icon(Icons.title),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      controller: TextEditingController(text: userData['title']),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      onChanged: (value) => _usersData[userIndex]['subtitle'] = value,
                                      decoration: InputDecoration(
                                        labelText: 'Subtitle',
                                        prefixIcon: const Icon(Icons.subtitles),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      controller: TextEditingController(text: userData['subtitle']),
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtrasFields(Map<String, dynamic> userData, int userIndex) {
    final extras = (userData['extras'] is Map<String, dynamic>) ? userData['extras'] as Map<String, dynamic> : {};
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // if (extras.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Custom Fields', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
        // ],
        for (final entry in extras.entries) ...[
          Stack(
            clipBehavior: Clip.none,
            children: [
              TextField(
                onChanged: (value) => _updateFieldValue(entry.key, value, userIndex),
                decoration: InputDecoration(
                  labelText: entry.key,
                  border: InputBorder.none,
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  prefixIcon: GestureDetector(
                    onTap: () => _pickIconForField(entry.key, userIndex),
                    child: Icon(_getIconForField(entry.key, userIndex)),
                  )
                ),
                controller: TextEditingController(text: _getFieldValue(entry.key, userIndex)),
              ),
              if (_getFieldValue(entry.key, userIndex).isEmpty)
                Positioned(
                  right: -20,
                  top: 8,
                  child: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: () => setState(() => _usersData[userIndex]['extras'].remove(entry.key)),
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

  Future<void> _pickIconForField(String key, int userIndex) async {
    IconPickerIcon? icon = await showIconPicker(
      context,
      configuration: const SinglePickerConfiguration(
        iconPackModes: [IconPack.material],
      ),
    );
    if (icon != null) {
      setState(() {
        final currentValue = _getFieldValue(key, userIndex);
        _usersData[userIndex]['extras'][key] = {
          'value': currentValue,
          'icon': icon.data.codePoint,
        };
      });
    }
  }

  IconData _getIconForField(String key, int userIndex) {
    final fieldData = _usersData[userIndex]['extras'][key];
    if (fieldData is Map<String, dynamic> && fieldData['icon'] != null) {
      return IconData(fieldData['icon'], fontFamily: 'MaterialIcons');
    }
    return Icons.category_outlined;
  }

  String _getFieldValue(String key, int userIndex) {
    final fieldData = _usersData[userIndex]['extras'][key];
    if (fieldData is Map<String, dynamic>) {
      return fieldData['value']?.toString() ?? '';
    }
    return fieldData?.toString() ?? '';
  }

  void _updateFieldValue(String key, String value, int userIndex) {
    final fieldData = _usersData[userIndex]['extras'][key];
    if (fieldData is Map<String, dynamic>) {
      _usersData[userIndex]['extras'][key] = {
        'value': value,
        'icon': fieldData['icon'],
      };
    } else {
      _usersData[userIndex]['extras'][key] = {
        'value': value,
        'icon': null,
      };
    }
  }
}

Future showEditUserDialog(BuildContext context, List<Map<String, dynamic>> usersData, {
  bool canEditMultiple = true,
}) async {
  return showDialog(
    context: context,
    builder: (context) => EditUserDialog(usersData: usersData, canEditMultiple: canEditMultiple),
  );
}
