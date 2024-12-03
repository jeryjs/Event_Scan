import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_categories_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _collectionNameController = TextEditingController();
  DateTime? _startDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('settings')
        .doc('config')
        .get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      _collectionNameController.text = data['collectionName'] ?? 'FDP_2024';
      _startDate = (data['startDate'] as Timestamp).toDate();
    } else {
      _collectionNameController.text = 'FDP_2024';
      _startDate = DateTime.now();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await FirebaseFirestore.instance.collection('settings').doc('config').set({
      'collectionName': _collectionNameController.text.trim(),
      'startDate': Timestamp.fromDate(_startDate!),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
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
                      title: 'Categories',
                      subtitle: 'Manage scanning categories',
                      leading: const Icon(Icons.category_outlined),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const ManageCategoriesDialog(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ElevatedButton(
                        onPressed: () async {
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
                        child: const Text(
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
