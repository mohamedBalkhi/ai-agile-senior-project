import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/recording_metadata.dart';
import 'recording_storage_service.dart';
import 'dart:developer' as dev;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'recording_background_service.dart';
import 'recording_notification_manager.dart';

class RecordingManager {
  static const Duration MAX_RECORDING_DURATION = Duration(minutes: 45);
  static const Duration WARNING_THRESHOLD = Duration(minutes: 5);
  
  final RecordingStorageService _storage;
  final RecordingBackgroundService _backgroundService;
  final RecordingNotificationManager _notificationManager;
  final _uuid = const Uuid();
  
  bool _isInitialized = false;
  String? _rnnoiseModelPath;
  Timer? _recordingTimer;
  Timer? _warningTimer;
  DateTime? _recordingStartTime;
  Duration _totalElapsedTime = Duration.zero;
  bool _recordingTimeExceeded = false;
  String? _currentMeetingId;
  String? _currentRecordingPath;
  
  final StreamController<Duration> _remainingTimeController = 
      StreamController<Duration>.broadcast();
  
  final StreamController<String?> _warningMessageController = 
      StreamController<String?>.broadcast();
  
  Stream<Duration> get remainingTime => _remainingTimeController.stream;
  Stream<String?> get warningMessage => _warningMessageController.stream;

  RecordingManager(
    this._storage,
    this._backgroundService,
    this._notificationManager,
  ) {
    _initializeRecorder();
    _setupRNNoiseModel();
  }

  

  

  

  Future<void> _initializeRecorder() async {
    if (_isInitialized) return;

    try {
      // Initialize recorder with retry logic
      int retryCount = 0;
      const maxRetries = 3;
      bool initSuccess = false;

      while (!initSuccess && retryCount < maxRetries) {
        try {
          await Recorder.instance.init(
            format: PCMFormat.f32le,
            sampleRate: 48000,
            channels: RecorderChannels.stereo,
          );
          
          // Set FFT smoothing for better visualization
          Recorder.instance.setFftSmoothing(0.5);
          
          initSuccess = true;
          _isInitialized = true;
          
          dev.log('Recorder initialized successfully on attempt ${retryCount + 1}',
            name: 'RecordingManager'
          );
        } catch (e) {
          retryCount++;
          dev.log(
            'Recorder initialization attempt $retryCount failed: $e',
            name: 'RecordingManager'
          );
          
          // Wait before retrying
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }
      }

      if (!_isInitialized) {
        throw Exception('Failed to initialize recorder after $maxRetries attempts');
      }

      // Setup RNNoise model after successful initialization
      await _setupRNNoiseModel();
    } catch (e) {
      _isInitialized = false;
      dev.log('Error initializing recorder: $e',
        name: 'RecordingManager',
        error: e
      );
      throw Exception('Failed to initialize recorder: $e');
    }
  }

  Future<void> _setupRNNoiseModel() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory('${appDir.path}/rnnoise');
      await modelDir.create(recursive: true);
      _rnnoiseModelPath = '${modelDir.path}/model.rnnn';

