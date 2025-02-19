
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';
import '../widgets/verification_code_widget.dart';
import '../widgets/auth_header.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          BlocBuilder<AuthCubit, AuthState>(
            buildWhen: (previous, current) => !current.isInSignupFlow,
            builder: (context, state) {
              if (!state.isInSignupFlow) {
                return TextButton.icon(
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Use Different Account'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: PopScope(
        canPop: false,
        child: BlocConsumer<AuthCubit, AuthState>(
          listenWhen: (previous, current) => 
              previous.status != current.status || 
              previous.error != current.error,
          listener: (context, state) {
            if (state.status == AuthStatus.organizationCreationRequired && state.isInSignupFlow) {
              context.read<AuthCubit>().clearErrors();
              Navigator.of(context).pushReplacementNamed('/create-organization');
            } else if (state.status == AuthStatus.error) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error ?? 'An error occurred')),
              );
            }
          },
          builder: (context, state) {
    
            if (state.error != null && state.status == AuthStatus.emailVerificationRequired) {
              context.read<AuthCubit>().clearErrors();
            }
            
            final email = state.userEmail;
            final name = state.decodedToken?.fullName;
            
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    if (!state.isInSignupFlow) ...[
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'This account requires email verification to continue',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ],
                    AuthHeader(
                      showLogo: false,
                      icon: Icons.mark_email_read_outlined,
                      title: 'Verify Your Email',
                      subtitle: !state.isInSignupFlow && name != null
                          ? 'Welcome back, $name!\nPlease verify your email address to continue'
                          : email != null 
                              ? 'Enter the verification code we sent to\n$email'
                              : 'Enter the verification code we sent to your email',
                      iconSize: 60.w,
                    ),
                    if (!state.isInSignupFlow && email != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    SizedBox(height: 32.h),
                    VerificationCodeWidget(
                      key: const ValueKey('verification_widget'),
                      onCompleted: (code) {
                        context.read<AuthCubit>().verifyEmail(code);
                      },
                      onResendPressed: () {
                        context.read<AuthCubit>().resendVerificationCode();
                      },
                      errorText: state.error,
                      isLoading: state.status == AuthStatus.loading,
                      email: email,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
