import 'package:agilemeets/data/models/organization/get_org_project_dto.dart';
import 'package:agilemeets/data/models/project/project_info_dto.dart';
import 'package:agilemeets/logic/cubits/organization/organization_cubit.dart';
import 'package:agilemeets/logic/cubits/organization/organization_state.dart';
import 'package:agilemeets/screens/shell_screen.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:agilemeets/widgets/organization/team_members_list.dart';
import 'package:agilemeets/widgets/organization/projects_list.dart';

class OrganizationDashboardScreen extends StatefulWidget {
  const OrganizationDashboardScreen({super.key});

  @override
  State<OrganizationDashboardScreen> createState() => _OrganizationDashboardScreenState();
}

class _OrganizationDashboardScreenState extends State<OrganizationDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizationCubit>()
        .loadOrganization();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationCubit, OrganizationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Organization'),
            bottom: state.status == OrganizationStatus.loading
                ? PreferredSize(
                    preferredSize: Size.fromHeight(2.h),
                    child: const LinearProgressIndicator(),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<OrganizationCubit>()
                    .loadOrganization();
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                context.read<OrganizationCubit>().loadOrganization(),
              ]);
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(context, state),
                  SizedBox(height: 24.h),
                  _buildTeamSection(context, state),
                  SizedBox(height: 24.h),
                  _buildProjectsSection(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStats(BuildContext context, OrganizationState state) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.group_outlined,
                  label: 'Total Members', //? should we count inactive members?
                  value: state.members.length.toString(),
                  color: AppTheme.primaryBlue,
                  delay: 100,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                  value: state.projects.length.toString(),
                  color: AppTheme.secondaryBlue,
                  delay: 200,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Admins',
                  value: state.members.where((m) => m.isAdmin && !m.isManager).length.toString(),
                  color: AppTheme.warningOrange,
                  delay: 300,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.pending_outlined,
                  label: 'Pending',
                  value: state.members.where((m) => !m.isActive).length.toString(),
                  color: AppTheme.errorRed,
                  delay: 400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20.w,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: AppTheme.headingLarge.copyWith(
                  fontSize: 20.sp,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            label,
            style: AppTheme.subtitle.copyWith(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildTeamSection(BuildContext context, OrganizationState state) {
    final activeMembers = state.members.where((m) => m.isActive).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Organization Members',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/organization/members'),
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (activeMembers.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Column(
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 48.w,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'No active members yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          TeamMembersList(
            members: activeMembers.take(3).toList(),
          ),
      ],
    );
  }

  Widget _buildProjectsSection(BuildContext context, OrganizationState state) {
    // Sort projects by createdAt in descending order to get most recent first
    final sortedProjects = List<GetOrgProjectDTO>.from(state.projects)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Projects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                ShellScreen.navigateToTab(2);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        if (state.projects.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Column(
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 48.w,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'No projects yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          ProjectsList(
            projects: sortedProjects.take(3).toList(),
          ),
      ],
    );
  }
}
