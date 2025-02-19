import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/enums/recurrence_type.dart';
import '../../data/enums/days_of_week.dart';
import '../../data/models/create_meeting_form.dart';
import '../../utils/app_theme.dart';
import '../meeting/datetime_picker.dart';

class RecurringPatternForm extends StatelessWidget {
  final RecurringMeetingPattern pattern;
  final ValueChanged<RecurringMeetingPattern> onChanged;

  const RecurringPatternForm({
    super.key,
    required this.pattern,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recurrence Type
          Text(
            'Repeat Pattern',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardGrey,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppTheme.cardBorderGrey),
            ),
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                _buildRecurrenceTypeOption(RecurrenceType.daily, 'Daily'),
                _buildRecurrenceTypeOption(RecurrenceType.weekly, 'Weekly'),
                _buildRecurrenceTypeOption(RecurrenceType.monthly, 'Monthly'),
              ],
            ),
          ),

          // Weekly Days Selection (only show when weekly is selected)
          if (pattern.recurrenceType == RecurrenceType.weekly) ...[
            SizedBox(height: 24.h),
            Text(
              'Repeat on',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _buildDayChip('Mon', DaysOfWeek.monday),
                _buildDayChip('Tue', DaysOfWeek.tuesday),
                _buildDayChip('Wed', DaysOfWeek.wednesday),
                _buildDayChip('Thu', DaysOfWeek.thursday),
                _buildDayChip('Fri', DaysOfWeek.friday),
                _buildDayChip('Sat', DaysOfWeek.saturday),
                _buildDayChip('Sun', DaysOfWeek.sunday),
              ],
            ),
          ],

          SizedBox(height: 24.h),

          // Interval
          Text(
            'Repeat Every',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardGrey,
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: pattern.interval.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppTheme.textDark,
                    ),
                    onChanged: (value) {
                      final interval = int.tryParse(value) ?? 1;
                      onChanged(pattern..interval = interval);
                    },
                  ),
                ),
                Text(
                  _getIntervalSuffix(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // End Date
          Text(
            'End Date',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 8.h),
          DateTimePicker(
            label: 'End Date',
            value: pattern.recurringEndDate,
            minDate: DateTime.now(),
            onChanged: (value) {
              onChanged(pattern..recurringEndDate = value);
            },
            dateOnly: true,
          ),
        ],
      ),
    );
  }

  String _getIntervalSuffix() {
    switch (pattern.recurrenceType) {
      case RecurrenceType.daily:
        return 'day(s)';
      case RecurrenceType.weekly:
        return 'week(s)';
      case RecurrenceType.monthly:
        return 'month(s)';
    }
  }

  void _toggleDay(DaysOfWeek day) {
    final currentValue = pattern.daysOfWeek.value;
    final newValue = currentValue ^ day.value; // XOR to toggle
    onChanged(pattern..daysOfWeek = DaysOfWeek(newValue));
  }

  Widget _buildRecurrenceTypeOption(RecurrenceType type, String label) {
    final isSelected = pattern.recurrenceType == type;
    return RadioListTile<RecurrenceType>(
      value: type,
      groupValue: pattern.recurrenceType,
      onChanged: (value) {
        if (value != null) {
          onChanged(pattern..recurrenceType = value);
        }
      },
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
        ),
      ),
      activeColor: AppTheme.primaryBlue,
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
    );
  }

  Widget _buildDayChip(String label, DaysOfWeek day) {
    final isSelected = pattern.daysOfWeek.contains(day);
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => _toggleDay(day),
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryBlue.withValues(alpha:0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.borderGrey,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
    );
  }
} 