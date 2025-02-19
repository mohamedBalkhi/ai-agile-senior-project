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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
      ..color = color.withValues(alpha:0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;
    
    // Number of waves to draw
    const int waveCount = 3;
    final path = Path();
    
    // Amplify the input amplitude for more dramatic effect
    final amplifiedAmplitude = math.pow(amplitude, 0.7).toDouble() * 1.5;
    
    // Draw multiple overlapping waves
    for (int wave = 0; wave < waveCount; wave++) {
      path.reset();
      path.moveTo(0, centerY);
      
      // Wave parameters - increased frequency range for more dynamic waves
      final frequency = 1.5 + wave * 0.8;  // More varied frequencies
      final phaseShift = wave * math.pi / 3;  // Wider phase shifts
      
      // Increased wave height and more dramatic scaling based on amplitude
      final waveHeight = height * 0.4 * amplifiedAmplitude * (1.0 - wave * 0.15);
      
      // Draw points along the wave
      for (double x = 0; x <= width; x += 1.5) { // Smaller step for smoother waves
        final progress = x / width;
        final normalizedX = progress * 2 * math.pi * frequency + phaseShift;
        
        // Add complexity to wave movement with compound sine waves
        final y = centerY + 
                 (math.sin(normalizedX) * 0.7 + math.sin(normalizedX * 1.5) * 0.3) * 
                 waveHeight * 
                 (isPaused ? 0.2 : 1.0);  // More dramatic pause reduction
        
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          // Enhanced curve smoothing
          final prevX = x - 1.5;
          final prevY = centerY + 
                       (math.sin((prevX / width * 2 * math.pi * frequency + phaseShift)) * 0.7 + 
                        math.sin((prevX / width * 2 * math.pi * frequency + phaseShift) * 1.5) * 0.3) * 
                       waveHeight * 
                       (isPaused ? 0.2 : 1.0);
          
          final controlX = (x + prevX) / 2;
          final controlY = (y + prevY) / 2;
          
          path.quadraticBezierTo(controlX, controlY, x, y);
        }
      }
      
      // Enhanced opacity variation between layers
      paint.color = color.withValues(alpha: 0.9 - wave * 0.25);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
