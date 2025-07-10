import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:event_scan/screens/dashboard/dashboard_screen.dart';

import '../settings/manage_categories_dialog.dart';
import './categories_grid.dart';
import 'day_header.dart';
import '../settings/settings_screen.dart';
import '../../services/database.dart';
import '../../models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<CategoryModel> _categories;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _calculateDayFromSnapshot(DocumentSnapshot snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final startDate = (data['startDate'] as Timestamp).toDate();
      return DateTime.now().difference(startDate).inDays + 1;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: Database.getSettingsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final day = _calculateDayFromSnapshot(snapshot.data!);
              return Column(
                children: [
                  DayHeader(day: day),
                  FutureBuilder<List<CategoryModel>>(
                    future: Database.getCategories(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Expanded(child: Center(child: CircularProgressIndicator()));
                      }
                      _categories = snapshot.data!;
                      if (_categories.isEmpty) {
                        return Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 48,
                                  color: Theme.of(context).disabledColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No categories created yet',
                                  style: TextStyle(
                                    color: Theme.of(context).disabledColor,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => const ManageCategoriesDialog(),
                                    ).then((_) {
                                      setState(() {}); // Refresh this screen as needed
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Manage Categories'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Expanded(child: CategoriesGrid(categories: _categories, selectedDay: day));
                    },
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: _animation,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: [ 
                      Colors.blue[100]!.withValues(alpha: 0.1),
                      Colors.blue[600]!.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomButton(
                      context,
                      icon: Icons.settings,
                      label: 'Settings',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      ).then((_) { 
                        setState(() {}); // Refresh this screen as needed
                      }),
                    ),
                    _buildBottomButton(
                      context,
                      icon: Icons.dashboard,
                      label: 'Dashboard',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DashboardScreen(categories: _categories)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24, color: Colors.blue[600]),
      label: Text(label, style: TextStyle(color: Colors.blue[600])),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
