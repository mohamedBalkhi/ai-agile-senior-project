import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/cubits/project/project_cubit.dart';
import '../../logic/cubits/project/project_state.dart';
import '../../widgets/project/project_card.dart';
import '../../widgets/project/create_project_dialog.dart';
import '../../utils/app_theme.dart';
import '../../logic/cubits/auth/auth_cubit.dart';
import '../../logic/cubits/auth/auth_state.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectCubit>().loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectCubit, ProjectState>(
      builder: (context, projectState) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final isAdmin = authState.decodedToken?.isAdmin ?? false;
            
            return Scaffold(
              appBar: AppBar(
                title: const Text('Projects'),
                bottom: projectState.status == ProjectStatus.loading
                    ? PreferredSize(
                        preferredSize: Size.fromHeight(2.h),
                        child: const LinearProgressIndicator(),
                      )
                    : null,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => context.read<ProjectCubit>().loadProjects(),
                    tooltip: 'Refresh',
                  ),
                  if (isAdmin) // Only show create button for admins
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showCreateProjectDialog(context),
                      tooltip: 'Create Project',
                    ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  await context.read<ProjectCubit>().loadProjects();
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStats(context, projectState),
                      SizedBox(height: 24.h),
                      _buildProjectsList(context, projectState, isAdmin),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStats(BuildContext context, ProjectState state) {
    final totalProjects = state.projects?.length ?? 0;
    final activeProjects = state.projects?.where((p) => p.projectStatus).length ?? 0;
    final inactiveProjects = totalProjects - activeProjects;

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
                  icon: Icons.folder_outlined,
                  label: 'Total Projects',
                  value: totalProjects.toString(),
                  color: AppTheme.primaryBlue,
                  delay: 100,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.rocket_launch_outlined,
                  label: 'Active',
                  value: activeProjects.toString(),
                  color: AppTheme.successGreen,
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
                  icon: Icons.pause_circle_outline,
                  label: 'Inactive',
                  value: inactiveProjects.toString(),
                  color: AppTheme.errorRed,
                  delay: 300,
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
        color: color.withValues(alpha:0.1),
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
              color: color.withValues(alpha:0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildProjectsList(BuildContext context, ProjectState state, bool isAdmin) {
    if (state.projects == null || state.projects!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64.sp,
              color: AppTheme.secondaryBlue,
            ),
            SizedBox(height: 16.h),
            Text(
              'No projects yet',
              style: AppTheme.headingMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              isAdmin 
                ? 'Create your first project to get started'
                : 'You haven\'t been assigned to any projects yet',
              style: AppTheme.subtitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            if (isAdmin)
              FilledButton.icon(
                onPressed: () => _showCreateProjectDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create Project'),
              ),
          ],
        ).animate().fadeIn().slideY(begin: 0.3),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.projects!.length,
      itemBuilder: (context, index) {
        final project = state.projects![index];
        return ProjectCard(
          project: project,
          onTap: () => Navigator.pushNamed(
            context,
            '/project-details',
            arguments: project.projectId,
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
      },
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    );
  }
} 