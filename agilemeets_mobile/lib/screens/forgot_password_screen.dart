import 'package:agilemeets/widgets/auth_header.dart';
import 'package:agilemeets/widgets/custom_button.dart';
import 'package:agilemeets/widgets/custom_card.dart';
import 'package:agilemeets/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../logic/cubits/auth/auth_cubit.dart';
import '../logic/cubits/auth/auth_state.dart';
import '../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.resetCodeSent) {
            Navigator.of(context).pushReplacementNamed(
              '/reset-password',
              arguments: state.email,
            );
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error ?? 'An error occurred')),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(width: 16.w),
                        Text(
                          'Reset Password',
                          style: AppTheme.headingMedium,
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      children: [
                        const AuthHeader(
                          icon: Icons.lock_reset_outlined,
                          showLogo: false,
                          title: 'Forgot Password?',
                          subtitle: 'Enter your email to receive a reset code',
                        ),
                        SizedBox(height: 32.h),
                        Form(
                          key: _formKey,
                          child: CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 24.h),
                        CustomButton(
                          onPressed: state.status == AuthStatus.loading
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthCubit>().requestPasswordReset(
                                      _emailController.text,
                                    );
                                  }
                                },
                          text: 'Send Reset Code',
                          isLoading: state.status == AuthStatus.loading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
