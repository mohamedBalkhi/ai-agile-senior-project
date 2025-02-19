import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/grouped_meetings_response.dart';
import '../../utils/app_theme.dart';
import '../../widgets/meeting/meeting_card.dart';

class GroupedMeetingsListView extends StatefulWidget {
  final List<MeetingGroupDTO> groups;
  final bool hasMore;
  final bool isLoading;
  final bool upcomingOnly;
  final Function()? onLoadMore;
  final Function(String)? onMeetingTap;
  final Function(String)? onMeetingLongPress;

  const GroupedMeetingsListView({
    super.key,
    required this.groups,
    required this.hasMore,
    required this.isLoading,
    required this.upcomingOnly,
    this.onLoadMore,
    this.onMeetingTap,
    this.onMeetingLongPress,
  });

  @override
  State<GroupedMeetingsListView> createState() => _GroupedMeetingsListViewState();
}

class _GroupedMeetingsListViewState extends State<GroupedMeetingsListView> {
  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty && !widget.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == widget.groups.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }

          final group = widget.groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
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
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: group.meetings.length,
                itemBuilder: (context, meetingIndex) {
                  final meeting = group.meetings[meetingIndex];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: MeetingCard(
                      meeting: meeting,
                      onTap: () => widget.onMeetingTap?.call(meeting.id),
                    ),
                  );
                },
              ),
            ],
          );
        },
        childCount: widget.groups.length + (widget.hasMore ? 1 : 0),
      ),
    );
  }
} 