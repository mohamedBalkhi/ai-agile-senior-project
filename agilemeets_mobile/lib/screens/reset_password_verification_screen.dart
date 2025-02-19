import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';
import '../widgets/verification_code_widget.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class ResetPasswordVerificationScreen extends StatefulWidget {
  final String email;

  const ResetPasswordVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordVerificationScreen> createState() => _ResetPasswordVerificationScreenState();
}

class _ResetPasswordVerificationScreenState extends State<ResetPasswordVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _codeVerified = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Reset Password', style: TextStyle(fontSize: 18.sp)),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.resetCodeVerified) {
              setState(() => _codeVerified = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code verified! Please set your new password.')),
              );
            } else if (state.status == AuthStatus.passwordResetSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset successful!')),
              );
              Future.delayed(const Duration(seconds: 2), () {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              });
            } else if (state.status == AuthStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error ?? 'An error occurred')),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    if (!_codeVerified) ...[
                      AuthHeader(
                        showLogo: false,
                        icon: Icons.mark_email_read_outlined,
                        title: 'Check Your Email',
                        subtitle: 'Enter the verification code we sent to\n${widget.email}',
                        iconSize: 60.w,
                      ),
                      SizedBox(height: 32.h),
                      VerificationCodeWidget(
                        onCompleted: (code) {
                          context.read<AuthCubit>().verifyResetCode(code);
                        },
                        onResendPressed: () {
                          context.read<AuthCubit>().requestPasswordReset(widget.email);
                        },
                        errorText: state.error,
                        isLoading: state.status == AuthStatus.loading,
                        email: widget.email,
                      ),
                    ] else ...[
                      AuthHeader(
                        showLogo: false,
                        icon: Icons.lock_reset_rounded,
                        title: 'Set New Password',
                        subtitle: 'Create a strong password for your account',
                        iconSize: 60.w,
                      ),
                      SizedBox(height: 32.h),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            CustomTextField(
                              controller: _passwordController,
                              label: 'New Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              animationIndex: 0,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              animationIndex: 1,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      CustomButton(
                        onPressed: state.status == AuthStatus.loading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthCubit>().resetPassword(
                                    _passwordController.text,
                                  );
                                }
                              },
                        text: 'Reset Password',
                        isLoading: state.status == AuthStatus.loading,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
