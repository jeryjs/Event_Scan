import 'package:event_scan/models/barcode_model.dart';
import 'package:flutter/material.dart';
import 'package:event_scan/services/database.dart';
import '../../components/edit_user_dialog.dart';

class ManageUsersScreen extends StatefulWidget {
  final List<BarcodeModel> users;

  const ManageUsersScreen({super.key, required this.users});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}
class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String searchQuery = '';
  List<BarcodeModel> filteredUsers = [];
  bool isSelectionMode = false;
  Set<int> selectedIndices = {};

  @override
  void initState() {
    super.initState();
    filteredUsers = widget.users;
  }

  void filterUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = widget.users.where((user) {
        return user.query(query.toLowerCase());
      }).toList();
    });
  }

  void toggleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
        if (selectedIndices.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedIndices.add(index);
      }
    });
  }

  void enterSelectionMode(int index) {
    setState(() {
      isSelectionMode = true;
      selectedIndices.add(index);
    });
  }

  void exitSelectionMode() {
    setState(() {
      isSelectionMode = false;
      selectedIndices.clear();
    });
  }

  void deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendees'),
        content: Text('Are you sure you want to delete ${selectedIndices.length} attendee(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Get selected users and their codes
              final selectedUsers = selectedIndices.map((index) => filteredUsers[index]).toList();
              final userCodes = selectedUsers.map((user) => user.code).toList();

              Navigator.pop(context); // Close dialog first
              // Capture a local context for SnackBar usage
              final sm = ScaffoldMessenger.of(context);
              // Show loading indicator
              if (mounted) sm.showSnackBar(const SnackBar(content: Text('Deleting attendees...')));

              try {
                // Delete from database
                final success = await Database.deleteUsers(userCodes);

                sm.hideCurrentSnackBar();

                if (success && mounted) {
                  // Remove from local list only if database deletion succeeded
                  setState(() {
                    widget.users.removeWhere((user) => userCodes.contains(user.code));
                    filterUsers(searchQuery);
                    exitSelectionMode();
                  });

                  sm.showSnackBar(SnackBar(content: Text('Deleted ${userCodes.length} attendee(s) successfully')));
                } else {
                  sm.showSnackBar(const SnackBar(content: Text('Failed to delete attendees')));
                }
              } catch (e) {
                sm.showSnackBar(SnackBar(content: Text('Error deleting attendees: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                floating: true,
                title: isSelectionMode 
                  ? Text('${selectedIndices.length} selected')
                  : const Text('Manage Attendees'),
                leading: isSelectionMode 
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: exitSelectionMode,
                    )
                  : null,
                actions: isSelectionMode
                  ? [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: selectedIndices.isNotEmpty ? deleteSelected : null,
                      ),
                    ]
                  : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.bottomCenter,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.teal.withValues(alpha: 0.4), Colors.cyan.withValues(alpha: 0.1)]),
                    ),
                    child: TextField(
                      onChanged: filterUsers,
                      decoration: InputDecoration(
                        hintText: 'Search attendees...',
                        prefixIcon: const Icon(Icons.search),
                        fillColor: Colors.blue.withValues(alpha: 0.1),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (filteredUsers.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty ? 'No attendees found' : 'No results found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isEmpty ? 'Add attendees to get started' : 'Try adjusting your search terms',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var user = filteredUsers[index];
                    bool isSelected = selectedIndices.contains(index);
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
                      child: ListTile(
                        leading: isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (_) => toggleSelection(index),
                            )
                          : CircleAvatar(child: Text((user.code.length) > 3 ? user.code.substring(user.code.length - 3) : user.code)),
                        title: Text(user.title),
                        subtitle: Text('Code: ${user.code}\n${user.subtitle}'),
                        trailing: !isSelectionMode
                          ? IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showEditUserDialog(context, [user], canEditMultiple: false).then((r) {
                                if (r != null && r.isNotEmpty) {
                                  setState(() {
                                    widget.users[widget.users.indexOf(user)] = r.first;
                                    filteredUsers[index] = r.first;
                                  });
                                }
                              }),
                            )
                          : null,
                        onTap: isSelectionMode
                          ? () => toggleSelection(index)
                          : null,
                        onLongPress: !isSelectionMode
                          ? () => enterSelectionMode(index)
                          : null,
                      ),
                    );
                  },
                  childCount: filteredUsers.length,
                  ),
                ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                await showEditUserDialog(context, [BarcodeModel.empty()]).then((result) {
                  setState(() { if (result != null) widget.users.addAll(result); });
                });
              },
              icon: const Icon(Icons.file_upload),
              label: const Text('Import'),
            ),
          ),
        ],
      ),
    );
  }
}