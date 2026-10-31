import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'theme.dart';
import 'views/pages/splash_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize centralized OneSignal push notification service & push subscription observer
  await NotificationService.initialize();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } else {
    debugPrint(
      "WARNING: Supabase URL or Anon Key not provided via --dart-define. Image uploads will fail.",
    );
  }
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: MezzoApp()));
}

class MezzoApp extends StatefulWidget {
  const MezzoApp({super.key});

  @override
  State<MezzoApp> createState() => _MezzoAppState();
}

class _MezzoAppState extends State<MezzoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // ⏸️ App minimized or phone locked: disable Firestore network to kill background listener reads
      try {
        FirebaseFirestore.instance.disableNetwork();
      } catch (e) {
        debugPrint('[AppLifecycle] Error disabling Firestore network: $e');
      }
    } else if (state == AppLifecycleState.resumed) {
      // ▶️ App brought back to foreground: reconnect Firestore and fetch fresh updates
      try {
        FirebaseFirestore.instance.enableNetwork();
      } catch (e) {
        debugPrint('[AppLifecycle] Error enabling Firestore network: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mezzo',
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
      ],
      home: const SplashPage(),
    );
  }
}

typedef MessMateApp = MezzoApp;
