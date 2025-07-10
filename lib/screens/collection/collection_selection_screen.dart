import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_scan/screens/collection/connect_collection_screen.dart';
import 'package:event_scan/screens/collection/create_collection_screen.dart';
import 'package:flutter/material.dart';

import '../../services/collection_manager.dart';
import '../home/home_screen.dart';

class CollectionSelectionScreen extends StatefulWidget {
  const CollectionSelectionScreen({super.key});

  @override
  State<CollectionSelectionScreen> createState() =>
      _CollectionSelectionScreenState();
}

class _CollectionSelectionScreenState extends State<CollectionSelectionScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _collections = [];
  bool _isLoading = true;
  bool _showAllCollections = false;
  bool _isExpansionOpen = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadCollections();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    final collections = await CollectionManager.getAvailableCollections();
    setState(() {
      _collections = collections;
      _isLoading = false;
    });
  }

  Future<void> _selectCollection(Map<String, dynamic> collection) async {
    final collectionId = collection['id'] as String;
    final savedAccessCode = collection['accessCode'] as String?;

    if (savedAccessCode != null && savedAccessCode.isNotEmpty) {
      // Use saved access code directly
      final verified = await CollectionManager.verifyCollectionAccess(
        collectionId,
        savedAccessCode,
      );
      if (verified) {
        await CollectionManager.setCurrentCollection(collectionId);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        // Saved access code is invalid, ask for new one
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Saved access code is invalid. Please enter the current access code.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          _promptForAccessCode(collectionId);
        }
      }
    } else {
      // No saved access code, prompt for it
      _promptForAccessCode(collectionId);
    }
  }

  Future<void> _promptForAccessCode(String collectionId) async {
    final result = await _showAccessCodeDialog();
    if (result != null) {
      final accessCode = result['accessCode'] as String;
      final shouldSaveAccessCode = result['saveAccessCode'] as bool;

      final verified = await CollectionManager.verifyCollectionAccess(
        collectionId,
        accessCode,
        saveAccessCode: shouldSaveAccessCode,
      );
      if (verified) {
        await CollectionManager.setCurrentCollection(collectionId);
        if (mounted) {
          // Show feedback if access code was saved
          if (shouldSaveAccessCode) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access code saved for future use'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Small delay to show the message before navigation
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // ignore: use_build_context_synchronously
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid access code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showAccessCodeDialog() async {
    final controller = TextEditingController();
    bool saveAccessCode = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
          title: const Text('Enter Access Code'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Access code',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            Tooltip(
              message: 'Save this access code',
              child: Switch(value: saveAccessCode, onChanged: (value) => setState(() => saveAccessCode = value)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'accessCode': controller.text.trim(),
                'saveAccessCode': saveAccessCode,
              }),
              child: const Text('Access'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createNewCollection() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateCollectionScreen()),
    );
    if (result == true) {
      _loadCollections();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.purple.shade900],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingWidget()
                      : _buildCollectionsList(),
                ),
                _buildInfoExpansion(),
                _buildBottomButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Image.asset(
            'assets/launcher_icons/ic_launcher_foreground.png',
            width: 90,
            height: 90,
          ),
          const SizedBox(height: 16),
          const Text(
            'Event Scan',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select or create an event collection',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildCollectionsList() {
    if (_collections.isEmpty) {
      return AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        child: _isExpansionOpen
            ? const SizedBox.shrink()
            : Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.09),
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No collections found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first event collection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
      );
    }

    final displayCollections = _showAllCollections
        ? _collections
        : _collections.take(3).toList();
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayCollections.length,
            itemBuilder: (context, index) =>
                _buildCollectionCard(displayCollections[index]),
          ),
        ),
        if (_collections.length > 3 && !_showAllCollections)
          TextButton.icon(
            onPressed: () => setState(() => _showAllCollections = true),
            icon: const Icon(Icons.expand_more, color: Colors.white),
            label: Text(
              'Show ${_collections.length - 3} more',
              style: const TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildCollectionCard(Map<String, dynamic> collection) {
    final startDate = (collection['startDate'] as Timestamp?)?.toDate();
    final eventTitle = collection['eventTitle'] ?? collection['id'];
    final hasAccessCode =
        collection['accessCode'] != null &&
        (collection['accessCode'] as String).isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectCollection(collection),
          onLongPress: () => _showCollectionManagementDialog(collection),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            key: Key(eventTitle),
                            eventTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          if (startDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${startDate.day}/${startDate.month}/${startDate.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 16,
                    ),
                  ],
                ),
                if (collection['creatorPassword'] != null || hasAccessCode)
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (collection['creatorPassword'] != null
                                    ? Colors.blue
                                    : Colors.green)
                                .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        collection['creatorPassword'] != null
                            ? 'CREATOR'
                            : 'SECURED',
                        style: TextStyle(
                          fontSize: 10,
                          color: (collection['creatorPassword'] != null
                              ? Colors.blue.shade300
                              : Colors.green.shade300),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _createNewCollection,
              icon: const Icon(Icons.add),
              label: const Text('Create New Collection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple.shade900,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _connectToExistingCollection,
              icon: const Icon(Icons.link, color: Colors.white),
              label: const Text(
                'Connect to Existing Collection',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoExpansion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'How do collections work?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            _isExpansionOpen ? Icons.expand_more : Icons.expand_less,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          iconColor: Colors.white.withValues(alpha: 0.8),
          collapsedIconColor: Colors.white.withValues(alpha: 0.8),
          childrenPadding: EdgeInsets.zero,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onExpansionChanged: (isExpanded) {
            setState(() => _isExpansionOpen = isExpanded);
          },
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem(
                    Icons.collections,
                    'What is a Collection?',
                    'A collection is like a separate event database. Each event gets its own collection to keep data organized.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.security,
                    'Security',
                    'Each collection is protected with an access code. Only people with the correct code can access the event data.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.group_work,
                    'Team Collaboration',
                    'Multiple organizers can connect to the same collection to work together in real-time.',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.tips_and_updates,
                    'Getting Started',
                    'Create a new collection for your event or connect to an existing one. Choose a memorable name like "xyz_conference_2025".',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _connectToExistingCollection() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ConnectCollectionScreen()),
    );
    if (result == true) {
      _loadCollections();
    }
  }

  Future<void> _showCollectionManagementDialog(
    Map<String, dynamic> collection,
  ) async {
    final collectionName = collection['id'] as String;
    bool deleteFromFirestore = false;
    final creatorCodeController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          title: Text('Remove Collection?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Collection: $collectionName'),
              const Text('Remove this collection from your device?'),
              const SizedBox(height: 24),
              CheckboxListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                ),
                value: deleteFromFirestore,
                onChanged: (value) => setState(() {
                  deleteFromFirestore = value ?? false;
                  errorText = null;
                }),
                title: const Text('Delete for everyone'),
                subtitle: const Text(
                  'This will remove the collection from the cloud database and all devices',
                  style: TextStyle(color: Colors.red),
                ),
                dense: true,
              ),
              if (deleteFromFirestore) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: creatorCodeController,
                  decoration: InputDecoration(
                    labelText: 'Creator Password',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                  ),
                  obscureText: true,
                  onChanged: (_) => setState(() => errorText = null),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (deleteFromFirestore) {
                        final code = creatorCodeController.text.trim();
                        final creatorCode =
                            await CollectionManager.getSavedCreatorPassword(
                              collectionName,
                            );

                        if (code == creatorCode) {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                          _deleteCollectionFromFirestore(collection, code);
                        } else {
                          setState(
                            () => errorText = 'Incorrect creator password',
                          );
                        }
                      } else {
                        Navigator.pop(context);
                        await _deleteCollectionLocally(collectionName);
                      }
                    },
                    child: Text(
                      deleteFromFirestore ? 'Remove Permanently' : 'Remove',
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCollectionLocally(String collectionName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Collection'),
        content: const Text(
          'This will remove the collection from this device only. The collection will remain in Firestore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CollectionManager.deleteCollectionLocally(collectionName);
      _loadCollections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection removed from this device')),
        );
      }
    }
  }

  Future<void> _deleteCollectionFromFirestore(
    Map<String, dynamic> collection,
    String creatorCode,
  ) async {
    final collectionName = collection['id'] as String;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection Permanently'),
        content: const Text(
          'This will permanently delete the collection and ALL its data from cloud database for all devices. This action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await CollectionManager.deleteCollectionFromFirestore(
        collectionName: collectionName,
        creatorPassword: creatorCode,
      );

      if (success) {
        await CollectionManager.deleteCollectionLocally(collectionName);
        _loadCollections();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Collection deleted permanently')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to delete collection. Check your creator Password.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
