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
  final ScrollController _scrollController = ScrollController();
  bool _showUpcomingOnly = true;

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

  Future<void> _loadMeetings({
    bool refresh = false,
    bool loadMore = false,
    bool loadPast = false,
  }) async {
    await context.read<MeetingCubit>().loadProjectMeetings(
      widget.projectId,
      refresh: refresh,
      loadMore: loadMore,
      loadPast: loadPast,
      upcomingOnly: _showUpcomingOnly,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<MeetingCubit>().state;
      if (!state.isRefreshing && 
          state.hasMoreFuture && 
          !state.isLoadingMore) {
        context.read<MeetingCubit>().loadProjectMeetings(
          widget.projectId,
          loadMore: true,
          loadPast: false,
          upcomingOnly: _showUpcomingOnly,
        );
      }
    } else if (_scrollController.position.pixels <= 200) {
      final state = context.read<MeetingCubit>().state;
      if (!state.isRefreshing && 
          state.hasMorePast && 
          !state.isLoadingMore) {
        context.read<MeetingCubit>().loadProjectMeetings(
          widget.projectId,
          loadMore: true,
          loadPast: true,
          upcomingOnly: _showUpcomingOnly,
        );
      }
    }
  }

 Future<void> _showQuickMeetingSheet() async {
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
    return BlocBuilder<MeetingCubit, MeetingState>(
      buildWhen: (previous, current) {
        return previous.status != current.status ||
               previous.groups != current.groups ||
               previous.error != current.error ||
               previous.isRefreshing != current.isRefreshing ||
               previous.isLoadingMore != current.isLoadingMore;
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
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadMeetings(refresh: true),
                    child: Stack(
                      children: [
                        GroupedMeetingsListView(
                          groups: state.groups ?? [],
                          scrollController: _scrollController,
                          hasMorePast: state.hasMorePast,
                          hasMoreFuture: state.hasMoreFuture,
                          isLoadingMore: state.isLoadingMore,
                          onLoadMorePast: () => _loadMeetings(
                            loadMore: true,
                            loadPast: true,
                          ),
                          onLoadMoreFuture: () => _loadMeetings(
                            loadMore: true,
                            loadPast: false,
                          ),
                          onRefresh: _showUpcomingOnly 
                              ? () => _loadMeetings(refresh: true)
                              : null,  // Disable refresh for "All" view
                        ),
                        if (state.status == MeetingStateStatus.error)
                          ErrorView(
                            message: state.error ?? 'Failed to load meetings',
                            onRetry: () => _loadMeetings(refresh: true),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16.w,
              bottom: 16.h,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick meeting FAB
                  FloatingActionButton(
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
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
            flex: 4,
            child: SegmentedButton<bool>(
              selected: {_showUpcomingOnly},
              onSelectionChanged: (value) {
                setState(() => _showUpcomingOnly = value.first);
                _loadMeetings(refresh: true);
              },
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  label: Text(
                    'Upcoming',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  icon: Icon(Icons.upcoming_outlined, size: 18.w),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text(
                    'All',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                  icon: Icon(Icons.history_outlined, size: 18.w),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 1,
            child: FilledButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  RouteConstants.createMeeting,
                  arguments: widget.projectId,
                );
                
                if (result == true && mounted) {
                  _loadMeetings(refresh: true);
                }
              },
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: const Center(
                child: Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }
} 