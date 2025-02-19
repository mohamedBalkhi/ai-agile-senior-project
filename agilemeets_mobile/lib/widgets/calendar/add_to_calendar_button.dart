import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io' show Platform;

class AddToCalendarButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AddToCalendarButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonText = Platform.isIOS
        ? 'Add to iOS Calendar'
        : 'Export Calendar';

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Platform.isIOS ? Icons.calendar_today : Icons.share,
        size: 24.w,
      ),
      label: Text(
        buttonText,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 16.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
} 