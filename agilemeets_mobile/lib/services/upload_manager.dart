import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'dart:developer' as dev;
import '../data/models/recording_metadata.dart';
import 'upload_background_service.dart';
import 'upload_notification_manager.dart';
import 'recording_storage_service.dart';
import '../data/repositories/meeting_repository.dart';
import 'package:flutter/services.dart';

class UploadManager {
  final UploadBackgroundService _backgroundService;
  final UploadNotificationManager _notificationManager;
  final RecordingStorageService _storage;
  final MeetingRepository _repository;
  
  final _progressController = StreamController<double>.broadcast();
  final _statusController = StreamController<String?>.broadcast();
  
  static const platform = MethodChannel('com.agilemeets.mobile/upload_service');
  CancelToken? _uploadCancelToken;
  Timer? _retryTimer;
  bool _isPaused = false;
  double _lastProgress = 0;
  bool _isCancelled = false;
  
  // Throttled progress stream to prevent too frequent UI updates
  Stream<double> get progress => _progressController.stream.distinct();
  
  Stream<String?> get status => _statusController.stream;

  UploadManager(
    this._backgroundService,
    this._notificationManager,
    this._storage,
    this._repository,
  );

  Future<void> startUpload(RecordingMetadata recording) async {
    try {
      // Reset cancellation state
      _isCancelled = false;
      _isPaused = false;
      
      // Cancel any existing upload
      _uploadCancelToken?.cancel();
      _uploadCancelToken = CancelToken();

      // Start background service
      final serviceStarted = await _backgroundService.start(
        recording.meetingId,
        recording.filePath,
      );

      if (!serviceStarted) {
        dev.log('Failed to start upload service, falling back to foreground upload',
          name: 'UploadManager');
      }

      // Update recording status
      final updatedRecording = recording.copyWith(
        status: RecordingUploadStatus.uploading,
        uploadProgress: 0,
        uploadAttempts: recording.uploadAttempts + 1,
        lastUploadAttempt: DateTime.now(),
      );
      await _storage.updateRecording(updatedRecording);

      // Update notification
      await _notificationManager.updateNotification(
        type: UploadNotificationType.uploading,
        progress: 0,
      );

      // Check if file exists
      final audioFile = File(recording.filePath);
      if (!await audioFile.exists()) {
        throw Exception('Recording file not found');
      }

      // Start upload
      try {
        final response = await _repository.uploadAudio(
          recording.meetingId,
          audioFile,
          onProgress: (progress) async {
            if (!_isCancelled && !_isPaused) {
              await updateProgress(progress);
            }
          },
          cancelToken: _uploadCancelToken,
        );

        // Check if cancelled during upload
        if (_isCancelled) {
          dev.log('Upload was cancelled, not processing response',
            name: 'UploadManager');
          return;
        }

        if (response.data != null) {
          // Update recording status
          await _storage.updateRecording(
            updatedRecording.copyWith(
              status: RecordingUploadStatus.completed,
              uploadProgress: 1.0,
            ),
          );

          // Update notification
          await _notificationManager.updateNotification(
            type: UploadNotificationType.completed,
            progress: 1.0,
          );

          // Update background service
          if (serviceStarted) {
            try {
              await _backgroundService.updateState(UploadServiceState.completed);
            } catch (e) {
              dev.log('Error updating background service state: $e',
                name: 'UploadManager');
            }
          }
          
          _statusController.add('Upload completed successfully');
        } else {
          throw Exception(response.message ?? 'Failed to upload recording');
        }
      } catch (e) {
        if (_isCancelled) {
          dev.log('Upload cancelled by user, ignoring error: $e',
            name: 'UploadManager');
          return;
        }
        rethrow;
      }
    } catch (e) {
      if (_isCancelled) {
        dev.log('Upload cancelled by user, ignoring error: $e',
          name: 'UploadManager');
        return;
      }

      if (e is! DioException || e.type != DioExceptionType.cancel) {
        dev.log('Error uploading recording: $e', name: 'UploadManager');
        
        // Update recording status
        await _storage.updateRecording(
          recording.copyWith(
            status: RecordingUploadStatus.failed,
            uploadProgress: 0,
          ),
        );

        // Update notification
        await _notificationManager.updateNotification(
          type: UploadNotificationType.error,
          error: "Please check your internet connection and try again.",
        );

        // Update background service
        try {
          await _backgroundService.updateState(UploadServiceState.error);
        } catch (e) {
          dev.log('Error updating background service state: $e',
            name: 'UploadManager');
        }
        
        _statusController.add('Upload failed: ${e.toString()}');
        
        // Schedule retry if appropriate
        if (recording.canRetry) {
          _scheduleRetry(recording);
        }
      }
    }
  }

