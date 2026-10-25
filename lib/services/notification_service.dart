import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../config/onesignal_config.dart';

/// Centralized service wrapping all OneSignal push notification interactions.
///
/// Follows the OneSignal v5 SDK architectural guidelines:
/// - Single centralized class isolating all OneSignal calls
/// - Strong reference to push subscription observer
/// - Verification dialog shown once when real server-assigned subscription ID is acquired
/// - Tagging and user identity management for students and mess owners
/// - Notification dispatching via OneSignal REST API
class NotificationService {
  NotificationService._();

  /// Default OneSignal App ID for Mess app.
  static const String defaultAppId = OneSignalConfig.appId;

  /// Global navigator key used for presentation of the verification dialog.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static String _appId = defaultAppId;
  static String? _restApiKey;
  static bool _initialized = false;

  /// Initializes the OneSignal SDK and sets up push notifications.
  ///
  /// Must be invoked in main() after [WidgetsFlutterBinding.ensureInitialized].
  static Future<void> initialize({
    String? customAppId,
    String? restApiKey,
    OSLogLevel logLevel = OSLogLevel.info,
  }) async {
    if (_initialized) return;

    _appId = customAppId ?? defaultAppId;
    final envKey = const String.fromEnvironment('ONESIGNAL_REST_API_KEY', defaultValue: '');
    _restApiKey = restApiKey ?? (envKey.isNotEmpty ? envKey : OneSignalConfig.defaultRestApiKey);

    try {
      // 1. Configure logging
      await setLogLevel(logLevel);

      // 2. Initialize SDK with App ID
      await OneSignal.initialize(_appId);

      _initialized = true;
      debugPrint('[NotificationService] OneSignal initialized successfully with App ID: $_appId');

      // 3. Request native system push permission directly (clean OS prompt, no popup)
      await requestPermission();
    } catch (e, st) {
      debugPrint('[NotificationService] Failed to initialize OneSignal: $e\n$st');
    }
  }

  /// Sets the OneSignal console log level.
  static Future<void> setLogLevel(OSLogLevel level) async {
    try {
      await OneSignal.Debug.setLogLevel(level);
    } catch (e) {
      debugPrint('[NotificationService] Error setting log level: $e');
    }
  }

