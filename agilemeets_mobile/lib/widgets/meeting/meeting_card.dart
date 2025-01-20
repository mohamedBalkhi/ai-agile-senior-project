import 'package:agilemeets/screens/meeting/meeting_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:agilemeets/data/models/meeting_dto.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:agilemeets/utils/date_formatter.dart';
import 'package:agilemeets/utils/route_constants.dart';
import 'package:agilemeets/utils/timezone_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agilemeets/data/enums/meeting_status.dart';
import 'package:agilemeets/data/enums/meeting_type.dart';
import 'package:agilemeets/widgets/meeting/recurring_meeting_info_dialog.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_cubit.dart';
import 'package:agilemeets/utils/pending_recordings_storage.dart';

class MeetingCard extends StatefulWidget {
  final MeetingDTO meeting;
  final VoidCallback? onTap;

  const MeetingCard({
    super.key,
    required this.meeting,
    this.onTap,
  });

  @override
  State<MeetingCard> createState() => _MeetingCardState();
}

class _MeetingCardState extends State<MeetingCard> {
  bool _hasPendingRecording = false;

  @override
  void initState() {
    super.initState();
    _checkPendingRecording();
  }

  Future<void> _checkPendingRecording() async {
    final pending = await PendingRecordingsStorage.getPendingRecordingForMeeting(
      widget.meeting.id,
    );
    if (mounted && pending != null) {
      setState(() {
        _hasPendingRecording = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localStartTime = TimezoneUtils.convertToLocalTime(widget.meeting.startTime);
    final localEndTime = TimezoneUtils.convertToLocalTime(widget.meeting.endTime);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: widget.meeting.isRecurring 
              ? AppTheme.primaryBlue.withOpacity(0.3)
              : AppTheme.cardBorderGrey,
          width: widget.meeting.isRecurring ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            RouteConstants.meetingDetails,
            arguments: widget.meeting.id,
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          children: [
            if (widget.meeting.isRecurring)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showRecurringInfo(context),
                      child: Icon(
                        widget.meeting.isRecurringInstance ? Icons.event_repeat : Icons.repeat,
                        size: 14.w,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      widget.meeting.isRecurringInstance ? 'Series Instance' : 'Recurring Meeting',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (widget.meeting.originalMeetingId != null)
                      GestureDetector(
                        onTap: () => _viewOriginalMeeting(context),
                        child: Row(
                          children: [
                            Text(
                              'View Original',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 14.w,
                              color: AppTheme.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    if (!widget.meeting.isRecurringInstance)
                      GestureDetector(
                        onTap: () => _showRecurringInfo(context),
                        child: Icon(
                          Icons.info_outline,
                          size: 14.w,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasPendingRecording)
                    Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(
                          color: AppTheme.warningOrange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pending_outlined,
                            size: 16.r,
                            color: AppTheme.warningOrange,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Pending Recording',
                            style: TextStyle(
                              color: AppTheme.warningOrange,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      _buildTypeIndicator(),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.meeting.title ?? 'Untitled Meeting',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.meeting.creatorName != null) ...[
                              SizedBox(height: 4.h),
                              Text(
                                'by ${widget.meeting.creatorName}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16.w,
                              color: AppTheme.textGrey,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              DateFormatter.formatTimeRange(localStartTime, localEndTime),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.meeting.hasAudio)
                            Padding(
                              padding: EdgeInsets.only(right: 8.w),
                              child: Icon(
                                Icons.mic,
                                size: 16.w,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          Icon(
                            Icons.people,
                            size: 16.w,
                            color: AppTheme.textGrey,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${widget.meeting.memberCount}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_shouldShowQuickActions())
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: _buildQuickActions(context),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowQuickActions() {
    return widget.meeting.status == MeetingStatus.scheduled || 
           widget.meeting.status == MeetingStatus.inProgress;
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        if (widget.meeting.status == MeetingStatus.scheduled && !_hasPendingRecording)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<MeetingCubit>().startMeeting(widget.meeting.id);
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MeetingSessionScreen(
                        meetingId: widget.meeting.id,
                      ),
                    ),
                  );
                }
              },
              icon: Icon(Icons.play_arrow_rounded),
              label: Text('Start'),
            ),
          )
        else if (widget.meeting.status == MeetingStatus.inProgress && !_hasPendingRecording)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MeetingSessionScreen(
                      meetingId: widget.meeting.id,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.login_rounded),
              label: Text('Join'),
            ),
          ),
        if (_hasPendingRecording)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  RouteConstants.meetingDetails,
                  arguments: widget.meeting.id,
                );
              },
              icon: Icon(
                Icons.upload_rounded,
                color: AppTheme.warningOrange,
              ),
              label: Text(
                'Upload Recording',
                style: TextStyle(
                  color: AppTheme.warningOrange,
                ),
              ),
            ),
          ),
        SizedBox(width: 8.w),
        OutlinedButton.icon(
          onPressed: () {
            if (widget.meeting.isRecurring) {
              _showRecurringCancelDialog(context);
            } else {
              _showCancelDialog(context);
            }
          },
          icon: Icon(Icons.close),
          label: Text('Cancel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorRed,
            side: BorderSide(color: AppTheme.errorRed),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeIndicator() {
    Color color;
    IconData icon;
    
    switch (widget.meeting.type) {
      case MeetingType.inPerson:
        color = AppTheme.primaryBlue;
        icon = Icons.people;
        break;
      case MeetingType.online:
        color = AppTheme.successGreen;
        icon = Icons.video_call;
        break;
      case MeetingType.done:
        color = AppTheme.textGrey;
        icon = Icons.history;
        break;
    }

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20.w,
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    
    switch (widget.meeting.status) {
      case MeetingStatus.scheduled:
        color = AppTheme.infoBlue;
        text = 'Scheduled';
        break;
      case MeetingStatus.inProgress:
        color = AppTheme.successGreen;
        text = 'In Progress';
        break;
      case MeetingStatus.completed:
        color = AppTheme.textGrey;
        text = 'Completed';
        break;
      case MeetingStatus.cancelled:
        color = AppTheme.errorRed;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showRecurringInfo(BuildContext context) {
    if (widget.meeting.recurringPattern != null) {
      showDialog(
        context: context,
        builder: (context) => RecurringMeetingInfoDialog(
          pattern: widget.meeting.recurringPattern!,
        ),
      );
    }
  }

  void _showRecurringCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Meeting'),
        content: const Text(
          'Do you want to cancel this occurrence or the entire series?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelMeeting(context, applyToSeries: false);
            },
            child: const Text('This Occurrence'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelMeeting(context, applyToSeries: true);
            },
            child: const Text('Entire Series'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Meeting'),
        content: const Text('Are you sure you want to cancel this meeting?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelMeeting(context);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelMeeting(BuildContext context, {bool? applyToSeries}) async {
    try {
      if (widget.meeting.isRecurring && applyToSeries != null) {
        await context.read<MeetingCubit>().modifyRecurringMeeting(
          widget.meeting.id,
          applyToSeries: applyToSeries,
          status: MeetingStatus.cancelled,
        );
      } else {
        await context.read<MeetingCubit>().cancelMeeting(widget.meeting.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel meeting: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _viewOriginalMeeting(BuildContext context) {
    if (widget.meeting.originalMeetingId != null) {
      Navigator.pushNamed(
        context,
        RouteConstants.meetingDetails,
        arguments: widget.meeting.originalMeetingId,
      );
    }
  }
}