      if (!await File(_rnnoiseModelPath!).exists()) {
        final byteData = await rootBundle.load('assets/rnnoise/model.rnnn');
        final buffer = byteData.buffer;
        await File(_rnnoiseModelPath!).writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
        );
        dev.log('RNNoise model copied to: $_rnnoiseModelPath', name: 'RecordingManager');
      }
    } catch (e) {
      dev.log('Error setting up RNNoise model: $e', name: 'RecordingManager');
      _rnnoiseModelPath = null;
    }
  }

  Future<String> startRecording(String meetingId) async {
    dev.log('Starting recording for meeting: $meetingId', name: 'RecordingManager');
    
    try {
        // Ensure initialization
        if (!_isInitialized) {
            await _initializeRecorder();
        }

        // Start the recorder device first
        if (!Recorder.instance.isDeviceStarted()) {
            dev.log('Starting recorder device', name: 'RecordingManager');
            Recorder.instance.start();
            await Future.delayed(const Duration(milliseconds: 100)); // Give device time to start
        }

        // Start background service
        dev.log('Starting background service for meeting: $meetingId', name: 'RecordingManager');
        final serviceStarted = await _backgroundService.start(meetingId);
        if (!serviceStarted) {
            dev.log('Background service failed to start', name: 'RecordingManager');
            await _notificationManager.updateNotification(
                type: NotificationType.error,
                elapsed: Duration.zero,
                error: 'Failed to start background service. Please check permissions.',
            );
            throw Exception('Failed to start background service. Please check permissions.');
        }

        final tempDir = await _storage.getRecordingsDirectory();
        final tempPath = '$tempDir/temp_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        dev.log('Starting recording with path: $tempPath', name: 'RecordingManager');
        
        // Ensure the recorder is ready before starting recording
        if (!Recorder.instance.isDeviceStarted()) {
            throw Exception('Recorder device not started');
        }
        
        Recorder.instance.startRecording(completeFilePath: tempPath);
        
        // Verify recording started successfully
        await Future.delayed(const Duration(milliseconds: 100));
        if (!Recorder.instance.isDeviceStarted()) {
            throw Exception('Recording failed to start');
        }
        
        _currentMeetingId = meetingId;
        _currentRecordingPath = tempPath;
        
     

        // Update background service state
        await _backgroundService.updateState(RecordingServiceState.recording);
        
        // Start timers and notifications
        _startTimers();
        await _notificationManager.updateNotification(
            type: NotificationType.recording,
            elapsed: Duration.zero,
            remaining: MAX_RECORDING_DURATION,
        );
        
        dev.log('Recording started successfully', name: 'RecordingManager');
        return tempPath;
    } catch (e) {
        dev.log('Error starting recording: $e', name: 'RecordingManager');
        // Clean up any partial initialization
        try {
            if (Recorder.instance.isDeviceStarted()) {
                Recorder.instance.stop();
            }
        } catch (cleanupError) {
            dev.log('Error during cleanup: $cleanupError', name: 'RecordingManager');
        }
        
        await Future.wait([
            _backgroundService.stop().catchError((e) => null),
            _notificationManager.cancelNotification().catchError((e) => null)
        ]);
        
        throw Exception('Failed to start recording: $e');
    }
  }

  void _startTimers() {
    // Only update _recordingStartTime if it's null (not already recording)
    if (_recordingStartTime == null) {
      _recordingStartTime = DateTime.now();
    }
    _recordingTimeExceeded = false;
    
    // Main timer for stopping recording - Add 500ms buffer
    _recordingTimer = Timer(MAX_RECORDING_DURATION - _totalElapsedTime + const Duration(milliseconds: 500), () async {
      if (_recordingTimeExceeded) return;  // Prevent double execution
      
      _recordingTimeExceeded = true;
      if (_currentMeetingId != null && _currentRecordingPath != null) {
        dev.log('Time limit reached, stopping recording. Total elapsed: ${_totalElapsedTime.inSeconds}s', 
          name: 'RecordingManager');
        _warningMessageController.add('Recording will stop now - Time limit reached');
        await stopRecording(_currentMeetingId!, _currentRecordingPath!, isTimeLimit: true);
      }
    });

    // Timer for updating remaining time and warnings - Use periodic timer with shorter interval
    _warningTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_recordingStartTime != null) {
        final now = DateTime.now();
        final elapsed = now.difference(_recordingStartTime!);
        final totalElapsed = _totalElapsedTime + elapsed;
        final remaining = MAX_RECORDING_DURATION - totalElapsed;
        
        // Only update UI and notifications every second
        if (totalElapsed.inMilliseconds % 1000 < 100) {
          dev.log(
            'Timer update - Elapsed: ${totalElapsed.inSeconds}s, '
            'Remaining: ${remaining.inSeconds}s, '
            'Start time: ${_recordingStartTime!.toIso8601String()}, '
            'Total elapsed: ${_totalElapsedTime.inSeconds}s',
            name: 'RecordingManager'
          );

          if (remaining.isNegative) {
            _warningTimer?.cancel();
            _remainingTimeController.add(Duration.zero);
            return;
          }

          // Always update the UI timer
          _remainingTimeController.add(remaining);

          // Determine if we need to show a warning
          String? warningMessage;
          if (remaining <= WARNING_THRESHOLD && !_recordingTimeExceeded) {
            if (remaining.inSeconds % 30 == 0 || // Every 30 seconds during warning period
                remaining.inSeconds <= 10) {      // Every second in final 10 seconds
              final minutes = remaining.inMinutes;
              final seconds = remaining.inSeconds % 60;
              warningMessage = 'Recording will stop in '
                '${minutes > 0 ? '$minutes minutes ' : ''}'
                '${seconds > 0 ? '$seconds seconds' : ''}';
              
              _warningMessageController.add(warningMessage);
            }
          }

          // Update notification with current progress and warning if needed
          await _notificationManager.updateNotification(
            type: warningMessage != null ? NotificationType.warning : NotificationType.recording,
            elapsed: totalElapsed,
            remaining: remaining,
            message: warningMessage,
          );
        }
      }
    });
  }

  Future<void> pauseRecording() async {
    dev.log('Pausing recording', name: 'RecordingManager');
    try {
      if (!_isInitialized) return;
      
      // Pause the timers
      _recordingTimer?.cancel();
      _warningTimer?.cancel();
      
      // Store the elapsed time
      if (_recordingStartTime != null) {
        _totalElapsedTime += DateTime.now().difference(_recordingStartTime!);
        _recordingStartTime = null;
      }

      Recorder.instance.setPauseRecording(pause: true);
      
      // Update background service and notification
      await _backgroundService.updateState(RecordingServiceState.paused);
      await _notificationManager.updateNotification(
        type: NotificationType.paused,
        elapsed: _totalElapsedTime,
        message: "Recording paused - Tap to resume",
      );
      
      dev.log('Recording paused. Total elapsed time: ${_totalElapsedTime.inSeconds}s', 
        name: 'RecordingManager');
    } catch (e) {
      dev.log('Error pausing recording: $e', name: 'RecordingManager');
      throw Exception('Failed to pause recording: $e');
    }
  }

  Future<void> resumeRecording() async {
    dev.log('Resuming recording', name: 'RecordingManager');
    try {
      if (!_isInitialized) return;
      
      // Calculate remaining time
      final remainingDuration = MAX_RECORDING_DURATION - _totalElapsedTime;
      if (remainingDuration.isNegative || remainingDuration == Duration.zero) {
        throw Exception('Recording time limit exceeded');
      }

      // Resume recording and timers
      _recordingStartTime = DateTime.now();
      _startTimers(); // This will now properly handle the existing _totalElapsedTime
      
      Recorder.instance.setPauseRecording(pause: false);
      
      // Update background service and notification
      await _backgroundService.updateState(RecordingServiceState.recording);
      await _notificationManager.updateNotification(
        type: NotificationType.recording,
        elapsed: _totalElapsedTime,
        remaining: remainingDuration,
      );
      
      dev.log('Recording resumed. Total elapsed time: ${_totalElapsedTime.inSeconds}s, Remaining: ${remainingDuration.inSeconds}s', 
        name: 'RecordingManager');
    } catch (e) {
      dev.log('Error resuming recording: $e', name: 'RecordingManager');
      throw Exception('Failed to resume recording: $e');
    }
  }

  Future<String> _applyNoiseReduction(String inputPath) async {
    try {
      final outputPath = inputPath.replaceAll('.wav', '_clean.wav');
      
      // Build FFmpeg command based on available model
      final String command;
      if (_rnnoiseModelPath != null) {
        // Use RNNoise with .rnnn model
        command = '-i "$inputPath" -ac 1 -af '
            'highpass=f=200,lowpass=f=3000,'
            'arnndn=m="$_rnnoiseModelPath",'
            'dynaudnorm=f=10:g=3:p=0.9:m=15.0 '
            '"$outputPath"';
        dev.log('Using RNNoise for noise reduction with model: $_rnnoiseModelPath', 
          name: 'RecordingManager');
      } else {
        // Fallback to afftdn if RNNoise model is not available
        command = '-i "$inputPath" -ac 1 -af '
            'afftdn=nf=-25,'
            'dynaudnorm=f=10:g=3:p=0.9:m=15.0 '
            '"$outputPath"';
        dev.log('Using afftdn for noise reduction (RNNoise not available)', 
          name: 'RecordingManager');
      }
      
      dev.log('Applying noise reduction: $command', name: 'RecordingManager');
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Delete original file to save space
        await File(inputPath).delete();
        dev.log('Noise reduction completed: $outputPath', name: 'RecordingManager');
        return outputPath;
      } else {
        final logs = await session.getLogs();
        dev.log('FFmpeg failed with logs: ${logs.join("\n")}', 
          name: 'RecordingManager');
        throw Exception('FFmpeg failed: ${logs.join("\n")}');
      }
    } catch (e) {
      dev.log('Error applying noise reduction: $e', name: 'RecordingManager');
      // Return original file if noise reduction fails
      return inputPath;
    }
  }

  Future<RecordingMetadata> stopRecording(String meetingId, String tempPath, {bool isTimeLimit = false, String? meetingTitle}) async {
    dev.log('Stopping recording for meeting: $meetingId (Time limit: $isTimeLimit)', 
      name: 'RecordingManager');
    try {
      if (!_isInitialized) {
        throw Exception('Recorder not initialized');
      }
      
      // Prevent duplicate stops
      if (!Recorder.instance.isDeviceStarted()) {
        dev.log('Recording already stopped', name: 'RecordingManager');
        throw Exception('Recording already stopped');
      }
      
      // 1. Cancel all timers and clear state
      _recordingTimer?.cancel();
      _warningTimer?.cancel();
      _recordingStartTime = null;
      _totalElapsedTime = Duration.zero;
      _currentMeetingId = null;
      _currentRecordingPath = null;
      
      // 2. Update background service and notification
      await _backgroundService.updateState(RecordingServiceState.processing);
      await _notificationManager.updateNotification(
        type: NotificationType.processing,
        elapsed: _totalElapsedTime,
        message: 'Processing audio recording...',
      );
      
      // 3. Stop the actual recording
      Recorder.instance.stopRecording();
      dev.log('Recording stopped', name: 'RecordingManager');
      
      // 4. Process the audio with noise reduction
      dev.log('Starting noise reduction...', name: 'RecordingManager');
      await _notificationManager.updateNotification(
        type: NotificationType.processing,
        elapsed: _totalElapsedTime,
        message: 'Applying noise reduction...',
      );
      final processedPath = await _applyNoiseReduction(tempPath);
      dev.log('Noise reduction completed: $processedPath', name: 'RecordingManager');
      
      // 5. Move to permanent storage
      await _notificationManager.updateNotification(
        type: NotificationType.processing,
        elapsed: _totalElapsedTime,
        message: 'Finalizing recording...',
      );
      final permanentPath = await _storage.moveToStorage(processedPath, meetingId);
      
      // 6. Get audio metadata
      final duration = await _getAudioDuration(permanentPath);
      final fileSize = await File(permanentPath).length();

      final metadata = RecordingMetadata(
        id: _uuid.v4(),
        meetingId: meetingId,
        filePath: permanentPath,
        recordedAt: DateTime.now(),
        fileSize: fileSize,
        duration: duration,
        wasTimeLimited: isTimeLimit,
      );

   
      
      // 7. Update notification to complete with meeting title
      await _notificationManager.updateNotification(
        type: NotificationType.complete,
        elapsed: duration,
        meetingTitle: meetingTitle,
      );
      
      // 8. Stop background service
      await _backgroundService.stop();

      dev.log('Saving recording metadata', name: 'RecordingManager');
      await _storage.saveRecording(metadata);
      dev.log('Recording metadata saved successfully', name: 'RecordingManager');
      
      return metadata;
    } catch (e) {
      dev.log('Error stopping recording: $e', name: 'RecordingManager');
      
      // Update notification with error
      await _notificationManager.updateNotification(
        type: NotificationType.error,
        elapsed: _totalElapsedTime,
        error: 'Failed to stop recording: $e',
      );
      
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<Duration> _getAudioDuration(String filePath) async {
    try {
      dev.log('Getting audio duration for: $filePath', name: 'RecordingManager');
      
      // Calculate duration based on file size and audio parameters
      final file = File(filePath);
      final fileSize = await file.length();
      
      // For f32le stereo at 48kHz:
      // - Each sample is 4 bytes (32 bits)
      // - Stereo means 2 channels
      // - Sample rate is 48000 per second
      const bytesPerSecond = 4 * 2 * 48000; // bytes per sample * channels * sample rate
      final durationInSeconds = fileSize / bytesPerSecond;
      final duration = Duration(milliseconds: (durationInSeconds * 1000).round());
      
      dev.log(
        'Audio duration calculated - '
        'File size: $fileSize bytes, '
        'Bytes per second: $bytesPerSecond, '
        'Duration: ${duration.inSeconds} seconds',
        name: 'RecordingManager'
      );
      
      return duration;
    } catch (e) {
      dev.log('Error calculating audio duration: $e', name: 'RecordingManager', error: e);
      return Duration.zero;
    }
  }

  Future<bool> isRecording() async {
    try {
      if (!_isInitialized) return false;
      // Check both the device state and our internal state
      return Recorder.instance.isDeviceStarted() && 
             _currentMeetingId != null &&
             _currentRecordingPath != null;
    } catch (e) {
      dev.log('Error checking recording status: $e', name: 'RecordingManager');
      return false;
    }
  }

  Future<bool> isPaused() async {
    try {
      if (!_isInitialized) return false;
      // Check if we have an active recording that's paused
      return _currentMeetingId != null && 
             _currentRecordingPath != null &&
             !Recorder.instance.isDeviceStarted();
    } catch (e) {
      dev.log('Error checking pause status: $e', name: 'RecordingManager');
      return false;
    }
  }

  Future<void> dispose() async {
    dev.log('Disposing RecordingManager', name: 'RecordingManager');
    _recordingTimer?.cancel();
    _warningTimer?.cancel();
    _remainingTimeController.close();
    _warningMessageController.close();
    if (_isInitialized) {
      Recorder.instance.deinit();
      _isInitialized = false;
    }
    await _backgroundService.stop();
  }

  // Public method to check initialization status
  Future<bool> ensureInitialized() async {
    if (_isInitialized) return true;
    
    try {
        await _initializeRecorder();
        return _isInitialized;
    } catch (e) {
        dev.log('Error ensuring recorder initialization: $e',
            name: 'RecordingManager',
            error: e
        );
        return false;
    }
  }

  // Public method to reinitialize recorder
  Future<void> reinitialize() async {
    try {
      await dispose();
      await Future.delayed(const Duration(milliseconds: 100));
      await _initializeRecorder();
      await _setupRNNoiseModel();
    } catch (e) {
      dev.log('Error reinitializing recorder: $e', name: 'RecordingManager');
      throw Exception('Failed to reinitialize recorder: $e');
    }
  }

  // Public method to clean up resources
  Future<void> cleanup() async {
    try {
        // Cancel timers
        _recordingTimer?.cancel();
        _warningTimer?.cancel();
        
        // Stop recording if active
        if (_isInitialized && Recorder.instance.isDeviceStarted()) {
            try {
                Recorder.instance.stopRecording();
                Recorder.instance.stop();
            } catch (e) {
                dev.log('Error stopping recorder: $e',
                    name: 'RecordingManager',
                    error: e
                );
            }
        }
        
        // Deinitialize recorder
        if (_isInitialized) {
            try {
                Recorder.instance.deinit();
            } catch (e) {
                dev.log('Error deinitializing recorder: $e',
                    name: 'RecordingManager',
                    error: e
                );
            }
            _isInitialized = false;
        }
        
        // Clean up services
        await Future.wait([
            _backgroundService.stop(),
            _notificationManager.cancelNotification()
        ]);
        
        // Reset state
        _currentMeetingId = null;
        _currentRecordingPath = null;
        _recordingStartTime = null;
        _totalElapsedTime = Duration.zero;
        _recordingTimeExceeded = false;
        
    } catch (e) {
        dev.log('Error during cleanup: $e',
            name: 'RecordingManager',
            error: e
        );
    }
  }
} 