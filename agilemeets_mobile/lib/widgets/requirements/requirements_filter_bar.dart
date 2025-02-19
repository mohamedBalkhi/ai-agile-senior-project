import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/enums/req_priority.dart';
import '../../data/enums/requirements_status.dart';
import '../../utils/app_theme.dart';
import '../../logic/cubits/requirements/requirements_state.dart';

class RequirementsFilterBar extends StatefulWidget {
  final FilterState filters;
  final ValueChanged<ReqPriority?> onPriorityChanged;
  final ValueChanged<RequirementStatus?> onStatusChanged;
  final VoidCallback onClearFilters;
  final bool isFiltering;

  const RequirementsFilterBar({
    super.key,
    required this.filters,
    required this.onPriorityChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
    this.isFiltering = false,
  });

  @override
  State<RequirementsFilterBar> createState() => _RequirementsFilterBarState();
}

class _RequirementsFilterBarState extends State<RequirementsFilterBar> 
    with AutomaticKeepAliveClientMixin {
  bool _isExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isFiltering)
            const LinearProgressIndicator(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
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
                // Header - Always visible
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16.sp,
                          color: widget.filters.hasActiveFilters 
                              ? AppTheme.primaryBlue 
                              : AppTheme.textGrey,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Filters',
                          style: TextStyle(
                            color: widget.filters.hasActiveFilters 
                                ? AppTheme.primaryBlue 
                                : AppTheme.textGrey,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.filters.hasActiveFilters) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '${(widget.filters.priority != null ? 1 : 0) + 
                                (widget.filters.status != null ? 1 : 0) +
                                (widget.filters.searchQuery.isNotEmpty ? 1 : 0)}',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (widget.filters.hasActiveFilters)
                          TextButton(
                            onPressed: widget.onClearFilters,
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 20.sp,
                          color: AppTheme.textGrey,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Expandable Content
                ClipRRect(
                  child: AnimatedCrossFade(
                    firstChild: const SizedBox(height: 0),
                    secondChild: Padding(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        bottom: 12.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1, color: AppTheme.cardBorderGrey),
                          SizedBox(height: 12.h),
                          // Priority Filter
                          _buildFilterGroup(
                            label: 'Priority',
                            values: ReqPriority.values,
                            selectedValue: widget.filters.priority,
                            onChanged: widget.onPriorityChanged,
                            chipBuilder: (priority) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: widget.filters.priority == priority
                                    ? priority.color.withOpacity(0.1)
                                    : AppTheme.cardGrey,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: widget.filters.priority == priority
                                      ? priority.color
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPriorityIcon(priority),
                                    size: 16.sp,
                                    color: widget.filters.priority == priority
                                        ? priority.color
                                        : AppTheme.textGrey,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    priority.label,
                                    style: TextStyle(
                                      color: widget.filters.priority == priority
                                          ? priority.color
                                          : AppTheme.textGrey,
                                      fontSize: 14.sp,
                                      fontWeight: widget.filters.priority == priority
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Status Filter
                          _buildFilterGroup(
                            label: 'Status',
                            values: RequirementStatus.values,
                            selectedValue: widget.filters.status,
                            onChanged: widget.onStatusChanged,
                            chipBuilder: (status) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: widget.filters.status == status
                                    ? status.color.withOpacity(0.1)
                                    : AppTheme.cardGrey,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: widget.filters.status == status
                                      ? status.color
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                status.label,
                                style: TextStyle(
                                  color: widget.filters.status == status
                                      ? status.color
                                      : AppTheme.textGrey,
                                  fontSize: 14.sp,
                                  fontWeight: widget.filters.status == status
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: _isExpanded 
                        ? CrossFadeState.showSecond 
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterGroup<T>({
    required String label,
    required List<T> values,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    required Widget Function(T) chipBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textGrey,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: values.map((value) => Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => onChanged(value == selectedValue ? null : value),
                child: chipBuilder(value),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getPriorityIcon(ReqPriority priority) {
    switch (priority) {
      case ReqPriority.low:
        return Icons.arrow_downward;
      case ReqPriority.medium:
        return Icons.remove;
      case ReqPriority.high:
        return Icons.arrow_upward;
    }
  }
}