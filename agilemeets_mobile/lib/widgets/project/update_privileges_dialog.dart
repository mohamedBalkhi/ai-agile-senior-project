import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/logic/cubits/project/project_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/project/project_member_dto.dart';
import '../../data/enums/privilege_level.dart';
import '../../logic/cubits/project/project_cubit.dart';
import '../../utils/app_theme.dart';
import 'privilege_selector.dart';

class UpdateMemberPrivilegesDialog extends StatefulWidget {
  final String projectId;
  final ProjectMemberDTO member;

  const UpdateMemberPrivilegesDialog({
    super.key,
    required this.projectId,
    required this.member,
  });

  @override
  State<UpdateMemberPrivilegesDialog> createState() => _UpdateMemberPrivilegesDialogState();
}

class _UpdateMemberPrivilegesDialogState extends State<UpdateMemberPrivilegesDialog> {
  late PrivilegeLevel meetingsPrivilege;
  late PrivilegeLevel membersPrivilege;
  late PrivilegeLevel requirementsPrivilege;
  late PrivilegeLevel tasksPrivilege;
  late PrivilegeLevel settingsPrivilege;
  bool _hasChanges = false;
  late bool isProjectManager;
  late bool isCurrentUser;

  @override
  void initState() {
    super.initState();
    meetingsPrivilege = PrivilegeLevel.fromString(widget.member.meetings);
    membersPrivilege = PrivilegeLevel.fromString(widget.member.members);
    requirementsPrivilege = PrivilegeLevel.fromString(widget.member.requirements);
    tasksPrivilege = PrivilegeLevel.fromString(widget.member.tasks);
    settingsPrivilege = PrivilegeLevel.fromString(widget.member.settings);
    
    final projectInfo = context.read<ProjectCubit>().state.selectedProject;
    isProjectManager = projectInfo?.projectManagerId == widget.member.userId;
    
    final currentUserId = context.read<AuthCubit>().state.userIdentifier;
    isCurrentUser = currentUserId == widget.member.userId;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha:0.1),
                  child: Text(
                    widget.member.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Privileges',
                        style: AppTheme.headingMedium,
                      ),
                      Text(
                        widget.member.name,
                        style: AppTheme.subtitle,
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(),
            
            SizedBox(height: 32.h),
            
            // Privileges Section
            PrivilegeSelector(
              label: 'Meetings',
              value: meetingsPrivilege,
              onChanged: (value) => setState(() {
                meetingsPrivilege = value;
                _hasChanges = true;
              }),
              delay: 200,
            ),
            
            PrivilegeSelector(
              label: 'Members',
              value: membersPrivilege,
              onChanged: (value) => setState(() {
                membersPrivilege = value  ;
                _hasChanges = true;
              }),
              delay: 300,
            ),
            
            PrivilegeSelector(
              label: 'Requirements',
              value: requirementsPrivilege,
              onChanged: (value) => setState(() {
                requirementsPrivilege = value;
                _hasChanges = true;
              }),
              delay: 400,
            ),
            
            PrivilegeSelector(
              label: 'Tasks',
              value: tasksPrivilege,
              onChanged: (value) => setState(() {
                tasksPrivilege = value;
                _hasChanges = true;
              }),
              delay: 500,
            ),
            
            PrivilegeSelector(
              label: 'Settings',
              value: settingsPrivilege,
              onChanged: (value) => setState(() {
                settingsPrivilege = value;
                _hasChanges = true;
              }),
              delay: 600,
            ),

            SizedBox(height: 32.h),
            
            // Actions
            BlocBuilder<ProjectCubit, ProjectState>(
              builder: (context, state) {
                final isLoading = state.status == ProjectStatus.updating;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading ? null : () {
                        if (_hasChanges) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Discard Changes?'),
                              content: const Text(
                                'Are you sure you want to discard your changes?'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close alert
                                    Navigator.pop(context); // Close dialog
                                  },
                                  child: const Text('Discard'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    FilledButton(
                      onPressed: isLoading || !_hasChanges ? null : _updatePrivileges,
                      child: isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Update'),
                    ),
                  ],
                ).animate().slideY(begin: 0.3, delay: 700.ms).fadeIn();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePrivileges() async {
    try {
      await context.read<ProjectCubit>().updateMemberPrivileges(
        projectId: widget.projectId,
        memberId: widget.member.userId,
        meetingsPrivilegeLevel: meetingsPrivilege.value,
        membersPrivilegeLevel: membersPrivilege.value,
        requirementsPrivilegeLevel: requirementsPrivilege.value,
        tasksPrivilegeLevel: tasksPrivilege.value,
        settingsPrivilegeLevel: settingsPrivilege.value,
      );

      if (!mounted) return;
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member privileges updated successfully'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update privileges: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
} 