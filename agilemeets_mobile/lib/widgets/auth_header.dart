import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool showLogo;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double spacing;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.showLogo = true,
    this.iconSize,
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
    this.spacing = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (showLogo) ...[
          Hero(
            tag: 'auth_icon',
            child: Image.asset(
              'assets/logo.png',
              width: 60.w,
              height: 60.w,
            ),
          ).animate()
            .scale(duration: 400.ms, curve: Curves.easeOut)
            .fade(),
          SizedBox(height: spacing.h),
        ],
        
        if (icon != null) ...[
          Icon(
            icon,
            size: iconSize ?? 80.w,
            color: iconColor ?? theme.primaryColor,
          ).animate()
            .scale(duration: 400.ms, curve: Curves.easeOut)
            .fade(),
          SizedBox(height: spacing.h),
        ],

        Text(
          title,
          style: titleStyle ?? TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate()
          .slideY(begin: 0.3)
          .fade(),

        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: subtitleStyle ?? TextStyle(
            fontSize: 16.sp,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha:0.7),
          ),
          textAlign: TextAlign.center,
        ).animate()
          .slideY(begin: 0.3, delay: 100.ms)
          .fade(),
      ],
    );
  }
}