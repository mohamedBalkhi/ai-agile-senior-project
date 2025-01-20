import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_cubit.dart';
import 'package:agilemeets/logic/cubits/meeting/meeting_state.dart';
import 'package:agilemeets/widgets/meeting/meeting_card.dart';
import 'package:agilemeets/widgets/shared/error_view.dart';
import 'package:agilemeets/widgets/shared/loading_indicator.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:agilemeets/utils/route_constants.dart';
import 'package:agilemeets/widgets/meeting/grouped_meetings_list_view.dart';

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
    );
  }

  void _onScroll() {
    // Check if we're near the bottom
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<MeetingCubit>().state;
      if (!state.isRefreshing && 
          state.hasMoreFuture && 
          !state.isLoadingMore) {
        _loadMeetings(
          loadMore: true,
          loadPast: false,
        );
      }
    }
    // Check if we're near the top
    else if (_scrollController.position.pixels <= 200) {
      final state = context.read<MeetingCubit>().state;
      if (!state.isRefreshing && 
          state.hasMorePast && 
          !state.isLoadingMore) {
        _loadMeetings(
          loadMore: true,
          loadPast: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
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
                 previous.hasMorePast != current.hasMorePast ||
                 previous.hasMoreFuture != current.hasMoreFuture;
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

          if (state.groups?.isEmpty ?? true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64.w,
                    color: AppTheme.textGrey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No meetings yet',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  GestureDetector(
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
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: AppTheme.primaryBlue,
                            size: 20.w,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Schedule Your First Meeting',
                            style: TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _loadMeetings(refresh: true),
            child: GroupedMeetingsListView(
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
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.add),
        label: const Text('New Meeting'),
      ),
    );
  }
} 