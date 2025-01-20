import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/enums/req_priority.dart';
import '../../data/enums/requirements_status.dart';
import '../../data/models/requirements/req_dto.dart';
import '../../utils/app_theme.dart';
import '../custom_text_field.dart';

class CreateRequirementDialog extends StatefulWidget {
  final String projectId;
  final bool isLoading;
  final ValueChanged<List<ReqDTO>> onSubmit;

  const CreateRequirementDialog({
    super.key,
    required this.projectId,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<CreateRequirementDialog> createState() => _CreateRequirementDialogState();
}

class _CreateRequirementDialogState extends State<CreateRequirementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ReqPriority _priority = ReqPriority.medium;
  RequirementStatus _status = RequirementStatus.newOne;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Requirement',
                style: AppTheme.headingMedium,
              ).animate().fadeIn(),
              
              SizedBox(height: 24.h),
              
              CustomTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Enter requirement title',
                prefixIcon: Icons.title_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                animate: true,
                animationIndex: 1,
              ),
              
              SizedBox(height: 16.h),
              
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter requirement description',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                animate: true,
                animationIndex: 2,
              ),
              
              SizedBox(height: 24.h),
              
              Text(
                'Priority',
                style: AppTheme.bodyText,
              ).animate().fadeIn(delay: 300.ms),
              
              SizedBox(height: 8.h),
              
              Wrap(
                spacing: 8.w,
                children: ReqPriority.values.map((priority) => InkWell(
                  onTap: () => setState(() => _priority = priority),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: _priority == priority 
                          ? priority.color.withOpacity(0.1)
                          : AppTheme.cardGrey,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: _priority == priority ? priority.color : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getPriorityIcon(priority), 
                             size: 16.sp,
                             color: _priority == priority ? priority.color : AppTheme.textGrey),
                        SizedBox(width: 4.w),
                        Text(priority.label,
                             style: TextStyle(
                               color: _priority == priority ? priority.color : AppTheme.textGrey,
                               fontSize: 14.sp,
                             )),
                      ],
                    ),
                  ),
                )).toList(),
              ).animate().fadeIn(delay: 400.ms),
              
              SizedBox(height: 24.h),
              
              Text(
                'Status',
                style: AppTheme.bodyText,
              ).animate().fadeIn(delay: 500.ms),
              
              SizedBox(height: 8.h),
              
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardGrey,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: RequirementStatus.values.map((status) {
                    return Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _status = status),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.h,
                            horizontal: 8.w,
                          ),
                          decoration: BoxDecoration(
                            color: _status == status
                                ? status.color.withOpacity(0.1)
                                : null,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            status.label,
                            style: TextStyle(
                              color: _status == status
                                  ? status.color
                                  : AppTheme.textGrey,
                              fontSize: 14.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 600.ms),
              
              SizedBox(height: 32.h),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  FilledButton(
                    onPressed: widget.isLoading ? null : _createRequirement,
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Create'),
                  ),
                ],
              ).animate().fadeIn(delay: 700.ms),
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

  void _createRequirement() {
    if (_formKey.currentState!.validate()) {
      final requirement = ReqDTO(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        priority: _priority,
        status: _status,
      );
      
      widget.onSubmit([requirement]);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 