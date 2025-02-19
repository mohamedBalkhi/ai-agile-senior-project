import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_theme.dart';

class UploadProgressWidget extends StatefulWidget {
  final double progress;
  final VoidCallback? onCancel;

  const UploadProgressWidget({
    super.key,
    required this.progress,
    this.onCancel,
  });

  @override
  State<UploadProgressWidget> createState() => _UploadProgressWidgetState();
}

class _UploadProgressWidgetState extends State<UploadProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _previousProgress = widget.progress;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: _previousProgress, end: widget.progress)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant UploadProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _previousProgress = oldWidget.progress;
      _controller.reset();
      _animation = Tween<double>(begin: _previousProgress, end: widget.progress)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Upload'),
        content: const Text('Are you sure you want to cancel the upload?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  @override
  Widget build(BuildContext context) {
    log('Progress: ${widget.progress}', name: 'UploadProgressWidget');
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentProgress = _animation.value;
        return Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Upload animation
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 40.w,
                        height: 40.h,
                        child: CircularProgressIndicator(
                          value: currentProgress,
                          strokeWidth: 3.w,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                        ),
                      ),
                      Icon(
                        Icons.cloud_upload_rounded,
                        size: 24.r,
                        color: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Uploading Recording',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Progress: ${(currentProgress * 100).toInt()}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: AppTheme.textGrey,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                height: 4.h,
                width: 200.w,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2.r),
                  child: LinearProgressIndicator(
                    value: currentProgress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              if (widget.onCancel != null)
                TextButton.icon(
                  onPressed: () => _handleCancel(context),
                  icon: Icon(
                    Icons.cancel_rounded,
                    size: 20.r,
                    color: AppTheme.errorRed,
                  ),
                  label: Text(
                    'Cancel Upload',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}