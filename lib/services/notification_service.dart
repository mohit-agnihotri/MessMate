import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static bool _dialogShown = false;

  /// Strongly-retained push subscription observer to prevent premature garbage collection.
  static OnPushSubscriptionChangeObserver? _subscriptionObserver;

  /// SharedPreferences key to guard the one-time verification dialog.
  static const String _prefDialogShownKey = 'onesignal_verification_dialog_shown';

  /// Initializes the OneSignal SDK and sets up the subscription observer.
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

      // 3. Register retained push subscription observer & evaluate initial state
      await _registerPushSubscriptionObserver();
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
  // Push Subscription Verification Dialog (OneSignal AI Requirement)
  // ───────────────────────────────────────────────────────────────────────────

  /// Registers the push subscription observer and checks if the device is already
  /// registered with a valid server-assigned subscription ID.
  static Future<void> _registerPushSubscriptionObserver() async {
    // Check if dialog was already presented in a prior session
    try {
      final prefs = await SharedPreferences.getInstance();
      _dialogShown = prefs.getBool(_prefDialogShownKey) ?? false;
    } catch (_) {}

    // Retain observer in a static field
    _subscriptionObserver = (OSPushSubscriptionChangedState stateChanges) {
      final currentId = stateChanges.current.id;
      debugPrint('[NotificationService] Push subscription state changed. ID: $currentId');
      if (_isValidSubscriptionId(currentId)) {
        _showVerificationDialogIfNeeded();
      }
    };

    OneSignal.User.pushSubscription.addObserver(_subscriptionObserver!);

    // Evaluate current subscription ID immediately (may already be server-assigned)
    final currentId = OneSignal.User.pushSubscription.id;
    debugPrint('[NotificationService] Current push subscription ID at registration: $currentId');
    if (_isValidSubscriptionId(currentId)) {
      _showVerificationDialogIfNeeded();
    }
  }

  /// A subscription ID is valid only when non-empty and NOT a "local-" placeholder.
  static bool _isValidSubscriptionId(String? id) {
    if (id == null) return false;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('local-')) return false;
    return true;
  }

  /// Displays the required Push Subscription Verification Dialog exactly once.
  static void _showVerificationDialogIfNeeded() {
    if (_dialogShown && hasPushPermission) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_dialogShown && hasPushPermission) return;

      final context = navigatorKey.currentContext;
      if (context == null) {
        // Navigator not mounted yet, retry after short delay
        Future.delayed(
          const Duration(milliseconds: 600),
          _showVerificationDialogIfNeeded,
        );
        return;
      }

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Your OneSignal SDK integration is complete!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: const Text(
              'You can now send Push Notifications & In-App Messages through OneSignal. Tap below to enable push notifications.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  _dialogShown = true;
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(_prefDialogShownKey, true);
                  } catch (_) {}
                  // Required: On button tap, request push permission
                  await requestPermission();
                },
                child: const Text(
                  'Got it',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          );
        },
      );
    });
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
