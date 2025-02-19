import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:developer' as dev;
import '../core/service_locator.dart';
import 'navigation_service.dart';

enum UploadServiceState {
  idle,
  preparing,
  uploading,
  paused,
  completed,
  error
}

class UploadServiceData {
  final String meetingId;
  final String filePath;
  final DateTime startTime;
  final UploadServiceState state;
  final double? progress;
  final String? error;

  UploadServiceData({
    required this.meetingId,
    required this.filePath,
    required this.startTime,
    required this.state,
    this.progress,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'meetingId': meetingId,
    'filePath': filePath,
    'startTime': startTime.toIso8601String(),
    'state': state.index,
    'progress': progress,
    'error': error,
  };

  factory UploadServiceData.fromJson(Map<String, dynamic> json) {
    return UploadServiceData(
      meetingId: json['meetingId'],
      filePath: json['filePath'],
      startTime: DateTime.parse(json['startTime']),
      state: UploadServiceState.values[json['state']],
      progress: json['progress'],
      error: json['error'],
    );
  }
}

class UploadBackgroundService {
  static const platform = MethodChannel('com.agilemeets.mobile/upload_service');
  static const navigationChannel = MethodChannel('com.agilemeets.mobile/navigation');
  
  UploadServiceState _currentState = UploadServiceState.idle;
  String? _currentMeetingId;
  String? _currentFilePath;
  double? _currentProgress;
  final _progressController = StreamController<double>.broadcast();
  final _stateController = StreamController<UploadServiceState>.broadcast();

  Stream<double> get progress => _progressController.stream;
  Stream<UploadServiceState> get state => _stateController.stream;

  UploadBackgroundService() {
    _setupNavigationChannel();
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onUploadProgress':
          final progress = call.arguments as double;
          await updateProgress(progress);
          break;
        case 'onUploadComplete':
          await updateState(UploadServiceState.completed);
          break;
        case 'onUploadError':
          final error = call.arguments as String;
          dev.log('Upload error from native: $error',
            name: 'UploadBackgroundService',
            error: error
          );
          await updateState(UploadServiceState.error);
          break;
      }
    });
  }

  void _setupNavigationChannel() {
    navigationChannel.setMethodCallHandler((call) async {
      if (call.method == 'openUploadScreen') {
        final meetingId = call.arguments as String;
        await _handleUploadNavigation(meetingId);
      }
    });
  }

  Future<void> _handleUploadNavigation(String meetingId) async {
    try {
      final navigationService = getIt<NavigationService>();
      await navigationService.openMeetingDetailsScreen(meetingId);
    } catch (e) {
      dev.log('Error handling upload navigation: $e',
        name: 'UploadBackgroundService',
        error: e
      );
    }
  }

  Future<bool> start(String meetingId, String filePath) async {
    try {
      if (Platform.isAndroid) {
        _currentMeetingId = meetingId;
        _currentFilePath = filePath;
        final result = await platform.invokeMethod<bool>(
          'startUploadService',
          {
            'meetingId': meetingId,
            'filePath': filePath,
          }
        ) ?? false;
        
        if (!result) {
          dev.log('Failed to start upload service',
            name: 'UploadBackgroundService');
          return false;
        }
      }

      _updateState(UploadServiceState.preparing);
      return true;
    } catch (e) {
      dev.log('Error starting background service: $e', 
        name: 'UploadBackgroundService',
        error: e
      );
      return false;
    }
  }

  Future<void> updateProgress(double progress) async {
    if (_currentProgress != progress) {
      _currentProgress = progress;
      _progressController.add(progress);
    }
  }

  Future<void> updateState(UploadServiceState newState) async {
    _updateState(newState);
    
    if (newState == UploadServiceState.completed || 
        newState == UploadServiceState.error) {
      await stop();
    }
  }

  void _updateState(UploadServiceState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
    }
  }

  Future<void> pause() async {
    if (_currentState == UploadServiceState.uploading) {
      _updateState(UploadServiceState.paused);
      
      if (Platform.isAndroid) {
        try {
          await platform.invokeMethod('pauseUpload');
        } catch (e) {
          dev.log('Error pausing upload: $e',
            name: 'UploadBackgroundService');
        }
      }
    }
  }

  Future<void> resume() async {
    if (_currentState == UploadServiceState.paused) {
      _updateState(UploadServiceState.uploading);
      
      if (Platform.isAndroid) {
        try {
          await platform.invokeMethod('resumeUpload');
        } catch (e) {
          dev.log('Error resuming upload: $e',
            name: 'UploadBackgroundService');
        }
      }
    }
  }

  Future<void> stop() async {
    _currentMeetingId = null;
    _currentFilePath = null;
    _currentProgress = null;
    _currentState = UploadServiceState.idle;

    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('stopUploadService');
      } catch (e) {
        dev.log('Error stopping upload service: $e',
          name: 'UploadBackgroundService');
      }
    }
  }

  Future<void> dispose() async {
    await stop();
    await _progressController.close();
    await _stateController.close();
  }

  UploadServiceState get currentState => _currentState;
  String? get currentMeetingId => _currentMeetingId;
  String? get currentFilePath => _currentFilePath;
  double? get currentProgress => _currentProgress;
} 