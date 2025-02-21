import 'package:agilemeets/utils/timezone_utils.dart';
import 'package:agilemeets/widgets/meeting/quick_meeting_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../logic/cubits/meeting/meeting_cubit.dart';
import '../../logic/cubits/meeting/meeting_state.dart';
import '../../widgets/meeting/grouped_meetings_list_view.dart';
import '../../widgets/shared/error_view.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../utils/app_theme.dart';
import '../../utils/route_constants.dart';
import '../../logic/cubits/project/project_cubit.dart';

class ProjectMeetingsTab extends StatefulWidget {
  final String projectId;

  const ProjectMeetingsTab({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectMeetingsTab> createState() => _ProjectMeetingsTabState();
}

class _ProjectMeetingsTabState extends State<ProjectMeetingsTab> {
  bool _showUpcomingOnly = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMeetings(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    const scrollThreshold = 200.0;

    // Load more when near bottom of the list
    if (maxScroll - currentScroll <= scrollThreshold) {
      _loadMeetings(loadMore: true);
    }
  }

  Future<void> _loadMeetings({
    bool refresh = false,
    bool loadMore = false,
  }) async {
    try {
      final timeZone = await TimezoneUtils.getLocalTimezone();
      if (!mounted) return;

      // When refreshing, clear all pagination state
      if (refresh) {
        context.read<MeetingCubit>().loadProjectMeetings(
          widget.projectId,
          refresh: true,
          loadMore: false,
          upcomingOnly: _showUpcomingOnly,
          timeZoneId: timeZone,
        );
      } else {
        await context.read<MeetingCubit>().loadProjectMeetings(
          widget.projectId,
          refresh: false,
          loadMore: loadMore,
          upcomingOnly: _showUpcomingOnly,
          timeZoneId: timeZone,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load timezone: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showQuickMeetingSheet() async {
    if (!context.read<ProjectCubit>().canManageMeetings()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You don\'t have permission to create meetings'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickMeetingSheet(projectId: widget.projectId),
    );

    if (result == true && mounted) {
      _loadMeetings(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<ProjectCubit>().canManageMeetings();
    
    return BlocBuilder<MeetingCubit, MeetingState>(
      buildWhen: (previous, current) {
        return previous.status != current.status ||
               previous.groups != current.groups ||
               previous.error != current.error ||
               previous.isRefreshing != current.isRefreshing ||
               previous.isLoadingMore != current.isLoadingMore ||
               previous.hasMore != current.hasMore ||
               previous.totalMeetingsCount != current.totalMeetingsCount;
      },
      builder: (context, state) {
        // Show initial loading
        if (state.status == MeetingStateStatus.initial && state.groups == null) {
          return const LoadingIndicator();
        }

        return Stack(
          children: [
            Column(
              children: [
                _buildHeader(state),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadMeetings(refresh: true),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (state.groups?.isEmpty ?? true)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _showUpcomingOnly 
                                        ? Icons.upcoming_outlined
                                        : Icons.history_outlined,
                                    size: 64.w,
                                    color: AppTheme.textGrey,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    _showUpcomingOnly
                                        ? 'No upcoming meetings'
                                        : 'No past meetings',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: AppTheme.textGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    _showUpcomingOnly
                                        ? 'Schedule a meeting to get started'
                                        : 'Past meetings will appear here',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppTheme.textGrey,
                                    ),
                                  ),
                                  if (canManage && _showUpcomingOnly)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildActionButton(
                                          icon: Icons.flash_on,
                                          label: 'Quick Meeting',
                                          onTap: _showQuickMeetingSheet,
                                        ),
                                        SizedBox(width: 16.w),
                                        _buildActionButton(
                                          icon: Icons.calendar_month_outlined,
                                          label: 'Schedule Meeting',
                                          onTap: () async {
                                            final result = await Navigator.pushNamed(
                                              context,
                                              RouteConstants.createMeeting,
                                              arguments: widget.projectId,
                                            );
                                            
                                            if (result == true && mounted) {
                                              _loadMeetings(refresh: true);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          )
                        else
                          GroupedMeetingsListView(
                            groups: state.groups ?? [],
                            hasMore: state.hasMore,
                            isLoading: state.isLoadingMore,
                            upcomingOnly: _showUpcomingOnly,
                            onLoadMore: () => _loadMeetings(loadMore: true),
                            onMeetingTap: (meetingId) {
                              Navigator.pushNamed(
                                context,
                                RouteConstants.meetingDetails,
                                arguments: meetingId,
                              );
                            },
                            onMeetingLongPress: (meetingId) {
                              // TODO: Show meeting options menu
                            },
                          ),
                        if (state.status == MeetingStateStatus.error)
                          SliverToBoxAdapter(
                            child: ErrorView(
                              message: state.error ?? 'Failed to load meetings',
                              onRetry: () => _loadMeetings(refresh: true),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (canManage)
              Positioned(
                right: 16.w,
                bottom: 16.h,
                child: FloatingActionButton(
                  heroTag: 'quick_meeting',
                  onPressed: _showQuickMeetingSheet,
                  backgroundColor: Colors.white,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flash_on,
                        color: AppTheme.primaryBlue,
                        size: 28.w,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(MeetingState state) {
    final canManage = context.read<ProjectCubit>().canManageMeetings();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.cardBorderGrey,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<bool>(
              selected: {_showUpcomingOnly},
              onSelectionChanged: state.status == MeetingStateStatus.loading
                  ? null
                  : (value) {
                      setState(() => _showUpcomingOnly = value.first);
                      _loadMeetings(refresh: true);
                    },
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upcoming_outlined, size: 16.w),
                      SizedBox(width: 4.w),
                      Text(
                        'Upcoming',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_outlined, size: 16.w),
                      SizedBox(width: 4.w),
                      Text(
                        'Past',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (canManage)
            IconButton(
              onPressed: state.status == MeetingStateStatus.loading
                  ? null
                  : () async {
                      final result = await Navigator.pushNamed(
                        context,
                        RouteConstants.createMeeting,
                        arguments: widget.projectId,
                      );
                      
                      if (result == true && mounted) {
                        _loadMeetings(refresh: true);
                      }
                    },
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(8.w),
              ),
              icon: Icon(Icons.add, size: 20.w),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppTheme.primaryBlue.withValues(alpha:0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryBlue,
              size: 18.w,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 