import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer' as developer;

import '../../data/models/meeting_details_dto.dart';
import '../../logic/cubits/meeting/meeting_cubit.dart';
import '../../data/enums/meeting_status.dart';
import '../../data/enums/meeting_type.dart';
import '../../screens/meeting/online_meeting_screen.dart';
import '../../utils/app_theme.dart';
import '../../logic/cubits/auth/auth_cubit.dart';
import '../../logic/cubits/project/project_cubit.dart';

class MeetingActionButtons extends StatelessWidget {
  final MeetingDetailsDTO meeting;

  const MeetingActionButtons({
    super.key,
    required this.meeting,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final canManage = context.read<ProjectCubit>().canManageMeetings();
    final isCreator = authState.decodedToken?.userId == meeting.creator?.userId;
    final isAdmin = authState.isAdmin;
    final canModify = isAdmin || isCreator || canManage;

    developer.log('Meeting status: ${meeting.status}', name: 'MeetingActionButtons');
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          if (meeting.status == MeetingStatus.scheduled && canModify)
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Meeting'),
              onPressed: () async {
                await context.read<MeetingCubit>().startMeeting(meeting.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8.w),
                          const Expanded(
                            child: Text('Meeting started successfully! You can now join the meeting.'),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.successGreen,
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'Join Now',
                        textColor: Colors.white,
                        onPressed: () {
                          if (meeting.type == MeetingType.online) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OnlineMeetingScreen(
                                  meetingId: meeting.id,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          if (meeting.status == MeetingStatus.inProgress && meeting.type == MeetingType.online)
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              label: const Text('Join Online Meeting'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OnlineMeetingScreen(
                      meetingId: meeting.id,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
              ),
            ),
          if (meeting.status != MeetingStatus.completed && 
              meeting.status != MeetingStatus.cancelled &&
              canModify)
            OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Cancel Meeting'),
              onPressed: () {
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
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<MeetingCubit>().cancelMeeting(meeting.id);
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: const BorderSide(color: AppTheme.errorRed),
              ),
            ),
        ],
      ),
    );
  }
}