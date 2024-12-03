import 'package:flutter/material.dart';
import '../../services/database.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categoriesFuture = Database.getCategories();
    });
  }

  Future<void> _addCategory() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isNotEmpty) {
      await Database.addCategory({'name': categoryName});
      _categoryController.clear();
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(String name) async {
    await Database.deleteCategory(name);
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'New Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Add Category'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading categories'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No categories found'));
                  }

                  final categories = snapshot.data!;
                  return DataTable(
                    columns: const [
                      DataColumn(label: Text('Category Name')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: categories.map((category) {
                      return DataRow(cells: [
                        DataCell(Text(category['name'])),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteCategory(category['name']),
                          ),
                        ),
                      ]);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
