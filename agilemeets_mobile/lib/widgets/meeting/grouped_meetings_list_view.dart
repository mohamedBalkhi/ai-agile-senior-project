import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/grouped_meetings_response.dart';
import '../../utils/app_theme.dart';
import '../../widgets/meeting/meeting_card.dart';
import '../../widgets/shared/loading_indicator.dart';
import '../../data/models/meeting_dto.dart';

class GroupedMeetingsListView extends StatefulWidget {
  final List<MeetingGroupDTO> groups;
  final ScrollController scrollController;
  final bool hasMorePast;
  final bool hasMoreFuture;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMorePast;
  final Future<void> Function() onLoadMoreFuture;
  final Future<void> Function()? onRefresh;

  const GroupedMeetingsListView({
    super.key,
    required this.groups,
    required this.scrollController,
    required this.hasMorePast,
    required this.hasMoreFuture,
    required this.isLoadingMore,
    required this.onLoadMorePast,
    required this.onLoadMoreFuture,
    this.onRefresh,
  });

  @override
  State<GroupedMeetingsListView> createState() => _GroupedMeetingsListViewState();
}

class _GroupedMeetingsListViewState extends State<GroupedMeetingsListView> {
  final _renderedGroups = <DateTime>{};
  bool _isLoadingPast = false;
  bool _isLoadingFuture = false;
  bool _isProgrammaticScroll = false;
  
  // Track last load positions to prevent multiple loads
  double? _lastPastLoadPosition;
  double? _lastFutureLoadPosition;

  @override
  void dispose() {
    _renderedGroups.clear();
    super.dispose();
  }

  bool _isNewGroup(MeetingGroupDTO group) {
    final isNew = !_renderedGroups.contains(group.date);
    if (isNew) {
      _renderedGroups.add(group.date);
    }
    return isNew;
  }

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  Future<void> _handleScroll() async {
    if (_isProgrammaticScroll) return;

    final currentPosition = widget.scrollController.position.pixels;
    final maxScroll = widget.scrollController.position.maxScrollExtent;

    // Near top - load past meetings
    if (currentPosition < 100 && 
        !_isLoadingPast && 
        widget.hasMorePast && 
        !widget.isLoadingMore &&
        (_lastPastLoadPosition == null || 
         currentPosition < _lastPastLoadPosition! - 50)) {
      setState(() {
        _isLoadingPast = true;
        _lastPastLoadPosition = currentPosition;
      });
      
      // Prevent the refresh indicator from triggering
      if (currentPosition < 50) {
        _isProgrammaticScroll = true;
        await widget.scrollController.animateTo(
          50,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
        _isProgrammaticScroll = false;
      }

      await widget.onLoadMorePast();
      if (mounted) {
        setState(() {
          _isLoadingPast = false;
          // Reset future load position when loading past
          _lastFutureLoadPosition = null;
        });
      }
    }
    
    // Near bottom - load future meetings
    if (maxScroll - currentPosition < 200 && 
        !_isLoadingFuture && 
        widget.hasMoreFuture && 
        !widget.isLoadingMore) {  // Removed position check to allow continuous loading
      setState(() {
        _isLoadingFuture = true;
        _lastFutureLoadPosition = currentPosition;
      });
      
      await widget.onLoadMoreFuture();
      if (mounted) {
        setState(() {
          _isLoadingFuture = false;
          // Don't reset past load position when loading future
          // This allows continuous loading in either direction
        });
      }
    }

    // Only reset load position trackers when significantly changing direction
    if (currentPosition < maxScroll * 0.3) {  // In top 30%
      _lastFutureLoadPosition = null;  // Allow future loads when going back down
    } else if (currentPosition > maxScroll * 0.7) {  // In bottom 30%
      _lastPastLoadPosition = null;  // Allow past loads when going back up
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64.w,
              color: AppTheme.textGrey,
            ),
            SizedBox(height: 16.h),
            Text(
              'No meetings found',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    Widget listView = CustomScrollView(
      controller: widget.scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Past meetings loading indicator
        if (widget.hasMorePast)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: 8.h,
                bottom: 16.h,
              ),
              child: Center(
                child: _isLoadingPast
                    ? const LoadingIndicator()
                    : TextButton.icon(
                        onPressed: () async {
                          setState(() => _isLoadingPast = true);
                          await widget.onLoadMorePast();
                          if (mounted) setState(() => _isLoadingPast = false);
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Load Past Meetings'),
                      ),
              ),
            ),
          ),

        // Meeting groups
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final group = widget.groups[index];
                return Column(
                  key: ValueKey('group_${group.date}'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: 16.h,
                        bottom: 8.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text(
                              group.groupTitle,
                              style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              indent: 12.w,
                              color: AppTheme.cardBorderGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...group.meetings.map((meeting) => Padding(
                      key: ValueKey('meeting_${meeting.id}'),
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: MeetingCard(meeting: meeting),
                    )),
                  ],
                ).animate(
                  key: ValueKey('anim_${group.date}'),
                  effects: [
                    if (_isNewGroup(group))
                      FadeEffect(
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
                  ],
                );
              },
              childCount: widget.groups.length,
            ),
          ),
        ),

        // Future meetings loading indicator
        if (widget.hasMoreFuture)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: 16.h,
                bottom: 8.h,
              ),
              child: Center(
                child: _isLoadingFuture
                    ? const LoadingIndicator()
                    : TextButton.icon(
                        onPressed: () async {
                          setState(() => _isLoadingFuture = true);
                          await widget.onLoadMoreFuture();
                          if (mounted) setState(() => _isLoadingFuture = false);
                        },
                        icon: const Icon(Icons.update),
                        label: const Text('Load More Meetings'),
                      ),
              ),
            ),
          ),
      ],
    );

    // Only wrap in RefreshIndicator if onRefresh is provided
    if (widget.onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: () async {
          // Only allow refresh if we're at the very top and not loading past meetings
          if (!_isLoadingPast && widget.scrollController.position.pixels <= 0) {
            await widget.onRefresh!();
          }
        },
        child: listView,
      );
    }

    return listView;
  }
} 