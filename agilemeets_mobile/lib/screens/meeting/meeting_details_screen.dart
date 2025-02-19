import 'dart:developer';
import 'dart:io';

import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/utils/timezone_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_cubit.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:intl/intl.dart';
import '../../data/enums/meeting_type.dart';
import '../../data/enums/meeting_status.dart';
import '../../widgets/shared/error_view.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../meeting/meeting_session_screen.dart';
import '../../logic/cubits/meeting/meeting_state.dart';
import 'package:agilemeets/widgets/meeting/meeting_info_header.dart';
import 'package:agilemeets/widgets/meeting/member_list.dart';
import 'package:agilemeets/widgets/meeting/meeting_action_buttons.dart';
import 'package:agilemeets/widgets/meeting/audio_player.dart';
import 'package:agilemeets/widgets/meeting/meeting_ai_report.dart';
import '../../utils/pending_recordings_storage.dart';
import '../../widgets/meeting/upload_progress_widget.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/recording_metadata.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailsScreen({
    Key? key,
    required this.meetingId,
  }) : super(key: key);

  @override
  State<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  PendingRecording? _pendingRecording;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _checkPendingRecording();
      if (mounted) {
        final meetingCubit = context.read<MeetingCubit>();
        await Future.wait([
          meetingCubit.loadMeetingDetails(widget.meetingId),
          meetingCubit.loadMeetingAIReport(widget.meetingId),
        ]);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkPendingRecording() async {
    await context.read<MeetingCubit>().loadPendingRecordings();
    final pending = context
        .read<MeetingCubit>()
        .state
        .pendingRecordings
        ?.firstWhereOrNull((r) => r.meetingId == widget.meetingId);
    log('Pending recording: $pending', name: 'MeetingDetailsScreen');
    if (mounted && pending != null) {
      setState(() {
        _pendingRecording = PendingRecording(
          meetingId: pending.meetingId,
          filePath: pending.filePath,
          recordedAt: pending.recordedAt,
        );
      });
    }
  }

  Future<void> _uploadPendingRecording() async {
    if (_pendingRecording == null) return;

    // Capture the pending recording and clear it so that the UI can update.
    final pendingRecording = _pendingRecording;
    setState(() {
      _pendingRecording = null;
    });

    try {
      final cubit = context.read<MeetingCubit>();
      await cubit.loadPendingRecordings();
      final existingRecording = cubit.state.pendingRecordings?.firstWhereOrNull(
        (r) =>
            r.meetingId == widget.meetingId &&
            r.filePath == pendingRecording!.filePath,
      );

      log('Found existing recording: $existingRecording',
          name: 'MeetingDetailsScreen');

      if (existingRecording != null) {
        log('Using existing recording for upload',
            name: 'MeetingDetailsScreen');
        await cubit.uploadRecording(existingRecording);
      } else {
        log('Creating new recording metadata for upload',
            name: 'MeetingDetailsScreen');
        final file = File(pendingRecording!.filePath);
        if (!await file.exists()) {
          throw Exception('Recording file not found');
        }
        final metadata = RecordingMetadata(
          id: const Uuid().v4(),
          meetingId: widget.meetingId,
          filePath: pendingRecording!.filePath,
          recordedAt: pendingRecording!.recordedAt,
          fileSize: await file.length(),
          duration: Duration.zero,
          status: RecordingUploadStatus.pending,
          uploadProgress: 0,
          uploadAttempts: 0,
          lastUploadAttempt: null,
          wasTimeLimited: false,
        );
        await cubit.uploadRecording(metadata);
      }
      
      // After successful upload, reload meeting details
      if (mounted) {
        await _loadInitialData();
      }
    } catch (e) {
      log('Error uploading recording: $e',
          name: 'MeetingDetailsScreen', error: e);
      if (mounted) {
        // Restore pending recording state if upload fails
        setState(() {
          _pendingRecording = pendingRecording;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload recording: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MeetingCubit, MeetingState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.error != current.error ||
          previous.isAudioUploading != current.isAudioUploading ||
          previous.audioUploadProgress != current.audioUploadProgress,
      listener: (context, state) {
        log(
          'State changed: ${state.status}, isUploading: ${state.isAudioUploading}, progress: ${state.audioUploadProgress}',
          name: 'MeetingDetailsScreen',
        );

        if (state.status == MeetingStateStatus.uploadCompleted) {
          setState(() {
            _pendingRecording = null;
          });

          // Reload meeting details after successful upload.
          _loadInitialData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording uploaded successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        } else if (state.error != null) {
          if (!state.error!.toLowerCase().contains('cancelled')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        }
      },
      builder: (context, state) {
        if (_isLoading || state.status == MeetingStateStatus.loading) {
          return const Scaffold(
            body: Center(child: LoadingIndicator()),
          );
        }

        if (state.status == MeetingStateStatus.error) {
          return Scaffold(
            body: ErrorView(
              message: state.error ?? 'An error occurred',
              onRetry: _loadInitialData,
            ),
          );
        }

        final meeting = state.selectedMeeting;
        if (meeting == null) {
          return const Scaffold(
            body: Center(child: Text('Meeting not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              meeting.title ?? 'Untitled Meeting',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              if (meeting.type == MeetingType.inPerson &&
                  meeting.creator?.userId ==
                      context.read<AuthCubit>().state.userIdentifier) ...[
                if ((meeting.status == MeetingStatus.scheduled &&
                        DateTime.now()
                                .difference(
                                    TimezoneUtils.convertToLocalTime(meeting.startTime))
                                .abs()
                                .inMinutes <=
                            30) ||
                    (meeting.status == MeetingStatus.inProgress &&
                        meeting.audioUrl == null))
                  FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(meeting.status == MeetingStatus.scheduled
                        ? 'Start Meeting'
                        : 'Continue Recording'),
                    onPressed: () async {
                      if (meeting.status == MeetingStatus.scheduled) {
                        await context.read<MeetingCubit>().startMeeting(meeting.id);
                      }

                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MeetingSessionScreen(meetingId: meeting.id),
                          ),
                        );
                      }
                    },
                  ),
              ] else if (meeting.type == MeetingType.online &&
                  meeting.status == MeetingStatus.scheduled)
                FilledButton.icon(
                  icon: const Icon(Icons.video_call),
                  label: const Text('Join Online'),
                  onPressed: () {
                    if (meeting.meetingUrl != null) {
                      // Code to launch URL can go here.
                    }
                  },
                ),
              SizedBox(width: 16.w),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _checkPendingRecording();
                    context
                        .read<MeetingCubit>()
                        .loadMeetingDetails(widget.meetingId);
                    context
                        .read<MeetingCubit>()
                        .loadMeetingAIReport(widget.meetingId);
                  },
                  child: ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      MeetingInfoHeader(meeting: meeting),
                      SizedBox(height: 16.h),
                      // Upload progress / pending widget.
                      BlocBuilder<MeetingCubit, MeetingState>(
                        builder: (context, uploadState) {
                          log(
                              'Upload widget builder ##############: isUploading: ${uploadState.isAudioUploading}, progress: ${uploadState.audioUploadProgress}',
                              name: 'MeetingDetailsScreen');

                          if (uploadState.isAudioUploading) {
                            return UploadProgressWidget(
                              progress: uploadState.audioUploadProgress ?? 0,
                              onCancel: () {
                                context.read<MeetingCubit>().cancelUpload();
                              },
                            );
                          } else if (_pendingRecording != null && 
                                   !uploadState.isAudioUploading && 
                                   uploadState.status != MeetingStateStatus.uploadCompleted) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 16.h),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppTheme.warningOrange,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.pending_outlined,
                                        color: AppTheme.warningOrange,
                                        size: 20.r,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Pending Recording',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.warningOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12.h),
                                  Text(
                                    'You have a recording from ${DateFormat('MMM d, y').format(_pendingRecording!.recordedAt)} that hasn\'t been uploaded yet.',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppTheme.textGrey,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Discard Recording'),
                                              content: const Text(
                                                  'Are you sure you want to discard this recording? This action cannot be undone.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context, true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppTheme.errorRed,
                                                  ),
                                                  child: const Text('Discard'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true && mounted) {
                                            await context
                                                .read<MeetingCubit>()
                                                .deletePendingRecording(widget.meetingId);
                                            setState(() {
                                              _pendingRecording = null;
                                            });
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.errorRed,
                                          side: const BorderSide(
                                              color: AppTheme.errorRed),
                                        ),
                                        child: const Text('Discard'),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _uploadPendingRecording,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.warningOrange,
                                          ),
                                          child: const Text('Upload Now'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      MemberList(
                          members: meeting.members ?? [],
                          creator: meeting.creator),
                      if (_pendingRecording == null)
                        MeetingActionButtons(meeting: meeting),
                      SizedBox(height: 16.h),
                      if (meeting.status == MeetingStatus.completed) ...[
                        if (state.aiReport != null)
                          MeetingAIReport(
                            report: state.aiReport!,
                            onRefresh: () {
                              context
                                  .read<MeetingCubit>()
                                  .loadMeetingAIReport(widget.meetingId);
                            },
                          ),
                      ],
                      if (meeting.status == MeetingStatus.completed &&
                          meeting.audioUrl != null)
                        SizedBox(height: 80.h),
                    ],
                  ),
                ),
              ),
              if (meeting.status == MeetingStatus.completed &&
                  meeting.audioUrl != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.white,
                    child: SafeArea(
                      top: false,
                      child: MeetingAudioPlayer(
                        meetingId: widget.meetingId,
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
}