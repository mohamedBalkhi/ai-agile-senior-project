import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as dev;

enum NotificationType {
  recording,
  paused,
  processing,
  error,
  complete,
  warning
}

class RecordingNotificationManager {
  static const NOTIFICATION_ID = 1;
  static const CHANNEL_ID = "recording_service";
  static const CHANNEL_NAME = "Recording Service";
  static const CHANNEL_DESCRIPTION = "Shows recording status";

  final FlutterLocalNotificationsPlugin _notifications;
  bool _isInitialized = false;

  RecordingNotificationManager(): _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
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
            importance: Importance.max,
            playSound: false,
            enableVibration: false,
            showBadge: false,
          ),
        );
      }

      _isInitialized = true;
      dev.log('NotificationManager initialized', name: 'RecordingNotificationManager');
    } catch (e) {
      dev.log(
        'Error initializing notifications: $e',
        name: 'RecordingNotificationManager',
        error: e,
      );
      rethrow;
    }
  }

  Future<void> updateNotification({
    required NotificationType type,
    required Duration elapsed,
    Duration? remaining,
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
      int? progress;
      int? maxProgress;
      List<AndroidNotificationAction>? actions;

      switch (type) {
        case NotificationType.recording:
          title = "Recording in Progress";
          if (remaining != null) {
            final totalDuration = elapsed + remaining;
            progress = ((elapsed.inMilliseconds * 100.0) / totalDuration.inMilliseconds).round().clamp(0, 100);
            maxProgress = 100;
            body = "Limit Remaining: ${_formatDuration(remaining)}";
          } else {
            body = message ?? "Recording...";
          }
          ongoing = true;
          autoCancel = false;
          showProgress = true;
          break;
          
        case NotificationType.paused:
          title = "Recording Paused";
          body = message ?? "Duration: ${_formatDuration(elapsed)}";
          if (remaining != null) {
            body += " | Limit Remaining: ${_formatDuration(remaining)}";
          }
          ongoing = true;
          autoCancel = false;
          break;
          
        case NotificationType.processing:
          title = "Processing Recording";
          body = message ?? "Please wait...";
          ongoing = true;
          autoCancel = false;
          showProgress = true;
          break;
          
        case NotificationType.error:
          title = "Recording Error";
          body = error ?? message ?? "An error occurred";
          ongoing = false;
          autoCancel = true;
          break;
          
        case NotificationType.complete:
          title = "Recording Complete";
          body = "Meeting: ${meetingTitle ?? 'Untitled'}\nDuration: ${_formatDuration(elapsed)}";
          ongoing = false;
          autoCancel = false;  // Make it persistent
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

        case NotificationType.warning:
          title = "Recording Warning";
          if (remaining != null) {
            final totalDuration = elapsed + remaining;
            progress = ((elapsed.inMilliseconds * 100.0) / totalDuration.inMilliseconds).round().clamp(0, 100);
            maxProgress = 100;
            body = message ?? "Time limit approaching";
            body += "\nLimit Remaining: ${_formatDuration(remaining)}";
          } else {
            body = message ?? "Time limit approaching";
          }
          ongoing = true;
          autoCancel = false;
          showProgress = true;
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
            importance: type == NotificationType.complete ? Importance.high : Importance.low,
            priority: type == NotificationType.complete ? Priority.high : Priority.low,
            ongoing: ongoing,
            autoCancel: autoCancel,
            showWhen: true,
            category: type == NotificationType.complete ? 
                     AndroidNotificationCategory.status : null,
            usesChronometer: type == NotificationType.recording,
            playSound: type == NotificationType.complete,
            enableVibration: type == NotificationType.complete,
            showProgress: showProgress,
            maxProgress: maxProgress ?? 100,
            progress: progress ?? 0,
            indeterminate: showProgress && progress == null,
            onlyAlertOnce: true,
            silent: type != NotificationType.complete,
            actions: actions,
            when: type == NotificationType.recording ? 
                  DateTime.now().millisecondsSinceEpoch - elapsed.inMilliseconds : 
                  type == NotificationType.complete ?
                  DateTime.now().millisecondsSinceEpoch : null,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: type == NotificationType.complete,
            interruptionLevel: type == NotificationType.complete ? 
                             InterruptionLevel.active : 
                             InterruptionLevel.passive,
          ),
        ),
      );

      dev.log(
        'Notification updated: $type | Elapsed: ${elapsed.inSeconds}s | ' +
        (remaining != null ? 'Remaining: ${remaining.inSeconds}s' : ''),
        name: 'RecordingNotificationManager'
      );
    } catch (e) {
      dev.log(
        'Error updating notification: $e',
        name: 'RecordingNotificationManager',
        error: e,
      );
    }
  }

  Future<void> cancelNotification() async {
    try {
      await _notifications.cancel(NOTIFICATION_ID);
      dev.log('Notification cancelled', name: 'RecordingNotificationManager');
    } catch (e) {
      dev.log(
        'Error cancelling notification: $e',
        name: 'RecordingNotificationManager',
        error: e,
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
} 