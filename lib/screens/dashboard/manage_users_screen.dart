import 'package:flutter/material.dart';
import 'package:event_scan/services/database.dart';
import '../../components/edit_user_dialog.dart';

class ManageUsersScreen extends StatefulWidget {
  final List<Map<String, dynamic>> users;

  const ManageUsersScreen({super.key, required this.users});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}
class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String searchQuery = '';
  List<Map<String, dynamic>> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    filteredUsers = widget.users;
  }

  void filterUsers(String query) {
    setState(() {
      searchQuery = query;
      filteredUsers = widget.users.where((user) {
        return user['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
               user['subtitle'].toString().toLowerCase().contains(query.toLowerCase()) ||
               user['extras'].values.any((value) => value.toString().toLowerCase().contains(query.toLowerCase())) ||
               user['code'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
      slivers: [
        SliverAppBar(
        expandedHeight: 180,
        floating: true,
        title: const Text('Manage Attendees'),
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
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(child: Text((user['code']?.length ?? 0) > 3 ? user['code'].substring(user['code'].length - 3) : user['code'] ?? '')),
                  title: Text(user['title'] ?? ''),
                  subtitle: Text('Code: ${user['code'] ?? ''}\n${user['subtitle'] ?? '-'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showEditUserDialog(context, [user], canEditMultiple: false),
                  ),
                  onLongPress: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete User'),
                      content: Text('Are you sure you want to delete ${user['title']}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              Database.deleteUser(user['code'] ?? '');
                              widget.users.removeAt(index);
                              filterUsers(searchQuery);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
          },
          childCount: filteredUsers.length,
          ),
        ),
      ],
      ),
    );
  }
}