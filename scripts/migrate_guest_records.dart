import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mess_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await reconcileGuestRecords();
}
/// Script to safely migrate old guest records that are missing `messId`.
/// It reconciles the correct `messId` by checking the generated `bills` for that month.
/// If a bill exists, it uses the bill's `messId`.
/// If no bill exists (e.g., current month), it uses the student's current `messId`.
Future<void> reconcileGuestRecords() async {
  debugPrint('Starting guest records reconciliation...');
  final db = FirebaseFirestore.instance;
  
  // Find all guest records missing messId
  // Since we can't easily query for "missing" field in Firestore, we query all guest records
  final snapshot = await db.collection('meal_records')
      .where('status', isEqualTo: 'guest')
      .get();
      
  int updatedCount = 0;
  int unresolvableCount = 0;
  
  final batch = db.batch();
  int batchCount = 0;

  for (final doc in snapshot.docs) {
    final data = doc.data();
    if (!data.containsKey('messId') || data['messId'] == null) {
      final studentId = data['studentId'] as String;
      final dateStr = data['date'] as String; // YYYY-MM-DD
      
      final date = DateTime.parse(dateStr);
      final month = date.month;
      final year = date.year;
      
      // Try to find a bill for this student for this month
      final billId = '${studentId}_${month}_$year';
      final billDoc = await db.collection('bills').doc(billId).get();
      
      String? correctMessId;
      
      if (billDoc.exists && billDoc.data() != null) {
        correctMessId = billDoc.data()!['messId'] as String?;
      } else {
        // Only fallback to current mess if the record belongs to the current month/year
        final now = DateTime.now();
        if (month == now.month && year == now.year) {
          final studentDoc = await db.collection('students').doc(studentId).get();
          if (studentDoc.exists && studentDoc.data() != null) {
            correctMessId = studentDoc.data()!['messId'] as String?;
          }
        }
      }
      
      if (correctMessId != null) {
        batch.update(doc.reference, {'messId': correctMessId});
        updatedCount++;
        batchCount++;
        
        if (batchCount == 500) {
          await batch.commit();
          batchCount = 0;
        }
      } else {
        debugPrint('Could not resolve messId for record: ${doc.id}');
        unresolvableCount++;
      }
    }
  }
  
  if (batchCount > 0) {
    await batch.commit();
  }
  
  debugPrint('Reconciliation complete. Updated: $updatedCount. Unresolvable: $unresolvableCount.');
}
