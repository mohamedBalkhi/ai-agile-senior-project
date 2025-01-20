import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/requirements/project_requirements_dto.dart';
import '../../data/enums/req_priority.dart';
import '../../utils/app_theme.dart';

class RequirementGridItem extends StatelessWidget {
  final ProjectRequirementsDTO requirement;
  final bool isSelected;
  final bool showCheckbox;
  final ValueChanged<bool?>? onSelected;
  final VoidCallback? onTap;

  const RequirementGridItem({
    super.key,
    required this.requirement,
    this.isSelected = false,
    this.showCheckbox = false,
    this.onSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 36.h,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: requirement.priority.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        _getPriorityIcon(requirement.priority),
                        color: requirement.priority.color,
                        size: 20.w,
                      ),
                    ),
                    const Spacer(),
                    if (showCheckbox)
                      Checkbox(
                        value: isSelected,
                        onChanged: onSelected,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requirement.title,
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (requirement.description != null) ...[
                      SizedBox(height: 4.h),
                      Expanded(
                        child: Text(
                          requirement.description!,
                          style: AppTheme.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 8.h),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: requirement.status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  requirement.status.label,
                  style: TextStyle(
                    color: requirement.status.color,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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