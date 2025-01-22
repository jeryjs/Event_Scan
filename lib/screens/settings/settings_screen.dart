import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database.dart';
import 'manage_categories_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _collectionNameController = TextEditingController();
  final _eventTitleController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    var settings = await Database.getSettings();
    _collectionNameController.text = settings['collectionName'] ?? 'FDP_2024';
    _eventTitleController.text = settings['eventTitle'] ?? 'Event Scan';
    _startDate = settings['startDate'] != null
        ? (settings['startDate'] as Timestamp).toDate()
        : DateTime.now();
    _endDate = settings['endDate'] != null
        ? (settings['endDate'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 7));
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    await Database.saveSettings({
      'collectionName': _collectionNameController.text.trim(),
      'eventTitle': _eventTitleController.text.trim(),
      'startDate': Timestamp.fromDate(_startDate!),
      'endDate': Timestamp.fromDate(_endDate!),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 5)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    Widget? leading,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: leading,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'App Configuration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSettingCard(
                      title: 'Event Title',
                      subtitle: 'Set the event title',
                      leading: const Icon(Icons.title),
                      trailing: SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _eventTitleController,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    _buildSettingCard(
                      title: 'Collection Name',
                      subtitle: 'Set the Firestore collection name',
                      leading: const Icon(Icons.folder_outlined),
                      trailing: SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _collectionNameController,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    _buildSettingCard(
                      title: 'Start Date',
                      subtitle: 'Configure the event start date',
                      leading: const Icon(Icons.calendar_today),
                      trailing: TextButton(
                        onPressed: () => _selectStartDate(context),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Select',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    _buildSettingCard(
                      title: 'End Date',
                      subtitle: 'Configure the event end date',
                      leading: const Icon(Icons.calendar_today),
                      trailing: TextButton(
                        onPressed: () => _selectEndDate(context),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Select',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    _buildSettingCard(
                      title: 'Categories',
                      subtitle: 'Manage scanning categories',
                      leading: const Icon(Icons.category_outlined),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ManageCategoriesDialog(),
                        ).then((_) {
                          setState(() {}); // Refresh settings screen if needed
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                await _saveSettings();
                                if (mounted) {
                                  navigator.popUntil((route) => route.isFirst);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text(
                                'Save Settings',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }
}
