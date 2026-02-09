import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        developer.log('User granted provisional permission');
      } else {
        developer.log('User declined or has not accepted permission');
        return;
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      developer.log('FCM Token: $_fcmToken');

      // Save token to Firebase for the current user
      await _saveFCMToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        developer.log('FCM Token refreshed: $token');
        _saveFCMToken();
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    } catch (e) {
      developer.log('Error initializing notifications: $e');
    }
  }

  Future<void> _saveFCMToken() async {
    final user = _auth.currentUser;
    if (user == null || _fcmToken == null) return;

    try {
      await _database.ref('users/${user.uid}/fcmToken').set(_fcmToken);
      developer.log('FCM token saved for user: ${user.uid}');
    } catch (e) {
      developer.log('Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    developer.log('Received foreground message: ${message.messageId}');
    // You can show a custom in-app notification here
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    developer.log('Message clicked when app was in background: ${message.messageId}');
    // Handle navigation based on message data
  }

  Future<void> sendNotificationToUser({
    required String uid,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final tokenSnapshot = await _database.ref('users/$uid/fcmToken').get();
      final token = tokenSnapshot.value as String?;

      if (token == null) {
        developer.log('No FCM token found for user: $uid');
        return;
      }

      // Send notification via Cloud Function or HTTP API
      // This would typically be done via a Cloud Function
      developer.log('Sending notification to user $uid with token $token');
      
      // TODO: Implement actual notification sending via Cloud Function
      // For now, we'll store the notification in the database
      await _database.ref('notifications/$uid').push().set({
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': ServerValue.timestamp,
        'read': false,
      });

    } catch (e) {
      developer.log('Error sending notification: $e');
    }
  }

  Future<void> sendESP32Notification({
    required String uid,
    required String alertType,
    required String message,
    Map<String, dynamic>? esp32Data,
  }) async {
    String title;
    switch (alertType) {
      case 'feed_low':
        title = '⚠️ Feed Level Low';
        break;
      case 'feeding_completed':
        title = '✅ Feeding Completed';
        break;
      case 'power_switch':
        title = '⚡ Power Source Changed';
        break;
      case 'system_error':
        title = '🚨 System Error';
        break;
      default:
        title = '📢 ESP32 Alert';
    }

    await sendNotificationToUser(
      uid: uid,
      title: title,
      body: message,
      data: {
        'type': alertType,
        'esp32_data': esp32Data ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
