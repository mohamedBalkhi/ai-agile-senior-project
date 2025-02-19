import 'package:agilemeets/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final bool animate;
  final int? animationDelay;

  const CustomCard({
    super.key,
    required this.child,
    this.animate = true,
    this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.cardBorderGrey,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: child,
      ),
    );

    if (animate && animationDelay != null) {
      return card
          .animate()
          .scale(delay: animationDelay!.ms)
          .fade();
    }

    return card;
  }
}