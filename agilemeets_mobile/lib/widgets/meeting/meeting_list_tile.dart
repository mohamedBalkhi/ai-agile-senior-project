import 'package:flutter/material.dart';
import 'package:agilemeets/data/models/meeting_dto.dart';
import 'package:agilemeets/data/enums/meeting_status.dart';
import 'package:agilemeets/utils/timezone_utils.dart';
import 'package:intl/intl.dart';

class MeetingListTile extends StatelessWidget {
  final MeetingDTO meeting;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MeetingListTile({
    super.key,
    required this.meeting,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final localStartTime = TimezoneUtils.convertToLocalTime(meeting.startTime);
    final timeFormat = DateFormat('HH:mm');
    final isCompleted = meeting.status == MeetingStatus.completed;
    final isCancelled = meeting.status == MeetingStatus.cancelled;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      title: Text(
        meeting.title ?? 'Untitled Meeting',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: isCancelled ? TextDecoration.lineThrough : null,
              color: isCancelled
                  ? Theme.of(context).textTheme.bodySmall?.color
                  : isCompleted
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : null,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            timeFormat.format(localStartTime),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          if (meeting.projectName != null) ...[
            const SizedBox(height: 4),
            Text(
              meeting.projectName!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (meeting.hasAudio)
            Icon(
              Icons.mic,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          if (meeting.isRecurring) ...[
            if (meeting.hasAudio)
              const SizedBox(width: 8),
            Icon(
              Icons.repeat,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }
} 