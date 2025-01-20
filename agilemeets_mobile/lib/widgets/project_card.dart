 import 'package:agilemeets/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProjectCard extends StatelessWidget {
  final String title;
  final String date;
  final double progress;
  final VoidCallback? onTap;

  const ProjectCard({
    super.key,
    required this.title,
    required this.date,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: title == 'Mobile App' ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.computer,
                  color: title == 'Mobile App' ? Colors.white : AppTheme.textDark,
                  size: 24.w,
                ),
                const Spacer(),
                Icon(
                  Icons.more_vert,
                  color: title == 'Mobile App' ? Colors.white : AppTheme.textGrey,
                  size: 20.w,
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                color: title == 'Mobile App' ? Colors.white : AppTheme.textDark,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              date,
              style: TextStyle(
                color: title == 'Mobile App' 
                    ? Colors.white.withOpacity(0.7) 
                    : AppTheme.textGrey,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 12.h),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: title == 'Mobile App' 
                  ? Colors.white.withOpacity(0.2) 
                  : AppTheme.cardGrey,
              valueColor: AlwaysStoppedAnimation(
                title == 'Mobile App' 
                    ? Colors.white 
                    : AppTheme.progressBlue,
              ),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ],
        ),
      ),
    );
  }
}