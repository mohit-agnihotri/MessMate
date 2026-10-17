import 'package:flutter_test/flutter_test.dart';
import 'package:mess_app/services/notification_service.dart';

void main() {
  group('NotificationService Tests', () {
    test('Default App ID is configured with exact OneSignal App ID', () {
      expect(
        NotificationService.defaultAppId,
        'f2bb3a4c-0631-4e35-a7e7-2155631fbbcf',
      );
    });

    test('NavigatorKey is non-null and ready for dialog mounting', () {
      expect(NotificationService.navigatorKey, isNotNull);
    });

    test('sendMessNotification gracefully returns false when REST API key is omitted', () async {
      final success = await NotificationService.sendMessNotification(
        messId: 'test_mess_123',
        title: 'Test Menu',
        message: 'Dal Fry, Roti',
      );
      // Without API key configured, it logs and safely returns false without crashing
      expect(success, false);
    });

    test('sendStudentNotification gracefully returns false when REST API key is omitted', () async {
      final success = await NotificationService.sendStudentNotification(
        studentId: 'student_456',
        title: 'Bill Updated',
        message: 'Your bill is ready',
      );
      expect(success, false);
    });
  });
}
