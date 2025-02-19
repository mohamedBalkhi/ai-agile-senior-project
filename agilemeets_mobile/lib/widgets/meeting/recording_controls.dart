import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_theme.dart';

class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final bool isProcessing;
  final VoidCallback onStartRecording;
  final VoidCallback onPauseRecording;
  final VoidCallback onResumeRecording;
  final VoidCallback onStopRecording;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.isPaused,
    this.isProcessing = false,
    required this.onStartRecording,
    required this.onPauseRecording,
    required this.onResumeRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isRecording) ...[
            // Start Recording Button
            _buildControlButton(
              onTap: onStartRecording,
              icon: Icons.fiber_manual_record_rounded,
              backgroundColor: AppTheme.primaryBlue.withValues(alpha:0.1),
              iconColor: AppTheme.primaryBlue,
              size: 64.r,
              iconSize: 32.r,
            ),
          ] else if (isProcessing) ...[
            // Processing indicator
            SizedBox(
              width: 64.r,
              height: 64.r,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          ] else ...[
            // Pause/Resume Button
            _buildControlButton(
              onTap: isPaused ? onResumeRecording : onPauseRecording,
              icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              backgroundColor: isPaused 
                  ? AppTheme.successGreen.withValues(alpha:0.1)
                  : AppTheme.warningYellow.withValues(alpha:0.1),
              iconColor: isPaused ? AppTheme.successGreen : AppTheme.warningYellow,
              size: 64.r,
              iconSize: 32.r,
            ),
            SizedBox(width: 24.w),
            // Stop Recording Button
            _buildControlButton(
              onTap: onStopRecording,
              icon: Icons.stop_rounded,
              backgroundColor: AppTheme.errorRed.withValues(alpha:0.1),
              iconColor: AppTheme.errorRed,
              size: 52.r,
              iconSize: 24.r,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required double size,
    required double iconSize,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(size / 2),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha:0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}