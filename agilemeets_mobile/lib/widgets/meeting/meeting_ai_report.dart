import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:agilemeets/data/models/meeting_ai_report_dto.dart';
import 'package:agilemeets/data/enums/ai_processing_status.dart';
import 'package:agilemeets/utils/app_theme.dart';
import 'package:shimmer/shimmer.dart';

class MeetingAIReport extends StatefulWidget {
  final MeetingAIReportDTO report;
  final VoidCallback? onRefresh;

  const MeetingAIReport({
    super.key,
    required this.report,
    this.onRefresh,
  });

  @override
  State<MeetingAIReport> createState() => _MeetingAIReportState();
}

class _MeetingAIReportState extends State<MeetingAIReport> {
  bool _isExpanded = true;
  bool _showFullTranscript = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (_isExpanded) ...[
            if (widget.report.processingStatus == AIProcessingStatus.completed) ...[
              _buildSummarySection(),
              if (widget.report.keyPoints?.isNotEmpty ?? false) _buildKeyPointsSection(),
              if (widget.report.transcript != null) _buildTranscriptSection(),
            ] else ...[
              _buildProcessingStatus(),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppTheme.cardGrey,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(_isExpanded ? 0 : 16.r),
            bottomRight: Radius.circular(_isExpanded ? 0 : 16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppTheme.primaryBlue,
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Meeting AI Report',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            Row(
              children: [
                if (widget.onRefresh != null &&
                    widget.report.processingStatus != AIProcessingStatus.completed)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
                    onPressed: widget.onRefresh,
                  ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppTheme.textGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingStatus() {
    if (widget.report.processingStatus == AIProcessingStatus.notStarted) {
      return Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.textGrey,
              size: 16.w,
            ),
            SizedBox(width: 8.w),
            Text(
              _getStatusMessage(),
              style: TextStyle(
                color: AppTheme.textGrey,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.report.processingStatus == AIProcessingStatus.processing ||
              widget.report.processingStatus == AIProcessingStatus.onQueue)
            Shimmer.fromColors(
              baseColor: AppTheme.cardGrey,
              highlightColor: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12.h,
                    width: 0.8.sw,
                    decoration: BoxDecoration(
                      color: AppTheme.cardGrey,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 12.h,
                    width: 0.6.sw,
                    decoration: BoxDecoration(
                      color: AppTheme.cardGrey,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: widget.report.processingStatus == AIProcessingStatus.failed ? 1.0 : null,
                  backgroundColor: AppTheme.cardGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.report.processingStatus == AIProcessingStatus.failed
                        ? AppTheme.errorRed
                        : AppTheme.progressBlue,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      widget.report.processingStatus == AIProcessingStatus.failed
                          ? Icons.error_outline
                          : Icons.info_outline,
                      color: widget.report.processingStatus == AIProcessingStatus.failed
                          ? AppTheme.errorRed
                          : AppTheme.textGrey,
                      size: 16.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      _getStatusMessage(),
                      style: TextStyle(
                        color: widget.report.processingStatus == AIProcessingStatus.failed
                            ? AppTheme.errorRed
                            : AppTheme.textGrey,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.cardGrey,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                color: AppTheme.primaryBlue,
                size: 18.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Summary',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            widget.report.summary ?? 'No summary available',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPointsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.cardGrey,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryBlue,
                size: 18.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Key Points',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...widget.report.keyPoints!.map((point) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 14.sp,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection() {
    final transcript = widget.report.transcript ?? 'No transcript available';
    final shouldTruncate = transcript.length > 500 && !_showFullTranscript;
    final displayText = shouldTruncate
        ? '${transcript.substring(0, 500)}...'
        : transcript;

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over,
                color: AppTheme.primaryBlue,
                size: 18.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Transcript',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            displayText,
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          if (transcript.length > 500) ...[
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () => setState(() => _showFullTranscript = !_showFullTranscript),
              child: Text(
                _showFullTranscript ? 'Show Less' : 'Show More',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusMessage() {
    switch (widget.report.processingStatus) {
      case AIProcessingStatus.notStarted:
        return 'AI processing not started';
      case AIProcessingStatus.onQueue:
        return 'Queued for processing';
      case AIProcessingStatus.processing:
        return 'Processing meeting content...';
      case AIProcessingStatus.completed:
        return 'Processing completed';
      case AIProcessingStatus.failed:
        return 'Processing failed.';
      default:
        return 'Unknown status';
    }
  }
}
