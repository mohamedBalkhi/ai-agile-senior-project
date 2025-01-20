import 'dart:developer';

import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/utils/pending_recordings_storage.dart';
import 'package:agilemeets/widgets/meeting/audio_waveform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../logic/cubits/meeting/meeting_cubit.dart';
import '../../logic/cubits/meeting/meeting_state.dart';
import '../../widgets/meeting/recording_controls.dart';
import '../../widgets/meeting/session_timer.dart';
import '../../widgets/meeting/member_attendance_list.dart';
import '../../utils/app_theme.dart';

class MeetingSessionScreen extends StatefulWidget {
  final String meetingId;

  const MeetingSessionScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<MeetingSessionScreen> createState() => _MeetingSessionScreenState();
}

class _MeetingSessionScreenState extends State<MeetingSessionScreen> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  String? _recordingPath;
  double _amplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _loadMeetingDetails();
    _initializeRecorder();
    _checkPendingRecording();
  }

  Future<void> _loadMeetingDetails() async {
    try {
      await context.read<MeetingCubit>().loadMeetingDetails(widget.meetingId);
    } catch (e) {
      log('Error loading meeting details: $e', name: 'MeetingSessionScreen');
      if (mounted) {
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
        // Navigate back if we can't load meeting details
        Navigator.pop(context);
      }
    }
  }

  Future<void> _initializeRecorder() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        log('No microphone permission', name: 'MeetingSessionScreen');
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

      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/meeting_${widget.meetingId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      log('Recording path: $_recordingPath', name: 'MeetingSessionScreen');
    } catch (e) {
      log('Error initializing recorder: $e', name: 'MeetingSessionScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize recording: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _checkPendingRecording() async {
    final pending = await PendingRecordingsStorage.getPendingRecordingForMeeting(
      widget.meetingId,
    );
    if (mounted && pending != null) {
      // If there's a pending recording, show dialog and pop
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Pending Recording'),
          content: Text('You have a pending recording for this meeting. Please upload or discard it before starting a new recording.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Pop session screen
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _startAmplitudeTimer() {
    if (!_isRecording || _isPaused) return;
    
    Future.delayed(const Duration(milliseconds: 50), () async {
      if (!mounted || !_isRecording || _isPaused) return;
      
      try {
        final amplitude = await _audioRecorder.getAmplitude();
        if (mounted && _isRecording && !_isPaused) {
          setState(() {
            final db = amplitude.current;
            _amplitude = (db + 80) / 60;  // More sensitive range
            _amplitude = _amplitude.clamp(0.0, 1.0);
            
            if (_amplitude < 0.05) {  
              _amplitude = 0.0;
            }
          });
        }
      } catch (e) {
        log('Error getting amplitude: $e', name: 'MeetingSessionScreen');
      }
      
      if (_isRecording && !_isPaused) {
        _startAmplitudeTimer();
      }
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 2,
          ),
          path: _recordingPath ?? '',
        );
        
        setState(() {
          _isRecording = true;
          _isPaused = false;
          _recordingDuration = Duration.zero;
          _amplitude = 0.0;
        });

        _startAmplitudeTimer();
      }
    } catch (e) {
      log('Error starting recording: $e', name: 'MeetingSessionScreen');
      if (mounted) {
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
      if (_isPaused) {
        await _audioRecorder.resume();
        setState(() {
          _isPaused = false;
        });
        _startAmplitudeTimer();
      } else {
        await _audioRecorder.pause();
        setState(() {
          _isPaused = true;
          _amplitude = 0.0;
        });
      }
    } catch (e) {
      log('Error toggling pause: $e', name: 'MeetingSessionScreen');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingPath = path;
        _amplitude = 0.0;  
      });

      if (path != null && mounted) {
        final shouldUpload = await _showUploadDialog();
        if (shouldUpload == true) {
          await context.read<MeetingCubit>().uploadMeetingAudio(
            widget.meetingId,
            path,
          );
          await context.read<MeetingCubit>().completeMeeting(widget.meetingId);

          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          await context.read<MeetingCubit>().completeMeeting(widget.meetingId);
          if (mounted) {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      log('Error stopping recording: $e', name: 'MeetingSessionScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handleUploadLater() async {
    if (_recordingPath != null) {
      await PendingRecordingsStorage.savePendingRecording(
        PendingRecording(
          meetingId: widget.meetingId,
          filePath: _recordingPath!,
          recordedAt: DateTime.now(),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording saved for later upload'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
    
    Navigator.of(context).pop();
  }

  Future<bool?> _showUploadDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Upload Recording'),
        content: const Text('Would you like to upload the recording now?'),
        actions: [
          TextButton(
            onPressed: _handleUploadLater,
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle immediate upload
              Navigator.of(context).pop(true);
            },
            child: const Text('Upload Now'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isRecording) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End Meeting'),
          content: const Text(
            'Are you sure you want to end the meeting? This will stop the recording.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('End Meeting'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _stopRecording();
        return true;
      }
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeetingCubit, MeetingState>(
      builder: (context, state) {
        final meeting = state.selectedMeeting;
        
        if (meeting == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

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
                      color: Colors.black.withOpacity(0.05),
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
                          SizedBox(height: 12.h),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: meeting.members?.length ?? 0,
                            itemBuilder: (context, index) {
                              final member = meeting.members?[index];
                              if (member == null) return const SizedBox.shrink();
                              
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16.r,
                                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
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
                                          color: AppTheme.primaryBlue.withOpacity(0.1),
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

              Expanded(
                child: meeting.creator?.userId == context.read<AuthCubit>().state.userIdentifier
                    ? Container(
                        margin: EdgeInsets.symmetric(horizontal: 16.w),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Recording Status and Timer
                              if (_isRecording)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 6.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorRed.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.fiber_manual_record,
                                            color: AppTheme.errorRed,
                                            size: 12.r,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Recording',
                                            style: TextStyle(
                                              color: AppTheme.errorRed,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    SessionTimer(
                                      isRecording: _isRecording,
                                      isPaused: _isPaused,
                                    ),
                                  ],
                                ),
                              SizedBox(height: 24.h),
                              // Waveform
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
                                  isRecording: _isRecording,
                                  isPaused: _isPaused,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              // Recording Controls
                              RecordingControls(
                                isRecording: _isRecording,
                                isPaused: _isPaused,
                                onStartRecording: _startRecording,
                                onPauseRecording: _togglePause,
                                onResumeRecording: _togglePause,
                                onStopRecording: _stopRecording,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Center(
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
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    if (_isRecording) {
      _stopRecording();
      _showUploadDialog();
    }
    super.dispose();
  }
}