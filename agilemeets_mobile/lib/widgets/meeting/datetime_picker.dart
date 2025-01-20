import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/date_formatter.dart';
import '../../utils/app_theme.dart';
import '../../data/enums/meeting_type.dart';

class DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateTime? minDate;
  final ValueChanged<DateTime> onChanged;
  final bool allowPastDates;
  final DateTime? maxDate;
  final MeetingType? meetingType;
  final bool dateOnly;
  final DateTime? minTime;
  final DateTime? maxTime;

  const DateTimePicker({
    super.key,
    required this.label,
    required this.value,
    this.minDate,
    required this.onChanged,
    this.allowPastDates = false,
    this.maxDate,
    this.meetingType,
    this.dateOnly = false,
    this.minTime,
    this.maxTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppTheme.textGrey,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () => _showPicker(context),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderGrey),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20.w,
                  color: AppTheme.textGrey,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    value != null 
                        ? DateFormatter.formatDateTime(value!)
                        : 'Select',
                    style: TextStyle(
                      color: value != null 
                          ? AppTheme.textDark 
                          : AppTheme.textGrey,
                      fontSize: 10.sp,
                    ),
                    overflow: TextOverflow.clip,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: meetingType == MeetingType.done 
          ? DateTime(2000) 
          : minDate ?? now,
      lastDate: maxDate ?? (meetingType == MeetingType.done
          ? now 
          : DateTime(2100)),
    );

    if (date != null && context.mounted) {
      if (dateOnly) {
        onChanged(date);
        return;
      }

      TimeOfDay? minTimeOfDay;
      TimeOfDay? maxTimeOfDay;
      
      if (minTime != null && date.year == minTime!.year && 
          date.month == minTime!.month && date.day == minTime!.day) {
        minTimeOfDay = TimeOfDay.fromDateTime(minTime!);
      }
      
      if (maxTime != null && date.year == maxTime!.year && 
          date.month == maxTime!.month && date.day == maxTime!.day) {
        maxTimeOfDay = TimeOfDay.fromDateTime(maxTime!);
      }

      final time = await showTimePicker(
        context: context,
        initialTime: value != null 
            ? TimeOfDay.fromDateTime(value!)
            : TimeOfDay.now(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        if (minTime != null && selectedDateTime.isBefore(minTime!)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Time cannot be before ${DateFormatter.formatTime(minTime!)}'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
          return;
        }

        if (maxTime != null && selectedDateTime.isAfter(maxTime!)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Time cannot be after ${DateFormatter.formatTime(maxTime!)}'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
          return;
        }

        onChanged(selectedDateTime);
      }
    }
  }
} 