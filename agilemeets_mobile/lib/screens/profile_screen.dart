import 'package:agilemeets/data/models/profile/profile_dto.dart';
import 'package:agilemeets/screens/profile/complete_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';
import '../logic/cubits/profile/profile_cubit.dart';
import '../logic/cubits/profile/profile_state.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final userId = context.read<AuthCubit>().state.userIdentifier;
    if (userId != null) {
      context.read<ProfileCubit>().loadProfile(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final profile = profileState.profile;
            final userName = profile?.fullName ?? authState.decodedToken?.fullName ?? 'User';
            final email = profile?.email ?? authState.decodedToken?.email ?? 'No email';

            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header with Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        children: [
                          Hero(
                            tag: 'profile_avatar',
                            child: Container(
                              width: 100.w,
                              height: 100.w,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue,
                                    AppTheme.secondaryBlue,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  userName[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ).animate().scale(delay: 200.ms),
                          
                          SizedBox(height: 16.h),
                          Text(
                            userName,
                            style: AppTheme.headingMedium,
                          ).animate().fadeIn().slideY(begin: 0.3),
                          SizedBox(height: 4.h),
                          Text(
                            email,
                            style: AppTheme.subtitle,
                          ).animate().fadeIn().slideY(begin: 0.3, delay: 100.ms),
                          
                          if (profile != null) ...[
                            SizedBox(height: 16.h),
                            _buildInfoChips(profile),
                          ],
                        ],
                      ),
                    ),

                    // Profile Sections
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          _buildSection(
                            'Account',
                            [
                              _buildProfileOption(
                                context,
                                'Edit Profile',
                                Icons.edit_outlined,
                                () => Navigator.push(
                                    context,
                                  MaterialPageRoute(
                                    builder: (_) => const CompleteProfileScreen(isNewUser: false),
                                  ),
                                ),
                                delay: 0,
                              ),
                              _buildProfileOption(
                                context,
                                'Change Password',
                                Icons.lock_outline_rounded,
                                () => /*Navigator.pushNamed(context, '/change-password')*/ {},
                                delay: 100,
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 16.h),
                          
                          _buildSection(
                            'Preferences',
                            [
                              _buildProfileOption(
                                context,
                                'Notifications',
                                Icons.notifications_none_rounded,
                                () {},
                                delay: 200,
                              ),
                              _buildProfileOption(
                                context,
                                'Language',
                                Icons.language_rounded,
                                () {},
                                delay: 300,
                              ),
                              _buildProfileOption(
                                context,
                                'Theme',
                                Icons.palette_outlined,
                                () {},
                                delay: 400,
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 24.h),
                          
                          CustomButton(
                            onPressed: () => context.read<AuthCubit>().logout(),
                            text: 'Logout',
                            
                          )
                          ,
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoChips(ProfileDTO profile) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: [
        if (profile.organizationName != null)
          _buildInfoChip(
            Icons.business_outlined,
            profile.organizationName!,
          ),
        if (profile.countryName != null)
          _buildInfoChip(
            Icons.location_on_outlined,
            profile.countryName!,
          ),
        if (profile.birthDate != null)
          _buildInfoChip(
            Icons.cake_outlined,
            DateFormat('MMM dd, yyyy').format(DateTime(
              profile.birthDate!.year,
              profile.birthDate!.month,
              profile.birthDate!.day,
            )),
          ),
      ].animate(interval: 100.ms).fadeIn().slideX(begin: 0.2, end: 0),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.w, color: AppTheme.textGrey),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              title,
              style: AppTheme.headingMedium.copyWith(fontSize: 18.sp),
            ),
          ),
          ...children,
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    required int delay,
  }) {
    final bool isLastItem = title == 'Theme';
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: !isLastItem ? const Border(
            bottom: BorderSide(
              color: AppTheme.cardBorderGrey,
              width: 1,
            ),
          ) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                size: 20.w,
                color: AppTheme.primaryBlue,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              title,
              style: AppTheme.bodyText,
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 24.w,
              color: AppTheme.textGrey,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }
}