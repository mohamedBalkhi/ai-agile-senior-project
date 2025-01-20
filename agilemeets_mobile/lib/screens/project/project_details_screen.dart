import 'package:agilemeets/data/enums/privilege_level.dart';
import 'package:agilemeets/data/models/project/member_privileges_dto.dart';
import 'package:agilemeets/data/models/project/project_info_dto.dart';
import 'package:agilemeets/data/models/project/project_member_dto.dart';
import 'package:agilemeets/data/repositories/requirements_repository.dart';
import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/logic/cubits/requirements/requirements_cubit.dart';
import 'package:agilemeets/screens/meeting/project_meetings_screen.dart';
import 'package:agilemeets/screens/project/requirements_screen.dart';
import 'package:agilemeets/utils/route_constants.dart';
import 'package:agilemeets/widgets/project/update_privileges_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../logic/cubits/project/project_cubit.dart';
import '../../logic/cubits/project/project_state.dart';
import '../../utils/app_theme.dart';
import '../../widgets/project/assign_member_dialog.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:agilemeets/screens/meeting/project_meetings_tab.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  int _selectedIndex = 0;
  late final RequirementsCubit requirementsCubit;

  @override
  void initState() {
    super.initState();
    requirementsCubit = RequirementsCubit(RequirementsRepository());
    requirementsCubit.loadRequirements(widget.projectId, refresh: true);
    
    _loadProjectData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    try {
      await context.read<ProjectCubit>().loadProjectDetails(widget.projectId);
      
      if (mounted) {
        final privileges = context.read<ProjectCubit>().state.memberPrivileges;
        final tabCount = _buildTabs(privileges).length;
        
        setState(() {
          _tabController = TabController(
            length: tabCount,
            vsync: this,
            initialIndex: _selectedIndex,
          );
          _tabController?.addListener(() {
            setState(() {
              _selectedIndex = _tabController?.index ?? 0;
            });
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load project: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectCubit, ProjectState>(
      builder: (context, state) {
        if (state.status == ProjectStatus.loading || _tabController == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.status == ProjectStatus.error) {
          return Scaffold(
            body: Center(
              child: Text(state.error ?? 'Failed to load project'),
            ),
          );
        }

        final project = state.selectedProject;
        if (project == null) {
          return const Scaffold(
            body: Center(
              child: Text('Project not found'),
            ),
          );
        }

        final privileges = state.memberPrivileges;
        final tabs = _buildTabs(privileges);
        final tabViews = _buildTabViews(context, privileges);

        if (_tabController?.length != tabs.length) {
          _tabController?.dispose();
          _tabController = TabController(
            length: tabs.length,
            vsync: this,
            initialIndex: math.min(_selectedIndex, tabs.length - 1),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(project.projectName),
            bottom: TabBar(
              controller: _tabController,
              tabs: tabs,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.meeting_room),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    RouteConstants.meetings,
                    arguments: project.projectId,
                  );
                },
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: tabViews,
          ),
        );
      },
    );
  }

  List<Widget> _buildTabs(MemberPrivilegesDTO? privileges) {
    final tabs = <Widget>[];
    
    tabs.add(const Tab(
      icon: Icon(Icons.dashboard_outlined),
      text: 'Overview',
    ));

    tabs.add(const Tab(
      icon: Icon(Icons.calendar_today_outlined),
      text: 'Meetings',
    ));

    if (privileges?.canViewMembers() ?? false) {
      tabs.add(const Tab(
        icon: Icon(Icons.people_outline),
        text: 'Members',
      ));
    }

    if (privileges?.canViewRequirements() ?? false) {
      tabs.add(const Tab(
        icon: Icon(Icons.assignment_outlined),
        text: 'Requirements',
      ));
    }

    return tabs;
  }

  List<Widget> _buildTabViews(BuildContext context, MemberPrivilegesDTO? privileges) {
    final views = <Widget>[];
    
    views.add(_buildInfoSection(context.read<ProjectCubit>().state.selectedProject!));
    
    views.add(ProjectMeetingsTab(projectId: widget.projectId));

    if (privileges?.canViewMembers() ?? false) {
      views.add(_buildMembersSection(
        context.read<ProjectCubit>().state.projectMembers ?? []
      ));
    }

    if (privileges?.canViewRequirements() ?? false) {
      views.add(BlocProvider.value(
        value: requirementsCubit,
        child: RequirementsScreen(projectId: widget.projectId),
      ));
    }

    return views;
  }

  Widget _buildInfoSection(ProjectInfoDTO project) {
    var privileges = context.read<ProjectCubit>().state.memberPrivileges;
    if (privileges == null && context.read<AuthCubit>().state.isAdmin) {
      privileges = const MemberPrivilegesDTO(
        meetingsPrivilegeLevel: PrivilegeLevel.write,
        membersPrivilegeLevel: PrivilegeLevel.write,
        requirementsPrivilegeLevel: PrivilegeLevel.write,
        tasksPrivilegeLevel: PrivilegeLevel.write,
        settingsPrivilegeLevel: PrivilegeLevel.write,
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        color: AppTheme.primaryBlue,
                        size: 24.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.projectName,
                            style: AppTheme.headingMedium,
                          ),
                          if (project.projectDescription != null) ...[
                            SizedBox(height: 4.h),
                            Text(
                              project.projectDescription!,
                              style: AppTheme.subtitle,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16.sp,
                      color: AppTheme.textGrey,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Project Manager: ${project.projectManagerName ?? 'Not Assigned'}',
                      style: AppTheme.subtitle,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          if (privileges != null) ...[
            _buildPrivilegesSection(privileges),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivilegesSection(MemberPrivilegesDTO privileges) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: AppTheme.primaryBlue,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Your Privileges',
                style: AppTheme.headingMedium,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildPrivilegeChip('Meetings', privileges.meetingsPrivilegeLevel.label),
              _buildPrivilegeChip('Members', privileges.membersPrivilegeLevel.label),
              _buildPrivilegeChip('Requirements', privileges.requirementsPrivilegeLevel.label),
              _buildPrivilegeChip('Tasks', privileges.tasksPrivilegeLevel.label),
              _buildPrivilegeChip('Settings', privileges.settingsPrivilegeLevel.label),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegeChip(String title, String? level) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: _getPrivilegeLevelColor(level).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getPrivilegeLevelColor(level).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: _getPrivilegeLevelColor(level).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              level ?? 'None',
              style: TextStyle(
                color: _getPrivilegeLevelColor(level),
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPrivilegeLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'admin':
        return AppTheme.primaryBlue;
      case 'write':
        return AppTheme.successGreen;
      case 'read':
        return AppTheme.infoBlue;
      default:
        return AppTheme.textGrey;
    }
  }

  Widget _buildMembersSection(List<ProjectMemberDTO> members) {
    final cubit = context.read<ProjectCubit>();
    final canManage = cubit.canManageMembers();
    
    final projectManagerId = cubit.state.selectedProject?.projectManagerId;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project Members',
                style: AppTheme.headingMedium,
              ),
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  onPressed: _showAssignMemberDialog,
                  tooltip: 'Add Member',
                ),
            ],
          ),
          SizedBox(height: 16.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isProjectManager = member.userId == projectManagerId;
              return Card(
                margin: EdgeInsets.only(bottom: 8.h),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                    child: Text(
                      member.name?.substring(0, 1).toUpperCase() ?? '?',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(member.name ?? 'Unknown'),
                      if (isProjectManager) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'PM',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (!isProjectManager && member.isAdmin) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              color: AppTheme.warningOrange,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    member.email ?? '', 
                    style: AppTheme.subtitle.copyWith(fontSize: 11.sp)
                  ),
                  trailing: canManage && !isProjectManager && !member.isAdmin
                      ? IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showUpdatePrivilegesDialog(member),
                          tooltip: 'Edit Privileges',
                        )
                      : null,
                ),
              ).animate().fadeIn(delay: (100 * index).ms);
            },
          ),
        ],
      ),
    );
  }

  void _showAssignMemberDialog() {
    final cubit = context.read<ProjectCubit>();
    final privileges = cubit.state.memberPrivileges;
    
    if (privileges == null || !privileges.membersPrivilegeLevel.canWrite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You don\'t have permission to manage project members'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    developer.log('Before showing assign member dialog - selectedProject: ${cubit.state.selectedProject?.projectName}');

    showDialog(
      context: context,
      builder: (context) => AssignMemberDialog(
        projectId: widget.projectId,
      ),
    );
  }

  void _showUpdatePrivilegesDialog(ProjectMemberDTO member) {
    final cubit = context.read<ProjectCubit>();
    final privileges = cubit.state.memberPrivileges;
    
    if (privileges == null || !privileges.membersPrivilegeLevel.canWrite) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You don\'t have permission to update member privileges'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => UpdateMemberPrivilegesDialog(
        projectId: widget.projectId,
        member: member,
      ),
    );
  }
} 