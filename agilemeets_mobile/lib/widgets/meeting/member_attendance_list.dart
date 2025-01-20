import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/meeting_member_dto.dart';
import '../../utils/app_theme.dart';

class MemberAttendanceList extends StatelessWidget {
  final List<MeetingMemberDTO> members;

  const MemberAttendanceList({
    super.key,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendees',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (context, index) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final member = members[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16.r,
                      child: Text(
                        member.memberName?[0] ?? '?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        member.memberName ?? 'Unknown Member',
                        style: TextStyle(
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    Icon(
                      member.hasConfirmed ? Icons.check_circle : Icons.pending,
                      color: member.hasConfirmed 
                          ? AppTheme.successGreen 
                          : AppTheme.warningOrange,
                      size: 20.w,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 