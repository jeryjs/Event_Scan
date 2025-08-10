import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/collection/collection_selection_screen.dart';
import 'services/collection_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Firebase initialized. Loading saved collection...');
  await CollectionManager.loadSavedCollection();
  print('Loaded collection: '
      '${CollectionManager.currentCollection}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building MyApp. currentCollection: '
        '${CollectionManager.currentCollection}');
    return MaterialApp(
      title: 'Event Scan',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CollectionManager.currentCollection != null 
          ? const DebugHomeScreen() 
          : const DebugCollectionSelectionScreen(),
    );
  }
}

// Debug wrappers to print when screens are built
class DebugHomeScreen extends StatelessWidget {
  const DebugHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    print('Showing HomeScreen');
    return const HomeScreen();
  }
}

class DebugCollectionSelectionScreen extends StatelessWidget {
  const DebugCollectionSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    print('Showing CollectionSelectionScreen');
    return const CollectionSelectionScreen();
  }
}
