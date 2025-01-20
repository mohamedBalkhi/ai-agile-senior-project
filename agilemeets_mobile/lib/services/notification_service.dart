import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/models/notification_token_dto.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _repository = NotificationsRepository();
  final _messaging = FirebaseMessaging.instance;
  final _deviceInfo = DeviceInfoPlugin();
  String? _deviceId;
  String? _fcmToken;
  
  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _initializeDeviceInfo();
    await _initializeNotifications();
    await _requestPermissions();
    await _setupForegroundHandler();
  }

  Future<void> _initializeDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
      }
    } catch (e) {
      developer.log('Error getting device info: $e', name: 'NotificationService');
    }
  }

  Future<void> _initializeNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    
    await _localNotifications.initialize(initializationSettings);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _setupForegroundHandler() async {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
        ),
      ),
    );
  }

  Future<bool> subscribe() async {
    try {
      _fcmToken = await _messaging.getToken();
      developer.log('FCM Token: $_fcmToken', name: 'NotificationService');
      
      if (_fcmToken == null || _deviceId == null) {
        developer.log(
          'Missing FCM token or device ID',
          name: 'NotificationService',
        );
        return false;
      }

      final dto = NotificationTokenDTO(
        token: _fcmToken!,
        deviceId: _deviceId!,
      );

      final response = await _repository.subscribe(dto);
      return response.data ?? false;
    } catch (e) {
      developer.log(
        'Error subscribing to notifications: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  Future<bool> unsubscribe() async {
    try {
      if (_fcmToken == null || _deviceId == null) {
        developer.log(
          'Missing FCM token or device ID for unsubscribe',
          name: 'NotificationService',
        );
        return false;
      }

      final dto = NotificationTokenDTO(
        token: _fcmToken!,
        deviceId: _deviceId!,
      );

      final response = await _repository.unsubscribe(dto);
      return response.data ?? false;
    } catch (e) {
      developer.log(
        'Error unsubscribing from notifications: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }
} 