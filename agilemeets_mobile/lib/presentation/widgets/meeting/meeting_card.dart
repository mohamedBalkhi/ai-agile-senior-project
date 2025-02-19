import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../data/models/meeting_dto.dart';
import '../../../data/enums/meeting_status.dart';
import '../../../data/enums/meeting_type.dart';
import '../../../screens/meeting/online_meeting_screen.dart';
import '../../../styles/app_theme.dart';

class MeetingCard extends StatelessWidget {
  final MeetingDTO meeting;
  final VoidCallback onTap;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      meeting.title ?? 'Untitled Meeting',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (meeting.type == MeetingType.online)
                    Icon(
                      Icons.videocam,
                      color: meeting.status == MeetingStatus.inProgress
                          ? AppTheme.primaryBlue
                          : Colors.grey,
                    ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                DateFormat('MMM d, y • h:mm a').format(meeting.startTime),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (meeting.type == MeetingType.online && meeting.status == MeetingStatus.inProgress) ...[
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam),
                    label: const Text('Join Meeting'),
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
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 