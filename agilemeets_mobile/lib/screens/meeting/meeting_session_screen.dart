import 'dart:developer' as dev;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:agilemeets/data/models/meeting_member_dto.dart';
import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/widgets/meeting/audio_waveform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../logic/cubits/meeting/meeting_cubit.dart';
import '../../logic/cubits/meeting/meeting_state.dart';
import '../../widgets/meeting/recording_controls.dart';
import '../../widgets/meeting/session_timer.dart';
import '../../utils/app_theme.dart';
import '../../data/models/recording_metadata.dart';
import '../../widgets/meeting/pending_recordings_list.dart';
import '../../widgets/meeting/upload_progress_widget.dart';
import 'dart:async';
import '../../services/recording_manager.dart';
import '../../core/service_locator.dart';
import 'dart:math' show max, min;

class MeetingSessionScreen extends StatefulWidget {
  final String meetingId;
  final String? initialTab;

  const MeetingSessionScreen({
    super.key,
    required this.meetingId,
    this.initialTab,
  });

  @override
  State<MeetingSessionScreen> createState() => _MeetingSessionScreenState();
}

class _MeetingSessionScreenState extends State<MeetingSessionScreen> with WidgetsBindingObserver {
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isProcessing = false;
  String? _recordingPath;
  double _amplitude = 0.0;
  bool _hasPendingRecording = false;
  bool _isCheckingPendingRecordings = true;  // New flag for loading state
  StreamSubscription? _warningSubscription;
  bool _isShowingDialog = false;
  String? _lastWarningMessage;
  bool _isUploading = false;
  MeetingCubit? _meetingCubit;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _isCleaningUp = false;
  ScaffoldMessengerState? _scaffoldMessenger;
  bool _recorderInitialized = false;
  bool _hasHandledRecordingStopped = false;
  Timer? _amplitudeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isRecording = false;
    _isPaused = false;
    _amplitude = 0.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    dev.log('didChangeDependencies called', name: 'MeetingSessionScreen');
    
    // Store ScaffoldMessenger reference
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Initialize context-dependent items here
    try {
      _meetingCubit = context.read<MeetingCubit>();
      dev.log('MeetingCubit initialized successfully', name: 'MeetingSessionScreen');
    } catch (e) {
      dev.log('Error initializing MeetingCubit: $e',
        name: 'MeetingSessionScreen',
        error: e
      );
    }
    
    // Only run initialization once
    if (!_isInitialized) {
      dev.log('Running first-time initialization', name: 'MeetingSessionScreen');
      _isInitialized = true;
      _initializeScreen();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    dev.log('App lifecycle state changed to: $state', name: 'MeetingSessionScreen');
    
    if (_isDisposed || _isCleaningUp) return;  // Add early return if already cleaning up
    
    switch (state) {
      case AppLifecycleState.detached:
        // App is being terminated, clean up everything
        _performCleanup();
        break;
        
      case AppLifecycleState.paused:
        // App is in background
        if (!_isRecording && !_isUploading) {
          // Only cleanup if we're not recording
          _performCleanup();
        } else {
          dev.log('App went to background while recording, keeping recorder active', 
            name: 'MeetingSessionScreen');
        }
        break;
        
      case AppLifecycleState.inactive:
        // Don't perform cleanup on inactive state
        dev.log('App became inactive, no cleanup needed',
          name: 'MeetingSessionScreen');
        break;
        
      case AppLifecycleState.resumed:
        // App came back to foreground
        if (_isRecording) {
          dev.log('App resumed while recording, restarting amplitude timer', 
            name: 'MeetingSessionScreen');
          _startAmplitudeTimer();
        }
        break;
        
      default:
        break;
    }
  }

  Future<void> _initializeScreen() async {
    try {
      // Load meeting details first
      await _loadMeetingDetails();
      
      // Then initialize recorder
      await _initializeRecorder();
      
      // Check for pending recordings
      await _checkPendingRecordings();
      
      // Finally restore recording state if any
      if (mounted) {
        await _restoreRecordingState();
      }
    } catch (e) {
      dev.log('Error initializing screen: $e',
        name: 'MeetingSessionScreen',
        error: e
      );
      
      if (mounted) {
        // Use a post-frame callback to ensure the scaffold is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error initializing screen: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        });
      }
    }
  }

