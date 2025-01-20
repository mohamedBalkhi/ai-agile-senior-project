import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/utils/timezone_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_cubit.dart';
import 'package:agilemeets/widgets/meeting/meeting_info_header.dart';
import 'package:agilemeets/widgets/meeting/member_list.dart';
import 'package:agilemeets/widgets/meeting/meeting_action_buttons.dart';
import 'package:agilemeets/widgets/meeting/audio_player.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:intl/intl.dart';
import '../../data/enums/meeting_type.dart';
import '../../data/enums/meeting_status.dart';
import '../../widgets/shared/error_view.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../meeting/meeting_session_screen.dart';
import '../../logic/cubits/meeting/meeting_state.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:agilemeets/widgets/meeting/meeting_ai_report.dart';
import '../../utils/pending_recordings_storage.dart';

class MeetingDetailsScreen extends StatefulWidget {
  final String meetingId;

  const MeetingDetailsScreen({
    super.key,
    required this.meetingId,
  });

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
    final pending = await PendingRecordingsStorage.getPendingRecordingForMeeting(
      widget.meetingId,
    );
    if (mounted && pending != null) {
      setState(() {
        _pendingRecording = pending;
      });
    }
  }

  Future<void> _uploadPendingRecording() async {
    if (_pendingRecording == null) return;

    try {
      await context.read<MeetingCubit>().uploadMeetingAudio(
        widget.meetingId,
        _pendingRecording!.filePath,
      );

      if (mounted) {
        await PendingRecordingsStorage.removePendingRecording(widget.meetingId);
        setState(() {
          _pendingRecording = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording uploaded successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
    return BlocBuilder<MeetingCubit, MeetingState>(
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
              onPressed: () => Navigator.pop(context),
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
                  meeting.creator?.userId == context.read<AuthCubit>().state.userIdentifier) ...[
                if ((meeting.status == MeetingStatus.scheduled &&
                     DateTime.now().difference(TimezoneUtils.convertToLocalTime(meeting.startTime)).abs().inMinutes <= 30) || 
                    (meeting.status == MeetingStatus.inProgress && meeting.audioUrl == null))
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
                            builder: (context) => MeetingSessionScreen(
                              meetingId: meeting.id,
                            ),
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
                      // final uri = Uri.parse(meeting.meetingUrl!);
                      // launchUrl(
                      //   uri,
                      //   mode: LaunchMode.externalApplication,
                      // );
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
                    context.read<MeetingCubit>().loadMeetingDetails(widget.meetingId);
                    context.read<MeetingCubit>().loadMeetingAIReport(widget.meetingId);
                  },
                  child: ListView(
                    padding: EdgeInsets.all(16.w),
                    children: [
                      MeetingInfoHeader(meeting: meeting),
                      SizedBox(height: 16.h),
                      if (_pendingRecording != null)
                        Container(
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
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Discard Recording'),
                                          content: const Text('Are you sure you want to discard this recording? This action cannot be undone.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.errorRed,
                                              ),
                                              child: const Text('Discard'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true && mounted) {
                                        await PendingRecordingsStorage.removePendingRecording(
                                          widget.meetingId,
                                        );
                                        setState(() {
                                          _pendingRecording = null;
                                        });
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.errorRed,
                                      side: const BorderSide(color: AppTheme.errorRed),
                                    ),
                                    child: const Text('Discard'),
                                  ),
                                  SizedBox(width: 8.w),
                                  ElevatedButton(
                                    onPressed: _uploadPendingRecording,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.warningOrange,
                                    ),
                                    child: const Text('Upload Now'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      MemberList(members: meeting.members ?? [], creator: meeting.creator),
                      if (_pendingRecording == null)
                        MeetingActionButtons(meeting: meeting),
                      SizedBox(height: 16.h),
                      if (meeting.status == MeetingStatus.completed) ...[
                        if (state.aiReport != null)
                          MeetingAIReport(
                            report: state.aiReport!,
                            onRefresh: () {
                              context.read<MeetingCubit>().loadMeetingAIReport(widget.meetingId);
                            },
                          ),
                      ],
                      // Add extra padding at bottom when audio player is present
                      if (meeting.status == MeetingStatus.completed && meeting.audioUrl != null)
                        SizedBox(height: 80.h),
                    ],
                  ),
                ),
              ),
              if (meeting.status == MeetingStatus.completed && meeting.audioUrl != null)
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