import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CalendarInfoCard extends StatelessWidget {
  const CalendarInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 32.w,
              color: Theme.of(context).colorScheme.primary,
            )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 500))
            .scale(),
            SizedBox(height: 16.h),
            Text(
              'Sync Your Meetings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 200))
            .slideX(),
            SizedBox(height: 8.h),
            Text(
              'Keep track of all your meetings by adding them to your device calendar. Updates will sync automatically.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 400))
            .slideX(),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.sync,
                  size: 16.w,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Auto-syncs with your calendar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 600))
            .slideX(),
          ],
        ),
      ),
    );
  }
} 