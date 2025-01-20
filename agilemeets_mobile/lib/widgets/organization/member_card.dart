import 'package:agilemeets/data/models/organization/get_org_member_dto.dart';
import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/logic/cubits/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MemberCard extends StatelessWidget {
  final GetOrgMemberDTO member;
  final Function(bool) onRoleChanged;

  const MemberCard({
    super.key,
    required this.member,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: CircleAvatar(
          backgroundColor: member.isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(
            member.memberName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: member.isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.memberName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: member.isActive
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (!member.isActive)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Pending',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member.memberEmail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                _buildRoleBadge(context),
                if (member.projects.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${member.projects.length} Projects',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: member.isManager || !member.isActive
            ? null
            : BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (!state.isAdmin || member.memberId == state.userIdentifier) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: member.isAdmin,
                        onChanged: member.isActive ? onRoleChanged : null,
                      ),
                      if (!member.isActive)
                        Text(
                          'Pending Invite',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 10.sp,
                              ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: member.isManager
            ? Theme.of(context).colorScheme.tertiaryContainer
            : member.isAdmin
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        member.isManager 
            ? 'Owner' 
            : member.isAdmin 
                ? 'Admin' 
                : member.isActive 
                    ? 'Member'
                    : 'Invited',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: member.isManager
                  ? Theme.of(context).colorScheme.tertiary
                  : member.isAdmin
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
} 