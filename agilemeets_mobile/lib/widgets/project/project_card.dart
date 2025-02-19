import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/project/project_info_dto.dart';
import '../../logic/cubits/project/project_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectCard extends StatelessWidget {
  final ProjectInfoDTO project;
  final VoidCallback? onTap;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap ?? () => _navigateToDetails(context),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.projectName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (project.projectDescription != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            project.projectDescription!,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16.sp,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    project.projectManagerName ?? 'No Manager',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: project.projectStatus
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      project.projectStatus ? 'Active' : 'Inactive',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: project.projectStatus
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    context.read<ProjectCubit>().loadProjectDetails(project.projectId);
    
    Navigator.pushNamed(
      context,
      '/project-details',
      arguments: project.projectId,
    );
  }
} 