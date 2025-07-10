import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:event_scan/services/database.dart';
import 'dart:convert';

class EditUserDialog extends StatefulWidget {
  final List<Map<String, dynamic>> usersData;

  const EditUserDialog({super.key, required this.usersData});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

dynamic _customEncoder(dynamic item) {
  if (item is Timestamp) {
    return item.toDate().toIso8601String();
  }
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

  void _addNewExtraField(int userIndex) {
    setState(() {
      if (!_usersData[userIndex]['extras'].containsKey('New Key')) {
        _usersData[userIndex]['extras']['New Key'] = '';
      }
    });
  }

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
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
              _isJsonMode
                  ? TextField(
                      controller: _jsonController,
                      maxLines: 15,
                      decoration: const InputDecoration(
                        hintText: 'Enter JSON data here',
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Column(
                      children: [
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
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 700),
                          child: TabBarView(
                            controller: _tabController,
                            children: _usersData.map((userData) {
                              int userIndex = _usersData.indexOf(userData);
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
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
              if (_isJsonMode && _jsonError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _jsonError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
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
      ),
    );
  }

  Widget _buildExtrasFields(Map<String, dynamic> userData, int userIndex) {
    final extras = (userData['extras'] is Map<String, dynamic>) ? userData['extras'] as Map<String, dynamic> : {};
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in extras.entries) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    onChanged: (value) {
                      if (_usersData[userIndex]['extras'].containsKey(value) && value != entry.key) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Duplicate key: $value')),
                        );
                        return;
                      }
                      final newKey = value;
                      final oldValue = _usersData[userIndex]['extras'].remove(entry.key);
                      _usersData[userIndex]['extras'][newKey] = oldValue;
                    },
                    decoration: InputDecoration(
                      labelText: 'Key',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    controller: TextEditingController(text: entry.key),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (value) => _usersData[userIndex]['extras'][entry.key] = value,
                    decoration: InputDecoration(
                      labelText: 'Value',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    controller: TextEditingController(text: entry.value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextButton.icon(
            onPressed: () => setState(() {
              _usersData[userIndex]['extras'].removeWhere((key, value) => key == 'New Key');
              _addNewExtraField(userIndex);
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add Field'),
          ),
        ],
      ),
    );
  }
}

void showEditUserDialog(BuildContext context, List<Map<String, dynamic>> usersData) {
  showDialog(
    context: context,
    builder: (context) => EditUserDialog(usersData: usersData),
  );
}
