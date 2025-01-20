import 'package:agilemeets/data/models/requirements/req_dto.dart';
import 'package:agilemeets/logic/cubits/requirements/requirements_cubit.dart';
import 'package:agilemeets/logic/cubits/requirements/requirements_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/requirements/project_requirements_dto.dart';
import '../../utils/app_theme.dart';
import 'requirement_card.dart';
import 'create_requirements_bottom_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agilemeets/logic/cubits/project/project_cubit.dart';


class RequirementsList extends StatelessWidget {
  /// The list of requirements to display
  final List<ProjectRequirementsDTO> requirements;
  
  /// The set of selected requirement IDs
  final Set<String> selectedIds;
  
  final bool selectionMode;
  final ValueChanged<String>? onRequirementSelected;
  final void Function(ProjectRequirementsDTO)? onRequirementTap;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final String projectId;
  final ValueChanged<List<ReqDTO>> onCreateRequirement;

  const RequirementsList({
    super.key,
    required this.requirements,
    this.selectedIds = const {},
    this.selectionMode = false,
    this.onRequirementSelected,
    this.onRequirementTap,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    required this.projectId,
    required this.onCreateRequirement,
  });

  @override
  Widget build(BuildContext context) {
    final privileges = context.read<ProjectCubit>().state.memberPrivileges;
    final canWrite = privileges?.canManageRequirements() ?? false;

    if (requirements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64.sp,
              color: AppTheme.textGrey,
            ),
            SizedBox(height: 16.h),
            Text(
              'No requirements found',
              style: AppTheme.headingMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              'Add your first requirement to get started',
              style: AppTheme.subtitle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            if (canWrite)
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Requirement'),
              ),
          ],
        ).animate().fadeIn().slideY(begin: 0.3),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter == 0 &&
            hasMore &&
            onLoadMore != null) {
          onLoadMore!();
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: requirements.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == requirements.length) {
            print('isLoading: $isLoading');
            print('hasMore: $hasMore');
            
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: const CircularProgressIndicator(),
              ),
            );
          }

          final requirement = requirements[index];
          return RequirementCard(
            requirement: requirement,
            isSelected: selectedIds.contains(requirement.id),
            showCheckbox: selectionMode,
            onSelected: selectionMode
                ? (selected) => onRequirementSelected?.call(requirement.id)
                : null,
            onTap: selectionMode
                ? () => onRequirementSelected?.call(requirement.id)
                : () => onRequirementTap?.call(requirement),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<RequirementsCubit, RequirementsState>(
        builder: (context, state) {
          return CreateRequirementsBottomSheet(
            projectId: projectId,
            isLoading: state.status == RequirementsStatus.creating,
            onSubmit: onCreateRequirement,
            onFileUpload: (filePath) async {
              await context.read<RequirementsCubit>().uploadRequirementsFile(
                projectId,
                filePath,
              );
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
} 