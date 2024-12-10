import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../components/edit_user_dialog.dart';
import '../../constants/category_icons.dart';
import 'manage_users_screen.dart';
import 'report_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

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
      _isLoading = false;
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
            child: _isLoading ? _buildShimmerStatsCards() : _buildStatsCards(),
          ),
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildShimmerStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      childAspectRatio: 1.3,
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      children: List.generate(4, (index) => _buildShimmerCard()),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16.0),
      childAspectRatio: 1.3,
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      children: [
        _buildStatCard('Total Users', _users.length.toString(), Icons.people, Colors.orange),
        _buildStatCard('Active Today', _calculateActiveUsers().toString(), Icons.person_add, Colors.green),
        ..._buildCategoryStats(),
      ],
    );
  }

  List<Widget> _buildCategoryStats() {
    if (_users.isEmpty) return [];
    
    return (_users.first['scanned']?.keys as Iterable<dynamic>?)
          ?.where((category) => category != 'High Tea')
          .map<Widget>((category) {
            final categoryIcon = getCategoryIconByName(category.toString());
            int count = _users.where((user) {
              var scanned = (user['scanned'] as Map<String, dynamic>?)?[category] as List<dynamic>?;
              return scanned != null && scanned.isNotEmpty;
            }).length;
            
            return _buildStatCard(
              category.toString(), 
              count.toString(), 
              categoryIcon.icon, 
              categoryIcon.color
            );
          }).toList() ?? [];
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.7), color],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  value, 
                  style: const TextStyle(
                    fontSize: 24, 
                    color: Colors.white, 
                    fontWeight: FontWeight.bold
                  )
                ),
                Text(
                  title, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateActiveUsers() {
    int activeUsers = 0;
    final currentDay = DateTime.now().day;
    for (var user in _users) {
      var scanned = user['scanned'] as Map<String, dynamic>? ?? {};
      for (var days in scanned.values) {
        if ((days as List).contains(currentDay)) {
          activeUsers++;
          break;
        }
      }
    }
    return activeUsers;
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