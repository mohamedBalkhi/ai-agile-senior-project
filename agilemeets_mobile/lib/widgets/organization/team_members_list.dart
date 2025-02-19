import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/organization/get_org_member_dto.dart';
import '../../utils/app_theme.dart';

class TeamMembersList extends StatelessWidget {
  final List<GetOrgMemberDTO> members;

  const TeamMembersList({
    super.key,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: members.map((member) {
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          decoration: AppTheme.cardDecoration,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            leading: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: member.isActive
                    ? AppTheme.primaryBlue.withValues(alpha:0.1)
                    : AppTheme.cardGrey,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  member.memberName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: member.isActive
                        ? AppTheme.primaryBlue
                        : AppTheme.textGrey,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    member.memberName,
                    style: AppTheme.headingMedium.copyWith(
                      fontSize: 16.sp,
                      color: member.isActive
                          ? AppTheme.textDark
                          : AppTheme.textGrey,
                    ),
                  ),
                ),
                if (!member.isActive)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Pending',
                      style: TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Text(
                  member.memberEmail,
                  style: AppTheme.subtitle.copyWith(
                    color: AppTheme.textGrey,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _buildRoleBadge(member),
                    if (member.projects.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBlue.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${member.projects.length} Projects',
                          style: TextStyle(
                            color: AppTheme.secondaryBlue,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 100.ms * members.indexOf(member));
      }).toList(),
    );
  }

  Widget _buildRoleBadge(GetOrgMemberDTO member) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (member.isManager) {
      backgroundColor = AppTheme.warningOrange.withValues(alpha:0.1);
      textColor = AppTheme.warningOrange;
      text = 'Owner';
    } else if (member.isAdmin) {
      backgroundColor = AppTheme.primaryBlue.withValues(alpha:0.1);
      textColor = AppTheme.primaryBlue;
      text = 'Admin';
    } else {
      backgroundColor = AppTheme.cardGrey;
      textColor = AppTheme.textGrey;
      text = member.isActive ? 'Member' : 'Invited';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
} 