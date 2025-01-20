import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/enums/privilege_level.dart';
import '../../utils/app_theme.dart';

class PrivilegeSelector extends StatelessWidget {
  final String label;
  final PrivilegeLevel value;
  final ValueChanged<PrivilegeLevel> onChanged;
  final int delay;
  final bool isWriteOnly;

  const PrivilegeSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.delay = 0,
    this.isWriteOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    // If isWriteOnly is true, we force the value to be write
    final effectiveValue = isWriteOnly ? PrivilegeLevel.write : value;
    
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodyText,
          ),
          SizedBox(height: 8.h),
          Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppTheme.cardBorderGrey),
            ),
            child: Row(
              children: [
                for (final level in PrivilegeLevel.values)
                  Expanded(
                    child: GestureDetector(
                      onTap: isWriteOnly ? null : () => onChanged(level),
                      child: Container(
                        decoration: BoxDecoration(
                          color: effectiveValue == level 
                              ? AppTheme.primaryBlue.withOpacity(0.1)
                              : null,
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (effectiveValue == level)
                              Positioned(
                                left: 8.w,
                                child: Icon(
                                  Icons.check,
                                  size: 16.w,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            Center(
                              child: Text(
                                level.label,
                                style: TextStyle(
                                  color: effectiveValue == level 
                                      ? AppTheme.primaryBlue
                                      : isWriteOnly && level != PrivilegeLevel.write
                                          ? AppTheme.textGrey.withOpacity(0.5)
                                          : AppTheme.textGrey,
                                  fontSize: 14.sp,
                                  fontWeight: effectiveValue == level
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: 0.3, delay: delay.ms).fadeIn();
  }
}