  /// Sets the OneSignal REST API key used for sending notifications directly from the app.
  static void setRestApiKey(String key) {
    _restApiKey = key;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // User Identity & Tags
  // ───────────────────────────────────────────────────────────────────────────

  /// Logs in under the specified external user ID (e.g. Firebase Auth UID or Student ID).
  static Future<void> login(String externalUserId) async {
    try {
      await OneSignal.login(externalUserId);
      debugPrint('[NotificationService] Logged in with external ID: $externalUserId');
    } catch (e) {
      debugPrint('[NotificationService] Error logging in: $e');
    }
  }

  /// Logs out the user and switches to a device-scoped anonymous user.
  static Future<void> logout() async {
    try {
      await OneSignal.logout();
      debugPrint('[NotificationService] Logged out user');
    } catch (e) {
      debugPrint('[NotificationService] Error logging out: $e');
    }
  }

  /// Adds or updates user tags for segmentation and targeting.
  static Future<void> addTags(Map<String, dynamic> tags) async {
    try {
      await OneSignal.User.addTags(tags);
      debugPrint('[NotificationService] Added tags: $tags');
    } catch (e) {
      debugPrint('[NotificationService] Error adding tags: $e');
    }
  }

  /// Removes tags by key.
  static Future<void> removeTags(List<String> keys) async {
    try {
      await OneSignal.User.removeTags(keys);
      debugPrint('[NotificationService] Removed tags: $keys');
    } catch (e) {
      debugPrint('[NotificationService] Error removing tags: $e');
    }
  }

  /// Fetches local tags for the current user.
  static Future<Map<String, String>> getTags() async {
    try {
      return await OneSignal.User.getTags();
    } catch (e) {
      debugPrint('[NotificationService] Error getting tags: $e');
      return {};
    }
  }

  /// Registers user role, mess ID, and notification preferences as OneSignal tags.
  static Future<void> setUserRoleAndMess({
    required String role, // 'student' or 'owner'
    required String messId,
    String? userId,
    Map<String, bool>? preferences,
  }) async {
    if (userId != null && userId.isNotEmpty) {
      await login(userId);
    }

    final tags = <String, dynamic>{
      'role': role,
      'mess_id': messId,
    };

    if (preferences != null) {
      for (final entry in preferences.entries) {
        tags['pref_${entry.key}'] = entry.value.toString();
      }
    }

    await addTags(tags);
  }

  /// Updates a single notification preference tag (e.g. 'menuPublished', 'announcements').
  static Future<void> updateNotificationPreference(String prefKey, bool enabled) async {
    await addTags({'pref_$prefKey': enabled.toString()});
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Email & SMS Subscriptions
  // ───────────────────────────────────────────────────────────────────────────

  /// Adds an email subscription to the current user.
  static Future<void> addEmail(String email) async {
    try {
      await OneSignal.User.addEmail(email);
    } catch (e) {
      debugPrint('[NotificationService] Error adding email: $e');
    }
  }

  /// Removes an email subscription.
  static Future<void> removeEmail(String email) async {
    try {
      await OneSignal.User.removeEmail(email);
    } catch (e) {
      debugPrint('[NotificationService] Error removing email: $e');
    }
  }

  /// Adds an SMS subscription to the current user.
  static Future<void> addSms(String smsNumber) async {
    try {
      await OneSignal.User.addSms(smsNumber);
    } catch (e) {
      debugPrint('[NotificationService] Error adding SMS: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Permissions & Status
  // ───────────────────────────────────────────────────────────────────────────

  /// Prompts the user with the native system push notification dialog.
  static Future<bool> requestPermission() async {
    try {
      final granted = await OneSignal.Notifications.requestPermission(true);
      if (granted) {
        await OneSignal.User.pushSubscription.optIn();
      }
      debugPrint('[NotificationService] Push notification permission result: $granted');
      return granted;
    } catch (e) {
      debugPrint('[NotificationService] Error requesting permission: $e');
      return false;
    }
  }

  /// Returns whether the app currently has push notification permission.
  static bool get hasPushPermission => OneSignal.Notifications.permission;

  /// Returns the current push subscription ID (null if not registered yet).
  static String? get pushSubscriptionId => OneSignal.User.pushSubscription.id;

  // ───────────────────────────────────────────────────────────────────────────
  // Sending Push Notifications via OneSignal REST API
  // ───────────────────────────────────────────────────────────────────────────

  /// Sends a push notification to all students enrolled in a specific mess.
  ///
  /// Optionally filters by student preference tag (e.g. 'menuPublished', 'announcements').
  static Future<bool> sendMessNotification({
    required String messId,
    required String title,
    required String message,
    String? targetPref,
    Map<String, dynamic>? data,
  }) async {
    if (messId.isEmpty) return false;

    final filters = <Map<String, dynamic>>[
      {
        'field': 'tag',
        'key': 'mess_id',
        'relation': '=',
        'value': messId,
      },
      {
        'operator': 'AND',
      },
      {
        'field': 'tag',
        'key': 'role',
        'relation': '=',
        'value': 'student',
      },
    ];

    if (targetPref != null && targetPref.isNotEmpty) {
      filters.addAll([
        {'operator': 'AND'},
        {
          'field': 'tag',
          'key': 'pref_$targetPref',
          'relation': '!=',
          'value': 'false',
        },
      ]);
    }

    final payload = {
      'app_id': _appId,
      'headings': {'en': title},
      'contents': {'en': message},
      'filters': filters,
      if (data != null) 'data': data,
    };

    return _dispatchRestNotification(payload);
  }

  /// Sends a push notification to a specific student by external ID.
  static Future<bool> sendStudentNotification({
    required String studentId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    if (studentId.isEmpty) return false;

    final payload = {
      'app_id': _appId,
      'headings': {'en': title},
      'contents': {'en': message},
      'include_aliases': {
        'external_id': [studentId],
      },
      'target_channel': 'push',
      if (data != null) 'data': data,
    };

    return _dispatchRestNotification(payload);
  }

  /// Sends a push notification to a specific mess owner by external ID (ownerId).
  static Future<bool> sendOwnerNotification({
    required String ownerId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    if (ownerId.isEmpty) return false;

    final payload = {
      'app_id': _appId,
      'headings': {'en': title},
      'contents': {'en': message},
      'include_aliases': {
        'external_id': [ownerId],
      },
      'target_channel': 'push',
      if (data != null) 'data': data,
    };

    return _dispatchRestNotification(payload);
  }

  /// Sends a push notification to all users across the platform.
  static Future<bool> sendBroadcastNotification({
    required String title,
    required String message,
    String? targetRole,
    Map<String, dynamic>? data,
  }) async {
    final filters = <Map<String, dynamic>>[];
    if (targetRole != null && targetRole.isNotEmpty) {
      filters.add({
        'field': 'tag',
        'key': 'role',
        'relation': '=',
        'value': targetRole,
      });
    }

    final payload = {
      'app_id': _appId,
      'headings': {'en': title},
      'contents': {'en': message},
      if (filters.isNotEmpty) 'filters': filters,
      if (filters.isEmpty) 'included_segments': ['All'],
      if (data != null) 'data': data,
    };

    return _dispatchRestNotification(payload);
  }

  /// Internal helper to dispatch notification payload to OneSignal REST endpoint.
  static Future<bool> _dispatchRestNotification(Map<String, dynamic> payload) async {
    if (_restApiKey == null || _restApiKey!.isEmpty) {
      debugPrint(
        '[NotificationService] Notice: ONESIGNAL_REST_API_KEY is not configured yet. '
        'Push payload prepared: ${jsonEncode(payload)}. '
        'Provide the key via NotificationService.setRestApiKey() or --dart-define=ONESIGNAL_REST_API_KEY=... to deliver pushes over the network.',
      );
      return false;
    }

    try {
      final uri = Uri.parse('https://onesignal.com/api/v1/notifications');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[NotificationService] Push dispatched successfully: ${response.body}');
        return true;
      } else {
        debugPrint(
          '[NotificationService] Push dispatch failed with code ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e, st) {
      debugPrint('[NotificationService] Network error dispatching push: $e\n$st');
      return false;
    }
  }
}
