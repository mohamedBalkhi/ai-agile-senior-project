import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/enums/req_priority.dart';
import '../../data/enums/requirements_status.dart';
import '../../data/models/requirements/project_requirements_dto.dart';
import '../../data/models/requirements/update_requirements_dto.dart';
import '../../utils/app_theme.dart';
import '../custom_text_field.dart';

class EditRequirementDialog extends StatefulWidget {
  /// The requirement to edit
  final ProjectRequirementsDTO requirement;
  
  /// Whether the dialog is in loading state
  final bool isLoading;
  
  /// Callback when the requirement is updated
  final ValueChanged<UpdateRequirementsDTO> onSubmit;

  const EditRequirementDialog({
    super.key,
    required this.requirement,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<EditRequirementDialog> createState() => _EditRequirementDialogState();
}

class _EditRequirementDialogState extends State<EditRequirementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late ReqPriority _priority;
  late RequirementStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.requirement.title);
    _descriptionController = TextEditingController(text: widget.requirement.description);
    _priority = widget.requirement.priority;
    _status = widget.requirement.status;
  }

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
                'Edit Requirement',
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
                children: ReqPriority.values.map((priority) {
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(priority),
                          size: 16.sp,
                          color: _priority == priority
                              ? priority.color
                              : AppTheme.textGrey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          priority.label,
                          style: TextStyle(
                            color: _priority == priority
                                ? priority.color
                                : AppTheme.textGrey,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    selected: _priority == priority,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _priority = priority);
                      }
                    },
                  );
                }).toList(),
              ).animate().fadeIn(delay: 400.ms),
              
              SizedBox(height: 24.h),
              
              Text(
                'Status',
                style: AppTheme.bodyText,
              ).animate().fadeIn(delay: 500.ms),
              
              SizedBox(height: 8.h),
              
              Wrap(
                spacing: 8.w,
                children: RequirementStatus.values.map((status) {
                  return ChoiceChip(
                    label: Text(
                      status.label,
                      style: TextStyle(
                        color: _status == status
                            ? status.color
                            : AppTheme.textGrey,
                        fontSize: 14.sp,
                      ),
                    ),
                    selected: _status == status,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _status = status);
                      }
                    },
                  );
                }).toList(),
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
                    onPressed: widget.isLoading ? null : _updateRequirement,
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Update'),
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

  void _updateRequirement() {
    if (_formKey.currentState!.validate()) {
      final dto = UpdateRequirementsDTO(
        requirementId: widget.requirement.id,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        status: _status,
        priority: _priority,
      );
      
      widget.onSubmit(dto);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 