import 'package:flutter/material.dart';
import '../../components/custom_step_slider.dart';
import '../../components/edit_user_dialog.dart';
import 'manage_users_screen.dart';
import 'report_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database.dart';
import '../../models/category_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  int _selectedDay = 0; // 0 represents 'All' days
  late List<String> _dayOptions;
  final Map<String, int> _categoryCounts = {};
  late AnimationController _initialAnimationController;
  late Animation<double> _initialAnimation;
  bool _hasAnimated = false;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initialAnimation = CurvedAnimation(
      parent: _initialAnimationController,
      curve: Curves.easeOut,
    );
    _initializeDayOptions();
    _loadData();
  }

  @override
  void dispose() {
    _initialAnimationController.dispose();
    super.dispose();
  }

  void _initializeDayOptions() {
    // Assuming maximum of 7 days
    _dayOptions = ['All', '1', '2', '3', '4', '5'];
  }

  Future<void> _loadData() async {
    _categories = await Database.getCategories();
    await _loadUsers();
    setState(() => _isLoading = false);
  }

  Future<void> _loadUsers() async {
    // Load users from Firebase once
    QuerySnapshot snapshot = await Database.getUsers();
    setState(() {
      _users = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      _isLoading = false;
    });
    _updateCategoryCounts();
    if (!_hasAnimated) {
      _initialAnimationController.forward();
      _hasAnimated = true;
    }
  }

  void _updateCategoryCounts() {
    _categoryCounts.clear();
    // Initialize all category counts to zero
    for (var category in _categories) {
      _categoryCounts[category.name] = 0;
    }
    for (var user in _users) {
      var scanned = user['scanned'] as Map<String, dynamic>? ?? {};
      for (var entry in scanned.entries) {
        var category = entry.key;
        var days = List<int>.from(entry.value ?? []);
        if (_selectedDay == 0 || days.contains(_selectedDay)) {
          _categoryCounts[category] = (_categoryCounts[category] ?? 0) + 1;
        }
      }
    }
  }

  void _onDaySelected(int index) {
    setState(() {
      _selectedDay = index;
      _updateCategoryCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(150.0),
          child: Column(
            children: [
              _buildDaySlider(),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          ReportScreen(users: _users, selectedDay: _selectedDay, categories: _categories),
        ],
      ),
    );
  }

  Widget _buildDaySlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: CustomStepSlider(
        values: _dayOptions,
        selectedValue: _dayOptions[_selectedDay],
        onValueSelected: (value) => _onDaySelected(_dayOptions.indexOf(value)),
        thumbColor: Colors.white.withOpacity(0.2),
        activeTextColor: Colors.white,
        inactiveTextColor: Colors.white70,
        containerHeight: 80.0,
        thumbSize: 55.0,
        activeFontSize: 24.0,
        inactiveFontSize: 16.0,
        sliderDecoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        thumbCorrection: const EdgeInsets.only(left: -10, right: -20),
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
        ],
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
        _buildAnimatedStatCard(
            'Total Users',
            _selectedDay == 0
                ? _calculateTotalUsers()
                : _calculateActiveUsers(),
            Icons.people, Colors.green),
        ..._buildCategoryStats(),
      ],
    );
  }

  List<Widget> _buildCategoryStats() {
    return _categories.map((category) {
      int count = _categoryCounts[category.name] ?? 0;
      return _buildAnimatedStatCard(
        category.name,
        count,
        category.icon.data,
        Color(category.colorValue),
      );
    }).toList();
  }

  Widget _buildAnimatedStatCard(String title, int value, IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _initialAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _initialAnimation.value)),
          child: Opacity(
            opacity: _initialAnimation.value,
            child: Transform.scale(
              scale: _initialAnimation.value,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: value.toDouble()),
                duration: const Duration(milliseconds: 500),
                builder: (context, val, _) {
                  return _buildStatCard(title, val.toInt().toString(), icon, color);
                },
              ),
            ),
          ),
        );
      },
    );
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

  int _calculateTotalUsers() {
    if (_selectedDay == 0) {
      return _users.length;
    } else {
      return _users.where((user) {
        var scanned = user['scanned'] as Map<String, dynamic>? ?? {};
        return scanned.values.any((days) => (days as List).contains(_selectedDay));
      }).length;
    }
  }

  int _calculateActiveUsers() {
    if (_selectedDay == 0) {
      return _users.where((user) {
        var scanned = user['scanned'] as Map<String, dynamic>? ?? {};
        return scanned.isNotEmpty;
      }).length;
    } else {
      return _users.where((user) {
        var scanned = user['scanned'] as Map<String, dynamic>? ?? {};
        return scanned.values.any((days) => (days as List).contains(_selectedDay));
      }).length;
    }
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