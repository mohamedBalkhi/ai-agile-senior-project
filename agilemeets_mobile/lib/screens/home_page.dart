import 'package:agilemeets/logic/cubits/auth/auth_cubit.dart';
import 'package:agilemeets/logic/cubits/home/home_cubit.dart';
import 'package:agilemeets/logic/cubits/home/home_state.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:agilemeets/utils/timezone_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../screens/shell_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..loadHomePageData(),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == HomeStatus.error) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.w,
                      color: AppTheme.errorRed,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error: ${state.error}',
                      style: AppTheme.bodyText.copyWith(color: AppTheme.errorRed),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: () => context.read<HomeCubit>().loadHomePageData(refresh: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = state.data;
          if (data == null) return const SizedBox();

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().loadHomePageData(refresh: true),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        SizedBox(height: 16.h),
                        
                        // Modern Header with Refresh Button
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello,',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppTheme.textGrey,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                      height: 1.4,
                                    ),
                                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                                  SizedBox(height: 4.h),
                                  Text(
                                    context.read<AuthCubit>().state.decodedToken?.fullName ?? '',
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                      letterSpacing: 0.3,
                                      height: 1.4,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => context.read<HomeCubit>().loadHomePageData(refresh: true),
                              icon: Icon(
                                Icons.refresh_rounded,
                                color: AppTheme.primaryBlue,
                                size: 24.w,
                              ),
                            ).animate().fadeIn().scale(delay: 200.ms),
                          ],
                        ),
                        
                        SizedBox(height: 24.h),
                        
                        // Quick Stats
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickStat(
                                icon: Icons.folder_outlined,
                                label: 'Projects',
                                value: data.totalProjectCount.toString(),
                              ),
                              _buildQuickStat(
                                icon: Icons.calendar_today_rounded,
                                label: 'Meetings',
                                value: data.totalUpcomingMeetingsCount.toString(),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        
                        SizedBox(height: 24.h),
                        
                        // Projects Section
                        _buildSectionHeader(
                          'Active Projects',
                          'View All',
                          onActionTap: () => ShellScreen.navigateToTab(1),
                        ),
                        SizedBox(height: 16.h),
                      ]),
                    ),
                  ),
                  if (data.activeProjects.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: _buildEmptyState(
                          icon: Icons.folder_outlined,
                          title: 'No Active Projects',
                          subtitle: 'Projects you\'re involved in will appear here',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: SizedBox(
                          height: 160.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: data.activeProjects.length,
                            itemBuilder: (context, index) {
                              final project = data.activeProjects[index];
                              return InkWell(
                                onTap: () {
                                  // Navigate to project details
                                  Navigator.pushNamed(
                                    context,
                                    '/project-details',
                                    arguments: project.id,
                                  );
                                },
                                child: Container(
                                  width: 280.w,
                                  margin: EdgeInsets.only(right: 16.w),
                                  padding: EdgeInsets.all(20.w),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _getProjectGradient(index),
                                    ),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header with icon and date
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8.w),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            child: Icon(
                                              _getProjectIcon(index),
                                              color: Colors.white,
                                              size: 20.w,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            DateFormat('MMM d, y').format(project.createdAt),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 12.sp,
                                              letterSpacing: 0.3,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12.h),
                                      
                                      // Project content - using Expanded to properly constrain
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Project name
                                            Text(
                                              project.name,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.3,
                                                height: 1.4,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (project.description != null) ...[
                                              SizedBox(height: 4.h),
                                              Expanded(
                                                child: Text(
                                                  project.description!,
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.8),
                                                    fontSize: 14.sp,
                                                    letterSpacing: 0.3,
                                                    height: 1.4,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      
                                      // Project manager at bottom
                                      SizedBox(height: 12.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            color: Colors.white.withOpacity(0.8),
                                            size: 16.w,
                                          ),
                                          SizedBox(width: 4.w),
                                          Expanded(
                                            child: Text(
                                              project.projectManager,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.8),
                                                fontSize: 12.sp,
                                                letterSpacing: 0.3,
                                                height: 1.4,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn().slideX(
                                    begin: 0.2,
                                    end: 0,
                                    delay: (100 * index).ms,
                                  );
                            },
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        SizedBox(height: 24.h),
                        
                        // Upcoming Meetings Section
                        _buildSectionHeader(
                          'Upcoming Meetings',
                          'View All',
                          onActionTap: () => ShellScreen.navigateToTab(2),
                        ),
                        SizedBox(height: 16.h),
                        if (data.upcomingMeetings.isEmpty)
                          _buildEmptyState(
                            icon: Icons.calendar_today_outlined,
                            title: 'No Upcoming Meetings',
                            subtitle: 'Your scheduled meetings will appear here',
                          )
                        else
                          Container(
                            decoration: AppTheme.cardDecoration,
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: data.upcomingMeetings.length,
                              itemBuilder: (context, index) {
                                final meeting = data.upcomingMeetings[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/meetings/details/',
                                      arguments: meeting.id,
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      border: index != data.upcomingMeetings.length - 1
                                          ? const Border(
                                              bottom: BorderSide(
                                                color: AppTheme.cardBorderGrey,
                                                width: 1,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 48.w,
                                          height: 48.w,
                                          decoration: BoxDecoration(
                                            color: _getMeetingColor(meeting).withValues(alpha: .1),
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Icon(
                                            meeting.hasAudio
                                                ? Icons.video_camera_front_rounded
                                                : Icons.people_outline_rounded,
                                            color: _getMeetingColor(meeting),
                                            size: 24.w,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                meeting.title ?? 'Untitled Meeting',
                                                style: AppTheme.bodyText.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
                                                  height: 1.4,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                _formatMeetingDateTime(meeting.startTime),
                                                style: AppTheme.subtitle.copyWith(
                                                  letterSpacing: 0.3,
                                                  height: 1.4,
                                                ),
                                              ),
                                              if (meeting.projectName != null) ...[
                                                SizedBox(height: 4.h),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.folder_outlined,
                                                      size: 14.w,
                                                      color: AppTheme.textGrey,
                                                    ),
                                                    SizedBox(width: 4.w),
                                                    Expanded(
                                                      child: Text(
                                                        meeting.projectName!,
                                                        style: TextStyle(
                                                          color: AppTheme.textGrey,
                                                          fontSize: 12.sp,
                                                          letterSpacing: 0.3,
                                                          height: 1.4,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 6.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getMeetingColor(meeting).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20.r),
                                          ),
                                          child: Text(
                                            _formatDuration(meeting.startTime, meeting.endTime),
                                            style: TextStyle(
                                              color: _getMeetingColor(meeting),
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.3,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        SizedBox(height: 24.h),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.cardBorderGrey),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48.w,
            color: AppTheme.textGrey,
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: Colors.white, size: 24.w),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action, {
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.headingMedium),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            action,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  List<Color> _getProjectGradient(int index) {
    final gradients = [
      [AppTheme.primaryBlue, AppTheme.secondaryBlue],
      [AppTheme.warningOrange, AppTheme.warningOrange.withRed(240)],
      [AppTheme.successGreen, AppTheme.successGreen.withGreen(180)],
    ];
    return gradients[index % gradients.length];
  }

  IconData _getProjectIcon(int index) {
    final icons = [
      Icons.rocket_launch_rounded,
      Icons.psychology_rounded,
      Icons.architecture_rounded,
    ];
    return icons[index % icons.length];
  }

  Color _getMeetingColor(dynamic meeting) {
    if (meeting.hasAudio) {
      return AppTheme.infoBlue;
    }
    return AppTheme.successGreen;
  }

  String _formatMeetingDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final meetingDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final localTime = TimezoneUtils.convertToLocalTime(dateTime);
    String prefix;
    if (meetingDate == DateTime(now.year, now.month, now.day)) {
      prefix = 'Today';
    } else if (meetingDate == tomorrow) {
      prefix = 'Tomorrow';
    } else {
      prefix = DateFormat('MMM d').format(dateTime);
    }

    return '$prefix, ${DateFormat('h:mm a').format(localTime)}';
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else {
      return '${duration.inMinutes} min';
    }
  }
}
