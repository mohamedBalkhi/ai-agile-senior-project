import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import '../core/service_locator.dart';
import 'navigation_service.dart';

enum RecordingServiceState {
  idle,
  preparing,
  recording,
  paused,
  processing,
  error
}

class RecordingServiceData {
  final String meetingId;
  final DateTime startTime;
  final Duration elapsedTime;
  final RecordingServiceState state;
  final String? currentFilePath;
  final bool isTimeLimited;

  RecordingServiceData({
    required this.meetingId,
    required this.startTime,
    required this.state,
    this.elapsedTime = Duration.zero,
    this.currentFilePath,
    this.isTimeLimited = false,
  });

  Map<String, dynamic> toJson() => {
    'meetingId': meetingId,
    'startTime': startTime.toIso8601String(),
    'elapsedTime': elapsedTime.inMilliseconds,
    'state': state.index,
    'currentFilePath': currentFilePath,
    'isTimeLimited': isTimeLimited,
  };

  factory RecordingServiceData.fromJson(Map<String, dynamic> json) {
    return RecordingServiceData(
      meetingId: json['meetingId'],
      startTime: DateTime.parse(json['startTime']),
      elapsedTime: Duration(milliseconds: json['elapsedTime']),
      state: RecordingServiceState.values[json['state']],
      currentFilePath: json['currentFilePath'],
      isTimeLimited: json['isTimeLimited'],
    );
  }
}

class RecordingBackgroundService {
  static const platform = MethodChannel('com.agilemeets.mobile/audio_recording_service');
  static const navigationChannel = MethodChannel('com.agilemeets.mobile/navigation');
  
  RecordingServiceState _currentState = RecordingServiceState.idle;
  Timer? _elapsedTimer;
  Duration _elapsedTime = Duration.zero;
  String? _currentMeetingId;

  RecordingBackgroundService() {
    _setupNavigationChannel();
  }

  void _setupNavigationChannel() {
    navigationChannel.setMethodCallHandler((call) async {
      if (call.method == 'openRecordingScreen') {
        final meetingId = call.arguments as String;
        await _handleRecordingNavigation(meetingId);
      }
    });
  }

  Future<void> _handleRecordingNavigation(String meetingId) async {
    try {
      final navigationService = getIt<NavigationService>();
      await navigationService.openRecordingScreen(meetingId);
    } catch (e) {
      dev.log('Error handling recording navigation: $e',
        name: 'RecordingBackgroundService',
        error: e
      );
    }
  }

  Future<bool> start(String meetingId) async {
    try {
      if (Platform.isAndroid) {
        _currentMeetingId = meetingId;
        final result = await platform.invokeMethod<bool>(
          'startAudioService',
          {'meetingId': meetingId}
        ) ?? false;
        
        if (!result) {
          dev.log('Failed to start audio service',
            name: 'RecordingBackgroundService');
          return false;
        }
      }

      _currentState = RecordingServiceState.preparing;
      return true;
    } catch (e) {
      dev.log('Error starting background service: $e', 
        name: 'RecordingBackgroundService',
        error: e
      );
      return false;
    }
  }

  Future<void> updateState(RecordingServiceState newState) async {
    _currentState = newState;

    if (newState == RecordingServiceState.recording) {
      _startElapsedTimer();
    } else if (newState == RecordingServiceState.paused) {
      _elapsedTimer?.cancel();
    } else if (newState == RecordingServiceState.idle || 
               newState == RecordingServiceState.error) {
      await stop();
    }
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedTime += const Duration(seconds: 1);
    });
  }

  Future<void> stop() async {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _elapsedTime = Duration.zero;
    _currentState = RecordingServiceState.idle;

    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('stopAudioService');
      } catch (e) {
        dev.log('Error stopping audio service: $e',
          name: 'RecordingBackgroundService');
      }
    }
  }

  RecordingServiceState get currentState => _currentState;
  Duration get elapsedTime => _elapsedTime;
  String? get currentMeetingId => _currentMeetingId;
} 