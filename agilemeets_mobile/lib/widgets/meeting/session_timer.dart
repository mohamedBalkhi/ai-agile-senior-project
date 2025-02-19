import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_theme.dart';

class SessionTimer extends StatefulWidget {
  final bool isRecording;
  final bool isPaused;
  final Duration? initialDuration;

  const SessionTimer({
    super.key,
    required this.isRecording,
    required this.isPaused,
    this.initialDuration,
  });

  @override
  State<SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends State<SessionTimer> {
  Timer? _timer;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration ?? Duration.zero;
    if (widget.isRecording && !widget.isPaused) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(SessionTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording ||
        widget.isPaused != oldWidget.isPaused) {
      if (widget.isRecording && !widget.isPaused) {
        _startTimer();
      } else if (!widget.isRecording) {
        _timer?.cancel();
      }
    }
  }

  void _startTimer() {
    // Cancel any existing timer first
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && widget.isRecording && !widget.isPaused) {
        setState(() {
          _duration += const Duration(seconds: 1);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: widget.isPaused 
              ? AppTheme.warningYellow 
              : AppTheme.errorRed,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isPaused ? Icons.pause : Icons.timer_outlined,
            size: 16.r,
            color: widget.isPaused 
                ? AppTheme.warningYellow 
                : AppTheme.errorRed,
          ),
          SizedBox(width: 6.w),
          Text(
            _formatDuration(_duration),
            style: TextStyle(
              color: widget.isPaused 
                  ? AppTheme.warningYellow 
                  : AppTheme.errorRed,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}