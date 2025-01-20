import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_theme.dart';

class AudioWaveform extends StatefulWidget {
  final double amplitude; // 0.0 to 1.0
  final bool isRecording;
  final bool isPaused;

  const AudioWaveform({
    super.key,
    required this.amplitude,
    required this.isRecording,
    required this.isPaused,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AudioWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !widget.isPaused) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      _animationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _AudioWaveformPainter(
              amplitude: widget.amplitude,
              isRecording: widget.isRecording,
              isPaused: widget.isPaused,
              color: widget.isPaused
                  ? AppTheme.textGrey
                  : AppTheme.primaryBlue,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _AudioWaveformPainter extends CustomPainter {
  final double amplitude;
  final bool isRecording;
  final bool isPaused;
  final Color color;

  _AudioWaveformPainter({
    required this.amplitude,
    required this.isRecording,
    required this.isPaused,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRecording) return;

    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    
    // Number of waves to draw
    const int waveCount = 3;
    final path = Path();
    
    // Draw multiple overlapping waves
    for (int wave = 0; wave < waveCount; wave++) {
      path.reset();
      path.moveTo(0, centerY);
      
      // Wave parameters
      final frequency = 2.0 + wave * 0.5;  // Different frequency for each wave
      final phaseShift = wave * math.pi / 4;    // Offset each wave
      final waveHeight = height * 0.3 * amplitude * (1.0 - wave * 0.2);
      
      // Draw points along the wave
      for (double x = 0; x <= width; x += 2) {
        final progress = x / width;
        final normalizedX = progress * 2 * math.pi * frequency + phaseShift;
        
        // Combine sine waves for more natural movement
        final y = centerY + 
                 math.sin(normalizedX) * waveHeight * 
                 (isPaused ? 0.3 : 1.0);  // Reduce amplitude when paused
        
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          // Use quadratic bezier curve for smoother waves
          final prevX = x - 2;
          final prevY = centerY + 
                       math.sin(prevX / width * 2 * math.pi * frequency + phaseShift) * 
                       waveHeight * (isPaused ? 0.3 : 1.0);
          
          final controlX = (x + prevX) / 2;
          final controlY = (y + prevY) / 2;
          
          path.quadraticBezierTo(controlX, controlY, x, y);
        }
      }
      
      // Draw the wave with slightly different opacity for each layer
      paint.color = color.withOpacity(0.8 - wave * 0.2);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
