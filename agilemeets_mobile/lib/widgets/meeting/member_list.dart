import 'dart:developer';

import 'package:agilemeets/data/models/project/project_member_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/meeting_member_dto.dart';
import '../../utils/app_theme.dart';
import '../../logic/cubits/auth/auth_cubit.dart';

class MemberList extends StatelessWidget {
  final List<MeetingMemberDTO> members;
  final MeetingMemberDTO? creator;

  const MemberList({
    super.key,
    required this.members,
    this.creator,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthCubit>().state.userIdentifier;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            if (creator != null) ...[
              _buildMemberRow(creator!, true, creator?.memberId == currentUserId),
              SizedBox(height: 12.h),
            ],
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (context, index) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final member = members[index];
                final isCurrentUser = member.memberId == currentUserId;
                return _buildMemberRow(member, false, isCurrentUser);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow(MeetingMemberDTO member, bool isCreator, bool isCurrentUser) {
    log('member: ${member.memberName}', name: 'MemberList');
    log('isCreator: $isCreator', name: 'MemberList');
    log('isCurrentUser: $isCurrentUser', name: 'MemberList');
    return Row(
      children: [
        CircleAvatar(
          radius: 16.r,
          backgroundColor: isCreator ? AppTheme.primaryBlue : null,
          child: Text(
            member.memberName?[0] ?? '?',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isCreator ? Colors.white : null,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    member.memberName ?? 'Unknown Member',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (isCreator)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Organizer',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  if (isCurrentUser && !isCreator)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.textGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'You',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                member.email ?? '',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textGrey,
                ),
              ),
            ],
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
  }
}