  void _scheduleRetry(RecordingMetadata recording) {
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 30), () {
      if (recording.canRetry) {
        startUpload(recording);
      }
    });
  }

  Future<void> pauseUpload() async {
    _isPaused = true;
    await _backgroundService.pause();
    await _notificationManager.updateNotification(
      type: UploadNotificationType.paused,
    );
    _statusController.add('Upload paused');
  }

  Future<void> resumeUpload() async {
    _isPaused = false;
    await _backgroundService.resume();
    await _notificationManager.updateNotification(
      type: UploadNotificationType.uploading,
    );
    _statusController.add('Upload resumed');
  }

  Future<void> cancelUpload() async {
    try {
      _isCancelled = true;
      _isPaused = false; // Reset pause state
      
      // Cancel any existing upload
      _uploadCancelToken?.cancel('Upload cancelled by user');
      _uploadCancelToken = null;
      
      // Cancel retry timer
      _retryTimer?.cancel();
      _retryTimer = null;
      
      // Stop background service
      await _backgroundService.stop();
      
      // Cancel notification
      await _notificationManager.cancelNotification();
      
      // Reset progress
      _lastProgress = 0;
      
      // Notify status
      _statusController.add('Upload cancelled');
      _progressController.add(0);
    } catch (e) {
      // Log but don't rethrow cancellation errors
      dev.log('Error during upload cancellation: $e',
        name: 'UploadManager',
        error: e);
    }
  }

  Future<void> dispose() async {
    _isCancelled = true;
    
    // Ensure progress is reset to 0 before disposing
    if (Platform.isAndroid) {
      try {
        await platform.invokeMethod('updateUploadProgress', {
          'progress': 0,  // Send as integer, not double
        });
      } catch (e) {
        dev.log('Error resetting progress during dispose: $e',
          name: 'UploadManager');
      }
    }
    
    await cancelUpload();
    await _progressController.close();
    await _statusController.close();
  }

  Future<void> updateProgress(double progress) async {
    if (_isCancelled || _isPaused) return;
    
    // Ensure progress is between 0 and 1
    progress = progress.clamp(0.0, 1.0);
    
    // Only update if there's a significant change
    if ((progress - _lastProgress).abs() >= 0.001) {
      _lastProgress = progress;
      _progressController.add(progress);
      
      if (Platform.isAndroid) {
        try {
          // Convert to integer percentage for platform channel
          final intProgress = (progress * 100).round();
          await platform.invokeMethod('updateUploadProgress', {
            'progress': intProgress,
          });
        } catch (e) {
          dev.log('Error updating upload progress: $e',
            name: 'UploadManager');
        }
      }
    }
  }


  Future<void> startCreateMeetingUpload({
  required String title,
  String? goal,
  required int language,
  required int type,
  required DateTime startTime,
  required DateTime endTime,
  required String timeZone,
  required String projectId,
  required List<String> memberIds,
  String? location,
  DateTime? reminderTime,
  required File audioFile,
  bool isRecurring = false,
  Map<String, dynamic>? recurringPattern,
}) async {
  try {
    // Reset cancellation state
    _isCancelled = false;
    _isPaused = false;
    
    // Cancel any existing upload
    _uploadCancelToken?.cancel();
    _uploadCancelToken = CancelToken();
    
    // Start background service (using projectId and file path as identifiers)
    final serviceStarted = await _backgroundService.start(projectId, audioFile.path);
    if (!serviceStarted) {
      dev.log('Failed to start background service, falling back to foreground upload',
          name: 'UploadManager');
    }
    
    // Update notification for starting upload
    await _notificationManager.updateNotification(
      type: UploadNotificationType.uploading,
      progress: 0,
    );
    
    // Check if file exists
    if (!await audioFile.exists()) {
      throw Exception('Audio file not found');
    }
    
    // Start the meeting creation upload
    final response = await _repository.createMeetingWithAudio(
      title: title,
      goal: goal,
      language: language,
      type: type,
      startTime: startTime,
      endTime: endTime,
      timeZone: timeZone,
      projectId: projectId,
      memberIds: memberIds,
      location: location,
      reminderTime: reminderTime,
      audioFile: audioFile,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      onProgress: (progress) async {
        if (!_isCancelled && !_isPaused) {
          await updateProgress(progress);
        }
      },
      cancelToken: _uploadCancelToken,
    );
    
    // Check if upload was cancelled during the request
    if (_isCancelled) {
      dev.log('Upload was cancelled, not processing response', name: 'UploadManager');
      return;
    }
    
    if (response.data != null) {
      // Upload succeeded:
      await _notificationManager.updateNotification(
        type: UploadNotificationType.completed,
        progress: 1.0,
      );
      
      if (serviceStarted) {
        try {
          await _backgroundService.updateState(UploadServiceState.completed);
        } catch (e) {
          dev.log('Error updating background service state: $e', name: 'UploadManager');
        }
      }
      
      _statusController.add('Meeting created and upload completed successfully');
    } else {
      throw Exception(response.message ?? 'Failed to create meeting with audio');
    }
  } catch (e) {
    if (_isCancelled) {
      dev.log('Upload cancelled by user, ignoring error: $e', name: 'UploadManager');
      return;
    }
    
    if (e is! DioException || e.type != DioExceptionType.cancel) {
      dev.log('Error during meeting creation with audio: $e', name: 'UploadManager');
      
      // Update notification to show error
      await _notificationManager.updateNotification(
        type: UploadNotificationType.error,
        error: "Please check your internet connection and try again.",
      );
      
      try {
        await _backgroundService.updateState(UploadServiceState.error);
      } catch (ex) {
        dev.log('Error updating background service state: $ex', name: 'UploadManager');
      }
      
      _statusController.add('Upload failed: ${e.toString()}');
      
      // Optionally, you can schedule a retry here if needed
    }
  }
}
} 