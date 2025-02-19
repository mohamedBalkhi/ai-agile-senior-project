import 'package:agilemeets/utils/timezone_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_cubit.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_state.dart';
import 'package:agilemeets/widgets/shared/error_view.dart';
import 'package:agilemeets/widgets/shared/loading_indicator.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:agilemeets/utils/route_constants.dart';
import 'package:agilemeets/widgets/meeting/grouped_meetings_list_view.dart';
import 'package:agilemeets/widgets/meeting/quick_meeting_sheet.dart';

class ProjectMeetingsScreen extends StatefulWidget {
  final String projectId;

  const ProjectMeetingsScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<ProjectMeetingsScreen> createState() => _ProjectMeetingsScreenState();
}

class _ProjectMeetingsScreenState extends State<ProjectMeetingsScreen> {
  bool _showUpcomingOnly = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings(refresh: true);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
          // Quick meeting button
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Quick Meeting',
            onPressed: _showQuickMeetingSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadMeetings(refresh: true),
          ),
        ],
      ),
      body: BlocBuilder<MeetingCubit, MeetingState>(
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
          if (state.status == MeetingStateStatus.initial ||
              (state.status == MeetingStateStatus.loading && state.groups == null)) {
            return const LoadingIndicator();
          }

          if (state.status == MeetingStateStatus.error && state.groups == null) {
            return ErrorView(
              message: state.error ?? 'Failed to load meetings',
              onRetry: () => _loadMeetings(refresh: true),
            );
          }

          return Stack(
            children: [
              Column(
                children: [
                  _buildHeader(state),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _loadMeetings(refresh: true),
                      child: Stack(
                        children: [
                          if (state.groups?.isEmpty ?? true)
                            Center(
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
                                  if (_showUpcomingOnly) ...[
                                    SizedBox(height: 24.h),
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
                                ],
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
              if (state.groups?.isNotEmpty ?? false)
                Positioned(
                  right: 16.w,
                  bottom: 16.h,
                  child: FloatingActionButton.extended(
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
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Schedule'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(MeetingState state) {
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
              onSelectionChanged: state.status == MeetingStateStatus.loading
                  ? null  // Disable during loading
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
                      Icon(Icons.upcoming_outlined, size: 18.w),
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
                      Icon(Icons.history_outlined, size: 18.w),
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
          SizedBox(width: 16.w),
          Expanded(
            flex: 1,
            child: FilledButton(
              onPressed: state.status == MeetingStateStatus.loading
                  ? null  // Disable during loading
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
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
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}