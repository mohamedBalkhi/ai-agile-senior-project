import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/timezone_dto.dart';
import '../../logic/cubits/timezone/timezone_cubit.dart';
import '../../logic/cubits/timezone/timezone_state.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../utils/app_theme.dart';

class TimeZoneSelector extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const TimeZoneSelector({
    super.key,
    this.value,
    required this.onChanged,
  });

  @override
  State<TimeZoneSelector> createState() => _TimeZoneSelectorState();
}

class _TimeZoneSelectorState extends State<TimeZoneSelector> {
  bool _showAllTimezones = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       
        BlocBuilder<TimeZoneCubit, TimeZoneState>(
          builder: (context, state) {
            if (state.status == TimeZoneStateStatus.initial) {
              context.read<TimeZoneCubit>().loadCommonTimezones();
              return const LoadingIndicator();
            }

            if (state.status == TimeZoneStateStatus.loading) {
              return const LoadingIndicator();
            }

            if (state.status == TimeZoneStateStatus.error) {
              return InputDecorator(
                decoration: InputDecoration(
                  errorText: state.error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: const Text('Failed to load timezones'),
              );
            }

            return Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search timezones',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppTheme.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppTheme.borderGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: AppTheme.primaryBlue),
                    ),
                    filled: true,
                    fillColor: AppTheme.cardGrey,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                SizedBox(height: 8.h),
                
                // Timezone List Container
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderGrey),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      // Header with toggle
                      Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 20.w,
                              color: AppTheme.textGrey,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _showAllTimezones ? 'All' : 'Common',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showAllTimezones = !_showAllTimezones;
                                });
                                if (_showAllTimezones) {
                                  context.read<TimeZoneCubit>().loadAllTimezones();
                                } else {
                                  context.read<TimeZoneCubit>().loadCommonTimezones();
                                }
                              },
                              icon: Icon(
                                _showAllTimezones ? Icons.filter_list : Icons.public,
                                size: 18.w,
                              ),
                              label: Text(
                                _showAllTimezones ? 'Show Common' : 'Show All',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      
                      // Timezone List
                      Container(
                        constraints: BoxConstraints(maxHeight: 200.h),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: state.timezones.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final timezone = state.timezones[index];
                            if (_searchQuery.isNotEmpty &&
                                !_matchesSearch(timezone)) {
                              return const SizedBox.shrink();
                            }
                            return _buildTimezoneItem(timezone);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  bool _matchesSearch(TimeZoneDTO timezone) {
    final searchTerms = _searchQuery.toLowerCase().split(' ');
    final displayName = timezone.displayName?.toLowerCase() ?? '';
    final utcOffset = timezone.utcOffset?.toLowerCase() ?? '';
    
    return searchTerms.every((term) => 
      displayName.contains(term) || utcOffset.contains(term)
    );
  }

  Widget _buildTimezoneItem(TimeZoneDTO timezone) {
    final isSelected = widget.value == timezone.id;
    final displayName = _formatDisplayName(timezone.displayName ?? '');
    final offset = _formatOffset(timezone.utcOffset ?? '');
    
    return Material(
      color: isSelected ? AppTheme.primaryBlue.withValues(alpha:0.1) : Colors.transparent,
      child: InkWell(
        onTap: () => widget.onChanged(timezone.id ?? ''),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'UTC $offset',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryBlue,
                  size: 20.w,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDisplayName(String displayName) {
    // Remove UTC offset from display name as we show it separately
    final regex = RegExp(r'\(UTC[+-]\d{2}:\d{2}\)');
    return displayName.replaceAll(regex, '').trim();
  }

  String _formatOffset(String offset) {
    // Convert "+03:00" to "+3" or "-03:00" to "-3"
    final regex = RegExp(r'([+-])(\d{2}):00');
    final match = regex.firstMatch(offset);
    if (match != null) {
      final sign = match.group(1);
      final hours = int.parse(match.group(2)!);
      return '$sign$hours';
    }
    return offset;
  }
} 