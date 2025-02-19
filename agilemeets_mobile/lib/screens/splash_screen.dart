import 'package:agilemeets/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';
import '../utils/onboarding_preference.dart';
import 'dart:developer' as developer;
import 'dart:math';
import '../services/auth_navigation_service.dart';
import '../widgets/shared/error_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    Future.delayed(const Duration(milliseconds: 2000), _initializeApp);
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  Future<void> _initializeApp() async {
    if (!mounted || _isNavigating) return;
    
    try {
      _isNavigating = true;
      final hasSeenOnboarding = await OnboardingPreference.hasSeenOnboarding();
      if (!mounted) return;
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get current state before checking
      final currentState = context.read<AuthCubit>().state;
      developer.log(
        'Initial state: ${currentState.status} (signup: ${currentState.isInSignupFlow})',
        name: 'SplashScreen'
      );
      
      // Handle current state if it's already set and not in error
      if (currentState.status != AuthStatus.initial && 
          currentState.status != AuthStatus.loading &&
          currentState.error == null) {
        AuthNavigationService.handleAuthState(
          context,
          status: currentState.status,
          isInSignupFlow: currentState.isInSignupFlow,
          hasSeenOnboarding: hasSeenOnboarding,
        );
        return;
      }

      // Otherwise check auth status
      context.read<AuthCubit>().checkAuthStatus();
      developer.log('Checking auth status', name: 'SplashScreen');
      if (!mounted) return;
      
      // Listen for state changes
      bool handled = false;
      await for (final state in context.read<AuthCubit>().stream) {
        if (!mounted || handled) return;
        
        developer.log(
          'Auth state update: ${state.status} (signup: ${state.isInSignupFlow})',
          name: 'SplashScreen'
        );
        
        // Handle navigation when error is cleared or for non-network errors
        if (state.status != AuthStatus.loading && 
            (state.error == null || !state.error!.contains('Network error'))) {
          handled = true;
          AuthNavigationService.handleAuthState(
            context,
            status: state.status,
            isInSignupFlow: state.isInSignupFlow,
            hasSeenOnboarding: hasSeenOnboarding,
          );
        }
      }
      
    } catch (e) {
      developer.log(
        'Error during splash screen initialization',
        name: 'SplashScreen',
        error: e,
      );
      if (!mounted) return;
      
      // Let the AuthCubit handle the error state
      context.read<AuthCubit>().checkAuthStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          developer.log('Splash screen state: ${state.status}', name: 'Splash Screen');
          developer.log('Splash screen error: ${state.error}', name: 'Splash Screen');
          
          // Show error view for network errors with retry button
          if (state.error?.contains('Network error') ?? false) {
            return ErrorView(
              message: 'Network error. Please check your connection and try again.',
              onRetry: () async {
                _isNavigating = false; // Reset navigation flag
                context.read<AuthCubit>().checkAuthStatus(isRetrying: true);
                // Re-initialize app after retry
                await _initializeApp();
              },
              isRetrying: state.status == AuthStatus.loading,
            );
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlue.withValues(alpha:0.05),
                  AppTheme.backgroundGrey,
                ],
                stops: const [0.0, 0.8],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48.w,
                      height: 48.w,
                      child: CustomPaint(
                        painter: LoadingPainter(
                          animation: _rotateAnimation,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Agile Meets',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class LoadingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  LoadingPainter({required this.animation, required this.color}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw multiple arcs with different rotations and opacities
    for (int i = 0; i < 3; i++) {
      final rotationOffset = (i * 2 * pi / 3);
      final startAngle = animation.value * pi * 2 + rotationOffset;
      paint.color = color.withValues(alpha:1 - (i * 0.2));
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * pi / 4,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(LoadingPainter oldDelegate) => true;
}
