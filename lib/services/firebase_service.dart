import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background processing
  await Firebase.initializeApp();
  Logger().i("Handling background message: ${message.messageId}");
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Lazy — only access FirebaseMessaging AFTER Firebase.initializeApp() is called
  late FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();
  ApiService? _apiService;
  bool _initialized = false;

  Future<void> initialize(ApiService apiService) async {
    if (_initialized) return;
    _apiService = apiService;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp();

      // 2. Now it's safe to access FirebaseMessaging
      _messaging = FirebaseMessaging.instance;

      // 3. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. Request permissions
      await _requestPermissions();

      // 5. Setup Local Notifications for foreground message displays
      await _setupLocalNotifications();

      // 6. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Notification';
        _logger.i('Received foreground message: $title');
        _showLocalNotification(message);
      });

      // 7. Handle notification click (when app is in background but running)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final title = message.notification?.title ?? 'Notification';
        _logger.i('App opened via notification click: $title');
        _handleNotificationClick(message);
      });

      // 8. Handle initial notification click (when app was terminated)
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        final title = initialMessage.notification?.title ?? 'Notification';
        _logger.i('App launched via initial notification: $title');
        _handleNotificationClick(initialMessage);
      }

      // 9. Listen for token refreshes
      _messaging.onTokenRefresh.listen((String token) async {
        final tokenSnippet = token.length > 6 ? token.substring(token.length - 6) : token;
        _logger.i("FCM Token refreshed: ...$tokenSnippet");
        await _uploadToken(token);
      });

      // 10. Register the token if already logged in
      await registerCurrentToken();

      _initialized = true;
      _logger.i('FirebaseService initialized successfully');
    } catch (e) {
      _logger.e('Error initializing FirebaseService', error: e);
    }
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    _logger.i('Notification permissions status: ${settings.authorizationStatus}');
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _logger.i('Local notification click payload: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'oyu_green_channel',
        'OYU Green Notifications',
        description: 'FCM push notifications for borehole status, tasks, and grievances',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      await _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'oyu_green_channel',
            'OYU Green Notifications',
            channelDescription: 'FCM push notifications for borehole status, tasks, and grievances',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> registerCurrentToken() async {
    try {
      if (_apiService == null || !_apiService!.isAuthenticated) {
        _logger.w('Cannot register token: API service not initialized or user not authenticated');
        return;
      }

      String? token = await _messaging.getToken();
      if (token != null) {
        await _uploadToken(token);
      } else {
        _logger.w('FCM registration token is null');
      }
    } catch (e) {
      _logger.e('Failed to register current FCM token', error: e);
    }
  }

  Future<void> deleteToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null && _apiService != null && _apiService!.isAuthenticated) {
        await _apiService!.unregisterFcmToken(token);
      }
      await _messaging.deleteToken();
      _logger.i('FCM Token deleted successfully');
    } catch (e) {
      _logger.e('Failed to delete/revoke FCM token', error: e);
    }
  }

  Future<void> _uploadToken(String token) async {
    if (_apiService != null && _apiService!.isAuthenticated) {
      String deviceInfo = Platform.isAndroid ? 'Android' : 'iOS';
      bool success = await _apiService!.registerFcmToken(token, deviceInfo: deviceInfo);
      if (success) {
        _logger.i('FCM token registered to API server successfully');
      } else {
        _logger.w('FCM token registration failed on API server');
      }
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    _logger.i('Routing notification action: ${message.data}');
  }
}
