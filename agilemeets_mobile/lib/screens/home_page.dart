import 'package:agilemeets/data/api/api_client.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final userName = state.decodedToken?.fullName ?? 'User';
        
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                
                // Modern Header
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                        SizedBox(height: 4.h),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Stack(
                          children: [
                            Icon(Icons.notifications_none_rounded, size: 24.w),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {},
                      ),
                    ).animate().fadeIn().scale(delay: 200.ms),
                  ],
                ),
                
                SizedBox(height: 32.h),
                
                // Quick Actions
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.secondaryBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAction(
                        icon: Icons.add_task_rounded,
                        label: 'New Task',
                        onTap: () {},
                      ),
                      _buildQuickAction(
                        icon: Icons.calendar_today_rounded,
                        label: 'Schedule',
                        onTap: () {},
                      ),
                      _buildQuickAction(
                        icon: Icons.people_outline_rounded,
                        label: 'Team',
                        onTap: () {},
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                
                SizedBox(height: 32.h),
                
                // Projects Section
                _buildSectionHeader('Active Projects', 'View All'),
                SizedBox(height: 16.h),
                SizedBox(
                  height: 160.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3, // Replace with actual project count
                    itemBuilder: (context, index) {
                      return Container(
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
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    _getProjectStatus(index),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _getProjectTitle(index),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '${_getProjectProgress(index)}% Completed',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Stack(
                              children: [
                                Container(
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                                Container(
                                  height: 4.h,
                                  width: _getProjectProgress(index) * 2.4.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideX(begin: 0.2, end: 0, delay: (100 * index).ms);
                    },
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // Tasks Section
                _buildSectionHeader('Today\'s Tasks', 'View All'),
                SizedBox(height: 16.h),
                _buildTasksList(),
                
                SizedBox(height: 32.h),
                
                // Upcoming Meetings Section
                _buildSectionHeader('Upcoming Meetings', 'View All'),
                SizedBox(height: 16.h),
                Container(
                  decoration: AppTheme.cardDecoration,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 2, // Replace with actual meeting count
                    itemBuilder: (context, index) {
                      return _buildMeetingItem(index);
                    },
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                
                SizedBox(height: 24.h), // Bottom padding
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
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
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTheme.headingMedium,
        ),
        TextButton(
          onPressed: () {},
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

  Widget _buildTasksList() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildTaskItem(
            'Design System Updates',
            0.7,
            AppTheme.progressBlue,
          ),
          SizedBox(height: 16.h),
          _buildTaskItem(
            'User Flow Implementation',
            0.4,
            AppTheme.warningOrange,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildTaskItem(String title, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTheme.bodyText),
            Text('${(progress * 100).toInt()}%', 
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4.r),
        ),
      ],
    );
  }

  Widget _buildMeetingItem(int index) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: index != 1 ? Border(
          bottom: BorderSide(
            color: AppTheme.cardBorderGrey,
            width: 1,
          ),
        ) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: _getMeetingColor(index).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _getMeetingIcon(index),
              color: _getMeetingColor(index),
              size: 24.w,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getMeetingTitle(index),
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  _getMeetingTime(index),
                  style: AppTheme.subtitle,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: _getMeetingColor(index).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              _getMeetingDuration(index),
              style: TextStyle(
                color: _getMeetingColor(index),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for meetings
  Color _getMeetingColor(int index) {
    return index == 0 ? AppTheme.infoBlue : AppTheme.successGreen;
  }

  IconData _getMeetingIcon(int index) {
    return index == 0 
      ? Icons.video_camera_front_rounded 
      : Icons.people_outline_rounded;
  }

  String _getMeetingTitle(int index) {
    return index == 0 
      ? 'Daily Standup' 
      : 'Sprint Planning';
  }

  String _getMeetingTime(int index) {
    return index == 0 
      ? 'Today, 10:00 AM' 
      : 'Tomorrow, 2:00 PM';
  }

  String _getMeetingDuration(int index) {
    return index == 0 ? '15 min' : '1 hour';
  }

  // Helper methods for projects
  List<Color> _getProjectGradient(int index) {
    switch (index) {
      case 0:
        return [AppTheme.primaryBlue, AppTheme.secondaryBlue];
      case 1:
        return [AppTheme.warningOrange, AppTheme.warningOrange.withRed(240)];
      default:
        return [AppTheme.successGreen, AppTheme.successGreen.withGreen(180)];
    }
  }

  IconData _getProjectIcon(int index) {
    switch (index) {
      case 0:
        return Icons.rocket_launch_rounded;
      case 1:
        return Icons.psychology_rounded;
      default:
        return Icons.architecture_rounded;
    }
  }

  String _getProjectStatus(int index) {
    switch (index) {
      case 0:
        return 'In Progress';
      case 1:
        return 'Planning';
      default:
        return 'Testing';
    }
  }

  String _getProjectTitle(int index) {
    switch (index) {
      case 0:
        return 'Mobile App Redesign';
      case 1:
        return 'AI Integration';
      default:
        return 'Backend Migration';
    }
  }

  int _getProjectProgress(int index) {
    switch (index) {
      case 0:
        return 75;
      case 1:
        return 30;
      default:
        return 60;
    }
  }
}
