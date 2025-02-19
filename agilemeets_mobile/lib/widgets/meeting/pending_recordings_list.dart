import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../data/models/recording_metadata.dart';
import '../../logic/cubits/meeting/meeting_cubit.dart';
import '../../logic/cubits/meeting/meeting_state.dart';
import '../../utils/app_theme.dart';
import '../../utils/date_formatter.dart';
import 'audio_player.dart';
import 'upload_progress_widget.dart';

class PendingRecordingWidget extends StatelessWidget {
  final String meetingId;

  const PendingRecordingWidget({
    super.key,
    required this.meetingId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MeetingCubit, MeetingState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        
        if (state.status == MeetingStateStatus.uploadCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upload completed successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      },
      builder: (context, state) {
        final recording = state.pendingRecordings?.firstWhereOrNull(
          (r) => r.meetingId == meetingId,
        );
        
        if (recording == null) {
          return const SizedBox.shrink();
        }

        if (state.isAudioUploading && recording.status == RecordingUploadStatus.uploading) {
          return UploadProgressWidget(
            progress: state.audioUploadProgress ?? recording.uploadProgress ?? 0,
            onCancel: () => context.read<MeetingCubit>().cancelUpload(),
          );
        }

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  'Recording from ${DateFormatter.formatDateTime(recording.recordedAt)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _getStatusText(recording.status),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _getStatusColor(recording.status),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (recording.status == RecordingUploadStatus.failed)
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        color: AppTheme.warningOrange,
                        onPressed: () => _handleUpload(context, recording),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.errorRed,
                      onPressed: () => _showDeleteDialog(context, meetingId),
                    ),
                    if (recording.status == RecordingUploadStatus.pending)
                      IconButton(
                        icon: const Icon(Icons.upload),
                        color: AppTheme.primaryBlue,
                        onPressed: () => _handleUpload(context, recording),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: MeetingAudioPlayer.fromFile(
                  filePath: recording.filePath,
                ),
              ),
              if (recording.wasTimeLimited) ...[
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_off,
                        size: 14.r,
                        color: AppTheme.warningOrange,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Recording stopped - Time limit reached',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _handleUpload(BuildContext context, RecordingMetadata recording) async {
    try {
      await context.read<MeetingCubit>().uploadRecording(recording);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start upload: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String _getStatusText(RecordingUploadStatus status) {
    switch (status) {
      case RecordingUploadStatus.pending:
        return 'Pending Upload';
      case RecordingUploadStatus.compressing:
        return 'Compressing...';
      case RecordingUploadStatus.uploading:
        return 'Uploading...';
      case RecordingUploadStatus.failed:
        return 'Upload Failed';
      case RecordingUploadStatus.completed:
        return 'Completed';
    }
  }

  Color _getStatusColor(RecordingUploadStatus status) {
    switch (status) {
      case RecordingUploadStatus.pending:
        return AppTheme.textGrey;
      case RecordingUploadStatus.compressing:
        return AppTheme.warningOrange;
      case RecordingUploadStatus.uploading:
        return AppTheme.primaryBlue;
      case RecordingUploadStatus.failed:
        return AppTheme.errorRed;
      case RecordingUploadStatus.completed:
        return AppTheme.successGreen;
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, String meetingId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<MeetingCubit>().deletePendingRecording(meetingId);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}