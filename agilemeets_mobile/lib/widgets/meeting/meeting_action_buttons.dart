import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/meeting_details_dto.dart';
import '../../logic/cubits/meeting/meeting_cubit.dart';
import '../../data/enums/meeting_status.dart';

class MeetingActionButtons extends StatelessWidget {
  final MeetingDetailsDTO meeting;

  const MeetingActionButtons({
    super.key,
    required this.meeting,
  });

  @override
  Widget build(BuildContext context) {
    log('Meeting status: ${meeting.status}', name: 'MeetingActionButtons');
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          if (meeting.status == MeetingStatus.inProgress)
            ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text('Complete'),
              onPressed: () {
                context.read<MeetingCubit>().completeMeeting(meeting.id);
              },
            ),
          if (meeting.status == MeetingStatus.scheduled)
            TextButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
              onPressed: () {
                context.read<MeetingCubit>().cancelMeeting(meeting.id);
              },
            ),
        ],
      ),
    );
  }
}