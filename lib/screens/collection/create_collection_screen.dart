import 'package:event_scan/screens/home/home_screen.dart';
import 'package:event_scan/services/collection_manager.dart';
import 'package:flutter/material.dart';

class CreateCollectionScreen extends StatefulWidget {
  const CreateCollectionScreen({super.key});

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _collectionNameController = TextEditingController();
  final _eventTitleController = TextEditingController();
  final _accessCodeController = TextEditingController();
  final _creatorPasswordController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isCreating = false;
  bool _checkingName = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _collectionNameController.addListener(_onCollectionNameChanged);
    _accessCodeController.addListener(() => setState(() {})); // For warning visibility
  }

  @override
  void dispose() {
    _collectionNameController.removeListener(_onCollectionNameChanged);
    _collectionNameController.dispose();
    _eventTitleController.dispose();
    _accessCodeController.dispose();
    _creatorPasswordController.dispose();
    super.dispose();
  }

  void _onCollectionNameChanged() {
    final name = _collectionNameController.text.trim();
    // Only check availability if the name is valid format
    if (name.isNotEmpty && RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(name)) {
      _checkCollectionNameAvailability(name);
    } else {
      setState(() {
        _nameError = null;
        _checkingName = false;
      });
    }
  }

  Future<void> _checkCollectionNameAvailability(String name) async {
    setState(() => _checkingName = true);
    
    // Add a small delay to prevent too many API calls
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_collectionNameController.text.trim() != name) {
      return; // User changed the text while we were waiting
    }
    
    final exists = await CollectionManager.collectionExists(name);
    
    if (mounted && _collectionNameController.text.trim() == name) {
      setState(() {
        _checkingName = false;
        _nameError = exists ? 'Collection name already exists' : null;
      });
    }
  }

  Widget _buildCollectionNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _collectionNameController,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value!)) {
            return 'Only letters, numbers, and underscores allowed';
          }
          if (_nameError != null) return _nameError;
          return null;
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Collection Name',
          hintText: 'e.g., xyz_conference_2025',
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          suffixIcon: _checkingName
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : _nameError == null && _collectionNameController.text.isNotEmpty
                  ? Icon(Icons.check, color: Colors.green.shade400)
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Future<void> _createCollection() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_nameError!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog for creator password
    final confirmed = await _showCreatorPasswordConfirmation();
    if (!confirmed) return;

    setState(() => _isCreating = true);

    final success = await CollectionManager.createCollection(
      collectionName: _collectionNameController.text.trim(),
      eventTitle: _eventTitleController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      accessCode: _accessCodeController.text.trim(),
      creatorPassword: _creatorPasswordController.text.trim(),
    );

    setState(() => _isCreating = false);

    if (success) {
      await CollectionManager.setCurrentCollection(_collectionNameController.text.trim());
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create collection. Name might already exist.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Collection'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),                  _buildCollectionNameField(),
                  const SizedBox(height: 4),
                  Text(
                    'Note: Collection names are case-sensitive',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                            _buildTextField(
                              controller: _eventTitleController,
                              label: 'Event Title',
                              hint: 'e.g., XYZ Annual Conference 2025',
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildDatePicker(
                              label: 'Start Date',
                              date: _startDate,
                              onChanged: (date) => setState(() => _startDate = date),
                            ),
                            const SizedBox(height: 16),
                            _buildDatePicker(
                              label: 'End Date',
                              date: _endDate,
                              onChanged: (date) => setState(() => _endDate = date),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _accessCodeController,
                              label: 'Access Code',
                              hint: 'Secure code for collection access',
                              obscureText: true,
                              validator: (value) {
                                // Allow blank for backwards compatibility
                                if (value != null && value.isNotEmpty && value.length < 4) {
                                  return 'At least 4 characters if provided';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _creatorPasswordController,
                              label: 'Creator Password',
                              hint: 'Special code for managing this collection',
                              obscureText: true,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Creator password is required';
                                }
                                if (value!.length < 6) {
                                  return 'Creator password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Note: Once set, the creator password cannot be changed.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const Spacer(),
                            if (_accessCodeController.text.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange.shade300, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Without an access code, anyone can join this collection',
                                        style: TextStyle(
                                          color: Colors.orange.shade300,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ElevatedButton(
                              onPressed: _isCreating ? null : _createCollection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.purple.shade900,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isCreating
                                  ? const CircularProgressIndicator()
                                  : const Text('Create Collection'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        subtitle: Text(
          '${date.day}/${date.month}/${date.year}',
          style: const TextStyle(color: Colors.white),
        ),
        trailing: const Icon(Icons.calendar_today, color: Colors.white),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          );
          if (picked != null) onChanged(picked);
        },
      ),
    );
  }

  Future<bool> _showCreatorPasswordConfirmation() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Creator Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please confirm your creator password to proceed:'),
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim() == _creatorPasswordController.text.trim()) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Creator passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
