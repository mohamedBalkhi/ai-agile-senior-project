import 'package:agilemeets/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/onboarding_preference.dart';
import 'signup_page.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      image: 'assets/svg/Meetings.svg',
      title: 'Run Better Agile Meetings',
      description: 'Make your daily standups, retros, and planning sessions more effective - whether in-person or remote.',
    ),
    const OnboardingPage(
      image: 'assets/svg/AI.svg',
      title: 'AI-Powered Meeting Analysis',
      description: 'Get automated key points, action items, and smart reports from your meetings using our AI assistant.',
    ),
    const OnboardingPage(
      image: 'assets/svg/Scheduling.svg',
      title: 'Meeting Scheduling',
      description: 'Schedule meetings and tasks easily with your team across different time zones.',
    ),
    const OnboardingPage(
      image: 'assets/svg/Tasks.svg',
      title: 'Simple Task Management',
      description: 'Track your team\'s tasks and view progress on basic agile boards.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlue.withOpacity(0.05),
                  AppTheme.backgroundGrey,
                ],
                stops: const [0.0, 0.8],
              ),
            ),
          ),
          
          // Content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (int page) {
                    setState(() => _currentPage = page);
                  },
                  itemBuilder: (context, index) => _pages[index],
                ),
              ),
              
              // Bottom navigation
              Container(
                padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: WormEffect(
                        dotColor: AppTheme.cardGrey,
                        activeDotColor: AppTheme.primaryBlue,
                        dotHeight: 8.h,
                        dotWidth: 8.w,
                        spacing: 8.w,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        if (_currentPage > 0)
                          TextButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: Text(
                              'Back',
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        Expanded(
                          child: CustomButton(
                            onPressed: () async {
                              if (_currentPage == _pages.length - 1) {
                                await OnboardingPreference.setOnboardingSeen();
                                if (!mounted) return;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                                );
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            text: _currentPage == _pages.length - 1 
                              ? 'Get Started' 
                              : 'Next',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            image,
            height: 280.h,
          ).animate()
            .fadeIn(duration: 600.ms)
            .scale(delay: 200.ms),
          SizedBox(height: 40.h),
          Text(
            title,
            style: AppTheme.headingLarge,
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(delay: 200.ms)
            .slideY(begin: 0.2, end: 0),
          SizedBox(height: 16.h),
          Text(
            description,
            style: AppTheme.subtitle,
            textAlign: TextAlign.center,
          ).animate()
            .fadeIn(delay: 400.ms)
            .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

