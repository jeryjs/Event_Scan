import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CollectionManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _currentCollectionKey = 'current_collection';
  static const String _collectionsKey = 'saved_collections';
  
  static String? _currentCollection;
  
  // Get current collection
  static String? get currentCollection => _currentCollection;
  
  // Set current collection
  static Future<void> setCurrentCollection(String collectionName) async {
    _currentCollection = collectionName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentCollectionKey, collectionName);
  }
  
  // Load saved collection on app start
  static Future<void> loadSavedCollection() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCollection = prefs.getString(_currentCollectionKey);
  }
  
  // Clear current collection (for logout/switch)
  static Future<void> clearCurrentCollection() async {
    _currentCollection = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentCollectionKey);
  }
  
  // Save collection info locally
  static Future<void> saveCollectionLocally({
    required String collectionName,
    required String eventTitle,
    required DateTime startDate,
    required DateTime endDate,
    String? accessCode,
    String? creatorPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final collectionsJson = prefs.getString(_collectionsKey) ?? '{}';
    final collections = Map<String, dynamic>.from(json.decode(collectionsJson));
    
    collections[collectionName] = {
      'eventTitle': eventTitle,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'accessCode': accessCode,
      'creatorPassword': creatorPassword,
      'lastAccessed': DateTime.now().millisecondsSinceEpoch,
    };
    
    await prefs.setString(_collectionsKey, json.encode(collections));
  }
  
  // Get locally saved collections
  static Future<List<Map<String, dynamic>>> getAvailableCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final collectionsJson = prefs.getString(_collectionsKey) ?? '{}';
    final collections = Map<String, dynamic>.from(json.decode(collectionsJson));
    
    return collections.entries.map((entry) {
      final data = Map<String, dynamic>.from(entry.value);
      return {
        'id': entry.key,
        'eventTitle': data['eventTitle'],
        'startDate': Timestamp.fromMillisecondsSinceEpoch(data['startDate']),
        'endDate': Timestamp.fromMillisecondsSinceEpoch(data['endDate']),
        'accessCode': data['accessCode'],
        'creatorPassword': data['creatorPassword'],
        'lastAccessed': data['lastAccessed'],
      };
    }).toList()
      ..sort((a, b) => (b['lastAccessed'] ?? 0).compareTo(a['lastAccessed'] ?? 0));
  }
  
  // Get saved access code for collection
  static Future<String?> getSavedAccessCode(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    final collectionsJson = prefs.getString(_collectionsKey) ?? '{}';
    final collections = Map<String, dynamic>.from(json.decode(collectionsJson));
    return collections[collectionName]?['accessCode'];
  }
  
  // Check if collection name exists
  static Future<bool> collectionExists(String collectionName) async {
    try {
      final configDoc = await _firestore.collection(collectionName).doc('.config').get();
      return configDoc.exists;
    } catch (e) {
      return false;
    }
  }
  
  // Create new collection
  static Future<bool> createCollection({
    required String collectionName,
    required String eventTitle,
    required DateTime startDate,
    required DateTime endDate,
    required String accessCode,
    required String creatorPassword,
  }) async {
    try {
      // Check if collection already exists
      final existingDoc = await _firestore.collection(collectionName).doc('.config').get();
      if (existingDoc.exists) {
        return false; // Collection already exists
      }
      
      // Create config document in the collection with categories array
      await _firestore.collection(collectionName).doc('.config').set({
        'eventTitle': eventTitle,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'accessCode': accessCode,
        'creatorPassword': creatorPassword,
        'categories': [], // Store categories directly in config
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Save locally
      await saveCollectionLocally(
        collectionName: collectionName,
        eventTitle: eventTitle,
        startDate: startDate,
        endDate: endDate,
        accessCode: accessCode,
        creatorPassword: creatorPassword,
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Verify access to collection
  static Future<bool> verifyCollectionAccess(String collectionName, String accessCode, {bool saveAccessCode = true}) async {
    try {
      final configDoc = await _firestore.collection(collectionName).doc('.config').get();
      if (!configDoc.exists) {
        throw Exception('Collection "$collectionName" does not exist.');
      }
      
      final data = configDoc.data() as Map<String, dynamic>;
      
      // Allow access if both accessCodes are empty (backwards compatibility) or if they match
      final isValid = (data['accessCode'] ?? '') == accessCode;

      // If valid, save collection info locally
      if (isValid) {
        await saveCollectionLocally(
          collectionName: collectionName,
          eventTitle: data['eventTitle'] ?? collectionName,
          startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
          accessCode: saveAccessCode ? accessCode : null, // Only save access code if requested
          creatorPassword: data['creatorPassword'], // Save creator code if available
        );
      }
      
      return isValid;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get collection config
  static Future<Map<String, dynamic>?> getCollectionConfig(String collectionName) async {
    try {
      final configDoc = await _firestore.collection(collectionName).doc('.config').get();
      if (configDoc.exists) {
        return configDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }
  
  // Update collection config
  static Future<void> updateCollectionConfig(String collectionName, Map<String, dynamic> config) async {
    await _firestore.collection(collectionName).doc('.config').set(config, SetOptions(merge: true));
  }

  // Verify creator access
  static Future<bool> verifyCreatorAccess(String collectionName, String creatorPassword) async {
    try {
      final configDoc = await _firestore.collection(collectionName).doc('.config').get();
      if (!configDoc.exists) return false;
      
      final data = configDoc.data() as Map<String, dynamic>;
      return (data['creatorPassword'] ?? '') == creatorPassword;
    } catch (e) {
      return false;
    }
  }

  // Update collection access codes (creator only)
  static Future<bool> updateCollectionAccessCodes({
    required String collectionName,
    required String creatorPassword,
    String? newAccessCode,
    String? newcreatorPassword,
  }) async {
    try {
      // Verify creator access first
      if (!await verifyCreatorAccess(collectionName, creatorPassword)) {
        return false;
      }

      final updates = <String, dynamic>{};
      if (newAccessCode != null) updates['accessCode'] = newAccessCode;
      if (newcreatorPassword != null) updates['creatorPassword'] = newcreatorPassword;

      await _firestore.collection(collectionName).doc('.config').update(updates);
      
      // Update local storage if this collection is saved
      final prefs = await SharedPreferences.getInstance();
      final collectionsJson = prefs.getString(_collectionsKey) ?? '{}';
      final collections = Map<String, dynamic>.from(json.decode(collectionsJson));
      
      if (collections.containsKey(collectionName)) {
        if (newAccessCode != null) collections[collectionName]['accessCode'] = newAccessCode;
        if (newcreatorPassword != null) collections[collectionName]['creatorPassword'] = newcreatorPassword;
        await prefs.setString(_collectionsKey, json.encode(collections));
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete collection from Firestore (creator only)
  static Future<bool> deleteCollectionFromFirestore({
    required String collectionName,
    required String creatorPassword,
  }) async {
    try {
      // Verify creator access first
      if (!await verifyCreatorAccess(collectionName, creatorPassword)) {
        return false;
      }

      // Get all documents in the collection
      final collectionRef = _firestore.collection(collectionName);
      final snapshot = await collectionRef.get();
      
      // Delete all documents in batches
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Delete collection locally only
  static Future<void> deleteCollectionLocally(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    final collectionsJson = prefs.getString(_collectionsKey) ?? '{}';
    final collections = Map<String, dynamic>.from(json.decode(collectionsJson));
    
    collections.remove(collectionName);
    await prefs.setString(_collectionsKey, json.encode(collections));
    
    // Clear current collection if it's the one being deleted
    if (_currentCollection == collectionName) {
      await clearCurrentCollection();
    }
  }

  // Get saved creator access code for collection
  static Future<String> getSavedCreatorPassword(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    final collectionsJson = prefs.getString(_collectionsKey) ?? '{}';
    final collections = Map<String, dynamic>.from(json.decode(collectionsJson));
    return collections[collectionName]?['creatorPassword'] ?? '';
  }
}
