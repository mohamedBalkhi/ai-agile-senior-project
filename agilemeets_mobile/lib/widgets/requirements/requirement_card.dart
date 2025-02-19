import 'package:agilemeets/data/enums/req_priority.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/requirements/project_requirements_dto.dart';
import '../../utils/app_theme.dart';

class RequirementCard extends StatelessWidget {
  /// The requirement to display
  final ProjectRequirementsDTO requirement;
  
  /// Callback when the card is tapped
  final VoidCallback? onTap;
  
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;
  final bool showCheckbox;

  const RequirementCard({
    super.key,
    required this.requirement,
    this.onTap,
    this.isSelected = false,
    this.onSelected,
    this.showCheckbox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListTile(
        onTap: onTap,
        selected: isSelected,
        leading: showCheckbox
            ? Checkbox(
                value: isSelected,
                onChanged: onSelected,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.r),
                ),
              )
            : Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: requirement.priority.color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getPriorityIcon(),
                  color: requirement.priority.color,
                  size: 20.w,
                ),
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                requirement.title,
                style: AppTheme.bodyText,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: requirement.status.color.withValues(alpha:0.1),
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
        subtitle: requirement.description != null
            ? Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(
                  requirement.description!,
                  style: AppTheme.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: showCheckbox
            ? null
            : Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }

  IconData _getPriorityIcon() {
    switch (requirement.priority) {
      case ReqPriority.low:
        return Icons.arrow_downward;
      case ReqPriority.medium:
        return Icons.remove;
      case ReqPriority.high:
        return Icons.arrow_upward;
    }
  }
} 