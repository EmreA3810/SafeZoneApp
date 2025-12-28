import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/report_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'web_push_config.dart';
import 'app_navigator.dart';
import 'screens/report_detail_screen.dart';
// No direct model imports needed for token/subscribe handling

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handling
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase, but don't crash if it fails
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // Initialize local notifications for foreground display (non-web)
    if (!kIsWeb) {
      await NotificationService.instance.initialize();
    }

    // Request notification permissions (iOS and Android 13+ POST_NOTIFICATIONS)
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Get FCM token
    await (kIsWeb
      ? messaging.getToken(vapidKey: WebPushConfig.vapidPublicKey)
      : messaging.getToken());

    // Ensure topic subscriptions are applied at startup (if user saved prefs)
    await _reapplyTopicSubscriptions();

    // Listen for token refresh events: update subscriptions
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _reapplyTopicSubscriptions();
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      if (!kIsWeb) {
        NotificationService.instance.showRemoteNotification(message);
      } else {
        // Show popup dialog for web notifications
        _showWebNotificationDialog(message);
      }
    });

    // Navigate when user taps a notification (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final data = message.data;
      final reportId = (data['reportId'] ?? data['id'] ?? data['report_id'])?.toString();
      if (reportId != null && reportId.isNotEmpty) {
        AppNavigator.navigatorKey.currentState?.pushNamed(
          '/report',
          arguments: reportId,
        );
      }
    });

  } catch (e) {
    // Firebase initialization failed - app will run with limited functionality
  }

  runApp(const MyApp());
}

// Constants for topic subscription management
const String _prefsKey = 'notification_categories';

// Show notification popup dialog for web
void _showWebNotificationDialog(RemoteMessage message) {
  final context = AppNavigator.navigatorKey.currentContext;
  if (context == null) return;

  final title = message.notification?.title ?? 'New Notification';
  final body = message.notification?.body ?? '';
  final reportId = message.data['reportId']?.toString();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
        if (reportId != null && reportId.isNotEmpty)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppNavigator.navigatorKey.currentState?.pushNamed(
                '/report',
                arguments: reportId,
              );
            },
            child: const Text('View'),
          ),
      ],
    ),
  );
}

// Reapply topic subscriptions based on saved preferences when app starts
// or when the FCM token refreshes (subscriptions are token-bound).
Future<void> _reapplyTopicSubscriptions() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    if (decoded.isEmpty) return;
    
    final messaging = FirebaseMessaging.instance;
    final subscriptions = <Future<void>>[];
    
    for (final entry in decoded.entries) {
      if (entry.value == true) {
        final topic = 'category_${entry.key}';
        subscriptions.add(
          messaging.subscribeToTopic(topic).then((_) {
            debugPrint('↻ Re-subscribed to $topic');
          }).catchError((e) {
            debugPrint('⚠️ Failed to subscribe to $topic: $e');
          }),
        );
      }
    }
    
    // Wait for all subscriptions to complete
    if (subscriptions.isNotEmpty) {
      await Future.wait(subscriptions);
    }
  } catch (e) {
    debugPrint('⚠️ Failed to reapply topic subscriptions: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ReportService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: AppNavigator.navigatorKey,
            title: 'SafeZone',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            routes: {
              '/report': (context) {
                final args = ModalRoute.of(context)!.settings.arguments;
                final reportId = args is String ? args : args.toString();
                return ReportDetailScreen(reportId: reportId);
              },
            },
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.currentUser != null) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }
}
