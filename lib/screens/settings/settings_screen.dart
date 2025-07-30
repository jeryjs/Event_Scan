import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'dart:io';
import '../../services/database.dart';
import '../../services/collection_manager.dart';
import '../collection/collection_selection_screen.dart';
import 'manage_categories_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  Future<void> _switchCollection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Collection'),
        content: const Text('Are you sure you want to switch to a different collection? You will need to authenticate again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CollectionManager.clearCurrentCollection();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CollectionSelectionScreen()),
          (route) => false,
        );
      }
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

  Future<void> _checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://api.github.com/repos/jeryjs/Event_Scan/releases/latest'));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);
      
      final latestVersion = data['tag_name'].toString().replaceFirst('v', '');
      
      if (latestVersion != packageInfo.version) {
        final arm64Asset = (data['assets'] as List).firstWhere((asset) => asset['name'].contains('arm64-v8a'), orElse: () => null);
        _showUpdateDialog(latestVersion, packageInfo.version, arm64Asset?['browser_download_url']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have the latest version!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to check for updates: $e')));
    }
  }

  void _showUpdateDialog(String latest, String current, String? downloadUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New version ($latest) is available!'),
            Text('Current: $current'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          if (downloadUrl != null)
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: downloadUrl));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download link copied!')));
              },
              child: const Text('Copy Link'),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[600])) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // App Settings
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('App Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _buildSettingTile(
                        title: 'Check for Updates',
                        subtitle: 'Check for new app versions',
                        icon: Icons.system_update,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _checkForUpdates,
                      ),
                      _buildSettingTile(
                        title: 'Switch Collection',
                        subtitle: 'Change event collection',
                        icon: Icons.swap_horiz,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _switchCollection,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Event Configuration
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Event Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      _buildSettingTile(
                        title: 'Event Title',
                        icon: Icons.title,
                        trailing: SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _eventTitleController,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                      _buildSettingTile(
                        title: 'Start Date',
                        icon: Icons.event,
                        trailing: TextButton(
                          onPressed: () => _selectStartDate(context),
                          child: Text(_startDate != null ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}' : 'Select'),
                        ),
                      ),
                      _buildSettingTile(
                        title: 'End Date',
                        icon: Icons.event_available,
                        trailing: TextButton(
                          onPressed: () => _selectEndDate(context),
                          child: Text(_endDate != null ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}' : 'Select'),
                        ),
                      ),
                      _buildSettingTile(
                        title: 'Categories',
                        subtitle: 'Manage scanning categories',
                        icon: Icons.category,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => const ManageCategoriesDialog(),
                        ).then((_) => setState(() {})),
                      ),
                      _buildSettingTile(
                        title: 'Edit Access Code',
                        subtitle: 'Modify collection access (creator only)',
                        icon: Icons.lock,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _editAccessCode,
                      ),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () async {
                            await _saveSettings();
                            if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
                          },
                          child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save Settings', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _editAccessCode() async {
    final currentCollection = CollectionManager.currentCollection;
    if (currentCollection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active collection')),
      );
      return;
    }

    // Check if creator password is saved locally
    String creatorPassword = await CollectionManager.getSavedCreatorPassword(currentCollection);
    
    // If not saved, ask for it
    if (creatorPassword.isEmpty) {
      final inputPassword = await _askForCreatorPassword();
      if (inputPassword == null) return;
      creatorPassword = inputPassword;
    }

    // Verify creator access
    final isValid = await CollectionManager.verifyCreatorAccess(currentCollection, creatorPassword);
    if (!isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid creator password'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get current access code
    final config = await CollectionManager.getCollectionConfig(currentCollection);
    final currentAccessCode = config?['accessCode'] ?? '';

    // Show edit dialog
    final newAccessCode = await _showEditAccessCodeDialog(currentAccessCode);
    if (newAccessCode == null) return;

    // Update access code
    final success = await CollectionManager.updateCollectionAccessCodes(
      collectionName: currentCollection,
      creatorPassword: creatorPassword,
      newAccessCode: newAccessCode,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access code updated successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update access code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _askForCreatorPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Creator Password Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the creator password to modify access code:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Creator Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showEditAccessCodeDialog(String currentAccessCode) async {
    final controller = TextEditingController(text: currentAccessCode);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Access Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Update the collection access code:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Access Code',
                hintText: 'Leave empty for open access',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
