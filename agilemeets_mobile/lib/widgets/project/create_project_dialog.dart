import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../logic/cubits/project/project_cubit.dart';
import '../../logic/cubits/project/project_state.dart';
import '../../logic/cubits/organization/organization_cubit.dart';
import '../../logic/cubits/organization/organization_state.dart';
import '../../data/models/organization/get_org_member_dto.dart';
import '../custom_text_field.dart';
import '../../utils/app_theme.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  GetOrgMemberDTO? _selectedManager;

  @override
  void initState() {
    super.initState();
    // Load organization members when dialog opens
    context.read<OrganizationCubit>().loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create New Project',
                style: AppTheme.headingMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(),
              
              SizedBox(height: 24.h),
              
              CustomTextField(
                controller: _nameController,
                label: 'Project Name',
                hint: 'Enter project name',
                prefixIcon: Icons.folder_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project name';
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
                hint: 'Enter project description',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                animate: true,
                animationIndex: 2,
              ),
              
              SizedBox(height: 16.h),
              
              // Project Manager Dropdown
              BlocBuilder<OrganizationCubit, OrganizationState>(
                builder: (context, state) {
                  final members = state.members
                      .where((m) => m.isActive)
                      .toList();

                  return DropdownButtonFormField<GetOrgMemberDTO>(
                    value: _selectedManager,
                    decoration: InputDecoration(
                      labelText: 'Project Manager',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: AppTheme.cardGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: members.map((member) {
                      return DropdownMenuItem(
                        value: member,
                        child: Text(member.memberName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedManager = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a project manager';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 300.ms);
                },
              ),
              
              SizedBox(height: 24.h),
              
              BlocBuilder<ProjectCubit, ProjectState>(
                builder: (context, state) {
                  final isLoading = state.status == ProjectStatus.creating;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
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
                        onPressed: isLoading ? null : _createProject,
                        child: isLoading
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
                  ).animate().fadeIn(delay: 400.ms);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createProject() async {
    if (_formKey.currentState!.validate()) {
      try {
        final projectCubit = context.read<ProjectCubit>();
        await projectCubit.createProject(
          projectName: _nameController.text,
          projectDescription: _descriptionController.text,
          projectManagerId: _selectedManager!.memberId,
        );

        if (!mounted) return;
        
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        // Close dialog
        Navigator.of(context).pop();
        
        // Optionally refresh projects list if needed
        await projectCubit.loadProjects();
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create project: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 