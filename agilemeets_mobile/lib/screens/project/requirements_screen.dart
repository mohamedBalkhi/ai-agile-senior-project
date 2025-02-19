import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/requirements/project_requirements_dto.dart';
import '../../data/enums/req_priority.dart';
import '../../data/enums/requirements_status.dart';
import '../../logic/cubits/requirements/requirements_cubit.dart';
import '../../logic/cubits/requirements/requirements_state.dart';
import '../../logic/cubits/project/project_cubit.dart';
import '../../utils/app_theme.dart';
import '../../widgets/requirements/edit_requirement_dialog.dart';
import '../../widgets/requirements/requirements_filter_bar.dart';
import '../../widgets/requirements/requirements_list.dart';
import '../../widgets/requirements/requirement_grid_item.dart';
import '../../widgets/requirements/create_requirements_bottom_sheet.dart';
import 'dart:developer' as developer;

class RequirementsScreen extends StatefulWidget {
  final String projectId;

  const RequirementsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  final _searchController = TextEditingController();
  bool _selectionMode = false;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    // Initial load
    _loadRequirements();
  }

  void _loadRequirements() {
    context.read<RequirementsCubit>().loadRequirements(
      widget.projectId,
      refresh: true,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _loadRequirements();
    }
  }

  @override
  Widget build(BuildContext context) {
    final privileges = context.read<ProjectCubit>().state.memberPrivileges;
    final canWrite = privileges?.canManageRequirements() ?? false;

    return BlocConsumer<RequirementsCubit, RequirementsState>(
      listenWhen: (previous, current) => 
        previous.status != current.status || 
        previous.error != current.error,
      listener: (context, state) {
        if (state.status == RequirementsStatus.error) {
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        } else if (state.status == RequirementsStatus.deleted) {
          // Exit selection mode
          developer.log('deleting in listener');
          setState(() => _selectionMode = false);
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Requirements deleted successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );

          // Refresh the list
          context.read<RequirementsCubit>().loadRequirements(widget.projectId, refresh: true);
        } else if (state.status == RequirementsStatus.created ||
                   state.status == RequirementsStatus.updated) {
          developer.log('created or updated');
          // Close any open dialogs when operation is successful
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.status == RequirementsStatus.created
                    ? 'Requirement created successfully'
                    : 'Requirement updated successfully',
              ),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      },
      builder: (context, state) {
        final hasRequirements = state.requirements.isNotEmpty ?? false;
        final hasActiveFilters = state.filters.hasActiveFilters;
        
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              _searchController.clear();
              context.read<RequirementsCubit>().clearFilters();
              await context.read<RequirementsCubit>().loadRequirements(
                widget.projectId,
                refresh: true,
              );
            },
            child: Column(
              children: [
                // Only show actions if user has write access
                if (canWrite)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          if (_selectionMode) ...[
                            Text(
                              '${state.selectedRequirementIds.length} selected',
                              style: AppTheme.headingMedium,
                            ),
                            const Spacer(),
                            ..._buildSelectionActions(context, state),
                          ] else ...[
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search requirements...',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.cardGrey,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 8.h,
                                  ),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _onSearch(),
                                textInputAction: TextInputAction.search,
                              ),
                            ),
                            if (hasRequirements || hasActiveFilters) ...[
                              IconButton(
                                icon: Icon(
                                  _isGridView ? Icons.view_list : Icons.grid_view,
                                  color: AppTheme.primaryBlue,
                                ),
                                onPressed: () => setState(() => _isGridView = !_isGridView),
                                tooltip: _isGridView ? 'List View' : 'Grid View',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.select_all,
                                  color: AppTheme.primaryBlue,
                                ),
                                onPressed: () => setState(() => _selectionMode = true),
                                tooltip: 'Select Items',
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                
                // Filter Bar (show when there are requirements or active filters)
                if (hasRequirements || hasActiveFilters)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: RequirementsFilterBar(
                      filters: state.filters,
                      onPriorityChanged: (priority) => _updateFilter(priority: priority),
                      onStatusChanged: (status) => _updateFilter(status: status),
                      onClearFilters: () {
                        _searchController.clear();
                        context.read<RequirementsCubit>().clearFilters();
                        _refreshList();
                      },
                      isFiltering: state.isFilteringInProgress,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),
                
                // Requirements List/Grid with Empty State
                Expanded(
                  child: state.status == RequirementsStatus.loading && !hasRequirements
                      ? const Center(child: CircularProgressIndicator())
                      : !hasRequirements && hasActiveFilters
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_outlined,
                                    size: 64.sp,
                                    color: AppTheme.textGrey,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'No matching requirements',
                                    style: AppTheme.headingMedium,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Try adjusting your filters',
                                    style: AppTheme.subtitle,
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 24.h),
                                  TextButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<RequirementsCubit>().clearFilters();
                                      _refreshList();
                                    },
                                    icon: const Icon(Icons.clear_all),
                                    label: const Text('Clear Filters'),
                                  ),
                                ],
                              ).animate().fadeIn().slideY(begin: 0.3),
                            )
                          : _isGridView && hasRequirements
                              ? _buildRequirementsGrid(state)
                              : RequirementsList(
                                  requirements: state.requirements ?? [],
                                  selectedIds: state.selectedRequirementIds,
                                  selectionMode: _selectionMode && canWrite,
                                  onRequirementSelected: canWrite ? (id) {
                                    context.read<RequirementsCubit>().toggleRequirementSelection(id);
                                  } : null,
                                  onRequirementTap: canWrite ? _showEditDialog : null,
                                  isLoading: state.status == RequirementsStatus.loading,
                                  hasMore: state.hasMorePages,
                                  onLoadMore: () => context.read<RequirementsCubit>().loadRequirements(
                                    widget.projectId,
                                  ),
                                  projectId: widget.projectId,
                                  onCreateRequirement: (requirements) {
                                    context.read<RequirementsCubit>().addRequirements(
                                      widget.projectId,
                                      requirements,
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
          // Only show FAB if user has write access
          floatingActionButton: canWrite && !_selectionMode && hasRequirements
            ? FloatingActionButton(
                onPressed: () => _showCreateDialog(context),
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: const Icon(Icons.add),
              ).animate().scale().fadeIn()
            : null,
        );
      },
    );
  }

  void _exitSelectionMode() {
    setState(() => _selectionMode = false);
    context.read<RequirementsCubit>().clearSelection();
  }

  List<Widget> _buildSelectionActions(BuildContext context, RequirementsState state) {
    final validSelectedIds = state.selectedRequirementIds
        .where((id) => state.requirements.any((r) => r.id == id) ?? false)
        .toList();

    return [
      IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: validSelectedIds.isEmpty
            ? null
            : () {
                showDialog(
                  context: context,
                  builder: (context) => BlocListener<RequirementsCubit, RequirementsState>(
                    listener: (context, state) {
                      if (state.status == RequirementsStatus.deleted) {
                        Navigator.pop(context);
                        _exitSelectionMode();
                        _refreshList();
                      }
                    },
                    child: AlertDialog(
                      title: const Text('Delete Requirements'),
                      content: Text(
                        'Are you sure you want to delete ${validSelectedIds.length} requirements?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            context.read<RequirementsCubit>().deleteRequirements(
                              widget.projectId,
                              validSelectedIds,
                            );
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                );
              },
      ),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
    ];
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocConsumer<RequirementsCubit, RequirementsState>(
        listenWhen: (previous, current) => 
          previous.status != current.status || 
          previous.error != current.error,
        listener: (context, state) {
          if (state.status == RequirementsStatus.created) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Requirements uploaded successfully'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
            _refreshList();
          } else if (state.status == RequirementsStatus.error) {
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'Failed to upload requirements'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        },
        builder: (context, state) {
          return CreateRequirementsBottomSheet(
            projectId: widget.projectId,
            isLoading: state.status == RequirementsStatus.creating,
            onSubmit: (requirements) {
              context.read<RequirementsCubit>().addRequirements(
                widget.projectId,
                requirements,
              );
            },
            onFileUpload: (filePath) async {
              // Show uploading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Uploading file...'),
                  duration: Duration(seconds: 1),
                ),
              );
              
              // Upload file
              await context.read<RequirementsCubit>().uploadRequirementsFile(
                widget.projectId,
                filePath,
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(ProjectRequirementsDTO requirement) {
    showDialog(
      context: context,
      builder: (context) => BlocListener<RequirementsCubit, RequirementsState>(
        listener: (context, state) {
          if (state.status == RequirementsStatus.updated) {
            Navigator.pop(context); // Close the dialog
            _refreshList(); // Refresh the list
          }
        },
        child: EditRequirementDialog(
          requirement: requirement,
          isLoading: context.watch<RequirementsCubit>().state.status == RequirementsStatus.updating,
          onSubmit: (dto) {
            context.read<RequirementsCubit>().updateRequirement(
              widget.projectId,
              dto,
            );
          },
        ),
      ),
    );
  }

  void _refreshList() {
    context.read<RequirementsCubit>().loadRequirements(
      widget.projectId,
      refresh: true,
    );
  }

  Widget _buildRequirementsGrid(RequirementsState state) {
    if (state.requirements.isEmpty ?? true) {
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
          ],
        ).animate().fadeIn().slideY(begin: 0.3),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.85,
      ),
      itemCount: state.requirements.length + (state.hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.requirements.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: const CircularProgressIndicator(),
            ),
          );
        }

        final requirement = state.requirements[index];
        return RequirementGridItem(
          requirement: requirement,
          isSelected: state.selectedRequirementIds.contains(requirement.id),
          showCheckbox: _selectionMode,
          onSelected: _selectionMode
              ? (selected) => context.read<RequirementsCubit>().toggleRequirementSelection(requirement.id)
              : null,
          onTap: _selectionMode
              ? () => context.read<RequirementsCubit>().toggleRequirementSelection(requirement.id)
              : () => _showEditDialog(requirement),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
      },
    );
  }

  void _updateFilter({ReqPriority? priority, RequirementStatus? status}) {
    context.read<RequirementsCubit>().updateFilters(
      projectId: widget.projectId,
      priority: priority,
      status: status,
      searchQuery: _searchController.text,
    );
  }

  void _onSearch() {
    context.read<RequirementsCubit>().updateFilters(
      projectId: widget.projectId,
      searchQuery: _searchController.text,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 