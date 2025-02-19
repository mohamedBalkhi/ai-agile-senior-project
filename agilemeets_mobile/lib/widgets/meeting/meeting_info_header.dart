import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/meeting_details_dto.dart';
import '../../utils/app_theme.dart';
import '../../utils/timezone_utils.dart';
import 'package:intl/intl.dart';

class MeetingInfoHeader extends StatelessWidget {
  final MeetingDetailsDTO meeting;

  const MeetingInfoHeader({
    super.key,
    required this.meeting,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  meeting.type.icon,
                  color: AppTheme.textGrey,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  meeting.type.label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (meeting.goal != null) ...[
              Text(
                'Goal',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                meeting.goal ?? '',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textGrey,
                ),
              ),
              SizedBox(height: 8.h),
            ],
            _buildDateTime(),
            if (meeting.location != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16.w,
                    color: AppTheme.textGrey,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    meeting.location ?? '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateTime() {
    final localStartTime = TimezoneUtils.convertToLocalTime(
          meeting.startTime
        );
        
        final localEndTime = TimezoneUtils.convertToLocalTime(
          meeting.endTime
        ); 
        return Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 20.w,
              color: AppTheme.textGrey,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(localStartTime),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${DateFormat('h:mm a').format(localStartTime)} - ${DateFormat('h:mm a').format(localEndTime)} (${DateTime.now().timeZoneName})',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
  }
} 