import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_theme.dart';

class LoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size ?? 24.w,
        height: size ?? 24.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.w,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }
} 