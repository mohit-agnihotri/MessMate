import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

/// Service for the global_dishes Firestore collection.
///
/// Architecture rule:
///   - Flutter always reads cached imageUrl from Firestore.
///   - This service NEVER calls Pexels or any external photo API.
///   - Pexels is used exclusively by the backend seeder script (scripts/seed_firebase_dishes.js).
class DishCatalogService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'global_dishes';

  /// Search dishes by partial name match using searchKeywords array.
  /// Returns up to [limit] results.
  static Future<List<DishModel>> searchDishes(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();

    // Firestore array-contains query on searchKeywords
    // This matches any keyword that starts with the query prefix via range query.
    final snapshot = await _db
        .collection(_collection)
        .where('searchKeywords', arrayContains: normalizedQuery)
        .limit(limit)
        .get();

    // If exact keyword match returns results, use them.
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
    }

    // Fallback: range query on 'name' field for prefix matching
    final rangeSnapshot = await _db
        .collection(_collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .limit(limit)
        .get();

    return rangeSnapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
  }

  /// Get all dishes for a specific category (e.g., 'veg', 'nonveg', 'dal').
  static Future<List<DishModel>> getByCategory(String category, {int limit = 50}) async {
    final snapshot = await _db
        .collection(_collection)
        .where('category', isEqualTo: category)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
  }

  /// Fetch all dishes (use sparingly — only for offline caching purposes).
  static Future<List<DishModel>> getAllDishes({int limit = 1000}) async {
    final snapshot = await _db
        .collection(_collection)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => DishModel.fromFirestore(doc)).toList();
  }

  /// Check if a dish with this name already has an imageUrl.
  /// Used by future new-dish logic to avoid redundant image fetches.
  static Future<bool> dishHasImage(String dishName) async {
    final snap = await _db
        .collection(_collection)
        .where('name', isEqualTo: dishName)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return false;
    final imageUrl = snap.docs.first.data()['imageUrl'] as String?;
    return imageUrl != null && imageUrl.startsWith('http');
  }
}
