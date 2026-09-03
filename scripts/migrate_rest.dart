import 'dart:convert';
import 'package:http/http.dart' as http;

final baseUrl = 'https://firestore.googleapis.com/v1/projects/messmate-a14cb/databases/(default)/documents';

Future<void> main() async {
  print('Starting migrations via REST...');

  // 1. Backfill dishes
  print('--- Backfilling Dishes ---');
  final dishesUrl = Uri.parse('$baseUrl/global_dishes');
  final dishesRes = await http.get(dishesUrl);
  if (dishesRes.statusCode == 200) {
    final data = jsonDecode(dishesRes.body);
    final docs = data['documents'] as List<dynamic>? ?? [];
    for (var doc in docs) {
      final name = doc['name'] as String;
      final fields = doc['fields'] as Map<String, dynamic>;
      
      if (fields['name'] != null && fields['name_lower'] == null) {
        final actualName = fields['name']['stringValue'] as String;
        print('Updating dish: $actualName');
        
        final updateUrl = Uri.parse('https://firestore.googleapis.com/v1/$name?updateMask.fieldPaths=name_lower');
        final updateRes = await http.patch(
          updateUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fields': {
              'name_lower': {'stringValue': actualName.toLowerCase()}
            }
          }),
        );
        if (updateRes.statusCode != 200) {
          print('Failed to update $actualName: ${updateRes.body}');
        }
      }
    }
  } else {
    print('Failed to fetch dishes: ${dishesRes.body}');
  }
  
  // 2. Migrate Guest Records
  print('--- Migrating Guest Records ---');
  final queryUrl = Uri.parse('$baseUrl:runQuery');
  final queryRes = await http.post(
    queryUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "structuredQuery": {
        "from": [{"collectionId": "meal_records"}],
        "where": {
          "fieldFilter": {
            "field": {"fieldPath": "status"},
            "op": "EQUAL",
            "value": {"stringValue": "guest"}
          }
        }
      }
    }),
  );
  
  if (queryRes.statusCode == 200) {
    final results = jsonDecode(queryRes.body) as List<dynamic>;
    int updatedCount = 0;
    for (var result in results) {
      if (result['document'] == null) continue;
      final doc = result['document'];
      final name = doc['name'] as String;
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      
      if (fields['messId'] == null && fields['studentId'] != null) {
        final studentId = fields['studentId']['stringValue'] as String;
        print('Found guest record missing messId for student: $studentId');
        
        final studentRes = await http.get(Uri.parse('$baseUrl/students/$studentId'));
        if (studentRes.statusCode == 200) {
          final studentData = jsonDecode(studentRes.body);
          final messId = studentData['fields']?['currentMessId']?['stringValue'];
          if (messId != null && messId.isNotEmpty) {
            print('Updating with messId: $messId');
            final updateUrl = Uri.parse('https://firestore.googleapis.com/v1/$name?updateMask.fieldPaths=messId');
            final patchRes = await http.patch(
              updateUrl,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'fields': {
                  'messId': {'stringValue': messId}
                }
              }),
            );
            if (patchRes.statusCode == 200) {
               updatedCount++;
            }
          }
        }
      }
    }
    print('Guest records updated: $updatedCount');
  } else {
    print('Failed to query meal_records: ${queryRes.body}');
  }
  
  print('Migrations completed!');
}
