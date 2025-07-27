import 'package:event_scan/models/barcode_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../components/custom_step_slider.dart';
import '../../components/edit_user_dialog.dart';
import 'manage_users_screen.dart';
import 'report_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database.dart';
import '../../models/category_model.dart';

class DashboardScreen extends StatefulWidget {
  final List<CategoryModel> categories;
  const DashboardScreen({super.key, required this.categories});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<BarcodeModel> _users = [];
  // ignore: unused_field
  bool _isLoading = true;
  int _selectedDay = 0; // 0 represents 'All' days
  List<String> _dayOptions = [];
  final Map<String, int> _categoryCounts = {};
  late AnimationController _initialAnimationController;
  late Animation<double> _initialAnimation;
  bool _hasAnimated = false;

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

  void _initializeDayOptions() async {
    var settings = await Database.getSettings();
    DateTime startDate = (settings['startDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    DateTime endDate = (settings['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7));
    int totalDays = endDate.difference(startDate).inDays + 1;
    setState(() {
      _dayOptions = ['All', for (int i = 1; i <= totalDays; i++) i.toString()];
    });
  }

  Future<void> _loadData() async {
    await _loadUsers();
    _updateCategoryCounts();
    if (!_hasAnimated) {
      _initialAnimationController.forward();
      _hasAnimated = true;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadUsers() async {
    // Load users from Firebase once
    QuerySnapshot snapshot = await Database.getUsers();
    setState(() {
      // Filter out system documents that start with '.'
      _users = snapshot.docs
          .where((doc) => !doc.id.startsWith('.'))
          .map((doc) => BarcodeModel.fromDocument(doc))
          .toList();
    });
  }

  void _updateCategoryCounts() {
    _categoryCounts.clear();
    // Initialize all category counts to zero
    for (var category in widget.categories) {
      _categoryCounts[category.name] = 0;
    }
    for (var user in _users) {
      for (var entry in user.scanned.entries) {
        var category = entry.key;
        var days = List<int>.from(entry.value);
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
          ReportScreen(users: _users, selectedDay: _selectedDay, categories: widget.categories),
        ],
      ),
    );
  }

  Widget _buildDaySlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        height: 80.0,
        child: Center(
          child: _dayOptions.isEmpty
            ? const CircularProgressIndicator()
            : CustomStepSlider(
                values: _dayOptions,
                selectedValue: _dayOptions[_selectedDay],
                onValueSelected: (value) => _onDaySelected(_dayOptions.indexOf(value)),
                thumbColor: Colors.white.withValues(alpha: 0.2),
                activeTextColor: Colors.white,
                inactiveTextColor: Colors.white70,
                containerHeight: 80.0,
                thumbSize: 55.0,
                activeFontSize: 24.0,
                inactiveFontSize: 16.0,
                sliderDecoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                thumbCorrection: const EdgeInsets.only(left: -10, right: -20),
              ),
        ),
      )
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
    return AnimationLimiter(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        childAspectRatio: 1.3,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: widget,
            ),
          ),
          children: [
            _buildAnimatedStatCard(
                'Total Attendees',
                _selectedDay == 0
                    ? _calculateTotalUsers()
                    : _calculateActiveUsers(),
                Icons.people, Colors.green),
            ..._buildCategoryStats(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryStats() {
    return widget.categories.map((category) {
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
              colors: [color.withValues(alpha: 0.7), color],
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
        return user.scanned.values.any((days) => (days as List).contains(_selectedDay));
      }).length;
    }
  }

  int _calculateActiveUsers() {
    if (_selectedDay == 0) {
      return _users.where((user) {
        return user.scanned.isNotEmpty;
      }).length;
    } else {
      return _users.where((user) {
        return user.scanned.values.any((days) => (days as List).contains(_selectedDay));
      }).length;
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.import_export),
            label: const Text('Import Attendees'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async => showEditUserDialog(context, []).then((newUsersData) {
              if (newUsersData != _users) setState(_loadData);
            }),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.manage_accounts),
            label: const Text('Manage Attendees'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.push(
                context, MaterialPageRoute(builder: (context) => ManageUsersScreen(users: _users))
              ).then((_) => setState(_updateCategoryCounts));
            },
          ),
        ],
      ),
    );
  }
}
