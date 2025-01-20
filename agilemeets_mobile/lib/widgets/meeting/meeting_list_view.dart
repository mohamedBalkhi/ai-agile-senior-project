import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/meeting_dto.dart';
import '../../utils/app_theme.dart';
import '../../utils/timezone_utils.dart';
import '../../data/enums/meeting_status.dart';
import '../../widgets/meeting/meeting_card.dart';
import '../../widgets/shared/loading_indicator.dart';
import 'package:intl/intl.dart';

class MeetingListView extends StatefulWidget {
  final List<MeetingDTO> meetings;
  final ScrollController scrollController;
  final bool hasMorePages;
  final bool showUpcomingOnly;

  const MeetingListView({
    super.key,
    required this.meetings,
    required this.scrollController,
    required this.hasMorePages,
    required this.showUpcomingOnly,
  });

  @override
  State<MeetingListView> createState() => _MeetingListViewState();
}

class _MeetingListViewState extends State<MeetingListView> {
  // Keep track of previously rendered groups
  final _renderedGroups = <DateTime>{};

  @override
  void dispose() {
    _renderedGroups.clear();
    super.dispose();
  }

  List<MeetingDTO> _filterAndSortMeetings(List<MeetingDTO> meetings) {
    var filtered = List<MeetingDTO>.from(meetings);
    
    if (widget.showUpcomingOnly) {
      filtered = filtered.where((m) => 
        m.status != MeetingStatus.completed && 
        m.status != MeetingStatus.cancelled
      ).toList();
    }

    filtered.sort((a, b) {
      final aTime = TimezoneUtils.convertToLocalTime(a.startTime);
      final bTime = TimezoneUtils.convertToLocalTime(b.startTime);
      return aTime.compareTo(bTime);
    });

    return filtered;
  }

  List<MeetingGroup> _groupMeetingsByDate(List<MeetingDTO> meetings) {
    final groups = <MeetingGroup>[];
    final now = DateTime.now();

    for (final meeting in meetings) {
      final localStartTime = TimezoneUtils.convertToLocalTime(meeting.startTime);
      final date = DateTime(localStartTime.year, localStartTime.month, localStartTime.day);
      
      final existingGroup = groups.firstWhere(
        (g) => g.date.year == date.year && 
               g.date.month == date.month && 
               g.date.day == date.day,
        orElse: () {
          final newGroup = MeetingGroup(date: date, meetings: []);
          groups.add(newGroup);
          return newGroup;
        },
      );

      if (!existingGroup.meetings.contains(meeting)) {
        existingGroup.meetings.add(meeting);
      }
    }

    return groups;
  }

  bool _shouldShowDateHeader(DateTime current, DateTime previous) {
    return current.year != previous.year ||
           current.month != previous.month ||
           current.day != previous.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    String dateText;
    if (date.year == now.year && 
        date.month == now.month && 
        date.day == now.day) {
      dateText = 'Today';
    } else if (date.year == tomorrow.year && 
               date.month == tomorrow.month && 
               date.day == tomorrow.day) {
      dateText = 'Tomorrow';
    } else if (date.year == yesterday.year && 
               date.month == yesterday.month && 
               date.day == yesterday.day) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('EEEE, MMMM d').format(date);
    }

    return Padding(
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
              dateText,
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
    );
  }

  bool _isNewGroup(MeetingGroup group) {
    final isNew = !_renderedGroups.contains(group.date);
    if (isNew) {
      _renderedGroups.add(group.date);
    }
    return isNew;
  }

  @override
  Widget build(BuildContext context) {
    // Filter and sort meetings first
    final filteredMeetings = _filterAndSortMeetings(widget.meetings);
    
    // Show empty state if no meetings after filtering
    if (filteredMeetings.isEmpty) {
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
              widget.showUpcomingOnly 
                ? 'No upcoming meetings'
                : 'No meetings yet',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      );
    }
    
    // Group meetings by date
    final groupedMeetings = _groupMeetingsByDate(filteredMeetings);

    return ListView.builder(
      controller: widget.scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: groupedMeetings.length,
      itemBuilder: (context, index) {
        final group = groupedMeetings[index];
        return Column(
          key: ValueKey('group_${group.date}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0 || _shouldShowDateHeader(group.date, groupedMeetings[index - 1].date))
              _buildDateHeader(group.date),
            ...group.meetings.map((meeting) => Padding(
              key: ValueKey('meeting_${meeting.id}'),
              padding: EdgeInsets.only(bottom: 8.h),
              child: MeetingCard(
                meeting: meeting,
              ),
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
    );
  }
}

class MeetingGroup {
  final DateTime date;
  final List<MeetingDTO> meetings;

  MeetingGroup({
    required this.date,
    required this.meetings,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeetingGroup &&
           date.year == other.date.year &&
           date.month == other.date.month &&
           date.day == other.date.day;
  }

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day);
}