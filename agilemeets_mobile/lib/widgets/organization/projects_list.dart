import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/organization/get_org_project_dto.dart';

class ProjectsList extends StatelessWidget {
  final List<GetOrgProjectDTO> projects;

  const ProjectsList({
    super.key,
    required this.projects,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: projects.map((project) {
        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          child: ListTile(
            leading: Container(
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
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  timeago.format(project.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.description != null)
                  Text(
                    project.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16.w,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      project.projectManager,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/project-details',
                arguments: project.id,
              );
            },
          ),
        ).animate().fadeIn(delay: 100.ms * projects.indexOf(project));
      }).toList(),
    );
  }
} 