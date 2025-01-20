import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/models/recurring_meeting_pattern_dto.dart';
import '../../utils/app_theme.dart';
import '../../data/enums/recurrence_type.dart';

class RecurringMeetingInfoDialog extends StatelessWidget {
  final RecurringMeetingPatternDTO pattern;

  const RecurringMeetingInfoDialog({
    super.key,
    required this.pattern,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  color: AppTheme.primaryBlue,
                  size: 24.w,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Recurring Pattern',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _buildPatternInfo(),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternInfo() {
    String patternText;
    switch (pattern.recurrenceType) {
      case RecurrenceType.daily:
        patternText = 'Repeats every ${pattern.interval} day(s)';
        break;
      case RecurrenceType.weekly:
        final days = pattern.getSelectedDays();
        patternText = 'Repeats every ${pattern.interval} week(s) on ${days.join(", ")}';
        break;
      case RecurrenceType.monthly:
        patternText = 'Repeats every ${pattern.interval} month(s)';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patternText,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textDark,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Until ${DateFormat('MMMM d, y').format(pattern.recurringEndDate)}',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }
} 