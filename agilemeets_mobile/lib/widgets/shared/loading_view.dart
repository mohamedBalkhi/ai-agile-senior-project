import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: CircularProgressIndicator(
              strokeWidth: 3.w,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading...',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
} 