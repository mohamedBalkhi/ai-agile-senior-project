import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_theme.dart';

class ReportSections extends StatelessWidget {
  final String meetingId;

  const ReportSections({
    super.key,
    required this.meetingId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPlaceholderSection('Summary'),
        SizedBox(height: 16.h),
        _buildPlaceholderSection('Key Points'),
        SizedBox(height: 16.h),
        _buildPlaceholderSection('Transcript'),
        SizedBox(height: 16.h),
        _buildPlaceholderSection('Action Items'),
        SizedBox(height: 16.h),
        _buildPlaceholderSection('Analytics'),
      ],
    );
  }

  Widget _buildPlaceholderSection(String title) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'This feature is coming soon...',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 