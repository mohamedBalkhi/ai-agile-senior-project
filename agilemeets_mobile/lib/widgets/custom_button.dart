import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool animate;
  final int? animationDelay;
  final TextStyle? textStyle;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.animate = true,
    this.animationDelay,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50.h),
        alignment: Alignment.center,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(strokeWidth: 2.w),
            )
          : Center(
              child: Text(
                text,
                style: textStyle ?? TextStyle(fontSize: 16.sp),
                textAlign: TextAlign.center,
              ),
            ),
    );

    if (animate && animationDelay != null) {
      return button
          .animate()
          .scale(delay: animationDelay!.ms)
          .fade();
    }

    return button;
  }
}