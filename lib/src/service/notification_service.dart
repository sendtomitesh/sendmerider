import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sendme_rider/src/api/api_path.dart';
import 'package:sendme_rider/src/api/rider_api_service.dart';
import 'package:sendme_rider/src/common/global_constants.dart';
import 'dart:io';

/// Top-level background handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('NotificationService: background message: ${message.data}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static Function(int orderId)? _onOrderTapped;

  static Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTapResponse,
    );

    // Create rider notification channel with outlet_notify ringtone
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'SendMe_1',
              'Rider_Notification',
              description: 'Rider order notification with ringtone',
              importance: Importance.max,
              sound: RawResourceAndroidNotificationSound('outlet_notify'),
              playSound: true,
            ),
          );
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage);
  }

  /// Foreground FCM — show local notification with ringtone
  static void _handleForegroundMessage(RemoteMessage rm) {
    final message = rm.data;
    debugPrint('NotificationService: foreground message: $message');

    // Silent update — just refresh UI, no popup
    if (message['isShowNotification'] == 'false') {
      GlobalConstants.streamController.add('notification');
      return;
    }

    // Extract title (backend sends different key names)
    final title =
        message['title'] ?? message['Title'] ?? rm.notification?.title ?? '';

    // Extract body
    final body =
        message['body'] ??
        message['Message'] ??
        message['message'] ??
        rm.notification?.body ??
        '';

    // Show notification with outlet_notify ringtone
    _showNotification(title, body, message.toString());

    // Broadcast so orders list refreshes
    GlobalConstants.streamController.add('notification');
  }

  static Future<void> _showNotification(
    String title,
    String body,
    String payload,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'SendMe_1',
      'Rider_Notification',
      channelDescription: 'Rider order notification with ringtone',
      playSound: true,
      sound: RawResourceAndroidNotificationSound('outlet_notify'),
      importance: Importance.max,
      priority: Priority.max,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
      sound: 'outlet_notify.caf',
    );
    await _localNotifications.show(
      0,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  static void _onNotificationTapResponse(NotificationResponse response) {
    if (response.payload != null) {
      final match = RegExp(r'orderId:\s*(\d+)').firstMatch(response.payload!);
      if (match != null) {
        final orderId = int.tryParse(match.group(1)!);
        if (orderId != null && _onOrderTapped != null) _onOrderTapped!(orderId);
      }
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final orderIdStr = data['orderId'] ?? data['OrderId'] ?? '';
    if (orderIdStr.toString().isNotEmpty) {
      final orderId = int.tryParse(orderIdStr.toString());
      if (orderId != null && _onOrderTapped != null) _onOrderTapped!(orderId);
    }
  }

  static Future<void> registerToken(int riderId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      GlobalConstants.firebaseToken = token;

      final url =
          '${ApiPath.updateUserToken}'
          'userId=$riderId'
          '&token=$token'
          '&deviceType=${GlobalConstants.deviceType}'
          '&userType=${GlobalConstants.rider}'
          '&deviceId=${GlobalConstants.deviceId}'
          '&version=${GlobalConstants.appVersion}';
      try {
        await RiderApiService().registerDeviceToken(url: url);
      } catch (_) {}

      _messaging.onTokenRefresh.listen((newToken) {
        GlobalConstants.firebaseToken = newToken;
      });
    } catch (e) {
      debugPrint('NotificationService: token error: $e');
    }
  }

  static void setNavigationCallback(Function(int orderId) callback) {
    _onOrderTapped = callback;
  }
}
