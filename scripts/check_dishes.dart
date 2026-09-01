import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final snap = await FirebaseFirestore.instance.collection('global_dishes').limit(5).get();
  for (var doc in snap.docs) {
    print('Dish: ${doc.id} => ${doc.data()}');
  }
}
