import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:mess_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('Starting backfill...');
  final snap = await FirebaseFirestore.instance.collection('global_dishes').get();
  int count = 0;
  for (var doc in snap.docs) {
    final data = doc.data();
    if (data['name'] != null && data['name_lower'] == null) {
      final name = data['name'].toString();
      await doc.reference.update({'name_lower': name.toLowerCase()});
      count++;
      print('Updated $name');
    }
  }
  print('Backfill complete! Updated $count dishes.');
}
