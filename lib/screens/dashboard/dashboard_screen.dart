import 'package:flutter/material.dart';
import '../../components/edit_user_dialog.dart';
import 'manage_users_screen.dart';
import 'report_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    // Load users from Firebase once
    QuerySnapshot snapshot = await Database.getUsers();
    setState(() {
      _users = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fancy AppBar with gradient
      appBar: AppBar(
        title: const Text('Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          ReportScreen(users: _users),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildStatsCards(),
          ),
          // Action Buttons
          _buildActionButtons(),
          // ...additional fancy UI elements...
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard('Total Users', _users.length.toString(), Icons.people, Colors.orange),
        _buildStatCard('Active Today', _calculateActiveUsers().toString(), Icons.person_add, Colors.green),
        // ...additional stats cards...
      ],
    );
  }

  int _calculateActiveUsers() {
    int activeUsers = 0;
    // ...code to calculate active users...
    return activeUsers;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(value, style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.import_export),
            label: const Text('Import Users'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const EditUserDialog(usersData: [{}]),
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.manage_accounts),
            label: const Text('Manage Users'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _manageExistingUsers,
          ),
          // ...additional action buttons...
        ],
      ),
    );
  }

  void _manageExistingUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManageUsersScreen(users: _users)),
    );
  }
}