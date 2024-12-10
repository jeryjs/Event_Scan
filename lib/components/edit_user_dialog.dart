import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:party_scan/services/database.dart';
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

  @override
  void initState() {
    super.initState();
    _usersData = List<Map<String, dynamic>>.from(widget.usersData);
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
          _usersData = List<Map<String, dynamic>>.from(jsonDecode(_jsonController.text));
          _tabController = TabController(length: _usersData.length, vsync: this);
        } catch (_) {
          // Handle JSON parse error if needed
        }
      }
    });
  }

  void _addNewUser() {
    setState(() {
      _usersData.add({
        'code': '',
        'name': '',
        'mail': '',
        'phone': '',
      });
      _tabController = TabController(length: _usersData.length, vsync: this);
      _tabController.animateTo(_usersData.length - 1);
    });
  }

  Future<void> _saveChanges() async {
    if (_isJsonMode) {
      try {
        _usersData = List<Map<String, dynamic>>.from(jsonDecode(_jsonController.text));
      } catch (_) {
        // Handle JSON parse error if needed
      }
    }
    for (var userData in _usersData) {
      await Database.updateUser(
        userData['code'],
        userData['name'],
        userData['mail'],
        userData['phone'],
      );
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(_isJsonMode ? Icons.view_compact : Icons.code),
                  onPressed: _toggleMode,
                ),
              ],
            ),
            SizedBox(
              height: 400,
              child: _isJsonMode
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
                                  (index) => Tab(text: 'User ${index + 1}')
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: _addNewUser,
                              tooltip: 'Add User',
                            ),
                          ],
                        ),
                        Expanded(
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
                                          colors: [Colors.blue[100]!.withOpacity(0.1), Colors.blue[600]!.withOpacity(0.1)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.qr_code, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Code: ${userData['code']??''}',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _usersData[userIndex]['name'] = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Name',
                                        prefixIcon: const Icon(Icons.person),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      controller: TextEditingController(text: userData['name']),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _usersData[userIndex]['mail'] = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: const Icon(Icons.email),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      controller: TextEditingController(text: userData['mail']),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _usersData[userIndex]['phone'] = value;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Phone',
                                        prefixIcon: Icon(Icons.phone),
                                      ),
                                      controller: TextEditingController(text: userData['phone']),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
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
    );
  }
}

void showEditUserDialog(BuildContext context, List<Map<String, dynamic>> usersData) {
  showDialog(
    context: context,
    builder: (context) => EditUserDialog(usersData: usersData),
  );
}