  Future<void> _loadMeetingDetails() async {
    try {
      if (_meetingCubit == null) return;
      await _meetingCubit!.loadMeetingDetails(widget.meetingId);
    } catch (e) {
      dev.log('Error loading meeting details: $e', name: 'MeetingSessionScreen');
      if (mounted) {
        // Use a post-frame callback to ensure the scaffold is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to load meeting details. Please try again.'),
              backgroundColor: AppTheme.errorRed,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _loadMeetingDetails,
              ),
            ),
          );
          Navigator.pop(context);
        });
      }
    }
  }

  Future<void> _initializeRecorder() async {
    try {
        // If already initialized, just return
        if (_recorderInitialized) {
            dev.log('Recorder already initialized', name: 'MeetingSessionScreen');
            return;
        }

        // Request microphone permission
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
            dev.log('No microphone permission', name: 'MeetingSessionScreen');
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Microphone permission is required'),
                        backgroundColor: AppTheme.errorRed,
                    ),
                );
            }
            return;
        }

        // Initialize recorder with retry logic
        int retryCount = 0;
        const maxRetries = 3;

        while (!_recorderInitialized && retryCount < maxRetries) {
            try {
                await Recorder.instance.init(
                    format: PCMFormat.f32le,
                    sampleRate: 48000,
                    channels: RecorderChannels.stereo,
                );
                
                // Set FFT smoothing for better visualization
                Recorder.instance.setFftSmoothing(0.5);
                
                // Start the recorder device
                Recorder.instance.start();
                await Future.delayed(const Duration(milliseconds: 100));
                
                if (!Recorder.instance.isDeviceStarted()) {
                    throw Exception('Failed to start recorder device');
                }
                
                _recorderInitialized = true;
                dev.log('Recorder initialized successfully on attempt ${retryCount + 1}', 
                    name: 'MeetingSessionScreen');
            } catch (e) {
                retryCount++;
                dev.log(
                    'Recorder initialization attempt $retryCount failed: $e',
                    name: 'MeetingSessionScreen'
                );
                
                // Clean up failed initialization
                try {
                    Recorder.instance.deinit();
                } catch (cleanupError) {
                    dev.log('Error during cleanup: $cleanupError', 
                        name: 'MeetingSessionScreen');
                }
                
                // Wait before retrying
                if (retryCount < maxRetries) {
                    await Future.delayed(Duration(milliseconds: 500 * retryCount));
                }
            }
        }

        if (!_recorderInitialized) {
            throw Exception('Failed to initialize recorder after $maxRetries attempts');
        }

        // Log device info
        if (Platform.isAndroid) {
            final deviceInfo = await DeviceInfoPlugin().androidInfo;
            dev.log(
                'Device Info - SDK: ${deviceInfo.version.sdkInt}, '
                'Model: ${deviceInfo.model}, '
                'Manufacturer: ${deviceInfo.manufacturer}, '
                'Device: ${deviceInfo.device}',
                name: 'MeetingSessionScreen'
            );
        }

        final tempDir = await getTemporaryDirectory();
        _recordingPath = '${tempDir.path}/meeting_${widget.meetingId}_${DateTime.now().millisecondsSinceEpoch}.wav';
        dev.log('Recording path: $_recordingPath', name: 'MeetingSessionScreen');
    } catch (e) {
        _recorderInitialized = false;
        dev.log('Error initializing recorder: $e', name: 'MeetingSessionScreen');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Failed to initialize recording: $e'),
                    backgroundColor: AppTheme.errorRed,
                ),
            );
        }
        rethrow;
    }
  }

  Future<bool> _ensureRecorderInitialized() async {
    if (_recorderInitialized) return true;
    
    try {
      await _initializeRecorder();
      return _recorderInitialized;
    } catch (e) {
      dev.log('Failed to initialize recorder: $e',
        name: 'MeetingSessionScreen',
        error: e
      );
      return false;
    }
  }

  Future<void> _checkPendingRecordings() async {
    try {
      setState(() {
        _isCheckingPendingRecordings = true;  // Set loading state
      });
      
      dev.log('Checking pending recordings', name: 'MeetingSessionScreen');
      await _meetingCubit!.loadPendingRecordings();
      final state = _meetingCubit!.state;
      
      final hasPendingForMeeting = state.pendingRecordings?.any(
        (r) => r.meetingId == widget.meetingId && r.status != RecordingUploadStatus.completed
      ) ?? false;
      
      dev.log('Has pending recordings for meeting: $hasPendingForMeeting', 
        name: 'MeetingSessionScreen');
      
      if (mounted) {
        setState(() {
          _hasPendingRecording = hasPendingForMeeting;
          _isCheckingPendingRecordings = false;  // Clear loading state
        });
      }
    } catch (e) {
      dev.log('Error checking pending recordings: $e', 
        name: 'MeetingSessionScreen', 
        error: e
      );
      if (mounted) {
        setState(() {
          _isCheckingPendingRecordings = false;  // Clear loading state on error
        });
      }
    }
  }

  Future<void> _restoreRecordingState() async {
    try {
      final recordingManager = getIt<RecordingManager>();
      final isRecording = await recordingManager.isRecording();
      final isPaused = await recordingManager.isPaused();
      
      // Clear any existing state first
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _amplitude = 0.0;
        });
      }

      // Only restore state if there's an actual recording in progress
      if (isRecording || isPaused) {
        if (mounted) {
          setState(() {
            _isRecording = isRecording;
            _isPaused = isPaused;
          });
          
          if (isRecording && !isPaused) {
            _startAmplitudeTimer();
          }
        }
      }
    } catch (e) {
      dev.log('Error restoring recording state: $e',
        name: 'MeetingSessionScreen',
        error: e
      );
      // On error, ensure UI state is cleared but don't clear cubit state
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isPaused = false;
          _amplitude = 0.0;
        });
      }
    }
  }

  void _handleStateUpdate(MeetingState state) async {
    if (_isDisposed || _isCleaningUp) return;

    dev.log('State update received: ${state.status}', name: 'MeetingSessionScreen');

    // Handle upload completion or cancellation first
    if (state.status == MeetingStateStatus.uploadCompleted ||
        state.status == MeetingStateStatus.uploadCancelled) {
      dev.log('Upload ${state.status}, cleaning up state', name: 'MeetingSessionScreen');
      
      // Reset recording state
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _isProcessing = false;
        _amplitude = 0.0;
        _isUploading = false;
      });

      // Check for pending recordings after upload completion/cancellation
      await _checkPendingRecordings();
      
      // Only navigate back on successful completion
      if (state.status == MeetingStateStatus.uploadCompleted && mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    // Update pending recording state
    final hasPendingForMeeting = state.pendingRecordings?.any(
      (r) => r.meetingId == widget.meetingId && r.status != RecordingUploadStatus.completed
    ) ?? false;
    
    // Update UI state based on recording status
    setState(() {
        _hasPendingRecording = hasPendingForMeeting;
        _isRecording = state.status == MeetingStateStatus.recording || 
                      state.status == MeetingStateStatus.recordingPaused;
        _isPaused = state.status == MeetingStateStatus.recordingPaused;
        _isProcessing = state.status == MeetingStateStatus.loading || 
                       state.status == MeetingStateStatus.processingRecording ||
                       state.isAudioUploading;
        _isUploading = state.isAudioUploading;
        
        if (!_isRecording && !_isProcessing) {
            _amplitude = 0.0;
            _stopAmplitudeTimer();
        } else if (_isRecording && !_isPaused) {
            _startAmplitudeTimer();
        }
    });

    // Add debug logging for dialog conditions
    dev.log(
      'Dialog conditions - '
      'Status: ${state.status}, '
      'hasHandledRecordingStopped: $_hasHandledRecordingStopped, '
      'hasCurrentRecording: ${state.currentRecording != null}',
      name: 'MeetingSessionScreen'
    );

    // Handle recording stopped state
    if (state.status == MeetingStateStatus.recordingStopped && 
        !_hasHandledRecordingStopped && 
        state.currentRecording != null &&
        !state.isAudioUploading) {  // Add this check to prevent showing dialog during upload
        _hasHandledRecordingStopped = true;
        
        try {
            if (mounted && _scaffoldMessenger != null) {
                _scaffoldMessenger!.clearSnackBars();
            }

            final shouldUploadNow = await _showUploadDialog();
            dev.log('Should upload now: $shouldUploadNow', name: 'MeetingSessionScreen');
            if (shouldUploadNow != null && shouldUploadNow && mounted) {
                dev.log('Uploading recording', name: 'MeetingSessionScreen');
                await _meetingCubit?.uploadRecording(
                    state.currentRecording!
                );
            }
            
            if (mounted) {
                await _checkPendingRecordings();
            }
        } catch (e) {
            dev.log('Error handling recording stopped: $e', 
                name: 'MeetingSessionScreen',
                error: e
            );
            if (mounted && _scaffoldMessenger != null) {
                _scaffoldMessenger!.showSnackBar(
                    SnackBar(
                        content: Text('Error processing recording: $e'),
                        backgroundColor: AppTheme.errorRed,
                    ),
                );
            }
        }
    }

    // Handle warning messages
    _handleWarningMessage(state.warningMessage);
  }

  void _handleWarningMessage(String? warningMessage) {
    if (!mounted || _scaffoldMessenger == null || warningMessage == null || 
        warningMessage == _lastWarningMessage) return;

    _lastWarningMessage = warningMessage;
    _scaffoldMessenger!.clearSnackBars();
    _scaffoldMessenger!.showSnackBar(
        SnackBar(
            content: Text(warningMessage),
            backgroundColor: AppTheme.warningOrange,
            duration: const Duration(seconds: 5),
        ),
    );
  }

  void _startAmplitudeTimer() {
    _stopAmplitudeTimer();
    
    if (!_isRecording || _isPaused || _isDisposed) return;

    _updateAmplitude();
    
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (mounted && _isRecording && !_isPaused) {
            _updateAmplitude();
        } else {
            _stopAmplitudeTimer();
        }
    });
  }

  void _stopAmplitudeTimer() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
  }

  void _updateAmplitude() {
    if (!mounted || !_isRecording || _isPaused) return;

    try {
        final volumeDb = Recorder.instance.getVolumeDb();
        final waveData = Recorder.instance.getWave();
        
        setState(() {
            double maxAmplitude = 0.0;
            if (waveData.isNotEmpty) {
                maxAmplitude = waveData.map((s) => s.abs()).reduce(max);
            }
            
            double normalizedVolume = 0.0;
            if (volumeDb > -60) {
                normalizedVolume = ((volumeDb + 60) / 60).clamp(0.0, 1.0);
            }
            
            _amplitude = ((maxAmplitude + normalizedVolume) / 2).clamp(0.0, 1.0);
        });
    } catch (e) {
        dev.log('Error updating amplitude: $e', 
            name: 'MeetingSessionScreen',
            error: e
        );
    }
  }

  Future<void> _startRecording() async {
    if (_hasPendingRecording) {
      dev.log('Cannot start recording - has pending recording', name: 'MeetingSessionScreen');
      ScaffoldMessenger.of(context).clearSnackBars();  // Clear existing snackbars
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please handle the pending recording before starting a new one'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    try {
      // Ensure recorder is initialized
      if (!await _ensureRecorderInitialized()) {
        throw Exception('Failed to initialize recorder');
      }
      
      await _meetingCubit?.handleRecordingState(
        widget.meetingId,
        RecordingAction.start
      );
    } catch (e) {
      dev.log('Error starting recording: $e', name: 'MeetingSessionScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();  // Clear existing snackbars
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _togglePause() async {
    if (!_isRecording) return;

    try {
      await _meetingCubit?.handleRecordingState(
        widget.meetingId,
        _isPaused ? RecordingAction.resume : RecordingAction.pause
      );
    } catch (e) {
      dev.log('Error toggling pause: $e', name: 'MeetingSessionScreen');
    }
  }

  Future<void> _stopRecording() async {
    if (_isProcessing || !_isRecording) return;

    try {
      setState(() {
        _isProcessing = true;
        _hasHandledRecordingStopped = false;  // Reset flag when starting new stop
      });

      dev.log('Starting to stop recording', name: 'MeetingSessionScreen');
      
      await _meetingCubit?.handleRecordingState(
        widget.meetingId,
        RecordingAction.stop
      );
      
      dev.log('stopRecording call completed', name: 'MeetingSessionScreen');
    } catch (e) {
      dev.log('Error stopping recording: $e', name: 'MeetingSessionScreen');
      
      // Ensure we clean up the UI state
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isRecording = false;
          _isPaused = false;
          _amplitude = 0.0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<bool?> _showUploadDialog() async {
    if (_isShowingDialog || _isDisposed) return null;
    
    try {
      _isShowingDialog = true;
      dev.log('Showing upload dialog', name: 'MeetingSessionScreen');
      
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Upload Recording'),
          content: const Text('Would you like to upload the recording now?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // false means upload later
              },
              child: const Text('Upload Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true), // true means upload now
              child: const Text('Upload Now'),
            ),
          ],
        ),
      );

      dev.log('Upload dialog result: $result', name: 'MeetingSessionScreen');
      return result;
    } finally {
      _isShowingDialog = false;
    }
  }

  Future<void> _performCleanup() async {
    if (_isDisposed || _isCleaningUp) return;
    
    try {
        _isCleaningUp = true;
        dev.log('Starting cleanup process', name: 'MeetingSessionScreen');
        
        // Stop amplitude updates
        _stopAmplitudeTimer();
        
        // Cancel timers and subscriptions
        _warningSubscription?.cancel();
        _warningSubscription = null;
        
        // Reset state
        _amplitude = 0.0;
        _isShowingDialog = false;
        _lastWarningMessage = null;
        _hasHandledRecordingStopped = false;

        // Handle active recording or upload
        if (_meetingCubit != null) {
            try {
                if (_isRecording && !_isDisposed) {
                    dev.log('Stopping active recording during cleanup', 
                        name: 'MeetingSessionScreen');
                    await _meetingCubit!.handleRecordingState(
                        widget.meetingId, 
                        RecordingAction.stop
                    );
                }
                
                if (_meetingCubit!.state.isAudioUploading) {
                    dev.log('Cancelling active upload during cleanup', 
                        name: 'MeetingSessionScreen');
                    await _meetingCubit!.cancelUpload();
                }
                
                dev.log('Cleaning up recording state', name: 'MeetingSessionScreen');
                _meetingCubit!.cleanupRecordingState();
            } catch (e) {
                dev.log('Error during recording/upload cleanup: $e',
                    name: 'MeetingSessionScreen',
                    error: e
                );
            }
        }
    } catch (e) {
        dev.log('Error during cleanup: $e',
            name: 'MeetingSessionScreen',
            error: e
        );
    } finally {
        _isCleaningUp = false;
    }
  }

  Widget _buildProcessingIndicator() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Processing animation
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 40.w,
                height: 40.h,
                child: CircularProgressIndicator(
                  strokeWidth: 3.w,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          // Processing title
          Text(
            'Processing Audio',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12.h),
          // Processing message
          Text(
            context.read<MeetingCubit>().state.processingMessage ?? 
            'Please wait while we process your recording...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              color: AppTheme.textGrey,
              height: 1.4,
            ),
          ),
          SizedBox(height: 24.h),
          // Progress bar
          Container(
            height: 4.h,
            width: 200.w,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2.r),
              child: const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure _meetingCubit is not null before using
    if (_meetingCubit == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final meeting = _meetingCubit!.state.selectedMeeting;
    
    if (meeting == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isOrganizer = meeting.creator?.userId == context.read<AuthCubit>().state.userIdentifier;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // Only show dialog if we're actually recording and have a current recording
        if (_isRecording && _meetingCubit!.state.currentRecording != null) {
          final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Recording in Progress'),
              content: const Text('Do you want to stop and save the recording before leaving?'),
              actions: [
                TextButton(
                  onPressed: () {
                    _performCleanup();
                    Navigator.of(context)
                      ..pop(false)  // Close dialog
                      ..pop();      // Pop screen
                  },
                  child: const Text('Discard Recording'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(context).pop(true);
                    await _stopRecording();
                  },
                  child: const Text('Save Recording'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Continue Recording'),
                ),
              ],
            ),
          );

          // If null, user wants to continue recording
          if (result == null) return;
          
          // If false, user wants to discard (already handled in dialog)
          if (!result) return;
          
          // If true, user wants to save (already handled in dialog)
          return;
        }
        
        // If not recording, just clean up and leave
        _performCleanup();
        Navigator.of(context).pop();
      },
      child: BlocConsumer<MeetingCubit, MeetingState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).clearSnackBars();  // Clear existing snackbars
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }

          // Update pending recording state when recordings change
          final hasPendingForMeeting = state.pendingRecordings?.any(
            (r) => r.meetingId == widget.meetingId && r.status != RecordingUploadStatus.completed
          ) ?? false;
          
          if (_hasPendingRecording != hasPendingForMeeting) {
            setState(() {
              _hasPendingRecording = hasPendingForMeeting;
            });
          }

          // Handle all state updates through our centralized handler
          _handleStateUpdate(state);
        },
        builder: (context, state) {
          final meeting = state.selectedMeeting;
          
          if (meeting == null) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final isOrganizer = meeting.creator?.userId == context.read<AuthCubit>().state.userIdentifier;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                meeting.title ?? 'Loading...',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.textDark,
            ),
            backgroundColor: Colors.grey[50],
            body: Column(
              children: [
                // Meeting Info Card
                Container(
                  margin: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Goal Section
                      if (meeting.goal != null && meeting.goal!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.flag_rounded,
                                    size: 18.r,
                                    color: AppTheme.textGrey,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Goal',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textGrey,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                meeting.goal!,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: AppTheme.textDark,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Divider
                      if (meeting.goal != null && meeting.goal!.isNotEmpty)
                        Divider(height: 1, color: Colors.grey[200]),

                      // Participants Section
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_rounded,
                                      size: 18.r,
                                      color: AppTheme.textGrey,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Participants',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textGrey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                if ((meeting.members?.length ?? 0) > 3)
                                  TextButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16.r),
                                          ),
                                        ),
                                        builder: (context) => DraggableScrollableSheet(
                                          initialChildSize: 0.6,
                                          minChildSize: 0.4,
                                          maxChildSize: 0.9,
                                          expand: false,
                                          builder: (context, scrollController) => Column(
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(16.w),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'All Participants',
                                                      style: TextStyle(
                                                        fontSize: 18.sp,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppTheme.textDark,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      icon: Icon(Icons.close, size: 24.r),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Divider(height: 1, color: Colors.grey[200]),
                                              Expanded(
                                                child: ListView.builder(
                                                  controller: scrollController,
                                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                                  itemCount: (meeting.members?.length ?? 0) + 1,
                                                  itemBuilder: (context, index) {
                                                    MeetingMemberDTO? member;
                                                    if (index == 0) {
                                                      member = meeting.creator;
                                                    } else {
                                                      member = meeting.members?[index - 1];
                                                    }
                                                    if (member == null) return const SizedBox.shrink();

                                                    return ListTile(
                                                      leading: CircleAvatar(
                                                        radius: 20.r,
                                                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                                        child: Text(
                                                          member.memberName?[0].toUpperCase() ?? '?',
                                                          style: TextStyle(
                                                            color: AppTheme.primaryBlue,
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: 16.sp,
                                                          ),
                                                        ),
                                                      ),
                                                      title: Text(
                                                        member.memberName ?? '',
                                                        style: TextStyle(
                                                          fontSize: 16.sp,
                                                          color: AppTheme.textDark,
                                                        ),
                                                      ),
                                                      trailing: member.memberId == meeting.creator?.memberId
                                                          ? Container(
                                                              padding: EdgeInsets.symmetric(
                                                                horizontal: 10.w,
                                                                vertical: 4.h,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                                                borderRadius: BorderRadius.circular(12.r),
                                                              ),
                                                              child: Text(
                                                                'Organizer',
                                                                style: TextStyle(
                                                                  fontSize: 12.sp,
                                                                  color: AppTheme.primaryBlue,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            )
                                                          : null,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'See all ${(meeting.members?.length ?? 0) + 1}',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: min(3, (meeting.members?.length ?? 0) + 1),
                              itemBuilder: (context, index) {
                                MeetingMemberDTO? member;
                                if (index == 0) {
                                  member = meeting.creator;
                                }
                                else {
                                  member = meeting.members?[index - 1];
                                }
                                if (member == null) return const SizedBox.shrink();
                                
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16.r,
                                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                        child: Text(
                                          member.memberName?[0].toUpperCase() ?? '?',
                                          style: TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          member.memberName ?? '',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                      if (member.memberId == meeting.creator?.memberId)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                size: 14.r,
                                                color: AppTheme.primaryBlue,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                'Organizer',
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: AppTheme.primaryBlue,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (isOrganizer) ...[
                  // Add PendingRecordingsList here
                  if (state.pendingRecordings?.isNotEmpty ?? false)
                    PendingRecordingWidget(meetingId: widget.meetingId),

                  // Show either pending recording message or recording controls
                  Expanded(
                    child: Center(
                      child: _isCheckingPendingRecordings 
                        ? const CircularProgressIndicator()  // Show loading during check
                        : _hasPendingRecording
                          ? SingleChildScrollView(
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: AppTheme.warningOrange,
                                      size: 24.r,
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      'Please handle the pending recording before starting a new one',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              margin: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isProcessing && state.status == MeetingStateStatus.processingRecording)
                                    _buildProcessingIndicator()
                                  else if (state.isAudioUploading)
                                    UploadProgressWidget(
                                      progress: state.audioUploadProgress ?? 0,
                                      onCancel: () => context.read<MeetingCubit>().cancelUpload(),
                                    )
                                  else if (_isRecording || _isPaused) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 6.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _isPaused 
                                              ? AppTheme.warningOrange.withOpacity(0.1)
                                              : AppTheme.errorRed.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20.r),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _isPaused 
                                                  ? Icons.pause_circle_filled
                                                  : Icons.fiber_manual_record,
                                                color: _isPaused 
                                                  ? AppTheme.warningOrange
                                                  : AppTheme.errorRed,
                                                size: 12.r,
                                              ),
                                              SizedBox(width: 6.w),
                                              Text(
                                                _isPaused ? 'Paused' : 'Recording',
                                                style: TextStyle(
                                                  color: _isPaused 
                                                    ? AppTheme.warningOrange
                                                    : AppTheme.errorRed,
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        SessionTimer(
                                          isRecording: _isRecording || _isPaused,
                                          isPaused: _isPaused,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24.h),
                                    Container(
                                      height: 120.h,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12.r),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: AudioWaveform(
                                        amplitude: _amplitude,
                                        isRecording: _isRecording || _isPaused,
                                        isPaused: _isPaused,
                                      ),
                                    ),
                                    SizedBox(height: 24.h),
                                    RecordingControls(
                                      isRecording: _isRecording || _isPaused,
                                      isPaused: _isPaused,
                                      isProcessing: _isProcessing,
                                      onStartRecording: _startRecording,
                                      onPauseRecording: _togglePause,
                                      onResumeRecording: _togglePause,
                                      onStopRecording: _stopRecording,
                                    ),
                                  ] else
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.mic,
                                          size: 48.r,
                                          color: AppTheme.primaryBlue,
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'Press the record button to start',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                        if (!_isProcessing && !state.isAudioUploading)
                                          Padding(
                                            padding: EdgeInsets.only(top: 24.h),
                                            child: RecordingControls(
                                              isRecording: false,
                                              isPaused: false,
                                              isProcessing: false,
                                              onStartRecording: _startRecording,
                                              onPauseRecording: _togglePause,
                                              onResumeRecording: _togglePause,
                                              onStopRecording: _stopRecording,
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ] else
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.textGrey,
                            size: 20.r,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Only the organizer can record the meeting',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _performCleanup();
    super.dispose();
  }
}