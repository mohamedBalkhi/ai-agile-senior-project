import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/logic/cubits/organization/organization_state.dart';
import 'package:agilemeets/logic/cubits/project/project_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/enums/privilege_level.dart';
import '../../logic/cubits/project/project_cubit.dart';
import '../../logic/cubits/organization/organization_cubit.dart';
import '../../utils/app_theme.dart';
import 'privilege_selector.dart';

class AssignMemberDialog extends StatefulWidget {
  final String projectId;
  
  const AssignMemberDialog({
    super.key,
    required this.projectId,
  });

  @override
  State<AssignMemberDialog> createState() => _AssignMemberDialogState();
}

class _AssignMemberDialogState extends State<AssignMemberDialog> {
  String? selectedMemberId;
  // Default privilege levels when adding a member
  PrivilegeLevel meetingsPrivilege = PrivilegeLevel.read;
  PrivilegeLevel tasksPrivilege = PrivilegeLevel.write;
  PrivilegeLevel requirementsPrivilege = PrivilegeLevel.read;
  PrivilegeLevel membersPrivilege = PrivilegeLevel.read;
  PrivilegeLevel settingsPrivilege = PrivilegeLevel.none;

  @override
  void initState() {
    super.initState();
    context.read<OrganizationCubit>().loadMembers();
    context.read<ProjectCubit>().loadProjectMembers(widget.projectId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthCubit>().state.userIdentifier;
    
    return BlocBuilder<ProjectCubit, ProjectState>(
      builder: (context, projectState) {
        // Get project details first
        final projectDetails = projectState.selectedProject;
        
        if (projectDetails == null) {
          // If we don't have project details, show loading or error
          return const Center(child: CircularProgressIndicator());
        }

        return BlocBuilder<OrganizationCubit, OrganizationState>(
          builder: (context, orgState) {
            // Get current project members IDs
            final currentMemberIds = projectState.projectMembers
                ?.map((m) => m.userId)
                .toSet() ?? {};

            final projectManagerId = projectDetails.projectManagerId;

            // Filter available members and ensure uniqueness
            final availableMembers = orgState.members
                .where((m) => 
                  m.isActive && // Only active members
                  !currentMemberIds.contains(m.memberId) && // Not already in project
                  m.memberId != projectManagerId // Not the project manager
                )
                .toList();

            // Reset selectedMemberId if it's no longer valid
            if (selectedMemberId != null && 
                !availableMembers.any((m) => m.memberId == selectedMemberId)) {
              selectedMemberId = null;
            }

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
                    Text(
                      'Add Member',
                      style: AppTheme.headingMedium,
                    ).animate().fadeIn(),
                    
                    SizedBox(height: 24.h),
                    
                    // Member Selection
                    if (availableMembers.isEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardGrey,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'No available members to add',
                          style: AppTheme.subtitle.copyWith(
                            color: AppTheme.textGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().slideY(begin: 0.3).fadeIn()
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardGrey,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedMemberId,
                          decoration: InputDecoration(
                            labelText: 'Select Member',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                          ),
                          items: availableMembers.map((member) {
                            return DropdownMenuItem<String>(
                              value: member.memberId,
                              child: Text(
                                '${member.memberName}${member.memberId == currentUserId ? ' (You)' : ''}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            final isAdmin = orgState.members
                                .where((m) => m.memberId == value && m.isAdmin)
                                .isNotEmpty;

                            setState(() {
                              selectedMemberId = value;
                              if (isAdmin) {
                                // Set all privileges to write for admin users
                                meetingsPrivilege = PrivilegeLevel.write;
                                membersPrivilege = PrivilegeLevel.write;
                                requirementsPrivilege = PrivilegeLevel.write;
                                tasksPrivilege = PrivilegeLevel.write;
                                settingsPrivilege = PrivilegeLevel.write;
                              } else {
                                // Reset to default privileges for normal users
                                meetingsPrivilege = PrivilegeLevel.read;
                                tasksPrivilege = PrivilegeLevel.write;
                                requirementsPrivilege = PrivilegeLevel.read;
                                membersPrivilege = PrivilegeLevel.read;
                                settingsPrivilege = PrivilegeLevel.none;
                              }
                            });
                          },
                        ),
                      ),

                    SizedBox(height: 32.h),
                    
                    // Privileges Section
                    Text(
                      'Privileges',
                      style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
                    ).animate().slideY(begin: 0.3, delay: 100.ms).fadeIn(),
                    
                    SizedBox(height: 24.h),
                    
                    _buildPrivilegeSelector(
                      'Meetings',
                      meetingsPrivilege,
                      (value) => setState(() => meetingsPrivilege = value),
                      delay: 200,
                      isWriteOnly: selectedMemberId == currentUserId,
                    ),
                    
                    _buildPrivilegeSelector(
                      'Members',
                      membersPrivilege,
                      (value) => setState(() => membersPrivilege = value),
                      delay: 300,
                      isWriteOnly: selectedMemberId == currentUserId,
                    ),
                    
                    _buildPrivilegeSelector(
                      'Requirements',
                      requirementsPrivilege,
                      (value) => setState(() => requirementsPrivilege = value),
                      delay: 400,
                      isWriteOnly: selectedMemberId == currentUserId,
                    ),
                    
                    _buildPrivilegeSelector(
                      'Tasks',
                      tasksPrivilege,
                      (value) => setState(() => tasksPrivilege = value),
                      delay: 500,
                      isWriteOnly: selectedMemberId == currentUserId,
                    ),
                    
                    _buildPrivilegeSelector(
                      'Settings',
                      settingsPrivilege,
                      (value) => setState(() => settingsPrivilege = value),
                      delay: 600,
                      isWriteOnly: selectedMemberId == currentUserId,
                    ),

                    SizedBox(height: 32.h),
                    
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: selectedMemberId == null ? null : _assignMember,
                          child: const Text('Assign'),
                        ),
                      ],
                    ).animate().slideY(begin: 0.3, delay: 700.ms).fadeIn(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrivilegeSelector(
    String label,
    PrivilegeLevel value,
    ValueChanged<PrivilegeLevel> onChanged,
    {required int delay,
    required bool isWriteOnly,
  }) {
    final isAdmin = selectedMemberId != null && 
        context.read<OrganizationCubit>().state.members
            .where((m) => m.memberId == selectedMemberId && m.isAdmin)
            .isNotEmpty;

    return PrivilegeSelector(
      label: label,
      value: value,
      onChanged: onChanged,
      delay: delay,
      isWriteOnly: isWriteOnly || isAdmin,  // Make uneditable for both self and admin
    );
  }

  Future<void> _assignMember() async {
    if (selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a member'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    try {
      final adminMembers = context.read<OrganizationCubit>().state.members.where((m) => m.isAdmin).toList();
      if (adminMembers.where((m) => m.memberId == selectedMemberId).isNotEmpty) {
        meetingsPrivilege = PrivilegeLevel.write;
        membersPrivilege = PrivilegeLevel.write;
        requirementsPrivilege = PrivilegeLevel.write;
        tasksPrivilege = PrivilegeLevel.write;
        settingsPrivilege = PrivilegeLevel.write;
      }
      await context.read<ProjectCubit>().assignMember(
        projectId: widget.projectId,
        memberId: selectedMemberId!,
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
          content: Text('Member assigned successfully'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign member: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}