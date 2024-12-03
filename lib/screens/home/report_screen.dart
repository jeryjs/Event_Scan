import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database.dart';
import '../../components/edit_user_dialog.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report'),
      ),
      body: FutureBuilder<Stream<QuerySnapshot>>(
        future: Database.getBarcodesStream(),
        builder: (context, streamSnapshot) {
          if (streamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (streamSnapshot.hasError) {
            return const Center(child: Text('Error loading stream'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: streamSnapshot.data,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading data'));
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No data found'));
              }

              final barcodes = snapshot.data!.docs;
              return DataTable(
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Mail')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: barcodes.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DataRow(cells: [
                    DataCell(Text(data['code'] ?? '')),
                    DataCell(Text(data['name'] ?? '')),
                    DataCell(Text(data['mail'] ?? '')),
                    DataCell(Text(data['phone'] ?? '')),
                    DataCell(IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditUserDialog(data: data),
                        );
                      },
                    )),
                  ]);
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
