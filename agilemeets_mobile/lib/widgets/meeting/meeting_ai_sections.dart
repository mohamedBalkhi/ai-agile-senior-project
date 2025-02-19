import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/app_theme.dart';

class MeetingAISections extends StatelessWidget {
  final String meetingId;

  const MeetingAISections({
    super.key,
    required this.meetingId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Analysis',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ).animate().fadeIn().slideX(begin: -0.2),
        SizedBox(height: 16.h),
        _buildAISection(
          title: 'Transcript',
          icon: Icons.description_outlined,
          color: AppTheme.primaryBlue,
          delay: 100,
          comingSoon: true,
        ),
        SizedBox(height: 12.h),
        _buildAISection(
          title: 'Key Points',
          icon: Icons.lightbulb_outline,
          color: AppTheme.warningOrange,
          delay: 200,
          comingSoon: true,
        ),
        SizedBox(height: 12.h),
        _buildAISection(
          title: 'Summary',
          icon: Icons.summarize_outlined,
          color: AppTheme.successGreen,
          delay: 300,
          comingSoon: true,
        ),
      ],
    );
  }

  Widget _buildAISection({
    required String title,
    required IconData icon,
    required Color color,
    required int delay,
    bool comingSoon = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.cardBorderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: comingSoon ? null : () {
            // Will implement AI feature navigation here
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      if (comingSoon) ...[
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.warningOrange.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.warningOrange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textGrey,
                  size: 24.w,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2);
  }
} 