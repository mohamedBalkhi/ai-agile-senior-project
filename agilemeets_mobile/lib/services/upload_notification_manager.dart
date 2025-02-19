import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as dev;

enum UploadNotificationType {
  uploading,
  paused,
  completed,
  error,
  warning
}

class UploadNotificationManager {
  static const NOTIFICATION_ID = 2;
  static const CHANNEL_ID = "upload_service";
  static const CHANNEL_NAME = "Upload Service";
  static const CHANNEL_DESCRIPTION = "Shows upload status";

  final FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  UploadNotificationManager(): _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings();
      
      await _notifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
        ),
      );

      if (Platform.isAndroid) {
        await _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
          const AndroidNotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            description: CHANNEL_DESCRIPTION,
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
            showBadge: false,
          ),
        );
      }

      _isInitialized = true;
      dev.log('UploadNotificationManager initialized', name: 'UploadNotificationManager');
    } catch (e) {
      dev.log(
        'Error initializing notifications: $e',
        name: 'UploadNotificationManager',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> updateNotification({
    required UploadNotificationType type,
    double? progress,
    String? error,
    String? message,
    String? meetingTitle,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      String title;
      String body;
      bool ongoing = false;
      bool autoCancel = true;
      bool showProgress = false;
      int? maxProgress;
      int? currentProgress;
      List<AndroidNotificationAction>? actions;

      switch (type) {
        case UploadNotificationType.uploading:
          title = "Uploading Recording";
          if (progress != null) {
            currentProgress = (progress * 100).round().clamp(0, 100);
            maxProgress = 100;
            body = "Progress: ${currentProgress}%";
          } else {
            body = message ?? "Preparing upload...";
          }
          ongoing = true;
          autoCancel = false;
          showProgress = true;
          break;
          
        case UploadNotificationType.paused:
          title = "Upload Paused";
          body = message ?? "Tap to resume";
          ongoing = true;
          autoCancel = false;
          if (progress != null) {
            currentProgress = (progress * 100).round().clamp(0, 100);
            maxProgress = 100;
            showProgress = true;
          }
          break;
          
        case UploadNotificationType.completed:
          title = "Upload Complete";
          body = meetingTitle != null 
              ? "Meeting: $meetingTitle\nUpload completed successfully"
              : "Recording uploaded successfully";
          ongoing = false;
          autoCancel = true;
          actions = [
            const AndroidNotificationAction(
              'view',
              'View Recording',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              cancelNotification: true,
            ),
          ];
          break;
          
        case UploadNotificationType.error:
          title = "Upload Failed";
          body = error ?? message ?? "An error occurred during upload";
          ongoing = false;
          autoCancel = true;
          actions = [
            const AndroidNotificationAction(
              'retry',
              'Retry',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              cancelNotification: true,
            ),
          ];
          break;

        case UploadNotificationType.warning:
          title = "Upload Warning";
          body = message ?? "Upload may be interrupted";
          if (progress != null) {
            currentProgress = (progress * 100).round().clamp(0, 100);
            maxProgress = 100;
            showProgress = true;
          }
          ongoing = true;
          autoCancel = false;
          break;
      }

      await _notifications.show(
        NOTIFICATION_ID,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            CHANNEL_ID,
            CHANNEL_NAME,
            channelDescription: CHANNEL_DESCRIPTION,
            importance: type == UploadNotificationType.completed || 
                       type == UploadNotificationType.error
                ? Importance.high 
                : Importance.low,
            priority: type == UploadNotificationType.completed || 
                     type == UploadNotificationType.error
                ? Priority.high 
                : Priority.low,
            ongoing: ongoing,
            autoCancel: autoCancel,
            showWhen: true,
            category: type == UploadNotificationType.completed 
                ? AndroidNotificationCategory.status 
                : null,
            playSound: type == UploadNotificationType.completed || 
                      type == UploadNotificationType.error,
            enableVibration: type == UploadNotificationType.completed || 
                           type == UploadNotificationType.error,
            showProgress: showProgress,
            maxProgress: maxProgress ?? 100,
            progress: currentProgress ?? 0,
            indeterminate: showProgress && currentProgress == null,
            onlyAlertOnce: true,
            silent: type != UploadNotificationType.completed && 
                   type != UploadNotificationType.error,
            actions: actions,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: type == UploadNotificationType.completed || 
                         type == UploadNotificationType.error,
            interruptionLevel: type == UploadNotificationType.completed || 
                             type == UploadNotificationType.error
                ? InterruptionLevel.active 
                : InterruptionLevel.passive,
          ),
        ),
      );

      dev.log(
        'Notification updated: $type | ' +
        (progress != null ? 'Progress: ${(progress * 100).round()}%' : ''),
        name: 'UploadNotificationManager'
      );
    } catch (e) {
      dev.log(
        'Error updating notification: $e',
        name: 'UploadNotificationManager',
        error: e,
      );
    }
  }

  Future<void> cancelNotification() async {
    try {
      await _notifications.cancel(NOTIFICATION_ID);
      dev.log('Notification cancelled', name: 'UploadNotificationManager');
    } catch (e) {
      dev.log(
        'Error cancelling notification: $e',
        name: 'UploadNotificationManager',
        error: e,
      );
    }
  }
} 