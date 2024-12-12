import 'package:flutter/material.dart';
import 'package:party_scan/services/database.dart';
import '../../components/edit_user_dialog.dart';

class ManageUsersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> users;

  const ManageUsersScreen({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    // Use the passed users data to minimize Firebase calls
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Existing Users'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.teal, Colors.cyan]),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          var user = users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            child: ListTile(
              leading: CircleAvatar(
                child: Text(user['code']?.substring(user['code'].length - 3) ?? ''),
              ),
              title: Text(user['name'] ?? ''),
              subtitle: Text('Code: ${user['code'] ?? ''}\nDesignation: ${user['designation'] ?? ''}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditUserDialog(usersData: [user]),
                  );
                },
              ),
              onLongPress: () => showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete User'),
                  content: Text('Are you sure you want to delete ${user['name']}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Database.deleteUser(user['code']??'');
                        users.removeAt(index);
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
      ),
    );
  }
}