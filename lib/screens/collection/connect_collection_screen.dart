import 'package:event_scan/screens/home/home_screen.dart';
import 'package:event_scan/services/collection_manager.dart';
import 'package:flutter/material.dart';

class ConnectCollectionScreen extends StatefulWidget {
  const ConnectCollectionScreen({super.key});

  @override
  State<ConnectCollectionScreen> createState() => _ConnectCollectionScreenState();
}

class _ConnectCollectionScreenState extends State<ConnectCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _collectionNameController = TextEditingController();
  final _accessCodeController = TextEditingController();
  bool _isConnecting = false;
  bool _saveAccessCode = true;
  bool _showAccessCode = false;

  @override
  void initState() {
    super.initState();
    _collectionNameController.addListener(_onCollectionNameChanged);
  }

  @override
  void dispose() {
    _collectionNameController.removeListener(_onCollectionNameChanged);
    _collectionNameController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  void _onCollectionNameChanged() async {
    final collectionName = _collectionNameController.text.trim();
    if (collectionName.isNotEmpty) {
      final savedAccessCode = await CollectionManager.getSavedAccessCode(collectionName);
      if (savedAccessCode != null && _accessCodeController.text.isEmpty) {
        setState(() {
          _accessCodeController.text = savedAccessCode;
        });
      }
    }
  }

  Future<void> _connectToCollection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    final collectionName = _collectionNameController.text.trim();
    final accessCode = _accessCodeController.text.trim();

    try {
      // Check if collection exists and verify access
      final verified = await CollectionManager.verifyCollectionAccess(
        collectionName, 
        accessCode, 
        saveAccessCode: _saveAccessCode
      );
      
      if (verified) {
        await CollectionManager.setCurrentCollection(collectionName);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Collection not found or invalid access code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is Exception ? e.toString() : 'Failed to connect to collection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isConnecting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Collection'),
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
                            const SizedBox(height: 20),
                            const Icon(
                              Icons.link,
                              size: 64,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Connect to Existing Collection',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the collection name and access code provided by your team',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            _buildTextField(
                              controller: _collectionNameController,
                              label: 'Collection Name',
                              hint: 'e.g., xyz_conference_2025',
                              validator: (value) {
                                if (value?.isEmpty ?? true) return 'Required';
                                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value!)) {
                                  return 'Only letters, numbers, and underscores allowed';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Note: Collection name is case-sensitive',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6),fontSize: 12,fontStyle: FontStyle.italic,),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _accessCodeController,
                              label: 'Access Code',
                              hint: 'Enter the secure access code',
                              obscureText: !_showAccessCode,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showAccessCode ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                onPressed: () => setState(() => _showAccessCode = !_showAccessCode),
                              ),
                              validator: (value) {
                                // Allow blank access code for backwards compatibility
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _saveAccessCode,
                                  onChanged: (value) => setState(() => _saveAccessCode = value ?? true),
                                  activeColor: Colors.white,
                                  checkColor: Colors.purple.shade900,
                                ),
                                Expanded(
                                  child: Text(
                                    'Remember access code for this collection',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _isConnecting ? null : _connectToCollection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.purple.shade900,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isConnecting
                                  ? const CircularProgressIndicator()
                                  : const Text('Connect to Collection'),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.white.withValues(alpha: 0.8),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Need Help?',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ask your event organizer for the collection name and access code. Both are required to connect to an existing event collection.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
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
    Widget? suffixIcon,
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
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
